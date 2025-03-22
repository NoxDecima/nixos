{ inputs, config, pkgs, settings, ... }:

let
    home = {
        username = settings.userName;
        homeDirectory = "/home/nox";
        stateVersion = "24.11";
        packages = [];
        file = {
            ".config/hypr".source = ./config/hypr;
            ".config/backgrounds".source = ./config/backgrounds;
        };
        sessionVariables = {};
    };
in {
  imports = [
     inputs.home-manager.nixosModules.home-manager
  ];

#  programs.home-manager.enable = true;
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  home-manager.users.${settings.userName} = {pkgs, settings }: {
    home = {
      username = settings.userName;
      homeDirectory = "/home/${settings.userName}";
      stateVersion = "24.11";
      packages = [ ];
      file = {
        ".config/hypr".source = ./config/hypr;
        ".config/backgrounds".source = ./config/backgrounds;
      };
      sessionVariables = { };
    };
  };
  programs.home-manager.enable = true;
}
