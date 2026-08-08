-----------------
--- MONITORS ----
-----------------
-- Migrated from hyprlang to the Hyprland 0.55+ Lua config format
-- See https://wiki.hypr.land/Configuring/Monitors/

hl.monitor({
    output = "HDMI-A-1",
    mode = "1920x1080@240", -- "@240.00Hz" also parses, but this is the canonical form
    position = "auto",
    scale = "auto",
})

hl.monitor({
    output = "DP-1",
    mode = "1920x1080@60",
    position = "auto-left",
    scale = "auto",
    transform = 1, -- 90 degrees; integer 0-7, same values as hyprlang
})

-- Fallback rule for any other monitor: mirror the main display
hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = "auto",
    mirror = "HDMI-A-1",
})

-- Workspace-to-monitor assignments
hl.workspace_rule({ workspace = "1", monitor = "HDMI-A-1", default = true })
hl.workspace_rule({ workspace = "2", monitor = "HDMI-A-1" })
hl.workspace_rule({ workspace = "5", monitor = "HDMI-A-1" })
hl.workspace_rule({ workspace = "3", monitor = "DP-1", default = true })
hl.workspace_rule({ workspace = "4", monitor = "DP-1" })

-- Ensure HDMI-A-1 is the primary monitor for XWayland (important for games for example)
hl.on("hyprland.start", function()
    hl.exec_cmd("xrandr --output HDMI-A-1 --primary")
end)
