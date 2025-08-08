{ pkgs, ... }:

{
    services.power-profiles-daemon.enable = true;

    environment.systemPackages = [
        pkgs.power-profiles-daemon
    ];
}