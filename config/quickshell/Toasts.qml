import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "theme" as Theme
import "services" as Services
import "widgets" as Widgets

PanelWindow {
    id: toastWindow
    property var panelRef    // injected from shell.qml: the Panel instance

    anchors.top: true
    anchors.right: true
    margins.top: 38
    margins.right: 12
    implicitWidth: 400
    implicitHeight: column.implicitHeight + 8
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    visible: Services.Notifications.activeToasts.length > 0

    function timeoutFor(urgency) {
        if (urgency === 0) return 4000   // low
        if (urgency === 2) return 0      // critical: never
        return 8000                       // normal
    }

    // Repeater destroys & recreates ALL delegates when activeToasts changes.
    // To keep surviving toasts' progress from resetting, each delegate saves
    // its progress to this map on destruction and restores it on creation.
    // Entries are dropped when the toast is no longer in activeToasts.
    property var savedProgress: ({})

    ColumnLayout {
        id: column
        anchors.fill: parent
        anchors.margins: 4
        spacing: Theme.Mocha.spaceSm

        Repeater {
            // Instantiate ALL active toasts (so every notif's Timer ticks even
            // while it's queued behind the visible 3). Only the first 3 are
            // visible; the rest are 0-height invisible cells whose timers
            // expire them in the background, so the +N pill count drops over
            // time without user intervention.
            model: Services.Notifications.activeToasts

            delegate: Item {
                id: cell
                Layout.fillWidth: true
                visible: index < 3
                implicitHeight: visible ? card.implicitHeight : 0

                property var entry: modelData
                property int duration: toastWindow.timeoutFor(entry?.urgency ?? 1)
                property real progress: 1
                property bool paused: hover.hovered

                Component.onCompleted: {
                    if (cell.entry && (cell.entry.id in toastWindow.savedProgress)) {
                        cell.progress = toastWindow.savedProgress[cell.entry.id]
                    }
                }

                Component.onDestruction: {
                    if (!cell.entry) return
                    const stillLive = Services.Notifications.activeToasts.some(
                        t => t.id === cell.entry.id
                    )
                    if (stillLive) {
                        toastWindow.savedProgress[cell.entry.id] = cell.progress
                    } else {
                        delete toastWindow.savedProgress[cell.entry.id]
                    }
                }

                Timer {
                    id: tickTimer
                    interval: 50
                    repeat: true
                    running: cell.duration > 0 && !cell.paused
                    onTriggered: {
                        cell.progress -= (50 / cell.duration)
                        if (cell.progress <= 0) {
                            Services.Notifications.expireToast(cell.entry.id)
                        }
                    }
                }

                HoverHandler { id: hover }

                Widgets.NCard {
                    id: card
                    anchors.fill: parent
                    canReply: false
                    entry: cell.entry
                    showProgress: cell.duration > 0
                    progress: cell.progress
                    urgency: cell.entry?.urgency ?? 1
                    onDismissed: Services.Notifications.dismiss(cell.entry.id)
                    onActionInvoked: (actionId) => {
                        if (actionId === "__reply__") {
                            if (toastWindow.panelRef) {
                                toastWindow.panelRef.openWithReply(cell.entry.id)
                            }
                            return
                        }
                        const action = cell.entry?.notification?.actions
                            ?.find(a => a.identifier === actionId)
                        if (action) action.invoke()
                    }
                }
            }
        }

        // Overflow pill — below the stack, indicating "click to see older".
        Rectangle {
            visible: Services.Notifications.activeToasts.length > 3
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: pillText.implicitWidth + Theme.Mocha.spaceMd * 2
            implicitHeight: pillText.implicitHeight + Theme.Mocha.spaceXs * 2
            radius: height / 2
            color: Theme.Mocha.surface1

            Text {
                id: pillText
                anchors.centerIn: parent
                text: `+ ${Services.Notifications.activeToasts.length - 3} more`
                color: Theme.Mocha.subtext0
                font.family: Theme.Mocha.fontFamily
                font.pixelSize: Theme.Mocha.fontSm
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                // Panel toggle wired in Phase 5; for now just clear the overflow.
                onClicked: {
                    Services.Notifications.activeToasts =
                        Services.Notifications.activeToasts.slice(0, 3)
                }
            }
        }
    }
}
