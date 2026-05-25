import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../theme" as Theme
import "../services" as Services

Rectangle {
    id: card

    property var entry
    property bool showProgress: false
    property real progress: 1.0
    property int urgency: entry?.urgency ?? 1
    property bool canReply: false
    property bool replyOpen: false

    // V15: low priority gets compact single-line variant
    readonly property bool lowCompact: urgency === 0

    // Per-app icon + accent color
    readonly property var appInfo: Services.AppRegistry.lookup(entry?.appName ?? "")
    readonly property color iconBg:
        urgency === 2  ? Theme.Mocha.red                       // critical
      : lowCompact     ? Theme.Mocha.surface0                  // low
      :                  (appInfo.color ?? Theme.Mocha.overlay1)
    readonly property color iconFg: lowCompact ? Theme.Mocha.subtext0 : Theme.Mocha.base

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

    function _relativeTime(ts) {
        if (!ts) return ""
        const dt = Math.max(0, Math.floor((Date.now() - ts) / 1000))
        if (dt < 60) return "now"
        if (dt < 3600) return Math.floor(dt / 60) + "m"
        if (dt < 86400) return Math.floor(dt / 3600) + "h"
        return Math.floor(dt / 86400) + "d"
    }

    width: 380
    implicitHeight: layout.implicitHeight + (lowCompact ? 18 : 24) + (showProgress ? 4 : 0)
    color: Qt.rgba(0.094, 0.094, 0.145, lowCompact ? 0.94 : 0.97)   // mantle@0.94 or 0.97
    opacity: lowCompact ? 0.92 : 1.0
    radius: 12
    border.width: 1
    border.color: urgency === 2 ? Theme.Mocha.red : Theme.Mocha.surface0

    GridLayout {
        id: layout
        anchors.fill: parent
        anchors.topMargin: lowCompact ? 9 : 12
        anchors.bottomMargin: lowCompact ? 9 : 12 + (card.showProgress ? 4 : 0)
        anchors.leftMargin: lowCompact ? 11 : 12
        anchors.rightMargin: lowCompact ? 11 : 12
        columns: 3
        rowSpacing: 0
        columnSpacing: lowCompact ? 9 : 10

        // [Col 1] App icon
        Rectangle {
            Layout.preferredWidth: lowCompact ? 26 : 34
            Layout.preferredHeight: lowCompact ? 26 : 34
            Layout.alignment: lowCompact ? Qt.AlignVCenter : Qt.AlignTop
            radius: lowCompact ? 6 : 8
            color: card.iconBg
            Text {
                anchors.centerIn: parent
                text: card.appInfo.icon ?? ""   // bell fallback
                color: card.iconFg
                font.family: Theme.Mocha.iconFamily
                font.pixelSize: lowCompact ? 13 : 16
            }
        }

        // [Col 2] Content
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: lowCompact ? Qt.AlignVCenter : Qt.AlignTop
            spacing: 0

            // Meta row: app · subject (left) + time (right) — hidden in low compact
            RowLayout {
                Layout.fillWidth: true
                visible: !card.lowCompact
                spacing: 8
                Text {
                    Layout.fillWidth: true
                    text: card.entry?.appName ?? ""
                    color: Theme.Mocha.subtext0
                    font.family: Theme.Mocha.fontMono
                    font.pixelSize: 10
                    font.letterSpacing: 0.4
                    elide: Text.ElideRight
                }
                Text {
                    text: card._relativeTime(card.entry?.timestamp ?? Date.now())
                    color: Theme.Mocha.subtext0
                    font.family: Theme.Mocha.fontMono
                    font.pixelSize: 10
                }
            }

            // Summary
            Text {
                Layout.fillWidth: true
                Layout.topMargin: card.lowCompact ? 0 : 3
                text: card.entry?.summary ?? ""
                color: Theme.Mocha.text
                font.family: Theme.Mocha.fontFamily
                font.pixelSize: card.lowCompact ? 11 : 12
                font.weight: Font.DemiBold
                wrapMode: Text.WordWrap
                maximumLineCount: card.lowCompact ? 1 : 2
                elide: Text.ElideRight
            }

            // Body (hidden in low compact)
            Text {
                id: bodyText
                Layout.fillWidth: true
                Layout.topMargin: 3
                visible: !card.lowCompact && (card.entry?.body ?? "") !== ""
                text: card.entry?.body ?? ""
                color: Theme.Mocha.subtext1
                font.family: Theme.Mocha.fontFamily
                font.pixelSize: 11
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

            // Action row (Reply synthetic + app-provided actions) — hidden in low compact
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 8
                visible: !card.lowCompact && (actionRepeater.count > 0 || (card.entry?.hasInlineReply ?? false))
                spacing: 6

                // Synthetic Reply button (when notif supports inline reply)
                Rectangle {
                    visible: card.entry?.hasInlineReply ?? false
                    Layout.preferredHeight: 24
                    implicitWidth: replyBtnText.implicitWidth + 20
                    radius: 6
                    color: replyBtnMa.containsMouse ? Theme.Mocha.surface1 : Theme.Mocha.mantle
                    border.width: 1
                    border.color: Qt.rgba(0.537, 0.706, 0.980, 0.3)   // blue@0.3
                    Text {
                        id: replyBtnText
                        anchors.centerIn: parent
                        text: "Reply"
                        color: Theme.Mocha.blue
                        font.family: Theme.Mocha.fontFamily
                        font.pixelSize: 11
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
                        property bool isPrimary: index === 0 && !(card.entry?.hasInlineReply ?? false)
                        Layout.preferredHeight: 24
                        implicitWidth: actionText.implicitWidth + 20
                        radius: 6
                        color: btnMa.containsMouse ? Theme.Mocha.surface1 : Theme.Mocha.mantle
                        border.width: 1
                        border.color: isPrimary
                            ? Qt.rgba(0.537, 0.706, 0.980, 0.3)   // blue@0.3
                            : Theme.Mocha.surface1

                        Text {
                            id: actionText
                            anchors.centerIn: parent
                            text: modelData.text ?? modelData.identifier
                            color: isPrimary ? Theme.Mocha.blue : Theme.Mocha.text
                            font.family: Theme.Mocha.fontFamily
                            font.pixelSize: 11
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

            // Inline reply input — only when canReply && replyOpen
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 6
                visible: card.canReply && card.replyOpen
                spacing: 6

                TextField {
                    id: replyField
                    objectName: "replyField"
                    Layout.fillWidth: true
                    placeholderText: card.entry?.inlineReplyPlaceholder ?? "Reply..."
                    font.family: Theme.Mocha.fontFamily
                    font.pixelSize: 11
                    color: Theme.Mocha.text
                    background: Rectangle {
                        color: Theme.Mocha.surface0
                        border.width: 1
                        border.color: Theme.Mocha.surface1
                        radius: 6
                    }
                    Keys.onReturnPressed: card.sendReply()
                    Keys.onEnterPressed: card.sendReply()
                    Keys.onEscapePressed: { card.replyOpen = false }
                }

                Rectangle {
                    Layout.preferredWidth: 56
                    Layout.preferredHeight: 24
                    radius: 6
                    color: sendBtnMa.containsMouse ? Theme.Mocha.blue : Theme.Mocha.surface1
                    Text {
                        anchors.centerIn: parent
                        text: "Send"
                        color: sendBtnMa.containsMouse ? Theme.Mocha.base : Theme.Mocha.text
                        font.family: Theme.Mocha.fontFamily
                        font.pixelSize: 11
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

        // [Col 3] Close button
        Rectangle {
            Layout.preferredWidth: 22
            Layout.preferredHeight: 22
            Layout.alignment: card.lowCompact ? Qt.AlignVCenter : Qt.AlignTop
            radius: 6
            color: closeMa.containsMouse ? Theme.Mocha.surface1 : Theme.Mocha.surface0
            border.width: 1
            border.color: Theme.Mocha.surface1
            Text {
                anchors.centerIn: parent
                text: "\uF00D"   // FA times
                color: Theme.Mocha.maroon
                font.family: Theme.Mocha.iconFamily
                font.pixelSize: 10
            }
            MouseArea {
                id: closeMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: card.dismissed()
            }
        }
    }

    // Progress bar — toast-only, inset from rounded corners
    Rectangle {
        visible: card.showProgress
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Theme.Mocha.radiusMd
        anchors.rightMargin: Theme.Mocha.radiusMd
        anchors.bottomMargin: 4
        height: 2
        color: Qt.rgba(1, 1, 1, 0.04)
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
