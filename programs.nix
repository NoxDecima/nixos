{ inputs, pkgs, settings, unstable, ... }:
let
    spotube = pkgs.callPackage (import ./flakes/spotube.nix) {};
in
{
    environment.systemPackages = with pkgs; [
	    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
	    git
	    gcc

	    btop

	    # Shell
      kitty

      # From unstable (152+) for the Gecko fix to Mozilla bug 2008777: stable's
      # 146 crashes on Hyprland 0.56's color-management protocol (wp_color_manager_v1
      # v2) — "wp_image_description_v1 has no event 2". See also firefox/zen if they crash.
      unstable.thunderbird


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
      steam

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
      apostrophe

      discord

      # NordVPN client (Additional NixOS setup steps: https://kenshin.ninja/p/wgnord-nixos-nordvpn/)
      wgnord

      # Language learning
      anki-bin
      mpv

      # WIFI applet
      networkmanagerapplet
	];

    xdg.mime.defaultApplications = {
      "inode/directory" = "org.gnome.Nautilus.desktop";
      "application/pdf" = "org.gnome.Evince.desktop";
    };
}
