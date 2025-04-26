{ pkgs, settings, ... }:

{
    environment.systemPackages = with pkgs; [
        nextcloud-client
    ];

    # To store authentication over restarts
    services.gnome.gnome-keyring.enable = true;
    security.pam.services.login.enableGnomeKeyring = true;
}

