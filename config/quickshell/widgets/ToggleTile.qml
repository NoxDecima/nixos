import QtQuick
import QtQuick.Layouts
import "../theme" as Theme
import "../services" as Services

Rectangle {
    id: tile
    color: Theme.Mocha.mantle
    radius: Theme.Mocha.radiusMd
    border.width: 1
    border.color: Theme.Mocha.surface0
    implicitHeight: grid.implicitHeight + Theme.Mocha.spaceSm * 2

    GridLayout {
        id: grid
        anchors.fill: parent
        anchors.margins: Theme.Mocha.spaceSm
        columns: 2
        rowSpacing: Theme.Mocha.spaceXs
        columnSpacing: Theme.Mocha.spaceXs

        // Icons use \uXXXX escapes — literal PUA glyphs get stripped during
        // some file writes, so we encode them as ASCII source instead.
        // All codepoints are Font Awesome glyphs included in Symbols Nerd Font.

        Toggle {
            Layout.fillWidth: true
            icon: ""; label: "Wi-Fi"          // wifi
            active: Services.Network.wifiEnabled
            onClicked: Services.Network.toggleWifi()
        }
        Toggle {
            Layout.fillWidth: true
            icon: ""; label: "Bluetooth"       // bluetooth
            active: Services.Bluetooth.powered
            onClicked: Services.Bluetooth.toggle()
        }
        Toggle {
            Layout.fillWidth: true
            icon: ""; label: "DND"             // bell-slash
            active: Services.DND.enabled
            onClicked: Services.Notifications.toggleDnd()
        }
        Toggle {
            Layout.fillWidth: true
            icon: ""; label: "Night"           // sun
            warn: Services.NightLight.active
            onClicked: Services.NightLight.toggle()
        }
        Toggle {
            Layout.fillWidth: true
            icon: ""; label: "Mute"            // volume-off
            active: Services.Audio.muted
            onClicked: Services.Audio.toggleMute()
        }
        Toggle {
            Layout.fillWidth: true
            icon: ""; label: "Mic"             // microphone-slash
            active: Services.Audio.micMuted
            onClicked: Services.Audio.toggleMicMute()
        }
        Toggle {
            Layout.fillWidth: true
            icon: ""; label: "Idle"            // bed
            active: Services.Idle.inhibited
            onClicked: Services.Idle.toggle()
        }
        Toggle {
            Layout.fillWidth: true
            icon: ""; label: Services.InputMethod.shortLabel  // keyboard
            onClicked: Services.InputMethod.toggle()
        }
    }
}
