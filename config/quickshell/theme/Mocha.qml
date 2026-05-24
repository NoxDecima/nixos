pragma Singleton
import QtQuick

QtObject {
    // Catppuccin Mocha palette (matches config/swaync/mocha_config.css)
    readonly property color base:      "#1e1e2e"
    readonly property color mantle:    "#181825"
    readonly property color crust:     "#11111b"
    readonly property color text:      "#cdd6f4"
    readonly property color subtext1:  "#bac2de"
    readonly property color subtext0:  "#a6adc8"
    readonly property color overlay2:  "#9399b2"
    readonly property color overlay1:  "#7f849c"
    readonly property color overlay0:  "#6c7086"
    readonly property color surface2:  "#585b70"
    readonly property color surface1:  "#45475a"
    readonly property color surface0:  "#313244"
    readonly property color blue:      "#89b4fa"
    readonly property color sapphire:  "#74c7ec"
    readonly property color sky:       "#89dceb"
    readonly property color teal:      "#94e2d5"
    readonly property color green:     "#a6e3a1"
    readonly property color yellow:    "#f9e2af"
    readonly property color peach:     "#fab387"
    readonly property color maroon:    "#eba0ac"
    readonly property color red:       "#f38ba8"
    readonly property color mauve:     "#cba6f7"
    readonly property color pink:      "#f5c2e7"
    readonly property color flamingo:  "#f2cdcd"
    readonly property color rosewater: "#f5e0dc"

    // Sizing
    readonly property int radiusSm: 6
    readonly property int radiusMd: 10
    readonly property int radiusLg: 14
    readonly property int spaceXs: 4
    readonly property int spaceSm: 8
    readonly property int spaceMd: 12
    readonly property int spaceLg: 16

    // Typography. iconFamily uses nerd-fonts.symbols-only — a purpose-built
    // icon-only font where every codepoint is a PUA glyph, so Qt doesn't have
    // to pick the right weight or worry about glyph coverage.
    readonly property string fontFamily: "Inter"
    readonly property string fontMono: "JetBrains Mono"
    readonly property string iconFamily: "Symbols Nerd Font Mono"
    readonly property int fontSm: 11
    readonly property int fontMd: 13
    readonly property int fontLg: 15
}
