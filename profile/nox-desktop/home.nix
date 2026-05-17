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
        # Hyprland
        ".config/hypr/hypridle.conf".source = ../../config/hypr/hypridle.conf;
        ".config/hypr/hyprlock.conf".source = ../../config/hypr/hyprlock.conf;
        ".config/hypr/hyprland.conf".source = ../../config/hypr/hyprland.conf;
        ".config/hypr/hyprpaper.conf".source = ../../config/hypr/hyprpaper.conf;
        ".config/hypr/monitors.conf".source = ../../config/hypr/monitors-desktop.conf;
        ".config/hypr/theme".source = ../../config/hypr/theme;
        ".config/hypr/hypr-config".source = ../../config/hypr/hypr-config;

        ".config/backgrounds".source = ../../config/backgrounds;
        ".config/swaync".source = ../../config/swaync;
        ".config/waybar".source = ../../config/waybar;
        ".config/wofi".source = ../../config/wofi;
        ".config/kitty".source = ../../config/kitty;
        ".config/nvim".source = config.lib.file.mkOutOfStoreSymlink
          "${config.home.homeDirectory}/nixos/config/nvim";
      };
      sessionVariables = { };
    };
}
