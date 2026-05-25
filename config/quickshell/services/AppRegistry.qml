pragma Singleton
import QtQuick
import "../theme" as Theme

QtObject {
    id: root

    // Map normalizedAppName -> { icon, color }
    // All icon codepoints are Font Awesome (U+F000-U+F2FF range), covered by
    // Symbols Nerd Font Mono. Avoiding MDI 5-digit codepoints for safety.
    readonly property var _registry: ({
        // Chat / messaging
        "discord":     { icon: "", color: Theme.Mocha.mauve },     // Discord-style (puzzle)
        "vesktop":     { icon: "", color: Theme.Mocha.mauve },
        "element":     { icon: "", color: Theme.Mocha.teal },      // chat
        "signal":      { icon: "", color: Theme.Mocha.blue },
        "telegram":    { icon: "", color: Theme.Mocha.sapphire },
        "slack":       { icon: "", color: Theme.Mocha.teal },

        // Mail
        "thunderbird": { icon: "", color: Theme.Mocha.sapphire },  // envelope
        "gmail":       { icon: "", color: Theme.Mocha.sapphire },
        "mail":        { icon: "", color: Theme.Mocha.sapphire },
        "cron":        { icon: "", color: Theme.Mocha.peach },     // job-style notifs

        // Media
        "spotify":     { icon: "", color: Theme.Mocha.green },     // music note
        "mpv":         { icon: "", color: Theme.Mocha.maroon },    // video-camera
        "firefox":     { icon: "", color: Theme.Mocha.peach },     // firefox
        "zen":         { icon: "", color: Theme.Mocha.peach },

        // Dev / system
        "deploy":      { icon: "", color: Theme.Mocha.green },     // terminal
        "journalctl":  { icon: "", color: Theme.Mocha.yellow },
        "system":      { icon: "", color: Theme.Mocha.subtext0 }, // cog
        "calendar":    { icon: "", color: Theme.Mocha.lavender },  // calendar
        "battery":     { icon: "", color: Theme.Mocha.green },     // battery-full

        // Default (unknown apps)
        "_default":    { icon: "", color: Theme.Mocha.overlay1 }   // bell
    })

    function lookup(appName) {
        if (!appName) return _registry["_default"]
        const key = appName.toLowerCase().trim()
        // Exact match first
        if (key in _registry) return _registry[key]
        // Substring fallback (e.g., "discord canary" -> "discord")
        for (const k in _registry) {
            if (k === "_default") continue
            if (key.includes(k) || k.includes(key)) return _registry[k]
        }
        return _registry["_default"]
    }

    function iconFor(appName) { return lookup(appName).icon }
    function colorFor(appName) { return lookup(appName).color }
}
