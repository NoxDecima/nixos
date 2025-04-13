{ inputs, pkgs, settings, ... }:

{
    environment.systemPackages = with pkgs; [
	    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
	    git
	    gcc

	    # Shell
        kitty

        thunderbird
        jetbrains.pycharm-professional

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
        spotube

        # Audio control
        pavucontrol

        # Disk space analysis
        baobab

        # PDF reader / editor
        evince

        vesktop
	];
}
