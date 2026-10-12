{ config, ... }:

{
    home.file.".config/hypr/monitors.lua".source = config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/nixos/config/hypr/monitors-work.lua";

    # Low-battery notifications: warn 20%, critical 10%, suspend at 5%.
    services.batsignal = {
      enable = true;
      extraArgs = [ "-w" "20" "-c" "10" "-d" "5" "-D" "systemctl suspend" ];
    };
}
