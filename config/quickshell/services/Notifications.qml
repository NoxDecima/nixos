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
        inlineReplySupported: true   // v2: TextField in NCard handles input
        keepOnReload: true

        onNotification: (notification) => {
            notification.tracked = true
            // IMPORTANT: store ONLY plain, serializable data in the entry.
            // Caching live QObjects here (the Notification or its `actions`
            // NotificationAction list) caused a use-after-free crash: when the
            // sender closed/replaced a notification, the server freed those
            // objects while the entry was still in `notifs`/`activeToasts`, and
            // the next Repeater delegate incubation dereferenced the dangling
            // pointer (QV4::QObjectWrapper::wrap -> SIGSEGV). Live objects are
            // now resolved on demand from `server.trackedNotifications` by id.
            const entry = {
                id: notification.id,
                appName: notification.appName,
                appIcon: notification.appIcon ?? "",
                appIconUrl: root._resolveIconSource(notification.appIcon ?? ""),
                summary: notification.summary,
                body: notification.body,
                urgency: notification.urgency,  // 0=low, 1=normal, 2=critical
                actions: (notification.actions ?? [])
                    .filter(a => a)
                    .map(a => ({ identifier: a.identifier, text: a.text ?? "" })),
                hasInlineReply: notification.hasInlineReply ?? false,
                inlineReplyPlaceholder: notification.inlineReplyPlaceholder ?? "",
                timestamp: Date.now()
            }
            root.notifs = [entry, ...root.notifs]
            if (!Services.DND.enabled) {
                root.activeToasts = [entry, ...root.activeToasts].slice(0, 10)
            }
            root.stateChanged()
        }
    }

    // Resolve the LIVE Notification QObject for an id from the server's tracked
    // set. Returns null if the notification has already been closed/freed
    // server-side (the whole point — we never hold the pointer ourselves).
    function _liveNotif(id) {
        const list = root.server.trackedNotifications?.values ?? []
        for (let i = 0; i < list.length; i++) {
            if (list[i] && list[i].id === id) return list[i]
        }
        return null
    }

    // Invoke an app-provided action (or "default") by looking up the live
    // notification at call time. No-op if it's already gone.
    function invokeAction(id, actionId) {
        const n = _liveNotif(id)
        if (!n) return
        const action = (n.actions ?? []).find(a => a && a.identifier === actionId)
        try { if (action && action.invoke) action.invoke() } catch (e) {}
    }

    // Send an inline reply for a notification by id, via the live object.
    function sendReply(id, text) {
        if (!text || text.length === 0) return
        const n = _liveNotif(id)
        try { if (n && n.sendInlineReply) n.sendInlineReply(text) } catch (e) {}
    }

    function dismiss(id) {
        const n = _liveNotif(id)
        try { if (n && n.dismiss) n.dismiss() } catch (e) { /* already closed */ }
        notifs = notifs.filter(e => e.id !== id)
        activeToasts = activeToasts.filter(e => e.id !== id)
        stateChanged()
    }

    function clearAll() {
        notifs.forEach(e => {
            const n = _liveNotif(e.id)
            try { if (n && n.dismiss) n.dismiss() } catch (err) {}
        })
        notifs = []
        activeToasts = []
        stateChanged()
    }

    function expireToast(id) {
        activeToasts = activeToasts.filter(n => n.id !== id)
        // notif stays in panel list until dismissed/cleared
    }

    // Resolve a dbus app_icon string (absolute path, file:// URL, or
    // freedesktop icon-theme name) to a URL usable as Image.source.
    // Returns "" if no usable source is found.
    function _resolveIconSource(appIcon) {
        if (!appIcon || appIcon.length === 0) return ""
        if (appIcon.startsWith("file://")) return appIcon
        if (appIcon.startsWith("/")) return "file://" + appIcon
        const p = Quickshell.iconPath(appIcon, true)
        return p || ""
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
