import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../theme" as Theme

Rectangle {
    id: card

    property var entry              // notification entry from Notifications service
    property bool showProgress: false
    property real progress: 1.0     // 0..1, toast-only
    property int urgency: entry?.urgency ?? 1
    property bool canReply: false   // true when rendered in a context with keyboard focus (panel)
    property bool replyOpen: false  // toggled by the synthetic Reply button

    signal dismissed()
    signal actionInvoked(string actionId)

    function sendReply() {
        const text = replyField.text
        if (!text || text.length === 0) return
        if (card.entry?.notification?.sendInlineReply) {
            card.entry.notification.sendInlineReply(text)
        }
        replyField.text = ""
        card.replyOpen = false
        card.dismissed()
    }

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
            visible: actionRepeater.count > 0 || (card.entry?.hasInlineReply ?? false)

            // Synthetic Reply button — only when the notif supports inline reply.
            // In panel (canReply=true): toggles replyOpen. In toast (canReply=false):
            // emits __reply__ for the toast layer to handle.
            Rectangle {
                visible: card.entry?.hasInlineReply ?? false
                Layout.fillWidth: true
                implicitHeight: 28
                radius: Theme.Mocha.radiusSm
                color: replyBtnMa.containsMouse ? Theme.Mocha.surface1 : Theme.Mocha.surface0
                border.width: 1
                border.color: Theme.Mocha.surface1

                Text {
                    anchors.centerIn: parent
                    text: "Reply"
                    color: Theme.Mocha.text
                    font.family: Theme.Mocha.fontFamily
                    font.pixelSize: Theme.Mocha.fontSm
                }
                MouseArea {
                    id: replyBtnMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (card.canReply) {
                            card.replyOpen = !card.replyOpen
                        } else {
                            card.actionInvoked("__reply__")
                        }
                    }
                }
            }

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

        // Inline reply input — only when this NCard is in panel context and user clicked Reply.
        RowLayout {
            Layout.fillWidth: true
            visible: card.canReply && card.replyOpen
            spacing: Theme.Mocha.spaceXs

            TextField {
                id: replyField
                objectName: "replyField"
                Layout.fillWidth: true
                placeholderText: card.entry?.inlineReplyPlaceholder ?? "Reply..."
                font.family: Theme.Mocha.fontFamily
                font.pixelSize: Theme.Mocha.fontSm
                color: Theme.Mocha.text
                background: Rectangle {
                    color: Theme.Mocha.surface0
                    border.width: 1
                    border.color: Theme.Mocha.surface1
                    radius: Theme.Mocha.radiusSm
                }
                Keys.onReturnPressed: card.sendReply()
                Keys.onEnterPressed: card.sendReply()
                Keys.onEscapePressed: { card.replyOpen = false }
            }

            Rectangle {
                Layout.preferredWidth: 56
                Layout.preferredHeight: 28
                radius: Theme.Mocha.radiusSm
                color: sendBtnMa.containsMouse ? Theme.Mocha.blue : Theme.Mocha.surface1
                Text {
                    anchors.centerIn: parent
                    text: "Send"
                    color: sendBtnMa.containsMouse ? Theme.Mocha.base : Theme.Mocha.text
                    font.family: Theme.Mocha.fontFamily
                    font.pixelSize: Theme.Mocha.fontSm
                }
                MouseArea {
                    id: sendBtnMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: card.sendReply()
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
