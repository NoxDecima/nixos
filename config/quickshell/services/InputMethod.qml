pragma Singleton
import QtQuick
import Quickshell.Io

Item {
    id: root
    property string currentIm: ""     // e.g. "keyboard-us" or "mozc"
    property string shortLabel: "EN"

    Process {
        id: query
        command: ["fcitx5-remote", "-n"]
        stdout: StdioCollector { onStreamFinished: {
            root.currentIm = text.trim()
            root.shortLabel = root._labelFor(root.currentIm)
        }}
    }
    Timer {
        interval: 1500; repeat: true; running: true; triggeredOnStart: true
        onTriggered: query.running = true
    }

    function _labelFor(im) {
        if (im.startsWith("mozc")) return "あ"
        if (im.startsWith("keyboard-jp")) return "JP"
        return "EN"
    }

    function toggle() {
        const p = Qt.createQmlObject(`
            import Quickshell.Io
            Process { command: ["fcitx5-remote", "-t"]; running: true }
        `, root)
        Qt.callLater(() => query.running = true)
    }
}
