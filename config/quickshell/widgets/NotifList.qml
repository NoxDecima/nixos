import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../theme" as Theme
import "../services" as Services

Item {
    id: root
    implicitWidth: 280
    implicitHeight: 360

    // Compute render mode
    readonly property int count: Services.Notifications.notifs.length
    readonly property string mode:
          count === 0 ? "empty"
        : count === 1 ? "single"
        : count > 12  ? "many"
        : root._groupedCount() > 0 ? "grouped"
        : "few"

    function _groupedCount() {
        const apps = new Set(Services.Notifications.notifs.map(n => n.appName))
        return Services.Notifications.notifs.length - apps.size > 0 ? apps.size : 0
    }

    // Header
    RowLayout {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Theme.Mocha.spaceSm

        Text {
            text: `Notifications · ${root.count} new`
            color: Theme.Mocha.subtext0
            font.family: Theme.Mocha.fontFamily
            font.pixelSize: Theme.Mocha.fontSm
            Layout.fillWidth: true
        }
        Text {
            text: " clear"   // trash + label;  = trash
            color: Theme.Mocha.subtext0
            font.family: Theme.Mocha.iconFamily
            font.pixelSize: Theme.Mocha.fontSm
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Services.Notifications.clearAll()
            }
        }
    }

    // Empty state
    Item {
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        visible: root.mode === "empty"
        Column {
            anchors.centerIn: parent
            spacing: Theme.Mocha.spaceSm
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: ""   // bell (Font Awesome)
                color: Theme.Mocha.overlay0
                font.family: Theme.Mocha.iconFamily
                font.pixelSize: 48
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "No notifications"
                color: Theme.Mocha.overlay0
                font.family: Theme.Mocha.fontFamily
                font.pixelSize: Theme.Mocha.fontSm
            }
        }
    }

    // List (single / few / many / grouped — all render as scrollable list)
    ScrollView {
        anchors.top: header.bottom
        anchors.topMargin: Theme.Mocha.spaceSm
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        visible: root.mode !== "empty"
        clip: true

        ColumnLayout {
            width: root.width
            spacing: Theme.Mocha.spaceSm

            Repeater {
                model: Services.Notifications.notifs
                delegate: NCard {
                    Layout.fillWidth: true
                    entry: modelData
                    onDismissed: Services.Notifications.dismiss(modelData.id)
                    onActionInvoked: (actionId) => modelData.notification?.invokeAction(actionId)
                }
            }
        }
    }
}
