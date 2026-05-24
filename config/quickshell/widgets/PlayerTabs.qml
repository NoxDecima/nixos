import QtQuick
import QtQuick.Layouts
import "../theme" as Theme
import "../services" as Services

Item {
    visible: Services.Mpris.players.length > 1
    implicitHeight: visible ? 22 : 0

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.Mocha.spaceMd
        spacing: Theme.Mocha.spaceSm

        Repeater {
            model: Services.Mpris.players
            delegate: Rectangle {
                property bool isActive: modelData === Services.Mpris.activePlayer
                implicitWidth: tabText.implicitWidth + 16
                implicitHeight: 20
                radius: 10
                color: isActive ? Theme.Mocha.surface0 : "transparent"

                Text {
                    id: tabText
                    anchors.centerIn: parent
                    text: modelData.identity ?? "Player"
                    color: isActive ? Theme.Mocha.text : Theme.Mocha.subtext0
                    font.family: Theme.Mocha.fontFamily
                    font.pixelSize: Theme.Mocha.fontSm - 1
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Services.Mpris.selectPlayer(modelData)
                }
            }
        }
    }
}
