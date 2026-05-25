import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import "../theme" as Theme
import "../services" as Services

Item {
    id: tabs
    visible: Services.Mpris.players.length > 1
    // 22 (pill) + 12 (breathing room) + 1 (divider) = 35
    implicitHeight: visible ? 35 : 0

    function _iconFor(player) {
        const de = player?.desktopEntry ?? ""
        if (!de) return ""
        return Quickshell.iconPath(de, true) || ""
    }

    // Separator at the bottom of the hero+tabs block.
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: Theme.Mocha.surface0
    }

    Row {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.leftMargin: 16
        spacing: 4

        Repeater {
            model: Services.Mpris.players
            delegate: Rectangle {
                id: tab
                property bool isActive: modelData === Services.Mpris.activePlayer
                property int state: modelData?.playbackState ?? 0
                property string iconSrc: tabs._iconFor(modelData)
                property bool useImage: appImg.status === Image.Ready

                height: 22
                implicitWidth: tabRow.implicitWidth + 20
                radius: 6
                color: isActive ? Theme.Mocha.surface0
                                : Qt.rgba(0.804, 0.839, 0.957, 0.04)
                border.width: isActive ? 1 : 0
                border.color: Theme.Mocha.surface1

                RowLayout {
                    id: tabRow
                    anchors.centerIn: parent
                    spacing: 6

                    // Status dot (playing/paused/idle)
                    Rectangle {
                        Layout.preferredWidth: 5
                        Layout.preferredHeight: 5
                        radius: 2.5
                        color: tab.state === MprisPlaybackState.Playing ? Theme.Mocha.green
                             : tab.state === MprisPlaybackState.Paused  ? Theme.Mocha.peach
                                                                        : Theme.Mocha.overlay0
                    }

                    // App icon: real image if resolvable, else music-note glyph
                    Item {
                        Layout.preferredWidth: 12
                        Layout.preferredHeight: 12
                        Image {
                            id: appImg
                            anchors.fill: parent
                            source: tab.iconSrc
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            asynchronous: true
                            visible: tab.useImage
                        }
                        Text {
                            anchors.centerIn: parent
                            visible: !tab.useImage
                            text: "\uF001"   // FA music
                            color: tab.isActive ? Theme.Mocha.text : Theme.Mocha.subtext0
                            font.family: Theme.Mocha.iconFamily
                            font.pixelSize: 11
                        }
                    }

                    // Player name
                    Text {
                        text: modelData?.identity ?? "Player"
                        color: tab.isActive ? Theme.Mocha.text : Theme.Mocha.subtext0
                        font.family: Theme.Mocha.fontFamily
                        font.pixelSize: 10
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Services.Mpris.selectPlayer(modelData)
                }
            }
        }
    }
}
