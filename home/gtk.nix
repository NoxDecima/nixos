{ inputs, ...}: {
    imports = [ inputs.catppuccin.homeModules.catppuccin ];

    gtk.enable = true;

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