import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import "theme" as Theme
import "services" as Services

ShellRoot {
    id: root

    Component.onCompleted: {
        Services.Notifications;
        Services.DND;
    }

    Panel { id: panel }
    Toasts { panelRef: panel }

    IpcHandler {
        target: "panel"
        function toggle(): void { panel.toggle() }
        function open(): void { panel.open() }
        function close(): void { panel.close() }
    }

    IpcHandler {
        target: "notifications"
        function toggleDnd(): void { Services.Notifications.toggleDnd() }
        function clearAll(): void { Services.Notifications.clearAll() }
        function waybar(): string { return Services.Notifications.waybarLine() }
    }
}
