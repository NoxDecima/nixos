{ inputs, pkgs, lib, ... }:

{
    # Automatic updating
    system.autoUpgrade = {
        enable = true;
        dates = "weekly";
        flake = inputs.self.outPath;
        flags = ["--recreate-lock-file"];
    };

    # Automatic cleanup
    nix.gc = {
        automatic = true;
        dates = "daily";
        options = "--delete-older-than 30d";
    };
    nix.settings.auto-optimise-store = true;

}