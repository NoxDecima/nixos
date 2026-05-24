import QtQuick
import QtQuick.Layouts
import "../theme" as Theme
import "../services" as Services

Rectangle {
    color: Theme.Mocha.mantle
    radius: Theme.Mocha.radiusMd
    implicitHeight: col.implicitHeight + Theme.Mocha.spaceSm * 2

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: Theme.Mocha.spaceSm
        spacing: Theme.Mocha.spaceXs

        Slider {
            Layout.fillWidth: true
            icon: ""                            // volume-up (Font Awesome)
            tint: Theme.Mocha.sapphire
            value: Services.Audio.volume
            onChanged: (v) => Services.Audio.setVolume(v)
        }
        Slider {
            Layout.fillWidth: true
            visible: Services.Brightness.available    // hides on hosts with no backlight
            icon: ""                            // sun (Font Awesome)
            tint: Theme.Mocha.peach
            value: Services.Brightness.value
            onChanged: (v) => Services.Brightness.setValue(v)
        }
    }
}
