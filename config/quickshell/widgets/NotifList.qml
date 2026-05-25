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

    // QML's binding analysis doesn't track properties read inside JS function
    // calls, so `_buildRows()` won't auto-re-evaluate when `notifs` mutates.
    // The invalidator counter is bumped on every Notifications state change,
    // forcing this binding to re-fire and rebuild the grouped row list.
    property int _invalidator: 0
    Connections {
        target: Services.Notifications
        function onStateChanged() { root._invalidator++ }
    }
    readonly property var displayRows: {
        root._invalidator;   // dependency — touch to subscribe
        return _buildRows()
    }

    // Called by Toasts.qml (via Panel.openWithReply) when the user clicks
    // "Reply" on a toast. Expands the relevant group if needed, opens the
    // matching NCard's reply field, and gives the TextField keyboard focus.
    function focusReplyFor(id) {
        const entry = Services.Notifications.notifs.find(n => n.id === id)
        if (!entry) return
        // If this entry is part of a group of >= 2 from same app, expand it
        const sameAppCount = Services.Notifications.notifs
            .filter(n => n.appName === entry.appName).length
        if (sameAppCount >= 2) {
            root.expandedApp = entry.appName
        }
        // Defer one event-loop tick so Repeater has time to instantiate
        // the corresponding NCard before we try to find and focus it.
        Qt.callLater(() => root._focusCardById(id))
    }

    function _focusCardById(id) {
        for (let i = 0; i < cardRepeater.count; i++) {
            const delegate = cardRepeater.itemAt(i)
            if (!delegate) continue
            // delegate is the ColumnLayout; first child is the NCard.
            const ncard = delegate.children[0]
            if (ncard && ncard.entry?.id === id) {
                ncard.replyOpen = true
                root._focusTextFieldIn(ncard)
                return
            }
        }
    }

    function _focusTextFieldIn(node) {
        if (!node) return false
        if (node.objectName === "replyField") {
            node.forceActiveFocus()
            return true
        }
        const kids = node.children
        if (!kids) return false
        for (let i = 0; i < kids.length; i++) {
            if (root._focusTextFieldIn(kids[i])) return true
        }
        return false
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
                id: cardRepeater
                model: root.displayRows
                delegate: ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Theme.Mocha.spaceXs

                    NCard {
                        Layout.fillWidth: true
                        canReply: true
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
                                        // Capture all IDs before any dismiss so the
                                        // reactive update from dismiss() doesn't
                                        // invalidate modelData mid-iteration.
                                        const ids = [modelData.entry.id]
                                        for (const o of (modelData.older ?? [])) {
                                            ids.push(o.id)
                                        }
                                        for (const id of ids) {
                                            Services.Notifications.dismiss(id)
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
