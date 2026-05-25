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

    property string expandedApp: ""

    function _buildRows() {
        const rows = []
        const seen = {}    // appName -> index in rows array

        for (const n of Services.Notifications.notifs) {
            const a = n.appName ?? ""
            if (!(a in seen)) {
                seen[a] = rows.length
                rows.push({ entry: n, appName: a, older: [] })
            } else {
                rows[seen[a]].older.push(n)
            }
        }

        // Flatten: each head; if expanded, its older entries follow.
        const out = []
        for (const r of rows) {
            out.push({
                type: "head",
                entry: r.entry,
                appName: r.appName,
                olderCount: r.older.length,
                older: r.older
            })
            if (r.older.length > 0 && root.expandedApp === r.appName) {
                for (const o of r.older) {
                    out.push({ type: "older", entry: o, appName: r.appName })
                }
            }
        }
        return out
    }

    readonly property var displayRows: _buildRows()

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
                model: root.displayRows
                delegate: ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Theme.Mocha.spaceXs

                    NCard {
                        Layout.fillWidth: true
                        entry: modelData.entry
                        onDismissed: Services.Notifications.dismiss(modelData.entry.id)
                        onActionInvoked: (actionId) => modelData.entry.notification?.invokeAction(actionId)
                    }

                    // Group pill: only on a "head" row with >=1 older entry
                    Rectangle {
                        visible: modelData.type === "head" && (modelData.olderCount ?? 0) > 0
                        Layout.fillWidth: true
                        implicitHeight: 22
                        radius: Theme.Mocha.radiusSm
                        color: Theme.Mocha.surface0

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.Mocha.spaceSm
                            anchors.rightMargin: Theme.Mocha.spaceSm

                            Text {
                                Layout.fillWidth: true
                                text: (root.expandedApp === modelData.appName
                                       ? "collapse"
                                       : `+ ${modelData.olderCount} more from ${modelData.appName}`)
                                color: Theme.Mocha.subtext0
                                font.family: Theme.Mocha.fontFamily
                                font.pixelSize: Theme.Mocha.fontSm
                            }
                            Text {
                                text: "Clear"
                                color: Theme.Mocha.overlay1
                                font.family: Theme.Mocha.fontFamily
                                font.pixelSize: Theme.Mocha.fontSm
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Services.Notifications.dismiss(modelData.entry.id)
                                        for (const o of (modelData.older ?? [])) {
                                            Services.Notifications.dismiss(o.id)
                                        }
                                    }
                                }
                            }
                        }

                        // Pill body click (everything except the Clear text)
                        // toggles expand/collapse.
                        MouseArea {
                            anchors.fill: parent
                            anchors.rightMargin: 60
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.expandedApp = (root.expandedApp === modelData.appName)
                                    ? "" : modelData.appName
                            }
                        }
                    }
                }
            }
        }
    }
}
