-- =====================================================================
--  Distortionz Queue · server.lua
--  Premium timed connection queue for FiveM / Qbox
-- =====================================================================

local connectingPlayers = {}

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
    length = length or 24
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

-- ─── Header items (logo or fallback icon + brand text) ──────────────

local function BuildHeaderColumns()
    local logoColumn

    if Config.Branding.logoUrl and Config.Branding.logoUrl ~= '' then
        logoColumn = {
            type = 'Column',
            width = 'auto',
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
        logoColumn = {
            type = 'Column',
            width = 'auto',
            items = {
                {
                    type   = 'TextBlock',
                    text   = Config.Branding.fallbackIcon or '📦',
                    size   = 'ExtraLarge',
                    weight = 'Bolder',
                }
            }
        }
    end

    return {
        logoColumn,
        {
            type = 'Column',
            width = 'stretch',
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
    }
end

-- ─── Adaptive Card (queue / waiting) ────────────────────────────────

local function BuildQueueCard(playerName, secondsLeft, totalSeconds, step)
    local spinner    = MakeSpinner(step)
    local dots       = MakeDots(step)
    local statusText = GetStatusMessage(step)
    local tip        = GetTip(step)
    local percent    = math.floor(((totalSeconds - secondsLeft) / totalSeconds) * 100)
    if percent < 0 then percent = 0 elseif percent > 100 then percent = 100 end

    local progressBar = MakeProgressBar(percent)

    return {
        type = 'AdaptiveCard',
        ['$schema'] = 'http://adaptivecards.io/schemas/adaptive-card.json',
        version = '1.5',

        body = {
            -- HEADER
            {
                type = 'Container',
                style = 'emphasis',
                bleed = true,
                items = {
                    {
                        type = 'ColumnSet',
                        columns = BuildHeaderColumns(),
                    }
                }
            },

            -- WELCOME + STATUS
            {
                type = 'Container',
                spacing = 'Medium',
                items = {
                    {
                        type   = 'TextBlock',
                        text   = Config.Text.welcomeTitle or 'Preparing your connection...',
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
            },

            -- STATS GRID : position · wait · online
            {
                type = 'ColumnSet',
                spacing = 'Medium',
                columns = {
                    {
                        type = 'Column', width = 'stretch', style = 'emphasis',
                        items = {
                            { type = 'TextBlock', text = 'POSITION',  size = 'Small', weight = 'Bolder', color = 'accent', isSubtle = true },
                            { type = 'TextBlock', text = '#1',        size = 'ExtraLarge', weight = 'Bolder', spacing = 'None' },
                        }
                    },
                    {
                        type = 'Column', width = 'stretch', style = 'emphasis',
                        items = {
                            { type = 'TextBlock', text = 'WAIT TIME', size = 'Small', weight = 'Bolder', color = 'accent', isSubtle = true },
                            { type = 'TextBlock', text = ('%ds'):format(secondsLeft), size = 'ExtraLarge', weight = 'Bolder', spacing = 'None' },
                        }
                    },
                    {
                        type = 'Column', width = 'stretch', style = 'emphasis',
                        items = {
                            { type = 'TextBlock', text = 'ONLINE',    size = 'Small', weight = 'Bolder', color = 'accent', isSubtle = true },
                            { type = 'TextBlock', text = ('%d / %d'):format(GetOnlineCount(), GetMaxClients()), size = 'ExtraLarge', weight = 'Bolder', spacing = 'None' },
                        }
                    },
                }
            },

            -- PROGRESS BAR
            {
                type = 'ColumnSet',
                spacing = 'Medium',
                columns = {
                    {
                        type = 'Column', width = 'stretch',
                        items = {
                            {
                                type     = 'TextBlock',
                                text     = progressBar,
                                fontType = 'Monospace',
                                color    = Config.Colors.progress,
                                size     = 'Medium',
                            }
                        }
                    },
                    {
                        type = 'Column', width = 'auto',
                        verticalContentAlignment = 'Center',
                        items = {
                            {
                                type   = 'TextBlock',
                                text   = ('%d%%'):format(percent),
                                weight = 'Bolder',
                                color  = Config.Colors.progress,
                            }
                        }
                    }
                }
            },

            -- TIP
            {
                type = 'Container',
                style = 'good',
                spacing = 'Medium',
                items = {
                    { type = 'TextBlock', text = '💡 Did you know?', size = 'Small', weight = 'Bolder', color = 'accent' },
                    { type = 'TextBlock', text = tip, spacing = 'Small', isSubtle = true, wrap = true },
                }
            },

            -- FOOTER
            {
                type = 'TextBlock',
                text = ('Queue mode: %s  ·  Build %s'):format(
                    Config.Queue.queueMode or 'Timed sync access',
                    Config.Script.version or '1.2.0'
                ),
                size = 'Small',
                isSubtle = true,
                horizontalAlignment = 'Center',
                spacing = 'Medium',
                wrap = true,
            }
        },

        actions = {
            { type = 'Action.OpenUrl', title = '💬 Discord', url = Config.Branding.discord },
            { type = 'Action.OpenUrl', title = '📜 Rules',   url = Config.Branding.rules   },
            { type = 'Action.OpenUrl', title = '🌐 Website', url = Config.Branding.website },
        }
    }
end

-- ─── Adaptive Card (approved / loading in) ──────────────────────────

local function BuildApprovedCard()
    return {
        type = 'AdaptiveCard',
        ['$schema'] = 'http://adaptivecards.io/schemas/adaptive-card.json',
        version = '1.5',
        body = {
            {
                type = 'Container',
                style = 'emphasis',
                bleed = true,
                items = {
                    { type = 'ColumnSet', columns = BuildHeaderColumns() }
                }
            },
            {
                type = 'Container',
                spacing = 'Medium',
                items = {
                    {
                        type   = 'TextBlock',
                        text   = '✅ Connection approved',
                        size   = 'ExtraLarge',
                        weight = 'Bolder',
                        color  = 'good',
                        wrap   = true,
                    },
                    {
                        type    = 'TextBlock',
                        text    = Config.Text.doneMessage or 'Loading into the city...',
                        spacing = 'Small',
                        wrap    = true,
                    }
                }
            }
        }
    }
end

-- ─── Card presenters with text fallback ─────────────────────────────

local function ShowQueueCard(deferrals, playerName, secondsLeft, totalSeconds, step)
    local ok, err = pcall(function()
        deferrals.presentCard(BuildQueueCard(playerName, secondsLeft, totalSeconds, step))
    end)
    if ok then return end

    local percent    = math.floor(((totalSeconds - secondsLeft) / totalSeconds) * 100)
    local spinner    = MakeSpinner(step)
    local dots       = MakeDots(step)
    local statusText = GetStatusMessage(step)
    local tip        = GetTip(step)

    deferrals.update((
        '%s\n%s\n\n%s %s%s\nTime remaining: %s second(s)\nProgress: %s%%\n\n%s'
    ):format(
        Config.Branding.serverName,
        Config.Branding.tagline,
        spinner, statusText, dots,
        secondsLeft, percent,
        tip
    ))

    print(('^3[%s]^7 presentCard fallback: %s'):format(GetCurrentResourceName(), err or 'unknown error'))
end

local function ShowApprovedCard(deferrals)
    local ok, err = pcall(function()
        deferrals.presentCard(BuildApprovedCard())
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

    local identifier = GetPlayerIdentifier(src)
    connectingPlayers[identifier] = true

    local totalSeconds = tonumber(Config.Queue.waitSeconds) or 10

    print(('^5[%s]^7 %s entered sync queue. Wait: %ss | Identifier: %s'):format(
        GetCurrentResourceName(),
        playerName or 'Unknown',
        totalSeconds,
        identifier
    ))

    for secondsLeft = totalSeconds, 1, -1 do
        if not connectingPlayers[identifier] then
            return
        end

        local step = (totalSeconds - secondsLeft) + 1
        ShowQueueCard(deferrals, playerName, secondsLeft, totalSeconds, step)
        Wait(1000)
    end

    ShowApprovedCard(deferrals)
    Wait(1000)

    connectingPlayers[identifier] = nil

    print(('^2[%s]^7 %s completed sync queue and is joining.'):format(
        GetCurrentResourceName(),
        playerName or 'Unknown'
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

    print(('^5[%s]^7 Started successfully. Version: ^2%s^7 | Sync wait: ^2%ss^7'):format(
        resourceName,
        Config.Script.version or '1.2.0',
        Config.Queue.waitSeconds or 10
    ))
end)