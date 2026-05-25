import QtQuick
import QtQuick.Layouts
import "../theme" as Theme

Rectangle {
    id: card

    property var entry              // notification entry from Notifications service
    property bool showProgress: false
    property real progress: 1.0     // 0..1, toast-only
    property int urgency: entry?.urgency ?? 1

    signal dismissed()
    signal actionInvoked(string actionId)

    width: 380
    implicitHeight: layout.implicitHeight + Theme.Mocha.spaceMd * 2
                  + (showProgress ? 4 : 0)
    radius: Theme.Mocha.radiusMd
    color: Theme.Mocha.surface0
    border.width: urgency === 2 ? 1 : 0
    border.color: urgency === 2 ? Theme.Mocha.red : "transparent"

    ColumnLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: Theme.Mocha.spaceMd
        anchors.bottomMargin: showProgress ? Theme.Mocha.spaceMd + 4 : Theme.Mocha.spaceMd
        spacing: Theme.Mocha.spaceXs

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.Mocha.spaceSm

            Text {
                text: entry?.appName ?? ""
                color: Theme.Mocha.subtext0
                font.family: Theme.Mocha.fontFamily
                font.pixelSize: Theme.Mocha.fontSm
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
            Text {
                text: "×"
                color: Theme.Mocha.overlay0
                font.pixelSize: Theme.Mocha.fontMd
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: card.dismissed()
                }
            }
        }

        Text {
            text: entry?.summary ?? ""
            color: Theme.Mocha.text
            font.family: Theme.Mocha.fontFamily
            font.pixelSize: Theme.Mocha.fontMd
            font.weight: Font.Medium
            Layout.fillWidth: true
            elide: Text.ElideRight
        }

        Text {
            id: bodyText
            Layout.fillWidth: true
            visible: (card.entry?.body ?? "") !== ""
            text: card.entry?.body ?? ""
            color: Theme.Mocha.subtext1
            font.family: Theme.Mocha.fontFamily
            font.pixelSize: Theme.Mocha.fontSm
            wrapMode: Text.WordWrap
            maximumLineCount: 3
            elide: Text.ElideRight

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                enabled: (card.entry?.actions ?? []).some(a => a.identifier === "default")
                onClicked: {
                    card.actionInvoked("default")
                    card.dismissed()
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.Mocha.spaceXs
            visible: actionRepeater.count > 0

            Repeater {
                id: actionRepeater
                model: (card.entry?.actions ?? []).filter(a => a.identifier !== "default")
                delegate: Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 28
                    radius: Theme.Mocha.radiusSm
                    color: btnMa.containsMouse ? Theme.Mocha.surface1 : Theme.Mocha.surface0
                    border.width: 1
                    border.color: Theme.Mocha.surface1

                    Text {
                        anchors.centerIn: parent
                        text: modelData.text ?? modelData.identifier
                        color: Theme.Mocha.text
                        font.family: Theme.Mocha.fontFamily
                        font.pixelSize: Theme.Mocha.fontSm
                    }

                    MouseArea {
                        id: btnMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            card.actionInvoked(modelData.identifier)
                            card.dismissed()
                        }
                    }
                }
            }
        }
    }

    // Progress bar — toast-only. Inset from the rounded corners so
    // it doesn't visually overflow the card's border-radius.
    Rectangle {
        visible: card.showProgress
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Theme.Mocha.radiusMd
        anchors.rightMargin: Theme.Mocha.radiusMd
        anchors.bottomMargin: 4
        height: 2
        color: Theme.Mocha.surface1
        radius: 1

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width * card.progress
            color: card.urgency === 2 ? Theme.Mocha.red : Theme.Mocha.blue
            radius: 1
        }
    }
}
