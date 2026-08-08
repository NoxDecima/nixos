------------------------------
--- WINDOWS AND WORKSPACES ---
------------------------------
-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/ for more

-- Ignore maximize requests from apps. You'll probably like this.
hl.window_rule({
    name = "suppress-maximize",
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- Fix some dragging issues with XWayland
hl.window_rule({
    name = "xwayland-drag-fix",
    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
        float = true,
        fullscreen = false,
        pin = false,
    },
    no_focus = true,
})

-- Pavucontrol
hl.window_rule({
    name = "pavucontrol-float-center",
    match = { class = "^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$" },
    float = true,
    center = true,
})

-- Quickshell panel + toasts (blur backdrop)
hl.layer_rule({
    name = "qs-panel-blur",
    match = { namespace = "qs-panel" },
    blur = true,
    ignore_alpha = 0.3,
})

-- Define default workspace for applications
local workspaceAssignments = {
    { class = "^(zen)(.*)$",                 workspace = 1 },
    { class = "^(jetbrains-pycharm)$",       workspace = 2 },
    { class = "^(obsidian)$",                workspace = 2 },
    { class = "^(thunderbird)$",             workspace = 3 },
    { class = "^(vesktop|discord|Slack)$",   workspace = 4 },
    { class = "^(steam)$",                   workspace = 5 },
    { class = "^(net.lutris.Lutris)$",       workspace = 5 },
}

for i, a in ipairs(workspaceAssignments) do
    hl.window_rule({
        name = "workspace-assign-" .. i,
        match = { class = a.class },
        workspace = a.workspace .. " silent",
    })
end

-- Prevent Hypridle when in fullscreen
hl.window_rule({
    name = "idle-inhibit-fullscreen",
    match = { fullscreen = true },
    idle_inhibit = "fullscreen",
})
