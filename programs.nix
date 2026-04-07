{ inputs, pkgs, settings, ... }:
let
    spotube = pkgs.callPackage (import ./flakes/spotube.nix) {};

    unstable = import inputs.nixpkgs-unstable {
        system = settings.system;
        config = {
          allowUnfree = true;
        };
    };
in
{
    environment.systemPackages = with pkgs; [
	    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
	    git
	    gcc

	    btop

	    # Shell
      kitty

      thunderbird


	    # JS
	    nodejs_24

      # Work
      qgis
      slack
      google-cloud-sdk
      inputs.claude-code.packages."${settings.system}".default

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
