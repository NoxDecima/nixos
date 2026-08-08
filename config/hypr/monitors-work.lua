--------------------------------
--- MONITORS AND WORKSPACES ----
--------------------------------
-- Migrated from hyprlang to the Hyprland 0.55+ Lua config format
-- See https://wiki.hypr.land/Configuring/Monitors/

-- monitor= lines become hl.monitor({ output, mode, position, scale, ... })
hl.monitor({
    output = "eDP-1",
    mode = "preferred",
    position = "auto",
    scale = "auto",
})

hl.monitor({
    output = "DP-3",
    mode = "preferred",
    position = "auto-up",
    scale = "auto",
})

-- Fallback rule for any other monitor: empty output matches unnamed monitors,
-- mirroring the laptop screen.
hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = "auto",
    mirror = "eDP-1",
})

-- Workspace-to-monitor assignments
hl.workspace_rule({ workspace = "1", monitor = "DP-3", default = true })
hl.workspace_rule({ workspace = "2", monitor = "DP-3" })
hl.workspace_rule({ workspace = "5", monitor = "DP-3" })
hl.workspace_rule({ workspace = "3", monitor = "eDP-1", default = true })
hl.workspace_rule({ workspace = "4", monitor = "eDP-1" })

-- Ensure DP-3 is the primary monitor for XWayland (important for games for example)
-- exec-once becomes an hl.on("hyprland.start", ...) handler: it fires once at
-- compositor startup and NOT on config reloads, matching exec-once semantics.
hl.on("hyprland.start", function()
    hl.exec_cmd("xrandr --output DP-3 --primary")
end)
