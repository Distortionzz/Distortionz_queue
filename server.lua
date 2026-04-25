local connectingPlayers = {}

local function GetPlayerIdentifier(source)
    local identifiers = GetPlayerIdentifiers(source)

    for _, identifier in ipairs(identifiers) do
        if identifier:find('license:') then
            return identifier
        end
    end

    return identifiers[1] or ('source:' .. tostring(source))
end

local function MakeProgressBar(percent)
    local totalBars = 24
    local filledBars = math.floor((percent / 100) * totalBars)
    local emptyBars = totalBars - filledBars

    return string.rep('█', filledBars) .. string.rep('░', emptyBars)
end

local function MakeSpinner(step)
    local frames = {
        '⠋',
        '⠙',
        '⠹',
        '⠸',
        '⠼',
        '⠴',
        '⠦',
        '⠧',
        '⠇',
        '⠏'
    }

    return frames[((step - 1) % #frames) + 1]
end

local function MakeDots(step)
    local frames = {
        '.',
        '..',
        '...',
        '....'
    }

    return frames[((step - 1) % #frames) + 1]
end

local function GetStatusMessage(step)
    local messages = Config.Queue.statusMessages or {}

    if #messages == 0 then
        return 'Preparing connection'
    end

    return messages[((step - 1) % #messages) + 1]
end

local function GetTip(step)
    local tips = Config.Queue.tips or {}

    if #tips == 0 then
        return Config.Queue.footer or 'Please wait while we prepare your session.'
    end

    return tips[((step - 1) % #tips) + 1]
end

local function BuildHeaderItems()
    local items = {}

    if Config.Queue.logoUrl and Config.Queue.logoUrl ~= '' then
        items[#items + 1] = {
            type = 'Image',
            url = Config.Queue.logoUrl,
            size = 'Small',
            style = 'Person'
        }
    else
        items[#items + 1] = {
            type = 'TextBlock',
            text = Config.Queue.fallbackIcon or '📦',
            size = 'ExtraLarge',
            weight = 'Bolder',
            wrap = true
        }
    end

    items[#items + 1] = {
        type = 'TextBlock',
        text = 'Distortionz',
        weight = 'Bolder',
        size = 'ExtraLarge',
        color = 'light',
        wrap = true,
        spacing = 'Medium'
    }

    return items
end

local function BuildQueueCard(playerName, secondsLeft, totalSeconds, step)
    local spinner = MakeSpinner(step)
    local dots = MakeDots(step)
    local statusText = GetStatusMessage(step)
    local tip = GetTip(step)

    local percent = math.floor(((totalSeconds - secondsLeft) / totalSeconds) * 100)

    if percent < 0 then
        percent = 0
    elseif percent > 100 then
        percent = 100
    end

    local bar = MakeProgressBar(percent)

    return {
        type = 'AdaptiveCard',
        ['$schema'] = 'http://adaptivecards.io/schemas/adaptive-card.json',
        version = '1.3',
        body = {
            {
                type = 'Container',
                bleed = true,
                style = 'emphasis',
                items = {
                    {
                        type = 'ColumnSet',
                        columns = {
                            {
                                type = 'Column',
                                width = 'auto',
                                items = BuildHeaderItems()
                            }
                        }
                    }
                }
            },
            {
                type = 'Container',
                spacing = 'Medium',
                style = 'emphasis',
                items = {
                    {
                        type = 'TextBlock',
                        text = Config.Queue.serverName or 'Distortionz RP',
                        weight = 'Bolder',
                        size = 'ExtraLarge',
                        color = Config.Queue.panelTitleColor or 'accent',
                        wrap = true
                    },
                    {
                        type = 'TextBlock',
                        text = Config.Queue.serverSubtitle or 'Premium Connection Queue',
                        isSubtle = true,
                        spacing = 'None',
                        wrap = true
                    }
                }
            },
            {
                type = 'Container',
                spacing = 'Medium',
                items = {
                    {
                        type = 'TextBlock',
                        text = Config.Queue.welcomeTitle or 'Preparing your connection...',
                        weight = 'Bolder',
                        size = 'Large',
                        wrap = true
                    },
                    {
                        type = 'TextBlock',
                        text = ('Welcome, %s'):format(playerName or 'Guest'),
                        spacing = 'Small',
                        wrap = true
                    }
                }
            },
            {
                type = 'FactSet',
                spacing = 'Medium',
                facts = {
                    {
                        title = 'Status',
                        value = ('%s %s%s'):format(spinner, statusText, dots)
                    },
                    {
                        title = 'Countdown',
                        value = ('%s second(s) remaining'):format(secondsLeft)
                    },
                    {
                        title = 'Queue Mode',
                        value = 'Timed sync access'
                    }
                }
            },
            {
                type = 'TextBlock',
                text = ('Progress  %s  %s%%'):format(bar, percent),
                wrap = true,
                spacing = 'Medium',
                fontType = 'Monospace',
                color = Config.Queue.accentColor or 'good'
            },
            {
                type = 'TextBlock',
                text = tip,
                isSubtle = true,
                spacing = 'Medium',
                wrap = true
            },
            {
                type = 'TextBlock',
                text = Config.Queue.footer or 'Please wait while we prepare your session.',
                isSubtle = true,
                spacing = 'Small',
                wrap = true
            }
        }
    }
end

local function BuildApprovedCard()
    return {
        type = 'AdaptiveCard',
        ['$schema'] = 'http://adaptivecards.io/schemas/adaptive-card.json',
        version = '1.3',
        body = {
            {
                type = 'Container',
                bleed = true,
                style = 'emphasis',
                items = {
                    {
                        type = 'ColumnSet',
                        columns = {
                            {
                                type = 'Column',
                                width = 'auto',
                                items = BuildHeaderItems()
                            }
                        }
                    }
                }
            },
            {
                type = 'TextBlock',
                text = Config.Queue.serverName or 'Distortionz RP',
                weight = 'Bolder',
                size = 'ExtraLarge',
                color = Config.Queue.panelTitleColor or 'accent',
                wrap = true,
                spacing = 'Medium'
            },
            {
                type = 'TextBlock',
                text = '✅ ' .. (Config.Queue.doneMessage or 'Connection approved. Loading into the city...'),
                weight = 'Bolder',
                size = 'Large',
                color = 'good',
                wrap = true
            }
        }
    }
end

local function ShowQueueCard(deferrals, playerName, secondsLeft, totalSeconds, step)
    local ok, err = pcall(function()
        deferrals.presentCard(BuildQueueCard(playerName, secondsLeft, totalSeconds, step))
    end)

    if ok then
        return
    end

    local percent = math.floor(((totalSeconds - secondsLeft) / totalSeconds) * 100)
    local spinner = MakeSpinner(step)
    local dots = MakeDots(step)
    local statusText = GetStatusMessage(step)
    local tip = GetTip(step)

    deferrals.update((
        '%s\n%s\n\n%s %s%s\nTime remaining: %s second(s)\nProgress: %s%%\n\n%s'
    ):format(
        Config.Queue.serverName or 'Distortionz RP',
        Config.Queue.serverSubtitle or 'Premium Connection Queue',
        spinner,
        statusText,
        dots,
        secondsLeft,
        percent,
        tip
    ))

    print(('[distortionz_queue] presentCard fallback used: %s'):format(err or 'unknown error'))
end

local function ShowApprovedCard(deferrals)
    local ok, err = pcall(function()
        deferrals.presentCard(BuildApprovedCard())
    end)

    if ok then
        return
    end

    deferrals.update('✅ ' .. (Config.Queue.doneMessage or 'Connection approved. Loading into the city...'))

    print(('[distortionz_queue] final presentCard fallback used: %s'):format(err or 'unknown error'))
end

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

    print(('[distortionz_queue] %s entered sync queue. Wait: %ss | Identifier: %s'):format(
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

    print(('[distortionz_queue] %s completed sync queue and is joining.'):format(
        playerName or 'Unknown'
    ))

    deferrals.done()
end)

AddEventHandler('playerDropped', function()
    local src = source
    local identifier = GetPlayerIdentifier(src)

    if connectingPlayers[identifier] then
        connectingPlayers[identifier] = nil
    end
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    local waitSeconds = Config.Queue and Config.Queue.waitSeconds or 10
    local version = Config.Script and Config.Script.version or '1.1.0'

    print(('[distortionz_queue] Started successfully. Version: %s | Sync wait time: %s seconds.'):format(
        version,
        waitSeconds
    ))
end)