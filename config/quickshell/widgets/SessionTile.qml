import QtQuick
import QtQuick.Layouts
import "../theme" as Theme
import "../services" as Services

Item {
    implicitHeight: row.implicitHeight

    RowLayout {
        id: row
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 6
        layoutDirection: Qt.LeftToRight

        component PwrBtn: Rectangle {
            property string icon: ""
            property bool danger: false
            signal clicked()
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            radius: 7
            color: ma.containsMouse
                ? (danger ? Qt.rgba(0.953, 0.545, 0.659, 0.18) : Theme.Mocha.surface1)
                : Theme.Mocha.surface0
            border.width: 1
            border.color: danger
                ? Qt.rgba(0.953, 0.545, 0.659, 0.25)   // red@0.25
                : Theme.Mocha.surface1

            Text {
                anchors.centerIn: parent
                text: parent.icon
                color: parent.danger ? Theme.Mocha.red : Theme.Mocha.subtext0
                font.family: Theme.Mocha.iconFamily
                font.pixelSize: 12
            }
            MouseArea {
                id: ma
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: parent.clicked()
            }
        }

        // \uXXXX escapes — literal PUA glyphs get stripped during Write.
        // Hyprland 0.55+ (Lua config) evaluates dispatch args as Lua, so we
        // pass the hl.dsp.* form directly (no legacy hyprlang support needed).
        PwrBtn { icon: "\uF023"; onClicked: Services.Hyprland.dispatch("hl.dsp.exec_cmd('hyprlock')") }            // lock
        PwrBtn { icon: "\uF08B"; onClicked: Services.Hyprland.dispatch("hl.dsp.exit()") }                            // sign-out
        PwrBtn { icon: "\uF236"; onClicked: Services.Hyprland.dispatch("hl.dsp.exec_cmd('systemctl suspend')") }    // bed
        PwrBtn { icon: "\uF021"; onClicked: Services.Hyprland.dispatch("hl.dsp.exec_cmd('reboot')") }               // refresh
        PwrBtn { icon: "\uF011"; danger: true; onClicked: Services.Hyprland.dispatch("hl.dsp.exec_cmd('shutdown now')") }  // power-off
    }
}
