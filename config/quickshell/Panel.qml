import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "theme" as Theme
import "services" as Services
import "widgets" as Widgets

PanelWindow {
    id: panel
    property bool isOpen: false

    anchors.top: true
    margins.top: 38
    implicitWidth: 580
    implicitHeight: 720
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    visible: isOpen
    exclusiveZone: 0

    function open()   { isOpen = true; Services.Notifications.activeToasts = [] }
    function close()  { isOpen = false }
    function toggle() { isOpen ? close() : open() }

    // Backdrop: closes the panel ONLY when the click lands in the 8px margin
    // around the surface (outside-click-to-close). Clicks inside the surface
    // fall through to whatever widget handles them (sliders, toggles, etc.)
    // and don't reach this MouseArea because Qt widgets accept their events.
    MouseArea {
        anchors.fill: parent
        onClicked: function(mouse) {
            if (mouse.x < 8 || mouse.x > width - 8
                || mouse.y < 8 || mouse.y > height - 8) {
                panel.close()
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 8
        color: Theme.Mocha.base
        opacity: 0.94
        radius: Theme.Mocha.radiusLg
        border.width: 1
        border.color: Theme.Mocha.surface1

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
                    Layout.preferredWidth: 220
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
}
