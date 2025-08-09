{ pkgs, ... }:

{
    # Virtualization
    virtualisation.podman.enable = true;
    environment.systemPackages = with pkgs; [
        nvidia-container-toolkit
    ];
}