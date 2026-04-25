Config = {}

Config.Script = {
    name = 'Distortionz Queue',
    version = '1.1.0'
}

Config.VersionCheck = {
    enabled = true,
    resourceName = 'distortionz_queue',
    currentVersion = '1.1.0',
    githubVersionUrl = 'https://raw.githubusercontent.com/Distortionzz/distortionz_queue/main/version.json'
}

Config.Queue = {
    enabled = true,

    -- Everyone waits this many seconds.
    waitSeconds = 10,

    serverName = 'Distortionz RP',
    serverSubtitle = 'Premium Connection Queue',

    -- Optional direct image URL. Leave empty to use fallbackIcon.
    logoUrl = '',
    fallbackIcon = '📦',

    -- Adaptive Card colors:
    -- default, dark, light, accent, good, warning, attention
    accentColor = 'good',
    panelTitleColor = 'accent',

    welcomeTitle = 'Preparing your connection...',
    doneMessage = 'Connection approved. Loading into the city...',

    statusMessages = {
        'Syncing identity',
        'Validating connection',
        'Preparing session',
        'Contacting city services',
        'Checking queue clearance',
        'Finalizing entry approval'
    },

    tips = {
        'Tip: Respect roleplay scenes and give others time to respond.',
        'Tip: Use /me and /do to add detail to your roleplay.',
        'Tip: Report bugs to staff so the city can keep improving.',
        'Tip: Keep your character story consistent and believable.',
        'Tip: Drive carefully near busy areas and active scenes.'
    },

    footer = 'Please wait while we prepare your session.'
}