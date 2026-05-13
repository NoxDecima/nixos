{ pkgs, ... }:

{
    environment.systemPackages = with pkgs; [
        cliphist
        wl-clipboard
    ];
}
