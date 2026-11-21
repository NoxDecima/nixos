{ config, pkgs, ... }:

{
  # Enable OpenGL
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

#    # Use basic virtual drivers instead of NVIDIA
#  services.xserver.videoDrivers = [ "modesetting" ];


  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = ["nvidia"];

  # NVIDIA settings
  hardware.nvidia = {
    # Modesetting is required for Wayland
    modesetting.enable = true;

    # Enable the NVIDIA settings menu
    nvidiaSettings = true;

    # Choose the driver version
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    # Required for Wayland
    open = true;

    # Power management (recommended)
    powerManagement = {
      enable = true;
    };
  };

  # No nvtopPackages.nvidia: it depends on cuda-merged, which is unfree (not on
  # cache.nixos.org) and gets built locally — tens of GB of disk on every
  # nixpkgs bump. GPU stats come from btop instead (cudaSupport, programs.nix).
}