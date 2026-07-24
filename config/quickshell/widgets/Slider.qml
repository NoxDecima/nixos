import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../theme" as Theme

RowLayout {
    id: row

    property string icon: ""
    property real value: 0       // 0..1, source of truth from outside
    property color tint: Theme.Mocha.blue
    signal changed(real v)

    spacing: Theme.Mocha.spaceSm

    Text {
        text: row.icon
        color: Theme.Mocha.subtext0
        font.family: Theme.Mocha.iconFamily
        font.pixelSize: 14
    }

    Slider {
        id: s
        Layout.fillWidth: true
        // Make the slider tall enough to grab reliably. Default implicit
        // height comes from the 12px handle which is hard to click on.
        implicitHeight: 22
        from: 0
        to: 1

        // No `value: row.value` binding — that fights the user's drag.
        // Instead: initialize once, and sync from row.value only when
        // the user is not actively pressing the slider.
        Component.onCompleted: value = row.value
        Connections {
            target: row
            function onValueChanged() { if (!s.pressed) s.value = row.value }
        }
        onMoved: row.changed(value)

        background: Rectangle {
            x: s.leftPadding
            y: s.topPadding + s.availableHeight / 2 - 2
            width: s.availableWidth
            height: 4
            radius: 2
            color: Theme.Mocha.surface1

            Rectangle {
                width: s.visualPosition * parent.width
                height: parent.height
                radius: 2
                color: row.tint
            }
        }

        handle: Rectangle {
            x: s.leftPadding + s.visualPosition * (s.availableWidth - width)
            y: s.topPadding + s.availableHeight / 2 - height / 2
            width: 10; height: 10; radius: 5
            color: row.tint
            border.width: 0
        }
    }

    Text {
        text: Math.round(s.value * 100) + "%"
        color: Theme.Mocha.subtext0
        font.family: Theme.Mocha.fontFamily
        font.pixelSize: Theme.Mocha.fontSm
        Layout.preferredWidth: 36
        horizontalAlignment: Text.AlignRight
    }
}
