pragma Singleton
import QtQuick
import Quickshell.Hyprland

QtObject {
    readonly property var workspaces: Hyprland.workspaces
    readonly property var activeWorkspace: Hyprland.focusedWorkspace

    function dispatch(cmd) { Hyprland.dispatch(cmd) }
}
