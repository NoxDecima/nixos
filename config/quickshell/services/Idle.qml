pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    readonly property string markerPath:
        Quickshell.env("XDG_RUNTIME_DIR") + "/idle-suspend.inhibit"

    property bool inhibited: false

    FileView {
        id: marker
        path: root.markerPath
        watchChanges: true
        onLoaded: root.inhibited = true
        onLoadFailed: root.inhibited = false
        onFileChanged: reload()
        Component.onCompleted: reload()
    }

    function toggle() {
        const p = Qt.createQmlObject(inhibited
            ? `import Quickshell.Io; Process { command: ["rm", "-f", "${root.markerPath}"]; running: true }`
            : `import Quickshell.Io; Process { command: ["touch", "${root.markerPath}"]; running: true }`,
            root)
        Qt.callLater(() => marker.reload())
    }
}
