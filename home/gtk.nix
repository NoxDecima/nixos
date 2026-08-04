{ inputs, config, pkgs, ...}: {
    gtk.enable = true;

    home.pointerCursor = {
        package = pkgs.bibata-cursors;
        name = "Bibata-Modern-Classic";
        size = 20;
        gtk.enable = true;
        x11.enable = true;
        hyprcursor.enable = true;
    };

    # Colloid (maintained) with the catppuccin color tweak, replacing the
    # archived catppuccin/gtk port — catppuccin/nix removed its gtk module
    # upstream, so `catppuccin.gtk.*` breaks on the next input update.
    # NOTE: the tweak suffixes the theme directory name ("-Catppuccin").
    # Accent color: set themeVariants to ONE of "default" (blue), "purple",
    # "pink", "red", "orange", "yellow", "green", "teal", "grey" — for
    # non-default accents the name becomes "Colloid-<Color>-Dark-Catppuccin".
    gtk.theme = {
        name = "Colloid-Dark-Catppuccin";
        # Custom darkness between Colloid's default catppuccin scheme
        # (window bg #292c3c) and its too-dark "black" tweak (#181825):
        # shift the dark background ladder onto the darker end of the
        # catppuccin mocha palette. grey-700 drives window/header/view,
        # grey-750 the sidebars, grey-800 the deepest tier — tune the hex
        # values below to taste and rebuild.
        package = (pkgs.colloid-gtk-theme.override {
            tweaks = [ "catppuccin" ];
            colorVariants = [ "dark" ];
            themeVariants = [ "default" ];
        }).overrideAttrs (old: {
            postPatch = (old.postPatch or "") + ''
                sed -i -e 's/^.grey-650: .*/$grey-650: #292c3c;/' \
                       -e 's/^.grey-700: .*/$grey-700: #1e1e2e;/' \
                       -e 's/^.grey-750: .*/$grey-750: #181825;/' \
                       -e 's/^.grey-800: .*/$grey-800: #11111b;/' \
                       src/sass/_color-palette-catppuccin.scss
            '';
        });
    };

    # Force the same theme onto GTK4/libadwaita apps for a uniform look
    # (explicit legacy behavior; new home-manager default would be null).
    # If a libadwaita app renders broken after a GTK/theme update, suspect
    # this first.
    gtk.gtk4.theme = config.gtk.theme;

    # GTK3 apps: force the dark stylesheet; GTK4/libadwaita apps ignore
    # gtk.theme and follow the color-scheme preference instead — without it
    # they render light (the old catppuccin module set this for us).
    gtk.gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
    dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
}
