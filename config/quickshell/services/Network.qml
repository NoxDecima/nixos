pragma Singleton
import QtQuick
import Quickshell.Io

Item {
    id: root
    property bool wifiEnabled: false
    property string activeSsid: ""

    Process {
        id: poll
        command: ["sh", "-c",
                  "nmcli -t -f WIFI,WIFI-HW general && nmcli -t -f ACTIVE,SSID dev wifi"]
        stdout: StdioCollector { onStreamFinished: root._parse(text) }
    }
    Timer {
        interval: 5000; repeat: true; running: true; triggeredOnStart: true
        onTriggered: poll.running = true
    }

    function _parse(out) {
        const lines = out.split("\n")
        wifiEnabled = lines[0]?.startsWith("enabled")
        const active = lines.slice(2).find(l => l.startsWith("yes:"))
        activeSsid = active ? active.split(":")[1] : ""
    }

    function toggleWifi() {
        const p = Qt.createQmlObject(`
            import Quickshell.Io
            Process { command: ["nmcli", "radio", "wifi", "${wifiEnabled ? "off" : "on"}"]; running: true }
        `, root)
        Qt.callLater(() => poll.running = true)
    }

    function refresh() { poll.running = true }
}
