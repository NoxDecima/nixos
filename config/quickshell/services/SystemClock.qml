pragma Singleton
import QtQuick
import Quickshell

QtObject {
    readonly property SystemClock clock: SystemClock {
        precision: SystemClock.Seconds
    }
    readonly property date now: clock.date
}
