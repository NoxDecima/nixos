pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import "." as Services    // sibling singletons (DND)

QtObject {
    id: root

    // All notifications still on screen (panel list + active toasts).
    property var notifs: []
    property int count: notifs.length

    // The subset currently visible as toasts (max 3 in v1).
    property var activeToasts: []

    signal stateChanged()

    property NotificationServer server: NotificationServer {
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        inlineReplySupported: false  // v1: not supported
        keepOnReload: true

        onNotification: (notification) => {
            notification.tracked = true
            const entry = {
                id: notification.id,
                appName: notification.appName,
                summary: notification.summary,
                body: notification.body,
                image: notification.image,
                urgency: notification.urgency,  // 0=low, 1=normal, 2=critical
                actions: notification.actions,
                timestamp: Date.now(),
                notification: notification
            }
            root.notifs = [entry, ...root.notifs]
            if (!Services.DND.enabled) {
                root.activeToasts = [entry, ...root.activeToasts].slice(0, 10)
            }
            root.stateChanged()
        }
    }

    function dismiss(id) {
        const entry = notifs.find(n => n.id === id)
        if (entry?.notification) entry.notification.dismiss()
        notifs = notifs.filter(n => n.id !== id)
        activeToasts = activeToasts.filter(n => n.id !== id)
        stateChanged()
    }

    function clearAll() {
        notifs.forEach(n => n.notification?.dismiss())
        notifs = []
        activeToasts = []
        stateChanged()
    }

    function expireToast(id) {
        activeToasts = activeToasts.filter(n => n.id !== id)
        // notif stays in panel list until dismissed/cleared
    }

    function toggleDnd() {
        Services.DND.toggle()
        if (Services.DND.enabled) activeToasts = []
        stateChanged()
    }

    // Returns JSON string for waybar's custom/notifications module
    function waybarLine() {
        const c = count
        const dnd = Services.DND.enabled
        let icon
        if (dnd) icon = "󰂛"        // bell-slash
        else if (c === 0) icon = "󰂜" // bell-off
        else icon = "󰂚"             // bell-ring
        return JSON.stringify({
            text: c > 0 ? `${icon} ${c}` : icon,
            tooltip: dnd ? "DND on" : `${c} notification${c === 1 ? "" : "s"}`,
            class: dnd ? "dnd" : (c > 0 ? "has-notifs" : "empty")
        })
    }

    // Notify waybar's custom/notifications module to refresh on state change.
    property Process _waybarSignal: Process {
        command: ["pkill", "-SIGRTMIN+8", "waybar"]
    }

    property Connections _stateConn: Connections {
        target: root
        function onStateChanged() { root._waybarSignal.running = true }
    }

    property Connections _dndConn: Connections {
        target: Services.DND
        function onEnabledChanged() { root.stateChanged() }
    }
}
