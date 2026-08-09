{ settings, pkgs, unstable, ... }:

{
    # Enable the X11 windowing system.
	services.xserver.enable = true;

	# GDM (Wayland-only since GNOME 50; the old `wayland` toggle was removed)
	services.displayManager.gdm.enable = true;
	# Without a stored session choice GDM 50 falls back to launching
	# "gnome-session", which isn't installed here → silent login loop.
	services.displayManager.defaultSession = "hyprland";

	# Hyprland (started plain, without uwsm) never activates systemd's
	# graphical-session.target, so user units like hypridle/waybar that are
	# WantedBy it stay dead. hyprland.conf starts this target via exec-once;
	# BindsTo pulls graphical-session.target up with it.
	systemd.user.targets.hyprland-session = {
	    description = "Hyprland compositor session";
	    bindsTo = [ "graphical-session.target" ];
	    wants = [ "graphical-session-pre.target" ];
	    after = [ "graphical-session-pre.target" ];
	};

	# These user units are global, so the GDM greeter user also starts them and
	# crash-loops (no config / no layer-shell there). Only run them for us.
	systemd.user.services.hypridle.unitConfig.ConditionUser = settings.userName;
	systemd.user.services.waybar.unitConfig.ConditionUser = settings.userName;

    services.libinput.touchpad.naturalScrolling = true;


	# TODO: enable capslock by default


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
    # TODO: revert to the tracked channel package once nixpkgs ships a waybar
    # with the Hyprland Lua-dispatch fix (upstream Alexays/Waybar PR #5013).
    # Without it, hyprland/workspaces clicks/scroll fail under the 0.55+ Lua
    # IPC protocol. Pin to a master commit that contains the fix instead.
    programs.waybar.package = unstable.waybar.overrideAttrs (old: {
        # Keep the upstream meson project version: master still reports
        # "Waybar v0.15.0" and nixpkgs' versionCheckPhase must match it.
        src = pkgs.fetchFromGitHub {
            owner = "Alexays";
            repo = "Waybar";
            rev = "084d87401d0a91182c16aa7e5f674a7dde767185"; # master @ 2026-08-03
            sha256 = "1iqm9n3nlhjkagy9f0x7mfjkfrm79din32kywass79yfncwz1srw";
        };
        # master gained a WWAN module; nixpkgs' -Dauto_features=enabled would
        # force it on and hard-require mm-glib (ModemManager). Disable it.
        # cava is not used here and master's subproject fallback pins cava
        # 1.0.0 (nixpkgs bundles 0.10.7-beta), so drop it too.
        mesonFlags = old.mesonFlags ++ [ "-Dwwan=disabled" "-Dcava=disabled" ];
    });
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
