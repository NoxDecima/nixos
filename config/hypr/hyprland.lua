-- Refer to the wiki for more information.
-- https://wiki.hyprland.org/Configuring/

--[[
-- Environment variables
--]]

-- See https://wiki.hyprland.org/Configuring/Environment-variables/

hl.env("XCURSOR_SIZE", "20")
hl.env("HYPRCURSOR_SIZE", "20")
hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Classic")

-- For Nvidia GPU, see https://wiki.hyprland.org/Nvidia/
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("NVD_BACKEND", "direct")

-------------
---Imports---
-------------
require("monitors")
require("hypr-config/general")
require("hypr-config/keybinds")
require("hypr-config/windows")


--[[
-- Autostart
--]]

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch like this:

hl.on("hyprland.start", function()
  hl.exec_cmd("fcitx5 -d --replace")
  hl.exec_cmd("systemctl --user start hyprpolkitagent")
  -- Activate graphical-session.target so hypridle/waybar user units start.
  hl.exec_cmd("systemctl --user start hyprland-session.target")

  hl.exec_cmd("waybar")
  hl.exec_cmd("quickshell")
  hl.exec_cmd("hyprpaper")
  hl.exec_cmd("hypridle")
  hl.exec_cmd("hyprsunset")
  hl.exec_cmd("nextcloud")
  hl.exec_cmd("blueman-applet")
  hl.exec_cmd("nm-applet")
  hl.exec_cmd("voxd --tray")

  hl.exec_cmd("wl-paste --type text --watch cliphist store")
  hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)


