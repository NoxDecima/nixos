{ pkgs, ... }:

{
  # Fcitx5 input method framework
  # Toggle input method with Ctrl+Space
  # First-time setup: run fcitx5-configtool and add Mozc
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";

    fcitx5 = {
      waylandFrontend = true;

      addons = with pkgs; [
        fcitx5-mozc   # Japanese
        fcitx5-gtk    # GTK integration
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    qt6Packages.fcitx5-configtool
  ];
}
