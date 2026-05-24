pragma Singleton
import QtQuick

QtObject {
    property bool enabled: false

    function toggle() { enabled = !enabled }
    function set(value) { enabled = !!value }
}
