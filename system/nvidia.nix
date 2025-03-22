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
}