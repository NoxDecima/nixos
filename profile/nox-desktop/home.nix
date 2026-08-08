{ config, settings, ... }:

{
    imports = [
		../../home/gtk.nix
		../../home/inputrc.nix
	];

    home = {
      username = settings.userName;
      homeDirectory = "/home/${settings.userName}";
      stateVersion = "24.11";
      packages = [ ];
      file = {
        # Hyprland (live symlinks into the repo — edit + auto-reload, no rebuild)
        ".config/hypr/hypridle.conf".source = config.lib.file.mkOutOfStoreSymlink
          "${config.home.homeDirectory}/nixos/config/hypr/hypridle.conf";
        ".config/hypr/idle-suspend.sh".source = config.lib.file.mkOutOfStoreSymlink
          "${config.home.homeDirectory}/nixos/config/hypr/idle-suspend.sh";
        ".config/hypr/hyprlock.conf".source = config.lib.file.mkOutOfStoreSymlink
          "${config.home.homeDirectory}/nixos/config/hypr/hyprlock.conf";
        ".config/hypr/hyprland.lua".source = config.lib.file.mkOutOfStoreSymlink
          "${config.home.homeDirectory}/nixos/config/hypr/hyprland.lua";
        ".config/hypr/hyprpaper.conf".source = config.lib.file.mkOutOfStoreSymlink
          "${config.home.homeDirectory}/nixos/config/hypr/hyprpaper.conf";
        ".config/hypr/monitors.lua".source = config.lib.file.mkOutOfStoreSymlink
          "${config.home.homeDirectory}/nixos/config/hypr/monitors-desktop.lua";
        ".config/hypr/theme".source = config.lib.file.mkOutOfStoreSymlink
          "${config.home.homeDirectory}/nixos/config/hypr/theme";
        ".config/hypr/hypr-config".source = config.lib.file.mkOutOfStoreSymlink
          "${config.home.homeDirectory}/nixos/config/hypr/hypr-config";

        ".config/backgrounds".source = ../../config/backgrounds;
        ".config/quickshell".source = config.lib.file.mkOutOfStoreSymlink
          "${config.home.homeDirectory}/nixos/config/quickshell";
        ".config/waybar".source = ../../config/waybar;
        ".config/wofi".source = ../../config/wofi;
        ".config/kitty".source = ../../config/kitty;
        ".config/nvim".source = config.lib.file.mkOutOfStoreSymlink
          "${config.home.homeDirectory}/nixos/config/nvim";
      };
      sessionVariables = { };
    };
}
