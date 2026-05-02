# 🚦 Distortionz Queue

**Premium timed connection queue for FiveM / Qbox.**
Gives every connecting player a short forced wait before entering the server, helping the server finish syncing resources and player data while showing a fully branded, advanced Adaptive Card connection screen.

---

## ✨ Features

### 🎨 Advanced Adaptive Card UI
- Branded header with logo or fallback icon
- Live stats grid: queue position, wait time, online count
- Animated progress bar with monospaced rendering
- Rotating spinner + status messages
- Rotating tip section with subtle styling
- One-click action buttons: **Discord · Rules · Website**

### 🚦 Queue System
- Configurable timed wait (default: 10 s)
- Equal treatment for all players (no priority bypass)
- Identifier-based tracking with cleanup on drop
- Final "Connection approved" card before drop-in
- Plain-text fallback if `presentCard` ever fails

### 🧾 Version Checker
- Detects outdated installs from your GitHub `version.json`
- Detects misconfigured URLs (HTML responses, 404s, etc.)
- Sends a custom User-Agent so GitHub doesn't rate-limit you
- Exposed as `exports.distortionz_queue:CheckVersion()` for manual re-checks

### ⚙️ Easy to customize
- Single `config.lua` covers branding, copy, colors, tips, and behavior
- No core logic edits needed for typical configuration

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
   - `Config.Branding.logoUrl` (optional — falls back to icon emoji)
3. Add to `server.cfg`:
   ```cfg
   ensure distortionz_queue
   ```
4. Restart the server.

## ⚙️ Configuration highlights

| Setting | Default | Notes |
|---|---|---|
| `Config.Queue.waitSeconds` | `10` | Forced sync wait per player |
| `Config.Queue.enabled` | `true` | Master switch |
| `Config.Colors.accent` | `'good'` | Adaptive Card semantic color |
| `Config.VersionCheck.enabled` | `true` | Hits GitHub on resource start |
| `Config.Tips` | 10 entries | Rotates one per second |
| `Config.StatusMessages` | 6 entries | Rotates one per second |

## 🔗 Links

- **Discord:** _set in config_
- **Updates:** GitHub releases
- **Issues / support:** GitHub Issues tab

---

## 📜 License

MIT — see `LICENSE`.