pragma Singleton
import QtQuick
import Quickshell.Services.Mpris

QtObject {
    id: root
    readonly property var players: Mpris.players?.values ?? []
    property var activePlayer: null

    onPlayersChanged: {
        if (!activePlayer || !players.includes(activePlayer)) {
            // Prefer a playing player; else first
            activePlayer = players.find(p => p.playbackState === MprisPlaybackState.Playing)
                          ?? players[0] ?? null
        }
    }

    function selectPlayer(p) { activePlayer = p }
}
