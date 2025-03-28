{ inputs, settings, pkgs, ... }:

{
    # Enable the X11 windowing system.
	services.xserver.enable = true;
	services.xserver.displayManager.gdm.enable = true;
	services.xserver.displayManager.gdm.wayland = true;

    # services.xserver.desktopManager.gnome.enable = true;

    # Enable the Hyprland compositor.
    programs.hyprland = {
        enable = true;
        xwayland.enable = true;
    };

    programs.waybar.enable = true;
    services.hypridle.enable = true;
    programs.hyprlock.enable = true;

    environment.systemPackages = with pkgs; [
	    hyprpicker
	    hyprpaper
	    hyprsunset
	    hyprshot
	    swaynotificationcenter
	    wofi
	    nautilus
	];

    xdg.portal = {
        enable = true;
        extraPortals = [ pkgs.xdg-desktop-portal-hyprland pkgs.xdg-desktop-portal-gtk ];
        config.common.default = "*";
    };

#    environment.sessionVariables = {
#        # For Hyprland with NVIDIA
#        LIBVA_DRIVER_NAME = "nvidia";
#        GBM_BACKEND = "nvidia-drm";
#        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
#        NVD_BACKEND = "direct";
#          # Optional, hint Electron apps to use Wayland:
#  };

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
