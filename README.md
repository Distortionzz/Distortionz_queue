# Distortionz Queue 🟡

> Premium timed connection queue for Qbox/FiveM — polished live dashboard card, real connection position, multi-phase sync, server stats, uptime & clock, capacity bar, and a cosmetic maintenance mode.

![FiveM](https://img.shields.io/badge/FiveM-cerulean-yellow?style=flat-square&labelColor=181b20)
![Qbox](https://img.shields.io/badge/Qbox-required-red?style=flat-square&labelColor=dfb317)
![License](https://img.shields.io/badge/License-MIT-brightgreen?style=flat-square)
![Version](https://img.shields.io/github/v/release/Distortionzz/Distortionz_queue?style=flat-square&color=d4aa62&label=version)

Gives **every** connecting player a short forced sync wait before entering the server, while showing a fully branded, data-rich Adaptive Card dashboard. The wait lets the server finish syncing resources and player data — and it is applied equally to every connection with **no role, staff, or priority bypass**.

---

## ✨ Features

### 📊 Polished live dashboard
- Branded header with logo or fallback icon **+ live server clock & date**
- Live stat tiles: **position · wait · online · slots free · uptime · capacity**
- **Dual progress bars** — your sync progress *and* live server capacity
- Multi-phase sync flow (Authenticating → Syncing → Finalizing) with phase pips
- Rotating spinner + status detail line, expanded for variety
- Rotating tip section with subtle styling
- One-click action buttons: **Discord · Rules · Website**
- Per-tile toggles in `config.lua` — show only what you want

### 🟢 Real connection position
- Tracks every concurrent connection by sequence
- Shows your **true position** among players currently syncing (e.g. `#2 / 5`)
- No more hardcoded `#1` — fully wired to live server data

### ✅ End-of-sync summary
- Final "Connection approved" card recaps the session:
  player, time waited, granted slot, players online, slots free, uptime

### 🛠️ Maintenance mode
- One config flag flips the card into a branded maintenance theme
- Purely cosmetic — players still serve the same wait and **are still admitted**; nobody is blocked or bypassed

### 🚦 Equal-treatment queue
- Configurable timed wait (default: **10 s**) applied to every connection
- **No priority / staff / role bypass — by design**
- Identifier-based tracking with cleanup on drop
- Plain-text fallback if `presentCard` ever fails

### 🧾 Version checker
- Detects outdated installs from your GitHub `version.json`
- Detects misconfigured URLs (HTML responses, 404s, etc.)
- Sends a custom User-Agent so GitHub doesn't rate-limit you
- Exposed as `exports.distortionz_queue:CheckVersion()` for manual re-checks

---

## 📦 Resource name

```
distortionz_queue
```

## 🛠 Installation

1. Drop the folder into `resources/[distortionz]/` (or wherever your custom scripts live).
2. Open `config.lua` and set:
   - `Config.Branding.serverName`
   - `Config.Branding.discord`
   - `Config.Branding.rules`
   - `Config.Branding.website`
   - `Config.Branding.logoUrl` (optional — falls back to the icon emoji)
3. Add to `server.cfg`:
   ```cfg
   ensure distortionz_queue
   ```
4. Restart the server.

## ⚙️ Configuration highlights

| Setting | Default | Notes |
|---|---|---|
| `Config.Queue.waitSeconds` | `10` | Forced sync wait — applied to every connection |
| `Config.Queue.enabled` | `true` | Master switch |
| `Config.Maintenance.enabled` | `false` | Cosmetic maintenance theme (still admits, still 10 s) |
| `Config.Phases` | 3 phases | Spread evenly across the wait; add/remove freely |
| `Config.Stats.*` | all `true` | Per-tile toggles (position, slots, uptime, capacity, clock…) |
| `Config.Time.clock24` | `false` | 12 h with AM·PM, or 24 h |
| `Config.Colors.*` | semantic | Adaptive Card semantic colors only — no custom hex |
| `Config.VersionCheck.enabled` | `true` | Hits GitHub on resource start |
| `Config.Tips` | 15 entries | Rotates one per second |
| `Config.StatusMessages` | 10 entries | Rotates one per second |

> **Note:** FiveM deferral Adaptive Cards only support named semantic colors
> (`default · dark · light · accent · good · warning · attention`) — custom
> brand hex is not possible in the connection card itself.

## 🔗 Links

- **Discord:** _set in config_
- **Updates:** GitHub releases
- **Issues / support:** GitHub Issues tab

---

## 📜 License

MIT — see `LICENSE`.
