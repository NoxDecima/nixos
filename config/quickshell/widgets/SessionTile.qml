import QtQuick
import QtQuick.Layouts
import "../theme" as Theme
import "../services" as Services

Rectangle {
    color: Theme.Mocha.mantle
    radius: Theme.Mocha.radiusMd
    implicitHeight: row.implicitHeight + Theme.Mocha.spaceSm * 2

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.margins: Theme.Mocha.spaceSm
        spacing: Theme.Mocha.spaceXs

        component PwrBtn: Rectangle {
            property string icon: ""
            property bool danger: false
            signal clicked()
            Layout.fillWidth: true
            implicitHeight: 36
            radius: Theme.Mocha.radiusSm
            color: ma.containsMouse
                ? (danger ? Qt.alpha(Theme.Mocha.red, 0.25) : Theme.Mocha.surface0)
                : "transparent"
            Text {
                anchors.centerIn: parent
                text: parent.icon
                color: parent.danger ? Theme.Mocha.red : Theme.Mocha.subtext0
                font.family: Theme.Mocha.iconFamily
                font.pixelSize: 14
            }
            MouseArea {
                id: ma
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: parent.clicked()
            }
        }

        // \uXXXX escapes — literal PUA glyphs get stripped by some file writes.
        PwrBtn { icon: "";  onClicked: Services.Hyprland.dispatch("exec hyprlock") }            // lock
        PwrBtn { icon: "";  onClicked: Services.Hyprland.dispatch("exit") }                     // sign-out
        PwrBtn { icon: "";  onClicked: Services.Hyprland.dispatch("exec systemctl suspend") }   // bed
        PwrBtn { icon: "";  onClicked: Services.Hyprland.dispatch("exec reboot") }              // refresh
        PwrBtn { icon: "";  danger: true; onClicked: Services.Hyprland.dispatch("exec shutdown now") }  // power-off
    }
}
