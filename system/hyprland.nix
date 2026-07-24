{ inputs, settings, pkgs, ... }:
let
    unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.system};
in
{
    # Enable the X11 windowing system.
	services.xserver.enable = true;

	# GDM
	services.xserver.displayManager.gdm = {
        enable = true;
        wayland = true;
    };

	# TODO: enable capslock by default
	# TODO: set a XCursor


    # services.xserver.desktopManager.gnome.enable = true;

    # Enable the Hyprland compositor.
    programs.hyprland = {
        enable = true;
        xwayland.enable = true;
        # Pull Hyprland and its portal from nixpkgs-unstable to get >= 0.56.0.
        # Stable (25.05) ships 0.49.0, which destroys bound wl_output resources
        # on same-name output replacement at S3 resume, disconnecting every
        # Wayland client (hyprlock, portal, ...) and leaving a dead lock screen.
        # Fixed upstream in Hyprland 0.56.0 (PR #15351).
        package = unstable.hyprland;
        portalPackage = unstable.xdg-desktop-portal-hyprland;
    };

    programs.waybar.enable = true;
    services.hypridle.enable = true;
    programs.hyprlock.enable = true;

    security.polkit.enable = true;

    environment.systemPackages = with pkgs; [
	    hyprpicker
	    hyprpaper
	    hyprsunset
	    hyprshot
	    unstable.quickshell
	    brightnessctl
	    playerctl
	    wofi
	    nautilus
        hyprpolkitagent
	];

    xdg = {
        portal = {
            enable = true;
            wlr.enable = false;
            extraPortals = [ unstable.xdg-desktop-portal-hyprland pkgs.xdg-desktop-portal-gtk ];
            config.common.default = "*";
        };
        mime = {
            defaultApplications = {
                "text/html" = [ "zen.desktop" ];
                "x-scheme-handler/http" = [ "zen.desktop" ];
                "x-scheme-handler/https" = [ "zen.desktop" ];
                "inode/directory" = [ "org.gnome.Nautilus.desktop" ];
                "x-scheme-handler/file" = [ "org.gnome.Nautilus.desktop" ];
                "x-scheme-handler/trash" = [ "org.gnome.Nautilus.desktop" ];
            };
        };
    };

    # Add this to your configuration.nix or the appropriate module
    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
#      WLR_NO_HARDWARE_CURSORS = "1";
      WAYLAND_DISPLAY = "wayland-1";
      XDG_CURRENT_DESKTOP = "Hyprland";
      XDG_SESSION_DESKTOP = "Hyprland";
      XDG_SESSION_TYPE = "wayland";
    };
}
