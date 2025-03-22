{ inputs, settings, pkgs, ... }:

{
    # Enable the X11 windowing system.
	services.xserver.enable = true;
	services.xserver.displayManager.gdm.enable = true;
	services.xserver.desktopManager.gnome.enable = true;

    # Enable the Hyprland compositor.
    programs.hyprland = {
        enable = true;
        xwayland.enable = true;
    };

  # Optional, hint Electron apps to use Wayland:
  # environment.sessionVariables.NIXOS_OZONE_WL = "1";

    xdg.portal = {
        enable = true;
        extraPortals = [ pkgs.xdg-desktop-portal-hyprland pkgs.xdg-desktop-portal-gtk ];
        config.common.default = "*";
    };

    environment.sessionVariables = {
        # For Hyprland with NVIDIA
        LIBVA_DRIVER_NAME = "nvidia";
        GBM_BACKEND = "nvidia-drm";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        NVD_BACKEND = "direct";
        XDG_SESSION_TYPE = "wayland";
        WLR_NO_HARDWARE_CURSORS = "1";
        NIXOS_OZONE_WL = "1";   # Optional, hint Electron apps to use Wayland:
  };
}
