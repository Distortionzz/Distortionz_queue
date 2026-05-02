-- =====================================================================
--  Distortionz Queue · config.lua
--  Premium timed connection queue for Distortionz RP
-- =====================================================================

Config = {}

-- ─── Script meta ────────────────────────────────────────────────────
Config.Script = {
    name    = 'Distortionz Queue',
    version = '1.2.0',
}

-- Convenient alias used by version_check.lua
Config.CurrentVersion = Config.Script.version

-- ─── Version checker ────────────────────────────────────────────────
Config.VersionCheck = {
    enabled      = true,
    checkOnStart = true,
    url          = 'https://raw.githubusercontent.com/Distortionzz/Distortionz_queue/main/version.json',
}

-- ─── Server branding ────────────────────────────────────────────────
Config.Branding = {
    serverName  = 'DistortinzRP',
    tagline     = 'A premium FiveM roleplay experience',
    logoUrl     = '',                                       -- direct image URL (96x96+ recommended)
    fallbackIcon = '📦',                                    -- shown if logoUrl is empty
    discord     = 'https://discord.gg/REPLACE_ME',
    rules       = 'https://distortinzrp.com/rules',
    website     = 'https://distortinzrp.com',
}

-- ─── Queue behavior ─────────────────────────────────────────────────
Config.Queue = {
    enabled     = true,
    waitSeconds = 10,                                       -- forced sync wait per player
    queueMode   = 'Timed sync access',                      -- shown in footer
}

-- ─── Adaptive Card colors ───────────────────────────────────────────
-- Valid values: default · dark · light · accent · good · warning · attention
Config.Colors = {
    accent     = 'good',
    panelTitle = 'accent',
    progress   = 'good',
}

-- ─── Copy / messages ────────────────────────────────────────────────
Config.Text = {
    welcomeTitle = 'Preparing your connection...',
    doneMessage  = 'Connection approved. Loading into the city...',
    footer       = 'Please wait while we prepare your session.',
}

-- ─── Rotating status (cycles every second of the wait) ──────────────
Config.StatusMessages = {
    'Syncing identity',
    'Validating connection',
    'Preparing session',
    'Contacting city services',
    'Checking queue clearance',
    'Finalizing entry approval',
}

-- ─── Rotating tips (one shown per second of the wait) ───────────────
Config.Tips = {
    'Drive carefully near busy areas and active scenes.',
    'Use /report to get help from staff.',
    'Always identify your character before initiating RP.',
    'Read the rules before causing conflict.',
    'Have your hands ready in serious situations.',
    'Need help? Open a ticket in our Discord.',
    'Value your life — every character only has one.',
    'Power-gaming and meta-gaming are not tolerated.',
    'Use /me and /do to add detail to your roleplay.',
    'Report bugs to staff so the city can keep improving.',
}