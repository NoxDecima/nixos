import QtQuick
import QtQuick.Layouts
import "../theme" as Theme

Rectangle {
    id: tile

    property string label: ""
    property string icon: ""
    property bool active: false
    property bool warn: false
    signal clicked()

    implicitHeight: 40
    radius: 8
    color: active ? Theme.Mocha.blue : Theme.Mocha.surface0
    border.width: 1
    border.color: active ? Theme.Mocha.blue : Theme.Mocha.surface1

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 3

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: tile.icon
            color: tile.active ? Theme.Mocha.base
                 : tile.warn   ? Theme.Mocha.peach
                                : Theme.Mocha.text
            font.family: Theme.Mocha.iconFamily
            font.pixelSize: 14
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: tile.label
            color: tile.active ? Theme.Mocha.base
                 : tile.warn   ? Theme.Mocha.peach
                                : Theme.Mocha.text
            font.family: Theme.Mocha.fontFamily
            font.pixelSize: 10
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: tile.clicked()
    }
}
