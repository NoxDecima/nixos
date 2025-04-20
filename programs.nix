{ inputs, pkgs, settings, ... }:

{
    environment.systemPackages = with pkgs; [
	    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
	    git
	    gcc

	    btop

	    # Shell
        kitty

        thunderbird
        jetbrains.pycharm-professional

        # Work
        qgis
        slack
        google-cloud-sdk

        gnome-clocks


        # Browser
        inputs.zen-browser.packages."${settings.system}".default # beta

        # NeoVim
        neovim
        fzf

        # Games
        lutris
        steam

        # Notes
        obsidian

        # Music
        inputs.nixpkgs-unstable.legacyPackages."${settings.system}".spotube

        # Audio control
        pavucontrol

        # Disk space analysis
        baobab

        # PDF reader / Image viewer
        evince
        loupe

        vesktop
	];
}
