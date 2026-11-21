{ inputs, pkgs, settings, unstable, ... }:
let
    spotube = pkgs.callPackage (import ./flakes/spotube.nix) {};
in
{
    environment.systemPackages = with pkgs; [
	    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
	    git
	    gcc

	    # cudaSupport only adds /run/opengl-driver/lib to the RUNPATH so btop can
	    # dlopen libnvidia-ml for the GPU box; it pulls in no CUDA packages (cached).
	    (btop.override { cudaSupport = true; })

	    # Shell
      kitty

      # Needs 152+ for the Gecko fix to Mozilla bug 2008777 (crash on Hyprland 0.56's
      # wp_color_manager_v1 v2); stable 26.05 now ships 160. Keep it on the same nixpkgs
      # as Zen: Thunderbird's wrapper prefixes LD_LIBRARY_PATH, which leaks into the
      # browser it spawns for links — mixing channels makes Zen fail on a glibc mismatch.
      thunderbird


	    # JS
	    nodejs_24

      # Work
      qgis
      slack
      google-cloud-sdk
      inputs.claude-code.packages."${settings.system}".default
      teams-for-linux

      jetbrains-toolbox

      # Utils
      gnome-clocks
      # TODO add a calculator


      # Browser
      inputs.zen-browser.packages."${settings.system}".default # beta

      # NeoVim
      neovim
      fzf
      lazygit
      tree-sitter
      ripgrep
      fd

      # Games
      lutris

      # Notes
      obsidian

      # Office
      libreoffice

      # Music
      spotube

      # Audio control
      pavucontrol

      # Disk space analysis
      baobab

      # PDF reader / Image viewer
      evince
      xournalpp
      loupe

      discord

      # NordVPN client (Additional NixOS setup steps: https://kenshin.ninja/p/wgnord-nixos-nordvpn/)
      wgnord

      # Language learning
      anki-bin
      mpv

      # WIFI applet
      networkmanagerapplet
	];

    # Steam via the module rather than the bare package: same wrapped Steam and
    # the same ~/.local/share/Steam data, plus the udev rules for controllers
    # and VR headsets (hardware.steam-hardware) and 32-bit audio support.
    programs.steam.enable = true;

    xdg.mime.defaultApplications = {
      "inode/directory" = "org.gnome.Nautilus.desktop";
      "application/pdf" = "org.gnome.Evince.desktop";
    };
}
