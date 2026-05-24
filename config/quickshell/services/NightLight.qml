pragma Singleton
import QtQuick
import Quickshell.Io

Item {
    id: root
    property bool active: false

    Process {
        id: check
        command: ["sh", "-c", "pgrep -x hyprsunset >/dev/null && echo on || echo off"]
        stdout: StdioCollector { onStreamFinished: root.active = text.trim() === "on" }
    }
    Timer {
        interval: 3000; repeat: true; running: true; triggeredOnStart: true
        onTriggered: check.running = true
    }

    function toggle() {
        const cmd = active
            ? "pkill -x hyprsunset"
            : "hyprsunset >/dev/null 2>&1 &"
        const p = Qt.createQmlObject(`
            import Quickshell.Io
            Process { command: ["sh", "-c", "${cmd}"]; running: true }
        `, root)
        Qt.callLater(() => check.running = true)
    }
}
