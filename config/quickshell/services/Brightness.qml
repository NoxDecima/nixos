pragma Singleton
import QtQuick
import Quickshell.Io

Item {
    id: root

    // Backlight device name. On NVIDIA Optimus laptops brightnessctl defaults
    // to "nvidia_0" which is a non-functional device — the actual screen
    // backlight is "intel_backlight". Override if your hardware differs.
    property string device: "intel_backlight"

    // True when brightnessctl returned a usable max for the configured device.
    // Hosts with no backlight (e.g. desktops) leave this false; UI consumers
    // should hide the slider in that case.
    readonly property bool available: _max > 1

    // Computed from _current / _max so a race between readMax and readCur
    // can't leave value temporarily out of [0..1] (which would put the slider
    // handle off-screen and render the percentage as a 4-digit number).
    readonly property real value: available ? _current / _max : 0
    property int _max: 1
    property int _current: 0

    Process {
        id: readMax
        command: ["brightnessctl", "-d", root.device, "m"]
        stdout: StdioCollector { onStreamFinished: {
            const parsed = parseInt(text)
            if (!isNaN(parsed) && parsed > 0) root._max = parsed
        }}
        running: true
    }
    Process {
        id: readCur
        command: ["brightnessctl", "-d", root.device, "g"]
        stdout: StdioCollector { onStreamFinished: {
            const parsed = parseInt(text)
            if (!isNaN(parsed)) root._current = parsed
        }}
        running: true
    }
    Timer {
        interval: 2000; repeat: true; running: root.available
        onTriggered: readCur.running = true
    }

    // Persistent writer Process: set command + running each time we want to apply.
    Process { id: writer }

    function setValue(v) {
        if (!available) return
        const target = Math.round(Math.max(0, Math.min(1, v)) * 100)
        writer.command = ["brightnessctl", "-d", root.device, "set", target + "%"]
        writer.running = true
        Qt.callLater(() => readCur.running = true)
    }
}
