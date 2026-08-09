{ config, ... }:

{
    home.file.".config/hypr/monitors.lua".source = config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/nixos/config/hypr/monitors-work.lua";
}
