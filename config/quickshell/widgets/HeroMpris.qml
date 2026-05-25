import QtQuick
import QtQuick.Layouts
import "../theme" as Theme
import "../services" as Services

Rectangle {
    id: hero
    property var player: Services.Mpris.activePlayer
    visible: player !== null
    implicitHeight: visible ? layout.implicitHeight + Theme.Mocha.spaceMd * 2 : 0
    color: Theme.Mocha.mantle
    radius: Theme.Mocha.radiusMd

    RowLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: Theme.Mocha.spaceMd
        spacing: Theme.Mocha.spaceMd

        Rectangle {
            id: art
            Layout.preferredWidth: 50; Layout.preferredHeight: 50
            radius: Theme.Mocha.radiusSm
            color: Theme.Mocha.surface0
            clip: true
            Image {
                anchors.fill: parent
                source: hero.player?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                visible: status === Image.Ready
            }
            Text {
                visible: art.children[0].status !== Image.Ready
                anchors.centerIn: parent
                text: ""   // music note (Font Awesome fallback when no art)
                color: Theme.Mocha.overlay0
                font.family: Theme.Mocha.iconFamily
                font.pixelSize: 22
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                text: hero.player?.trackTitle ?? ""
                color: Theme.Mocha.text
                font.family: Theme.Mocha.fontFamily
                font.pixelSize: Theme.Mocha.fontMd
                font.weight: Font.Bold
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
            Text {
                text: hero.player?.trackArtist ?? ""
                color: Theme.Mocha.subtext0
                font.family: Theme.Mocha.fontFamily
                font.pixelSize: Theme.Mocha.fontSm
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: hero._fmt(hero.player?.position ?? 0)
                    color: Theme.Mocha.subtext0
                    font.pixelSize: Theme.Mocha.fontSm - 1
                }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 3
                    radius: 1.5
                    color: Theme.Mocha.surface1
                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: parent.width * hero._progress()
                        color: Theme.Mocha.blue
                        radius: 1.5
                    }
                }
                Text {
                    text: hero._fmt(hero.player?.length ?? 0)
                    color: Theme.Mocha.subtext0
                    font.pixelSize: Theme.Mocha.fontSm - 1
                }
            }
        }

        Row {
            spacing: Theme.Mocha.spaceXs
            component PB: Rectangle {
                property string icon: ""
                signal clicked()
                width: 30; height: 30; radius: 15
                color: ma2.containsMouse ? Theme.Mocha.surface0 : "transparent"
                Text { anchors.centerIn: parent; text: parent.icon; color: Theme.Mocha.text; font.family: Theme.Mocha.iconFamily }
                MouseArea { id: ma2; anchors.fill: parent; hoverEnabled: true; onClicked: parent.clicked() }
            }
            // \uXXXX escapes — literal PUA glyphs get stripped during some writes.
            PB { icon: ""; onClicked: hero.player?.previous() }                              // step-backward
            PB { icon: hero.player?.playbackState === 1 ? "" : "";                     // pause / play
                 onClicked: hero.player?.togglePlaying() }
            PB { icon: ""; onClicked: hero.player?.next() }                                  // step-forward
        }
    }

    function _progress() {
        const len = player?.length ?? 0
        return len > 0 ? (player?.position ?? 0) / len : 0
    }
    function _fmt(s) {
        s = Math.floor(s)
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0")
    }
}
