pragma Singleton
import QtQuick
import Quickshell.Io

Item {
    id: root
    property bool powered: false

    Process {
        id: poll
        command: ["sh", "-c", "bluetoothctl show | grep -E 'Powered:' | awk '{print $2}'"]
        stdout: StdioCollector { onStreamFinished: root.powered = text.trim() === "yes" }
    }
    Timer {
        interval: 5000; repeat: true; running: true; triggeredOnStart: true
        onTriggered: poll.running = true
    }

    function toggle() {
        const p = Qt.createQmlObject(`
            import Quickshell.Io
            Process { command: ["bluetoothctl", "power", "${powered ? "off" : "on"}"]; running: true }
        `, root)
        Qt.callLater(() => poll.running = true)
    }
}
