import QtQuick
import QtQuick.Layouts
import "../theme" as Theme

Rectangle {
    id: tile

    property string label: ""
    property string icon: ""      // unicode glyph (Nerd Font / Material)
    property bool active: false
    property bool warn: false
    signal clicked()

    implicitWidth: 100
    implicitHeight: 56
    radius: Theme.Mocha.radiusMd
    color: warn ? Qt.alpha(Theme.Mocha.peach, 0.25)
         : active ? Qt.alpha(Theme.Mocha.blue, 0.25)
         : Theme.Mocha.surface0
    border.width: 1
    border.color: warn ? Theme.Mocha.peach
                : active ? Theme.Mocha.blue
                : Theme.Mocha.surface1

    RowLayout {
        anchors.fill: parent
        anchors.margins: Theme.Mocha.spaceSm
        spacing: Theme.Mocha.spaceXs

        Text {
            text: tile.icon
            color: tile.warn ? Theme.Mocha.peach
                 : tile.active ? Theme.Mocha.blue
                 : Theme.Mocha.subtext0
            font.family: Theme.Mocha.iconFamily
            font.pixelSize: 16
        }
        Text {
            text: tile.label
            color: Theme.Mocha.text
            font.family: Theme.Mocha.fontFamily
            font.pixelSize: Theme.Mocha.fontSm
            Layout.fillWidth: true
            elide: Text.ElideRight
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: tile.clicked()
    }
}
