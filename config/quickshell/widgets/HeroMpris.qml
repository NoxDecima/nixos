import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import "../theme" as Theme
import "../services" as Services

Rectangle {
    id: hero
    property var player: Services.Mpris.activePlayer
    visible: player !== null
    implicitHeight: visible ? layoutRow.implicitHeight + 28 : 0   // 14*2 padding
    color: Theme.Mocha.mantle

    function _fmt(s) {
        s = Math.floor(s)
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0")
    }
    function _progress() {
        const len = player?.length ?? 0
        return len > 0 ? (player?.position ?? 0) / len : 0
    }

    // Hero/body separator (V15 border-bottom)
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: Theme.Mocha.surface0
    }

    RowLayout {
        id: layoutRow
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.topMargin: 14
        anchors.bottomMargin: 14
        spacing: 14

        // [Col 1] Art — 50x50 with mauve->blue diagonal gradient fallback
        Rectangle {
            id: art
            Layout.preferredWidth: 50
            Layout.preferredHeight: 50
            radius: 10
            clip: true
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: Theme.Mocha.mauve }
                GradientStop { position: 1.0; color: Theme.Mocha.blue }
            }
            // Album art overlay when MPRIS provides one
            Image {
                id: artImg
                anchors.fill: parent
                source: hero.player?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                visible: status === Image.Ready
                asynchronous: true
            }
            // Fallback music-note glyph (when no album art)
            Text {
                anchors.centerIn: parent
                visible: artImg.status !== Image.Ready
                text: ""   // FA music
                color: Theme.Mocha.base
                font.family: Theme.Mocha.iconFamily
                font.pixelSize: 22
            }
        }

        // [Col 2] Info column
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                Layout.fillWidth: true
                text: hero.player?.trackTitle ?? ""
                color: Theme.Mocha.text
                font.family: Theme.Mocha.fontFamily
                font.pixelSize: 14
                font.weight: Font.Bold
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                Layout.topMargin: 2
                text: hero.player?.trackArtist ?? ""
                color: Theme.Mocha.subtext1
                font.family: Theme.Mocha.fontFamily
                font.pixelSize: 11
                elide: Text.ElideRight
            }

            // Progress row (mono times + slim bar)
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 6
                spacing: 8

                Text {
                    text: hero._fmt(hero.player?.position ?? 0)
                    color: Theme.Mocha.subtext0
                    font.family: Theme.Mocha.fontMono
                    font.pixelSize: 10
                }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 3
                    radius: 2
                    color: Qt.rgba(0.804, 0.839, 0.957, 0.15)   // text@0.15
                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: parent.width * hero._progress()
                        color: Theme.Mocha.text
                        radius: 2
                    }
                }
                Text {
                    text: hero._fmt(hero.player?.length ?? 0)
                    color: Theme.Mocha.subtext0
                    font.family: Theme.Mocha.fontMono
                    font.pixelSize: 10
                }
            }
        }

        // [Col 3] Controls (prev, play [inverted], next)
        Row {
            spacing: 4

            // Prev
            Rectangle {
                width: 30
                height: 30
                radius: 15
                color: prevMa.containsMouse ? Theme.Mocha.surface1 : Theme.Mocha.surface0
                Text {
                    anchors.centerIn: parent
                    text: ""   // FA step-backward
                    color: Theme.Mocha.text
                    font.family: Theme.Mocha.iconFamily
                    font.pixelSize: 11
                }
                MouseArea {
                    id: prevMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: hero.player?.previous()
                }
            }

            // Play / pause — INVERTED (text bg, base color)
            Rectangle {
                width: 30
                height: 30
                radius: 15
                color: Theme.Mocha.text
                opacity: playMa.containsMouse ? 0.85 : 1.0
                Text {
                    anchors.centerIn: parent
                    text: hero.player?.playbackState === MprisPlaybackState.Playing ? "" : ""   // pause / play
                    color: Theme.Mocha.base
                    font.family: Theme.Mocha.iconFamily
                    font.pixelSize: 12
                }
                MouseArea {
                    id: playMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: hero.player?.togglePlaying()
                }
            }

            // Next
            Rectangle {
                width: 30
                height: 30
                radius: 15
                color: nextMa.containsMouse ? Theme.Mocha.surface1 : Theme.Mocha.surface0
                Text {
                    anchors.centerIn: parent
                    text: ""   // FA step-forward
                    color: Theme.Mocha.text
                    font.family: Theme.Mocha.iconFamily
                    font.pixelSize: 11
                }
                MouseArea {
                    id: nextMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: hero.player?.next()
                }
            }
        }
    }
}
