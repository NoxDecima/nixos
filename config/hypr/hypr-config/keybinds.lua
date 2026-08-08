
-------------------
--- KEYBINDINGS ---
-------------------
-- Migrated from hyprlang to the Hyprland 0.55+ Lua config format
-- See https://wiki.hypr.land/Configuring/Basics/Binds/ for more
 
local mainMod = "SUPER" -- Sets "Windows" key as main modifier
 
-- Programs
local terminal = "kitty"
local fileManager = "nautilus"
local menu = "pkill wofi || wofi --show drun"


hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.window.pseudo()) -- dwindle
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit")) -- dwindle
 
-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))
 
-- Move windows with mainMod + SHIFT + arrow keys
hl.bind(mainMod .. " + SHIFT + left", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + up", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + down", hl.dsp.window.move({ direction = "down" }))
 
-- Move current workspace to another monitor
hl.bind(mainMod .. " + CTRL + SHIFT + left", hl.dsp.workspace.move({ monitor = "l" }))
hl.bind(mainMod .. " + CTRL + SHIFT + down", hl.dsp.workspace.move({ monitor = "d" }))
hl.bind(mainMod .. " + CTRL + SHIFT + up", hl.dsp.workspace.move({ monitor = "u" }))
hl.bind(mainMod .. " + CTRL + SHIFT + right", hl.dsp.workspace.move({ monitor = "r" }))
 
-- Creating grouped windows (also interesting https://github.com/outfoxxed/hy3)
-- hl.bind(mainMod .. " + T", hl.dsp.group.toggle())
 
-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9] (silently)
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i, follow = false }))
end
 
-- Example special workspace (scratchpad)
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))
 
-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
 
-- Resize active window with mainMod + CTRL + arrow keys (repeats while held)
hl.bind(mainMod .. " + CTRL + left", hl.dsp.window.resize({ x = -50, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + right", hl.dsp.window.resize({ x = 50, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + up", hl.dsp.window.resize({ x = 0, y = -50, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + down", hl.dsp.window.resize({ x = 0, y = 50, relative = true }), { repeating = true })
 
-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
 
-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl s 10%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl s 10%-"), { locked = true, repeating = true })
 
-- Requires playerctl
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
 
-- Screenshots save
hl.bind("PRINT", hl.dsp.exec_cmd("hyprshot -m output -o $HOME/Pictures/Screenshots"))
hl.bind(mainMod .. " + PRINT", hl.dsp.exec_cmd("hyprshot -m window -o $HOME/Pictures/Screenshots"))
hl.bind("SHIFT + PRINT", hl.dsp.exec_cmd("hyprshot -m region -o $HOME/Pictures/Screenshots"))
 
-- Screenshots clipboard
hl.bind("CTRL + PRINT", hl.dsp.exec_cmd("hyprshot -m output --clipboard-only -o $HOME/Pictures/Screenshots"))
hl.bind("CTRL + " .. mainMod .. " + PRINT", hl.dsp.exec_cmd("hyprshot -m window --clipboard-only -o $HOME/Pictures/Screenshots"))
hl.bind("CTRL + SHIFT + PRINT", hl.dsp.exec_cmd("hyprshot -m region --clipboard-only -o $HOME/Pictures/Screenshots"))
 
-- Toggle notifications panel
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("qs ipc call panel toggle"))
 
-- Clear notifications
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("qs ipc call notifications clearAll"))
 
-- Color picker
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("hyprpicker -a"))
 
-- Toggle waybar
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("pkill waybar || waybar"))
 
-- Lock screen
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))
 
-- Voice recording trigger
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("voxd --trigger-record"))
 
-- Clipboard history
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("cliphist list | wofi --dmenu | cliphist decode | wl-copy"))
