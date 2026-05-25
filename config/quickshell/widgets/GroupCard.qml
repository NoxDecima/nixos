import QtQuick
import QtQuick.Layouts
import "../theme" as Theme
import "../services" as Services

Rectangle {
    id: groupCard

    property var head           // newest entry from the app
    property var older          // array of older entries
    property string appName
    property bool expanded: false

    signal toggleExpand()
    signal clearGroup()
    signal headDismissed()
    signal olderDismissed(int index)

    color: Theme.Mocha.surface0
    border.width: 1
    border.color: Theme.Mocha.surface1
    radius: 10
    clip: true
    implicitHeight: headArea.implicitHeight + (expanded ? bodyArea.implicitHeight : 0)

    readonly property var appInfo: Services.AppRegistry.lookup(appName)
    readonly property int totalCount: 1 + (older?.length ?? 0)

    function _relTime(ts) {
        if (!ts) return ""
        const dt = Math.max(0, Math.floor((Date.now() - ts) / 1000))
        if (dt < 60) return "now"
        if (dt < 3600) return Math.floor(dt / 60) + "m"
        if (dt < 86400) return Math.floor(dt / 3600) + "h"
        return Math.floor(dt / 86400) + "d"
    }

    // Reusable item row component (V15 .g-item)
    component ItemRow: Rectangle {
        property string fromText
        property string bodyText
        property string timeText
        signal dismissedRow()
        Layout.fillWidth: true
        implicitHeight: 30
        radius: 6
        color: Theme.Mocha.mantle
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 8
            Text {
                text: fromText
                color: Theme.Mocha.mauve
                font.family: Theme.Mocha.fontMono
                font.pixelSize: 10
            }
            Text {
                Layout.fillWidth: true
                text: bodyText
                color: Theme.Mocha.subtext1
                font.family: Theme.Mocha.fontFamily
                font.pixelSize: 11
                elide: Text.ElideRight
            }
            Text {
                text: timeText
                color: Theme.Mocha.overlay0
                font.family: Theme.Mocha.fontMono
                font.pixelSize: 9
            }
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.dismissedRow()
        }
    }

    // [Head area]
    Item {
        id: headArea
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        implicitHeight: headGrid.implicitHeight + 24   // padding 12*2

        GridLayout {
            id: headGrid
            anchors.fill: parent
            anchors.margins: 12
            columns: 4
            rowSpacing: 0
            columnSpacing: 10

            // App icon (34x34, app-color bg)
            Rectangle {
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                radius: 8
                color: groupCard.appInfo.color
                Text {
                    anchors.centerIn: parent
                    text: groupCard.appInfo.icon
                    color: Theme.Mocha.base
                    font.family: Theme.Mocha.iconFamily
                    font.pixelSize: 16
                }
            }

            // Meta column: app . N messages + preview
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    Layout.fillWidth: true
                    text: `${groupCard.appName} · ${groupCard.totalCount} messages`
                    color: Theme.Mocha.subtext0
                    font.family: Theme.Mocha.fontMono
                    font.pixelSize: 10
                    font.letterSpacing: 0.4
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    text: groupCard.head?.body || groupCard.head?.summary || ""
                    color: Theme.Mocha.text
                    font.family: Theme.Mocha.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
            }

            // Count badge "x N"
            Rectangle {
                implicitWidth: countText.implicitWidth + 12
                implicitHeight: 20
                radius: 4
                color: Theme.Mocha.mantle
                border.width: 1
                border.color: Theme.Mocha.surface1
                Text {
                    id: countText
                    anchors.centerIn: parent
                    text: `× ${groupCard.totalCount}`
                    color: Theme.Mocha.subtext0
                    font.family: Theme.Mocha.fontMono
                    font.pixelSize: 10
                }
            }

            // Chevron (FA chevron-right when collapsed, chevron-down when expanded)
            Text {
                text: groupCard.expanded ? "\uF078" : "\uF054"
                color: Theme.Mocha.overlay1
                font.family: Theme.Mocha.iconFamily
                font.pixelSize: 11
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: groupCard.toggleExpand()
        }
    }

    // [Body area — visible when expanded]
    Item {
        id: bodyArea
        anchors.top: headArea.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        visible: groupCard.expanded
        implicitHeight: visible ? bodyCol.implicitHeight + 12 : 0

        // Top separator
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: Theme.Mocha.surface1
        }

        ColumnLayout {
            id: bodyCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: 5
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 4

            // Head row first (so user can dismiss head from expanded view)
            ItemRow {
                fromText: groupCard.head?.summary ?? ""
                bodyText: groupCard.head?.body ?? ""
                timeText: groupCard._relTime(groupCard.head?.timestamp)
                onDismissedRow: groupCard.headDismissed()
            }

            Repeater {
                model: groupCard.older ?? []
                delegate: ItemRow {
                    fromText: modelData.summary ?? ""
                    bodyText: modelData.body ?? ""
                    timeText: groupCard._relTime(modelData.timestamp)
                    onDismissedRow: groupCard.olderDismissed(index)
                }
            }

            // "Clear all" footer (FA trash-o + label)
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 2
                implicitHeight: 24
                radius: 6
                color: clearMa.containsMouse ? Theme.Mocha.surface1 : Theme.Mocha.mantle
                Text {
                    anchors.centerIn: parent
                    text: "\uF014  Clear all"
                    color: Theme.Mocha.overlay1
                    font.family: Theme.Mocha.iconFamily
                    font.pixelSize: 11
                }
                MouseArea {
                    id: clearMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: groupCard.clearGroup()
                }
            }
        }
    }
}
