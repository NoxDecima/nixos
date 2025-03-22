{ settings, ... }:

{
    home = {
      username = settings.userName;
      homeDirectory = "/home/${settings.userName}";
      stateVersion = "24.11";
      packages = [ ];
      file = {
        ".config/hypr".source = ./config/hypr;
        ".config/backgrounds".source = ./config/backgrounds;
        ".config/swaync".source = ./config/swaync;
        ".config/waybar".source = ./config/waybar;
        ".config/wofi".source = ./config/wofi;
      };
      sessionVariables = { };
    };
}
