{ inputs, pkgs, ...}: {
    imports = [ inputs.catppuccin.homeModules.catppuccin ];

    gtk.enable = true;

    home.pointerCursor = {
        package = pkgs.bibata-cursors;
        name = "Bibata-Modern-Classic";
        size = 20;
        gtk.enable = true;
        x11.enable = true;
        hyprcursor.enable = true;
    };

    catppuccin = {
        gtk = {
          enable = true;
          flavor = "mocha";
          accent = "blue";
          size = "standard";
          tweaks = [ "normal" ];
        };
    };
}
