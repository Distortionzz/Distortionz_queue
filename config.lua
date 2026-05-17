-- =====================================================================
--  Distortionz Queue · config.lua
--  Premium timed connection queue for Distortionz RP
-- =====================================================================

Config = {}

-- ─── Script meta ────────────────────────────────────────────────────
Config.Script = {
    name    = 'Distortionz Queue',
    version = '1.3.0',
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
    serverName   = 'DistortionzRP',
    tagline      = 'A premium FiveM roleplay experience',
    logoUrl      = '',                                      -- direct image URL (96x96+ recommended)
    fallbackIcon = '🟡',                                     -- shown if logoUrl is empty
    discord      = 'https://discord.gg/REPLACE_ME',
    rules        = 'https://Distortionzrp.com/rules',
    website      = 'https://Distortionzrp.com',
}

-- ─── Queue behavior ─────────────────────────────────────────────────
-- waitSeconds is applied to EVERY connection. There is intentionally no
-- role / priority / staff bypass — all connections serve the full sync.
Config.Queue = {
    enabled     = true,
    waitSeconds = 10,                                       -- forced sync wait per connection
    queueMode   = 'Timed sync access',                      -- shown in footer
}

-- ─── Maintenance mode ───────────────────────────────────────────────
-- Cosmetic ops theme only. Players still serve the same waitSeconds wait
-- and are still admitted afterwards — this just reskins the card so the
-- community knows work is happening. No one is blocked or bypassed.
Config.Maintenance = {
    enabled = false,
    icon    = '🛠️',
    title   = 'Scheduled maintenance in progress',
    message = 'We are polishing the city. Your connection will continue normally — thanks for your patience.',
    footer  = 'Maintenance mode · every connection still syncs normally',
}

-- ─── Multi-phase sync flow ──────────────────────────────────────────
-- Phases are spread evenly across waitSeconds. Add or remove freely —
-- the flow re-balances automatically.
Config.Phases = {
    { icon = '🔐', name = 'Authenticating identity' },
    { icon = '🌐', name = 'Syncing world & player data' },
    { icon = '✅', name = 'Finalizing secure entry' },
}

-- ─── Live stat tiles (toggle individually) ──────────────────────────
Config.Stats = {
    showPosition = true,                                    -- live spot among players currently syncing
    showWait     = true,                                    -- seconds remaining
    showOnline   = true,                                    -- online / max
    showSlots    = true,                                    -- free slots
    showUptime   = true,                                    -- server uptime since resource start
    showCapacity = true,                                    -- server fullness %
    showClock    = true,                                    -- live server clock in header
}

-- ─── Time display ───────────────────────────────────────────────────
Config.Time = {
    clock24    = false,                                     -- false = 12h w/ AM·PM, true = 24h
    dateFormat = '%a %d %b %Y',
}

-- ─── Adaptive Card colors ───────────────────────────────────────────
-- Valid values: default · dark · light · accent · good · warning · attention
-- (FiveM deferral cards do not support custom hex — semantic names only.)
Config.Colors = {
    accent     = 'good',
    panelTitle = 'accent',
    progress   = 'good',
    capacity   = 'accent',
}

-- ─── Copy / messages ────────────────────────────────────────────────
Config.Text = {
    welcomeTitle = 'Preparing your connection',
    doneTitle    = 'Connection approved',
    doneMessage  = 'Welcome to the city — loading you in now.',
    footer       = 'Please wait while we prepare your session.',
}

-- ─── Rotating status detail (secondary line, cycles each second) ─────
Config.StatusMessages = {
    'Verifying connection integrity',
    'Negotiating secure session',
    'Allocating a city slot',
    'Loading server resources',
    'Synchronizing player profile',
    'Contacting city services',
    'Checking queue clearance',
    'Warming up the world state',
    'Validating entitlements',
    'Finalizing entry approval',
}

-- ─── Rotating tips (one shown per second of the wait) ───────────────
Config.Tips = {
    'Drive carefully near busy areas and active scenes.',
    'Use /report to reach staff when you need help.',
    'Always establish your character before initiating RP.',
    'Read the rules before escalating any conflict.',
    'Keep your hands visible in serious situations.',
    'Need help? Open a ticket in our Discord.',
    'Value your life — every character only has one.',
    'Power-gaming and meta-gaming are not tolerated.',
    'Use /me and /do to add detail to your roleplay.',
    'Report bugs to staff so the city keeps improving.',
    'New here? Ask in Discord for a new-player guide.',
    'Quality roleplay beats winning every interaction.',
    'Stay in character on all in-city channels.',
    'Fear for your life — act realistically under threat.',
    'Respect active scenes; do not interfere uninvited.',
}
