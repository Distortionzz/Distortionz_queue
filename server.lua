-- =====================================================================
--  Distortionz Queue · server.lua
--  Premium timed connection queue for FiveM / Qbox
--  Polished live dashboard · real position · server stats · phases
-- =====================================================================

local SERVER_START      = os.time()                 -- uptime anchor (resource start)
local connectingPlayers = {}                         -- identifier -> { seq, name, startedAt }
local connectSeq        = 0                          -- monotonic connection counter

-- ─── Helpers ────────────────────────────────────────────────────────

local function GetPlayerIdentifier(source)
    local identifiers = GetPlayerIdentifiers(source)
    for _, identifier in ipairs(identifiers) do
        if identifier:find('license:') then
            return identifier
        end
    end
    return identifiers[1] or ('source:' .. tostring(source))
end

local function MakeProgressBar(percent, length)
    length = length or 22
    percent = math.max(0, math.min(100, percent or 0))
    local filled = math.floor((percent / 100) * length + 0.5)
    return string.rep('█', filled) .. string.rep('░', length - filled)
end

local SPINNER_FRAMES = { '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏' }
local function MakeSpinner(step)
    return SPINNER_FRAMES[((step - 1) % #SPINNER_FRAMES) + 1]
end

local DOT_FRAMES = { '.', '..', '...', '....' }
local function MakeDots(step)
    return DOT_FRAMES[((step - 1) % #DOT_FRAMES) + 1]
end

local function GetStatusMessage(step)
    local messages = Config.StatusMessages or {}
    if #messages == 0 then return 'Preparing connection' end
    return messages[((step - 1) % #messages) + 1]
end

local function GetTip(step)
    local tips = Config.Tips or {}
    if #tips == 0 then
        return Config.Text.footer or 'Please wait while we prepare your session.'
    end
    return tips[((step - 1) % #tips) + 1]
end

local function GetMaxClients()
    return GetConvarInt('sv_maxclients', 48)
end

local function GetOnlineCount()
    return #GetPlayers()
end

local function GetSlotsFree()
    return math.max(0, GetMaxClients() - GetOnlineCount())
end

local function GetCapacityPercent()
    local max = GetMaxClients()
    if max <= 0 then return 0 end
    return math.max(0, math.min(100, math.floor((GetOnlineCount() / max) * 100 + 0.5)))
end

local function FormatUptime(seconds)
    seconds = math.max(0, math.floor(seconds or 0))
    local d = math.floor(seconds / 86400); seconds = seconds - d * 86400
    local h = math.floor(seconds / 3600);  seconds = seconds - h * 3600
    local m = math.floor(seconds / 60)
    local s = seconds - m * 60
    if d > 0 then return ('%dd %02dh %02dm'):format(d, h, m) end
    if h > 0 then return ('%dh %02dm'):format(h, m) end
    if m > 0 then return ('%dm %02ds'):format(m, s) end
    return ('%ds'):format(s)
end

local function GetUptimeString()
    return FormatUptime(os.time() - SERVER_START)
end

local function GetClockParts()
    local t = Config.Time or {}
    local timeFmt = t.clock24 and '%H:%M:%S' or '%I:%M:%S %p'
    return os.date(timeFmt), os.date(t.dateFormat or '%a %d %b %Y')
end

-- Phase resolver: spreads Config.Phases evenly across the wait.
local function GetPhase(step, totalSteps)
    local phases = Config.Phases or {}
    local n = #phases
    if n == 0 then
        return { icon = '⏳', name = GetStatusMessage(step) }, 1, 1
    end
    local prop = (step - 0.5) / math.max(1, totalSteps)
    local idx  = math.floor(prop * n) + 1
    if idx < 1 then idx = 1 elseif idx > n then idx = n end
    return phases[idx], idx, n
end

local function PhasePips(idx, n)
    local out = {}
    for i = 1, n do out[i] = (i <= idx) and '●' or '○' end
    return table.concat(out, '  ')
end

-- Live position among players currently in the sync wait.
local function GetPositionInfo(mySeq)
    local total, ahead = 0, 0
    for _, v in pairs(connectingPlayers) do
        total = total + 1
        if v.seq and v.seq < mySeq then ahead = ahead + 1 end
    end
    if total < 1 then total = 1 end
    return ahead + 1, total
end

-- ─── Card building blocks ───────────────────────────────────────────

local function BuildHeaderColumns()
    local columns = {}

    if Config.Branding.logoUrl and Config.Branding.logoUrl ~= '' then
        columns[#columns + 1] = {
            type = 'Column', width = 'auto',
            items = {
                {
                    type    = 'Image',
                    url     = Config.Branding.logoUrl,
                    size    = 'Medium',
                    style   = 'Default',
                    altText = Config.Branding.serverName,
                }
            }
        }
    else
        columns[#columns + 1] = {
            type = 'Column', width = 'auto',
            verticalContentAlignment = 'Center',
            items = {
                {
                    type   = 'TextBlock',
                    text   = Config.Branding.fallbackIcon or '🟡',
                    size   = 'ExtraLarge',
                    weight = 'Bolder',
                }
            }
        }
    end

    columns[#columns + 1] = {
        type = 'Column', width = 'stretch',
        verticalContentAlignment = 'Center',
        items = {
            {
                type   = 'TextBlock',
                text   = Config.Branding.serverName,
                size   = 'ExtraLarge',
                weight = 'Bolder',
                color  = Config.Colors.panelTitle,
                wrap   = true,
            },
            {
                type     = 'TextBlock',
                text     = Config.Branding.tagline,
                size     = 'Small',
                spacing  = 'None',
                isSubtle = true,
                wrap     = true,
            }
        }
    }

    if Config.Stats and Config.Stats.showClock then
        local clock, date = GetClockParts()
        columns[#columns + 1] = {
            type = 'Column', width = 'auto',
            verticalContentAlignment = 'Center',
            items = {
                {
                    type                = 'TextBlock',
                    text                = clock,
                    size                = 'Medium',
                    weight              = 'Bolder',
                    color               = Config.Colors.accent,
                    horizontalAlignment = 'Right',
                },
                {
                    type                = 'TextBlock',
                    text                = date,
                    size                = 'Small',
                    spacing             = 'None',
                    isSubtle            = true,
                    horizontalAlignment = 'Right',
                }
            }
        }
    end

    return columns
end

local function StatTile(label, value)
    return {
        type = 'Column', width = 'stretch', style = 'emphasis',
        items = {
            { type = 'TextBlock', text = label, size = 'Small',  weight = 'Bolder', color = 'accent', isSubtle = true, wrap = true },
            { type = 'TextBlock', text = value, size = 'Large',   weight = 'Bolder', spacing = 'None', wrap = true },
        }
    }
end

-- Chunks enabled tiles into rows of three for a dashboard grid.
local function StatGridRows(tiles)
    local rows = {}
    for i = 1, #tiles, 3 do
        local cols = {}
        for j = i, math.min(i + 2, #tiles) do
            cols[#cols + 1] = tiles[j]
        end
        rows[#rows + 1] = {
            type    = 'ColumnSet',
            spacing = (i == 1) and 'Medium' or 'Small',
            columns = cols,
        }
    end
    return rows
end

local function ProgressRow(label, percent, color)
    percent = math.max(0, math.min(100, percent or 0))
    return {
        type = 'ColumnSet', spacing = 'Small',
        columns = {
            {
                type = 'Column', width = 'auto',
                verticalContentAlignment = 'Center',
                items = {
                    { type = 'TextBlock', text = label, size = 'Small', weight = 'Bolder', isSubtle = true }
                }
            },
            {
                type = 'Column', width = 'stretch',
                verticalContentAlignment = 'Center',
                items = {
                    {
                        type     = 'TextBlock',
                        text     = MakeProgressBar(percent, 22),
                        fontType = 'Monospace',
                        color    = color,
                        size     = 'Medium',
                    }
                }
            },
            {
                type = 'Column', width = 'auto',
                verticalContentAlignment = 'Center',
                items = {
                    { type = 'TextBlock', text = ('%d%%'):format(percent), weight = 'Bolder', color = color }
                }
            }
        }
    }
end

-- ─── Adaptive Card (queue / maintenance share one builder) ──────────

local function BuildConnectionCard(opts)
    local playerName   = opts.playerName
    local secondsLeft  = opts.secondsLeft
    local totalSeconds = opts.totalSeconds
    local step         = opts.step
    local maintenance  = opts.maintenance and Config.Maintenance or nil

    local phase, phaseIdx, phaseCount = GetPhase(step, totalSeconds)
    local spinner    = MakeSpinner(step)
    local dots       = MakeDots(step)
    local statusText = GetStatusMessage(step)
    local tip        = GetTip(step)

    local percent = math.floor(((totalSeconds - secondsLeft) / totalSeconds) * 100)
    if percent < 0 then percent = 0 elseif percent > 100 then percent = 100 end

    local S = Config.Stats or {}
    local tiles = {}
    if S.showPosition then
        tiles[#tiles + 1] = StatTile('POSITION', ('#%d / %d'):format(opts.position or 1, opts.totalSyncing or 1))
    end
    if S.showWait then
        tiles[#tiles + 1] = StatTile('WAIT TIME', ('%ds'):format(secondsLeft))
    end
    if S.showOnline then
        tiles[#tiles + 1] = StatTile('ONLINE', ('%d / %d'):format(GetOnlineCount(), GetMaxClients()))
    end
    if S.showSlots then
        tiles[#tiles + 1] = StatTile('SLOTS FREE', ('%d'):format(GetSlotsFree()))
    end
    if S.showUptime then
        tiles[#tiles + 1] = StatTile('UPTIME', GetUptimeString())
    end
    if S.showCapacity then
        tiles[#tiles + 1] = StatTile('CAPACITY', ('%d%%'):format(GetCapacityPercent()))
    end

    -- HERO block (queue vs maintenance copy)
    local heroItems
    if maintenance then
        heroItems = {
            {
                type   = 'TextBlock',
                text   = ('%s %s'):format(maintenance.icon or '🛠️', maintenance.title or 'Maintenance in progress'),
                size   = 'Large',
                weight = 'Bolder',
                color  = 'warning',
                wrap   = true,
            },
            {
                type    = 'TextBlock',
                text    = maintenance.message or 'Your connection will continue normally.',
                spacing = 'Small',
                wrap    = true,
            },
            {
                type    = 'TextBlock',
                text    = ('Welcome, %s'):format(playerName or 'Guest'),
                spacing = 'Small',
                isSubtle = true,
                wrap    = true,
            },
        }
    else
        heroItems = {
            {
                type   = 'TextBlock',
                text   = Config.Text.welcomeTitle or 'Preparing your connection',
                size   = 'Large',
                weight = 'Bolder',
                wrap   = true,
            },
            {
                type    = 'TextBlock',
                text    = ('Welcome, %s'):format(playerName or 'Guest'),
                spacing = 'Small',
                wrap    = true,
            },
            {
                type    = 'TextBlock',
                text    = ('%s %s%s'):format(spinner, statusText, dots),
                color   = Config.Colors.accent,
                spacing = 'Small',
                wrap    = true,
            },
        }
    end

    local body = {
        -- HEADER
        {
            type  = 'Container',
            style = 'emphasis',
            bleed = true,
            items = {
                { type = 'ColumnSet', columns = BuildHeaderColumns() }
            }
        },

        -- HERO
        {
            type    = 'Container',
            spacing = 'Medium',
            items   = heroItems,
        },

        -- PHASE INDICATOR
        {
            type    = 'Container',
            style   = 'emphasis',
            spacing = 'Medium',
            items   = {
                {
                    type = 'ColumnSet',
                    columns = {
                        {
                            type = 'Column', width = 'stretch',
                            verticalContentAlignment = 'Center',
                            items = {
                                {
                                    type   = 'TextBlock',
                                    text   = ('%s  Phase %d of %d · %s'):format(
                                        phase.icon or '⏳', phaseIdx, phaseCount, phase.name or 'Working'
                                    ),
                                    weight = 'Bolder',
                                    wrap   = true,
                                }
                            }
                        },
                        {
                            type = 'Column', width = 'auto',
                            verticalContentAlignment = 'Center',
                            items = {
                                {
                                    type                = 'TextBlock',
                                    text                = PhasePips(phaseIdx, phaseCount),
                                    color               = Config.Colors.accent,
                                    weight              = 'Bolder',
                                    horizontalAlignment = 'Right',
                                }
                            }
                        }
                    }
                }
            }
        },
    }

    -- STATS GRID
    for _, row in ipairs(StatGridRows(tiles)) do
        body[#body + 1] = row
    end

    -- DUAL PROGRESS (your sync + server capacity)
    body[#body + 1] = {
        type    = 'Container',
        spacing = 'Medium',
        items   = {
            ProgressRow('Sync     ', percent, Config.Colors.progress),
            ProgressRow('Capacity ', GetCapacityPercent(), Config.Colors.capacity),
        }
    }

    -- TIP
    body[#body + 1] = {
        type    = 'Container',
        style   = 'good',
        spacing = 'Medium',
        items   = {
            { type = 'TextBlock', text = '💡 Did you know?', size = 'Small', weight = 'Bolder', color = 'accent' },
            { type = 'TextBlock', text = tip, spacing = 'Small', isSubtle = true, wrap = true },
        }
    }

    -- FOOTER
    local footerText
    if maintenance then
        footerText = maintenance.footer or 'Maintenance mode · every connection still syncs normally'
    else
        footerText = ('Queue mode: %s  ·  Build %s'):format(
            Config.Queue.queueMode or 'Timed sync access',
            Config.Script.version or '1.3.0'
        )
    end
    body[#body + 1] = {
        type                = 'TextBlock',
        text                = footerText,
        size                = 'Small',
        isSubtle            = true,
        horizontalAlignment = 'Center',
        spacing             = 'Medium',
        wrap                = true,
    }

    return {
        type        = 'AdaptiveCard',
        ['$schema'] = 'http://adaptivecards.io/schemas/adaptive-card.json',
        version     = '1.5',
        body        = body,
        actions     = {
            { type = 'Action.OpenUrl', title = '💬 Discord', url = Config.Branding.discord },
            { type = 'Action.OpenUrl', title = '📜 Rules',   url = Config.Branding.rules   },
            { type = 'Action.OpenUrl', title = '🌐 Website', url = Config.Branding.website },
        }
    }
end

-- ─── Adaptive Card (approved / end-of-sync summary) ─────────────────

local function BuildApprovedCard(summary)
    return {
        type        = 'AdaptiveCard',
        ['$schema'] = 'http://adaptivecards.io/schemas/adaptive-card.json',
        version     = '1.5',
        body = {
            {
                type  = 'Container',
                style = 'emphasis',
                bleed = true,
                items = {
                    { type = 'ColumnSet', columns = BuildHeaderColumns() }
                }
            },
            {
                type    = 'Container',
                spacing = 'Medium',
                items   = {
                    {
                        type   = 'TextBlock',
                        text   = ('✅ %s'):format(Config.Text.doneTitle or 'Connection approved'),
                        size   = 'ExtraLarge',
                        weight = 'Bolder',
                        color  = 'good',
                        wrap   = true,
                    },
                    {
                        type    = 'TextBlock',
                        text    = Config.Text.doneMessage or 'Welcome to the city — loading you in now.',
                        spacing = 'Small',
                        wrap    = true,
                    }
                }
            },
            {
                type    = 'Container',
                style   = 'good',
                spacing = 'Medium',
                items   = {
                    {
                        type  = 'FactSet',
                        facts = {
                            { title = 'Player',         value = summary.name or 'Guest' },
                            { title = 'You waited',     value = ('%ds'):format(summary.waited or 0) },
                            { title = 'Granted slot',   value = ('#%d'):format(summary.position or 1) },
                            { title = 'Players online', value = ('%d / %d'):format(summary.online or 0, summary.max or 0) },
                            { title = 'Slots free',     value = ('%d'):format(summary.slotsFree or 0) },
                            { title = 'Server uptime',  value = summary.uptime or '0s' },
                        }
                    }
                }
            },
            {
                type                = 'TextBlock',
                text                = ('%s  ·  Build %s'):format(
                    Config.Branding.serverName or 'Server',
                    Config.Script.version or '1.3.0'
                ),
                size                = 'Small',
                isSubtle            = true,
                horizontalAlignment = 'Center',
                spacing             = 'Medium',
                wrap                = true,
            }
        }
    }
end

-- ─── Card presenters with plain-text fallback ───────────────────────

local function ShowConnectionCard(deferrals, opts)
    local ok, err = pcall(function()
        deferrals.presentCard(BuildConnectionCard(opts))
    end)
    if ok then return end

    local phase = GetPhase(opts.step, opts.totalSeconds)
    local percent = math.floor(((opts.totalSeconds - opts.secondsLeft) / opts.totalSeconds) * 100)
    deferrals.update((
        '%s — %s\n\n%s %s\nPosition: #%d / %d   Online: %d/%d   Uptime: %s\nProgress: %d%%   Time remaining: %ds\n\n%s'
    ):format(
        Config.Branding.serverName, Config.Branding.tagline,
        phase.icon or '⏳', phase.name or 'Working',
        opts.position or 1, opts.totalSyncing or 1,
        GetOnlineCount(), GetMaxClients(), GetUptimeString(),
        percent, opts.secondsLeft,
        GetTip(opts.step)
    ))
    print(('^3[%s]^7 presentCard fallback: %s'):format(GetCurrentResourceName(), err or 'unknown error'))
end

local function ShowApprovedCard(deferrals, summary)
    local ok, err = pcall(function()
        deferrals.presentCard(BuildApprovedCard(summary))
    end)
    if ok then return end

    deferrals.update('✅ ' .. (Config.Text.doneMessage or 'Connection approved. Loading into the city...'))
    print(('^3[%s]^7 final presentCard fallback: %s'):format(GetCurrentResourceName(), err or 'unknown error'))
end

-- ─── Connection handler ─────────────────────────────────────────────

AddEventHandler('playerConnecting', function(playerName, setKickReason, deferrals)
    local src = source

    if not Config or not Config.Queue or not Config.Queue.enabled then
        return
    end

    deferrals.defer()
    Wait(0)

    connectSeq = connectSeq + 1
    local mySeq      = connectSeq
    local identifier = GetPlayerIdentifier(src)
    local startedAt  = os.time()
    connectingPlayers[identifier] = { seq = mySeq, name = playerName, startedAt = startedAt }

    local totalSeconds  = tonumber(Config.Queue.waitSeconds) or 10
    local isMaintenance = Config.Maintenance and Config.Maintenance.enabled or false

    print(('^5[%s]^7 %s entered sync queue (seq #%d). Wait: %ss | Maintenance: %s | Identifier: %s'):format(
        GetCurrentResourceName(), playerName or 'Unknown', mySeq, totalSeconds,
        tostring(isMaintenance), identifier
    ))

    for secondsLeft = totalSeconds, 1, -1 do
        if not connectingPlayers[identifier] then
            return
        end

        local step = (totalSeconds - secondsLeft) + 1
        local position, totalSyncing = GetPositionInfo(mySeq)

        ShowConnectionCard(deferrals, {
            playerName   = playerName,
            secondsLeft  = secondsLeft,
            totalSeconds = totalSeconds,
            step         = step,
            position     = position,
            totalSyncing = totalSyncing,
            maintenance  = isMaintenance,
        })

        Wait(1000)
    end

    local finalPosition = select(1, GetPositionInfo(mySeq))
    ShowApprovedCard(deferrals, {
        name      = playerName,
        waited    = os.time() - startedAt,
        position  = finalPosition,
        online    = GetOnlineCount(),
        max       = GetMaxClients(),
        slotsFree = GetSlotsFree(),
        uptime    = GetUptimeString(),
    })
    Wait(1000)

    connectingPlayers[identifier] = nil

    print(('^2[%s]^7 %s completed sync queue and is joining.'):format(
        GetCurrentResourceName(), playerName or 'Unknown'
    ))

    deferrals.done()
end)

AddEventHandler('playerDropped', function()
    local identifier = GetPlayerIdentifier(source)
    if connectingPlayers[identifier] then
        connectingPlayers[identifier] = nil
    end
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    print(('^5[%s]^7 Started. Version: ^2%s^7 | Sync wait: ^2%ss^7 | Maintenance: ^2%s^7 | All connections equal (no bypass).'):format(
        resourceName,
        Config.Script.version or '1.3.0',
        Config.Queue.waitSeconds or 10,
        tostring(Config.Maintenance and Config.Maintenance.enabled or false)
    ))
end)
