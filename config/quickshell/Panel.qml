import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import "theme" as Theme
import "services" as Services
import "widgets" as Widgets

PanelWindow {
    id: panel
    property bool isOpen: false

    // Fullscreen layer-shell window: backdrop fills the screen so any click
    // outside the inner surface closes the panel.
    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    visible: isOpen
    exclusiveZone: 0

    function open()   { isOpen = true; Services.Notifications.activeToasts = [] }
    function close()  { isOpen = false }
    function toggle() { isOpen ? close() : open() }

    // Any click that reaches this MouseArea is outside the inner surface
    // (children of the surface consume their own clicks before bubbling here).
    MouseArea {
        anchors.fill: parent
        onClicked: panel.close()
    }

    Rectangle {
        id: surface
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 12
        width: 640
        height: 720
        color: Theme.Mocha.mantle
        opacity: 0.97
        radius: Theme.Mocha.radiusLg
        border.width: 1
        border.color: Theme.Mocha.surface0
        layer.enabled: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.Mocha.spaceMd
            spacing: Theme.Mocha.spaceMd

            Widgets.HeroMpris { Layout.fillWidth: true }
            Widgets.PlayerTabs { Layout.fillWidth: true }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Theme.Mocha.spaceMd

                // Left rail
                ColumnLayout {
                    Layout.preferredWidth: 200
                    Layout.fillHeight: true
                    spacing: Theme.Mocha.spaceSm

                    Widgets.ToggleTile { Layout.fillWidth: true }
                    Widgets.SliderTile { Layout.fillWidth: true }
                    Widgets.SessionTile { Layout.fillWidth: true }
                    Item { Layout.fillHeight: true }
                }

                // Right column (notifications)
                Widgets.NotifList {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }
        }
    }

    // DropShadow renders ONLY the shadow (transparent where source is opaque,
    // shadow where source has alpha). The surface Rectangle stays visible as
    // itself; the shadow appears underneath via z: -1.
    DropShadow {
        source: surface
        anchors.fill: surface
        horizontalOffset: 0
        verticalOffset: 14
        radius: 36
        samples: 24
        color: "#8c000000"
        z: -1
    }
}
