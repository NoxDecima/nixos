# Quickshell V15 Visual Fidelity — Design Spec

**Date:** 2026-05-25
**Status:** Pending approval
**Predecessors:** `2026-05-23-quickshell-shell-design.md` (v1), `2026-05-25-quickshell-refinement-design.md` (v2)
**Reference:** V15 mockup extracted to `/tmp/swaync-design/`, especially `variations.css`, `variations-5.jsx`, `variations-6.jsx`.

## Goal

Bring the Quickshell shell's visual presentation in line with the V15 mockup. The previous refinement round (`2026-05-25-quickshell-refinement-design.md`) addressed structural items (click-outside, grouped notifs, inline reply) but left meaningful visual gaps. This round closes them.

## Non-goals (still deferred)

- Swipe-to-dismiss on toasts
- Multi-monitor toasts (still primary only)
- Notification persistence
- AI chat / OCR / Lens sidebar
- Panel drop shadow (waiting on `Qt5Compat.GraphicalEffects` to land on Quickshell's QML import path — followup #61)

## Decisions log

| # | Topic | Choice |
|---|---|---|
| 1 | Hero distinct background | `Mocha.mantle` + radial-gradient overlay (mauve@0.25 left + blue@0.22 right) + `border-bottom: 1px surface0` |
| 2 | Hero art (empty state) | 50×50, radius 10, `linear-gradient(135deg, mauve, blue)` background, `base`-colored disc icon |
| 3 | Hero title | 13.5px **Bold** (was 13px Bold from v2; the 13.5 matches V15 exactly) |
| 4 | Hero scrub bar | 3px height (V15 spec, not 5px as I'd hand-waved earlier), 2px radius, bg `rgba(205,214,244,0.15)`, fill `text` color |
| 5 | Hero controls | 30×30 circles. Prev/next: `surface0` bg + text color. Play: **`text` bg + `base` color** (inverted accent). |
| 6 | Player tabs | Pill style: 4×10 padding, radius 6, bg `rgba(205,214,244,0.04)`, subtext0 text, 10.5px sans. Active: surface0 bg + text color + inset 1px surface1 border. Dot: 5×5 circle — green=playing, peach=paused, overlay0=idle |
| 7 | Hero/body divider | `border-bottom: 1px surface0` on the hero container (covered by item 1) |
| 8 | Tile surface borders | Already in place from v2 Task 2.2 — verify visible |
| 9 | Toggle layout | Vertical: icon on top, label below. Height 40px, radius 8, bg surface0, border 1px surface1. Gap 3px between icon and label. Label 9.5px. |
| 10 | Toggle active state | Solid `blue` bg, `base`-color icon+label, blue border (replaces our current alpha tint) |
| 11 | NotifList header | Mono font, 11px, `subtext0` color, UPPERCASE with `letter-spacing: 0.08em`. "NOTIFICATIONS · N NEW" / "🗑 CLEAR ALL" |
| 12 | Slider styling | 3px bar (V15 spec), subtler handle (smaller, integrated). Color tint per-instance (sapphire for volume, peach for brightness — already set) |
| 13 | Session row | Separate 30×28 buttons, radius 7, individual surface0 bg + surface1 border. Layout: `flex justify-content space-around` |
| 14 | LowToast (low-urgency variant) | NCard renders a `compact` mode when `urgency === 0`: 26×26 icon column (vs 34), single-line summary only (no body, no actions, no progress bar), 92% opacity, smaller padding (9×11) |
| 15 | GroupCard (separate widget) | New `widgets/GroupCard.qml` — 34×34 app-color icon, mono header `appname · N messages`, single-line preview of newest, `× N` count badge, chevron, expanded body shows `from / text / time` compact rows |
| 16 | NCard refactor to .toast structure | Major: 3-column grid `34px icon | 1fr content | auto close`. Content has meta row (mono app·subject + time on right), summary (12.5px Bold), body (11.5px subtext1), action row. `.t-action.primary` for the first/default action gets blue accent. Close button (×) is 22×22, surface0 bg, maroon icon. |
| 17 | Per-app icon/color registry | New `services/AppRegistry.qml` singleton. Maps `appName` → `{ icon, color }`. Covers known apps (Discord, Spotify, Thunderbird, etc.); unknown → generic icon + `overlay1` color. |
| 18 | Time field on NCard | New: NCard shows relative time (`2m`, `14m`, `1h`) since notif arrived. Computed from `entry.timestamp`. |
| 19 | NotifList header "CLEAR ALL" → calls `Services.Notifications.clearAll()` | Already wired, just restyle |

## A — Hero refinements

### `widgets/HeroMpris.qml` — full restructure

V15 hero (from `variations.css`):
```css
.v15 .hero {
  padding: 14px 16px;
  border-bottom: 1px solid var(--surface0);
  background: var(--mantle);
  position: relative; isolation: isolate; overflow: hidden;
}
.v15 .hero::before {
  /* radial gradient overlay */
  background:
    radial-gradient(ellipse 55% 100% at 0% 50%, rgba(203,166,247,0.25), transparent 60%),
    radial-gradient(ellipse 55% 100% at 100% 50%, rgba(137,180,250,0.22), transparent 60%);
}
.v15 .hero-main { display: grid; grid-template-columns: 50px 1fr auto; gap: 14px; }
.v15 .hero .art {
  width: 50px; height: 50px; border-radius: 10px;
  background: linear-gradient(135deg, var(--mauve), var(--blue));
  color: var(--base);
}
.v15 .hero .info .t { font-size: 13.5px; font-weight: 700; line-height: 1.25; }
.v15 .hero .info .a { font-size: 11px; color: var(--subtext1); margin-top: 2px; }
.v15 .hero .info .prog { font-size: 9.5px; font-family: var(--mono); gap: 8px; margin-top: 6px; }
.v15 .hero .info .prog .bar { height: 3px; border-radius: 2px; background: rgba(205,214,244,0.15); }
.v15 .hero .info .prog .bar i { background: var(--text); }
.v15 .hero .ctrls { gap: 4px; }
.v15 .hero .pb { width: 30px; height: 30px; border-radius: 50%; background: var(--surface0); color: var(--text); }
.v15 .hero .pb.play { background: var(--text); color: var(--base); }
```

QML translation:

```qml
// Hero container
Rectangle {
    id: hero
    property var player: Services.Mpris.activePlayer
    visible: player !== null
    implicitHeight: visible ? layout.implicitHeight + 28 : 0   // padding 14*2
    color: Theme.Mocha.mantle

    // Radial-gradient overlay simulated via two QtQuick.Shapes RadialGradients
    // OR via two semi-transparent Rectangles with stops if Shapes module is unavailable.
    // Simplest fallback: a layered Item with two soft-clipped Rectangles using
    // Qt's RadialGradient (from QtQuick.Shapes module, available without Qt5Compat).

    // 1px surface0 divider at bottom
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: Theme.Mocha.surface0
    }

    RowLayout {
        id: layout
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.topMargin: 14
        anchors.bottomMargin: 14
        spacing: 14

        // Art (50×50, gradient fallback)
        Rectangle {
            id: art
            Layout.preferredWidth: 50
            Layout.preferredHeight: 50
            radius: 10
            gradient: Gradient {
                orientation: Gradient.Diagonal     // approximates 135deg linear-gradient
                GradientStop { position: 0.0; color: Theme.Mocha.mauve }
                GradientStop { position: 1.0; color: Theme.Mocha.blue }
            }
            // Album art image overlay (when available)
            Image {
                anchors.fill: parent
                source: hero.player?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                visible: status === Image.Ready
            }
            // Fallback disc icon (when no album art)
            Text {
                anchors.centerIn: parent
                visible: art.children[0].status !== Image.Ready
                text: "F"   // FontAwesome compact-disc — or use  music
                color: Theme.Mocha.base
                font.family: Theme.Mocha.iconFamily
                font.pixelSize: 22
            }
        }

        // Info column
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                text: hero.player?.trackTitle ?? ""
                color: Theme.Mocha.text
                font.family: Theme.Mocha.fontFamily
                font.pixelSize: 13     // V15 says 13.5, Qt rounds; close enough
                font.weight: Font.Bold
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
            Text {
                text: hero.player?.trackArtist ?? ""
                color: Theme.Mocha.subtext1
                font.family: Theme.Mocha.fontFamily
                font.pixelSize: 11
                Layout.fillWidth: true
                Layout.topMargin: 2
                elide: Text.ElideRight
            }

            // Progress row
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 6
                spacing: 8

                Text {
                    text: hero._fmt(hero.player?.position ?? 0)
                    color: Theme.Mocha.subtext0
                    font.family: Theme.Mocha.fontMono
                    font.pixelSize: 9
                }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 3
                    radius: 2
                    color: Qt.rgba(0.804, 0.839, 0.957, 0.15)   // rgba(205,214,244,0.15)
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
                    font.pixelSize: 9
                }
            }
        }

        // Controls (prev, play [inverted], next)
        Row {
            spacing: 4
            // Prev: 30 circle, surface0 bg, text color
            // Play: 30 circle, TEXT bg, BASE color   ← inverted
            // Next: 30 circle, surface0 bg, text color
            // Implementation: 3 Rectangle buttons, each 30×30, radius 15
        }
    }
}
```

### Player tabs — restyle to V15 pill format

```qml
// widgets/PlayerTabs.qml (full restructure)
Item {
    visible: Services.Mpris.players.length > 1
    implicitHeight: visible ? 32 : 0

    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Qt.rgba(0.804, 0.839, 0.957, 0.06)   // rgba(205,214,244,0.06)
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.topMargin: 11   // includes border + 10 padding-top
        spacing: 4

        Repeater {
            model: Services.Mpris.players
            delegate: Rectangle {
                property bool isActive: modelData === Services.Mpris.activePlayer
                property string state: modelData?.playbackState === 1 ? "playing"
                                     : modelData?.playbackState === 2 ? "paused" : "idle"
                Layout.preferredHeight: 22
                radius: 6
                color: isActive ? Theme.Mocha.surface0
                                : Qt.rgba(0.804, 0.839, 0.957, 0.04)
                border.width: isActive ? 1 : 0
                border.color: Theme.Mocha.surface1

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    // Status dot
                    Rectangle {
                        Layout.preferredWidth: 5
                        Layout.preferredHeight: 5
                        radius: 2.5
                        color: parent.parent.state === "playing" ? Theme.Mocha.green
                             : parent.parent.state === "paused"  ? Theme.Mocha.peach
                             : Theme.Mocha.overlay0
                    }
                    // App icon (from AppRegistry — see Section H)
                    Text {
                        text: Services.AppRegistry.iconFor(modelData?.identity ?? "")
                        color: parent.parent.isActive ? Theme.Mocha.text : Theme.Mocha.subtext0
                        font.family: Theme.Mocha.iconFamily
                        font.pixelSize: 11
                    }
                    // App name
                    Text {
                        text: modelData?.identity ?? "Player"
                        color: parent.parent.isActive ? Theme.Mocha.text : Theme.Mocha.subtext0
                        font.family: Theme.Mocha.fontFamily
                        font.pixelSize: 10
                        leftPadding: 6
                        rightPadding: 10
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
```

## B — Toggle widget rewrite (icon-top label-below)

### `widgets/Toggle.qml` — replace existing

```qml
Rectangle {
    id: tile
    property string label: ""
    property string icon: ""
    property bool active: false
    property bool warn: false
    signal clicked()

    implicitHeight: 40
    radius: 8
    color: active ? Theme.Mocha.blue : Theme.Mocha.surface0
    border.width: 1
    border.color: active ? Theme.Mocha.blue : Theme.Mocha.surface1

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 3

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: tile.icon
            color: active ? Theme.Mocha.base
                 : warn   ? Theme.Mocha.peach
                          : Theme.Mocha.text
            font.family: Theme.Mocha.iconFamily
            font.pixelSize: 14
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: tile.label
            color: active ? Theme.Mocha.base
                 : warn   ? Theme.Mocha.peach
                          : Theme.Mocha.text
            font.family: Theme.Mocha.fontFamily
            font.pixelSize: 10
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: tile.clicked()
    }
}
```

ToggleTile stays mostly the same — its GridLayout (2 cols, gap 5) and the 8 toggles unchanged. The new Toggle widget is taller (40px), icon-top, solid blue when active.

## C — Slider polish

### `widgets/Slider.qml` — refine bar + handle

V15 has no explicit slider CSS (the panel mockup shows visual slider style but the JSX doesn't specify CSS rules — it's stylistic). Match the V15 image:
- Bar: 3-4px height
- Handle: small (8×8), subtle, integrated with the bar (not a popping circle)

Edit existing Slider.qml:
- Change `implicitHeight: 28` → `implicitHeight: 22`
- Change background `height: 4` → `height: 4` (keep)
- Change handle `width: 16; height: 16; radius: 8` → `width: 10; height: 10; radius: 5` (subtler)
- Keep the tint colors (sapphire for volume, peach for brightness)

## D — Session row separated buttons

### `widgets/SessionTile.qml` — replace existing

Current: 5 buttons in a row sharing a single tile bg with the outer tile border.
V15: 5 separate small buttons, each its own surface0 bg + surface1 border.

```qml
RowLayout {
    spacing: 6
    Layout.alignment: Qt.AlignHCenter

    component PwrBtn: Rectangle {
        property string icon: ""
        property bool danger: false
        signal clicked()
        Layout.preferredWidth: 30
        Layout.preferredHeight: 28
        radius: 7
        color: ma.containsMouse
            ? (danger ? Qt.alpha(Theme.Mocha.red, 0.25) : Theme.Mocha.surface1)
            : Theme.Mocha.surface0
        border.width: 1
        border.color: danger ? Qt.rgba(0.953, 0.545, 0.659, 0.25)   // red@0.25
                             : Theme.Mocha.surface1

        Text {
            anchors.centerIn: parent
            text: parent.icon
            color: parent.danger ? Theme.Mocha.red : Theme.Mocha.subtext0
            font.family: Theme.Mocha.iconFamily
            font.pixelSize: 12
        }
        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }

    // 5 buttons (lock, sign-out, sleep, reboot, power-off)
    PwrBtn { icon: ""; onClicked: Services.Hyprland.dispatch("exec hyprlock") }
    PwrBtn { icon: ""; onClicked: Services.Hyprland.dispatch("exit") }
    PwrBtn { icon: ""; onClicked: Services.Hyprland.dispatch("exec systemctl suspend") }
    PwrBtn { icon: ""; onClicked: Services.Hyprland.dispatch("exec reboot") }
    PwrBtn { icon: ""; danger: true; onClicked: Services.Hyprland.dispatch("exec shutdown now") }
}
```

Wrap in an outer container that does NOT have its own tile border (since each button has its own border now). Or remove the outer tile chrome entirely.

## E — NotifList header (mono uppercase)

In `widgets/NotifList.qml`, find the header block:

```qml
    RowLayout {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Theme.Mocha.spaceSm

        Text {
            text: `Notifications · ${root.count} new`
            color: Theme.Mocha.subtext0
            font.family: Theme.Mocha.fontFamily
            font.pixelSize: Theme.Mocha.fontSm
            Layout.fillWidth: true
        }
        Text {
            text: " clear"
            ...
        }
    }
```

Change to:

```qml
    RowLayout {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Theme.Mocha.spaceSm

        Text {
            text: (root.count > 0
                   ? `NOTIFICATIONS · ${root.count} NEW`
                   : `NOTIFICATIONS · 0 NEW`)
            color: Theme.Mocha.subtext0
            font.family: Theme.Mocha.fontMono
            font.pixelSize: 11
            font.letterSpacing: 1.0   // approximate 0.08em
            Layout.fillWidth: true
        }
        Text {
            text: " CLEAR ALL"
            color: Theme.Mocha.overlay1
            font.family: Theme.Mocha.fontMono
            font.pixelSize: 11
            font.letterSpacing: 1.0
            visible: root.count > 0
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Services.Notifications.clearAll()
            }
        }
    }
```

## F — NCard refactor to V15 `.toast` structure

### `widgets/NCard.qml` — major restructure

V15 `.toast` (used for BOTH panel cards AND toasts):
```
.toast {
    bg: rgba(24,24,37,0.97); border 1px surface0; radius 12;
    box-shadow: 0 12px 32px rgba(0,0,0,0.55);
}
.toast .t-body { grid: 34px 1fr auto; gap 10; padding 12; align-items: start; }
.toast .t-icon { 34×34, radius 8, app-color bg, base color }
.toast .t-content { min-width: 0 }
.toast .t-meta { mono 10.5px subtext0; letter-spacing 0.04em; margin-bottom 3 }
.toast .t-summary { 12.5px text 600 line-height 1.35 }
.toast .t-text { 11.5px subtext1 line-height 1.45 margin-top 3 }
.toast .t-actions { gap 6 margin-top 8 }
.toast .t-action { 11px sans, mantle bg, text color, padding 5×10, radius 6, border 1px surface1 }
.toast .t-action.primary { color blue, border rgba(137,180,250,0.3) }
.toast .t-close { 22×22, radius 6, surface0 bg, maroon color, border 1px surface1 }
.toast.critical { border red + glow }
.toast.low { opacity 0.92; grid 26px 1fr auto; padding 9×11 }
.toast.low .t-icon { 26×26, radius 6, surface0 bg, subtext0 color }
```

New QML structure:

```qml
Rectangle {
    id: card

    property var entry
    property bool showProgress: false
    property real progress: 1.0
    property int urgency: entry?.urgency ?? 1
    property bool canReply: false
    property bool replyOpen: false
    property bool lowCompact: urgency === 0    // NEW — low priority gets compact form

    signal dismissed()
    signal actionInvoked(string actionId)

    width: 380
    implicitHeight: layout.implicitHeight + (lowCompact ? 18 : 24)   // 9*2 vs 12*2
    color: Qt.rgba(0.094, 0.094, 0.145, lowCompact ? 0.94 : 0.97)
    opacity: lowCompact ? 0.92 : 1.0
    radius: 12
    border.width: 1
    border.color: urgency === 2 ? Theme.Mocha.red : Theme.Mocha.surface0

    // Helper: lookup app icon + color
    readonly property var appInfo: Services.AppRegistry.for(entry?.appName ?? "")
    readonly property color iconBg:
        urgency === 2 ? Theme.Mocha.red                       // critical
      : lowCompact     ? Theme.Mocha.surface0                  // low
      :                  (appInfo?.color ?? Theme.Mocha.overlay1)
    readonly property color iconFg:
        lowCompact ? Theme.Mocha.subtext0 : Theme.Mocha.base

    GridLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: lowCompact ? 9 : 12
        anchors.leftMargin: lowCompact ? 11 : 12
        anchors.rightMargin: lowCompact ? 11 : 12
        columns: 3
        rowSpacing: 0
        columnSpacing: lowCompact ? 9 : 10

        // [Col 1] App icon
        Rectangle {
            Layout.preferredWidth: lowCompact ? 26 : 34
            Layout.preferredHeight: lowCompact ? 26 : 34
            Layout.alignment: lowCompact ? Qt.AlignVCenter : Qt.AlignTop
            radius: lowCompact ? 6 : 8
            color: card.iconBg
            Text {
                anchors.centerIn: parent
                text: card.appInfo?.icon ?? ""   // bell fallback
                color: card.iconFg
                font.family: Theme.Mocha.iconFamily
                font.pixelSize: lowCompact ? 13 : 16
            }
        }

        // [Col 2] Content
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: lowCompact ? Qt.AlignVCenter : Qt.AlignTop
            spacing: 0

            // Meta row: app · subject (left) + time (right)
            RowLayout {
                Layout.fillWidth: true
                visible: !card.lowCompact
                Text {
                    Layout.fillWidth: true
                    text: card.entry?.appName ?? ""
                    color: Theme.Mocha.subtext0
                    font.family: Theme.Mocha.fontMono
                    font.pixelSize: 10
                    font.letterSpacing: 0.4
                    elide: Text.ElideRight
                }
                Text {
                    text: card._relativeTime(card.entry?.timestamp ?? Date.now())
                    color: Theme.Mocha.subtext0
                    font.family: Theme.Mocha.fontMono
                    font.pixelSize: 10
                }
            }

            // Summary
            Text {
                Layout.fillWidth: true
                Layout.topMargin: card.lowCompact ? 0 : 3
                text: card.entry?.summary ?? ""
                color: Theme.Mocha.text
                font.family: Theme.Mocha.fontFamily
                font.pixelSize: card.lowCompact ? 11 : 12
                font.weight: Font.DemiBold
                wrapMode: Text.WordWrap
                maximumLineCount: card.lowCompact ? 1 : 2
                elide: Text.ElideRight
            }

            // Body
            Text {
                id: bodyText
                Layout.fillWidth: true
                Layout.topMargin: 3
                visible: !card.lowCompact && (card.entry?.body ?? "") !== ""
                text: card.entry?.body ?? ""
                color: Theme.Mocha.subtext1
                font.family: Theme.Mocha.fontFamily
                font.pixelSize: 11
                wrapMode: Text.WordWrap
                maximumLineCount: 3
                elide: Text.ElideRight

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: (card.entry?.actions ?? []).some(a => a.identifier === "default")
                    onClicked: { card.actionInvoked("default"); card.dismissed() }
                }
            }

            // Actions row (and synthetic Reply button — see Task 6.2 of v2)
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 8
                visible: !card.lowCompact && (actionRepeater.count > 0 || (card.entry?.hasInlineReply ?? false))
                spacing: 6

                // Reply button (synthetic, when hasInlineReply)
                Rectangle { /* unchanged from v2 Task 6.2 */ }

                Repeater {
                    id: actionRepeater
                    model: (card.entry?.actions ?? []).filter(a => a.identifier !== "default")
                    delegate: Rectangle {
                        // V15 t-action style: primary uses blue accent
                        property bool isPrimary: index === 0   // first action = primary
                        Layout.preferredHeight: 24
                        implicitWidth: actionText.implicitWidth + 20
                        radius: 6
                        color: Theme.Mocha.mantle
                        border.width: 1
                        border.color: isPrimary
                            ? Qt.rgba(0.537, 0.706, 0.980, 0.3)   // rgba(137,180,250,0.3)
                            : Theme.Mocha.surface1

                        Text {
                            id: actionText
                            anchors.centerIn: parent
                            text: modelData.text ?? modelData.identifier
                            color: isPrimary ? Theme.Mocha.blue : Theme.Mocha.text
                            font.family: Theme.Mocha.fontFamily
                            font.pixelSize: 11
                        }
                        /* MouseArea unchanged */
                    }
                }
            }

            // Inline reply input (TextField + Send) — unchanged from v2 Task 6.2
        }

        // [Col 3] Close button
        Rectangle {
            Layout.preferredWidth: 22
            Layout.preferredHeight: 22
            Layout.alignment: Qt.AlignTop
            radius: 6
            color: Theme.Mocha.surface0
            border.width: 1
            border.color: Theme.Mocha.surface1
            Text {
                anchors.centerIn: parent
                text: ""   // X (Font Awesome)
                color: Theme.Mocha.maroon
                font.family: Theme.Mocha.iconFamily
                font.pixelSize: 10
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: card.dismissed()
            }
        }
    }

    // Progress bar — toast-only, unchanged from v1 (already V15-style: inset, blue fill)

    function _relativeTime(ts) {
        const dt = Math.max(0, Math.floor((Date.now() - ts) / 1000))
        if (dt < 60) return "now"
        if (dt < 3600) return Math.floor(dt / 60) + "m"
        if (dt < 86400) return Math.floor(dt / 3600) + "h"
        return Math.floor(dt / 86400) + "d"
    }
}
```

## G — GroupCard (new widget)

### `widgets/GroupCard.qml` — new file

V15 `.n-group`:
- bg surface0, border 1px surface1, radius 10
- Head: grid `34px 1fr auto auto`, padding 12, gap 10
- Head icon: 34×34 radius 8, app-color bg
- Meta: app name (mono 10.5px subtext0 letter-spacing 0.04em) + preview (12px text 600)
- Count: mono 11px mantle bg, border surface1 (badge style)
- Chev: overlay1 color
- Expanded body: padding 4 8 8, gap 4, separator border-top surface1
- Items: grid `1fr auto`, padding 8 10, radius 6, mantle bg
- g-row: flex baseline gap 8
- g-from: mono 10.5px lavender
- g-text: 11.5px subtext1, ellipsize
- g-time: mono 10px overlay0

```qml
Rectangle {
    id: groupCard

    property var head           // newest entry from the app
    property var older          // array of older entries
    property string appName
    property bool expanded: false

    signal toggleExpand()
    signal clearGroup()
    signal headDismissed()
    signal olderDismissed(int index)

    color: Theme.Mocha.surface0
    border.width: 1
    border.color: Theme.Mocha.surface1
    radius: 10
    implicitHeight: head_area.implicitHeight + (expanded ? body_area.implicitHeight : 0)

    readonly property var appInfo: Services.AppRegistry.for(appName)
    readonly property int totalCount: 1 + (older?.length ?? 0)

    // [Head area]
    Item {
        id: head_area
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        implicitHeight: headGrid.implicitHeight + 24   // padding 12*2

        GridLayout {
            id: headGrid
            anchors.fill: parent
            anchors.margins: 12
            columns: 4
            rowSpacing: 0
            columnSpacing: 10

            // App icon (34×34, app-color)
            Rectangle {
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                radius: 8
                color: groupCard.appInfo?.color ?? Theme.Mocha.overlay1
                Text {
                    anchors.centerIn: parent
                    text: groupCard.appInfo?.icon ?? ""
                    color: Theme.Mocha.base
                    font.family: Theme.Mocha.iconFamily
                    font.pixelSize: 16
                }
            }

            // Meta column: app · N messages + preview
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    Layout.fillWidth: true
                    text: `${groupCard.appName} · ${groupCard.totalCount} messages`
                    color: Theme.Mocha.subtext0
                    font.family: Theme.Mocha.fontMono
                    font.pixelSize: 10
                    font.letterSpacing: 0.4
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    text: groupCard.head?.body || groupCard.head?.summary || ""
                    color: Theme.Mocha.text
                    font.family: Theme.Mocha.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
            }

            // Count badge "× N"
            Rectangle {
                implicitWidth: countText.implicitWidth + 12
                implicitHeight: 20
                radius: 4
                color: Theme.Mocha.mantle
                border.width: 1
                border.color: Theme.Mocha.surface1
                Text {
                    id: countText
                    anchors.centerIn: parent
                    text: `× ${groupCard.totalCount}`
                    color: Theme.Mocha.subtext0
                    font.family: Theme.Mocha.fontMono
                    font.pixelSize: 10
                }
            }

            // Chevron
            Text {
                text: groupCard.expanded ? ""  /* chev-down */ : "" /* chev-right */
                color: Theme.Mocha.overlay1
                font.family: Theme.Mocha.iconFamily
                font.pixelSize: 11
            }
        }

        // Click anywhere on head toggles expand
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: groupCard.toggleExpand()
        }
    }

    // [Body area — visible when expanded]
    Item {
        id: body_area
        anchors.top: head_area.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        visible: groupCard.expanded
        implicitHeight: visible ? bodyCol.implicitHeight + 12 : 0

        // Top separator
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: Theme.Mocha.surface1
        }

        ColumnLayout {
            id: bodyCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: 5
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 4

            // Head as one of the items (so user can dismiss head too)
            // Followed by older entries
            ItemRow {
                from: groupCard.head?.summary ?? ""
                text: groupCard.head?.body ?? ""
                time: groupCard._relTime(groupCard.head?.timestamp)
                onClicked: groupCard.headDismissed()
            }
            Repeater {
                model: groupCard.older ?? []
                delegate: ItemRow {
                    from: modelData.summary ?? ""
                    text: modelData.body ?? ""
                    time: groupCard._relTime(modelData.timestamp)
                    onClicked: groupCard.olderDismissed(index)
                }
            }

            // "Clear all in group" footer button
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 2
                implicitHeight: 22
                radius: 6
                color: clearMa.containsMouse ? Theme.Mocha.surface1 : Theme.Mocha.mantle
                Text {
                    anchors.centerIn: parent
                    text: ` Clear all`
                    color: Theme.Mocha.overlay1
                    font.family: Theme.Mocha.iconFamily
                    font.pixelSize: 10
                }
                MouseArea {
                    id: clearMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: groupCard.clearGroup()
                }
            }
        }
    }

    // Reusable item row component
    component ItemRow: Rectangle {
        property string from
        property string text
        property string time
        signal clicked()
        Layout.fillWidth: true
        implicitHeight: 30
        radius: 6
        color: Theme.Mocha.mantle
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 8
            Text {
                text: from
                color: Theme.Mocha.lavender
                font.family: Theme.Mocha.fontMono
                font.pixelSize: 10
            }
            Text {
                Layout.fillWidth: true
                text: text
                color: Theme.Mocha.subtext1
                font.family: Theme.Mocha.fontFamily
                font.pixelSize: 11
                elide: Text.ElideRight
            }
            Text {
                text: time
                color: Theme.Mocha.overlay0
                font.family: Theme.Mocha.fontMono
                font.pixelSize: 9
            }
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }

    function _relTime(ts) {
        if (!ts) return ""
        const dt = Math.max(0, Math.floor((Date.now() - ts) / 1000))
        if (dt < 60) return "now"
        if (dt < 3600) return Math.floor(dt / 60) + "m"
        if (dt < 86400) return Math.floor(dt / 3600) + "h"
        return Math.floor(dt / 86400) + "d"
    }
}
```

### NotifList integration

In NotifList's Repeater delegate (currently the ColumnLayout with NCard + pill), branch on `modelData.olderCount > 0`:

```qml
delegate: Item {
    Layout.fillWidth: true
    implicitHeight: useGroup ? groupCard.implicitHeight : ncardWrap.implicitHeight

    readonly property bool useGroup: modelData.olderCount > 0

    // Group rendering
    GroupCard {
        id: groupCard
        anchors.fill: parent
        visible: useGroup
        head: modelData.entry
        older: modelData.older
        appName: modelData.appName
        expanded: root.expandedApp === modelData.appName
        onToggleExpand: root.expandedApp = (root.expandedApp === modelData.appName) ? "" : modelData.appName
        onClearGroup: {
            const ids = [modelData.entry.id, ...(modelData.older ?? []).map(o => o.id)]
            for (const id of ids) Services.Notifications.dismiss(id)
        }
        onHeadDismissed: Services.Notifications.dismiss(modelData.entry.id)
        onOlderDismissed: (idx) => Services.Notifications.dismiss(modelData.older[idx].id)
    }

    // Non-group rendering (single NCard, no pill)
    Item {
        id: ncardWrap
        anchors.fill: parent
        visible: !useGroup
        NCard {
            anchors.fill: parent
            canReply: true
            entry: modelData.entry
            onDismissed: Services.Notifications.dismiss(modelData.entry.id)
            onActionInvoked: (actionId) => modelData.entry.notification?.invokeAction(actionId)
        }
    }
}
```

(The old "pill below NCard" approach goes away — GroupCard owns the grouped UI.)

## H — Per-app icon/color registry

### `services/AppRegistry.qml` — new singleton

```qml
pragma Singleton
import QtQuick
import "../theme" as Theme

QtObject {
    // Map normalizedAppName -> { icon: PUA-codepoint, color: token }
    readonly property var _registry: ({
        // Chat / messaging
        "discord":     { icon: "F", color: Theme.Mocha.mauve },     // mdi.discord
        "vesktop":     { icon: "F", color: Theme.Mocha.mauve },
        "element":     { icon: "E", color: Theme.Mocha.teal },      // chat
        "signal":      { icon: "E", color: Theme.Mocha.blue },
        "telegram":    { icon: "E", color: Theme.Mocha.sapphire },
        "slack":       { icon: "E", color: Theme.Mocha.teal },

        // Mail
        "thunderbird": { icon: "0", color: Theme.Mocha.sapphire },  // mdi.email
        "gmail":       { icon: "0", color: Theme.Mocha.sapphire },
        "mail":        { icon: "0", color: Theme.Mocha.sapphire },
        "cron":        { icon: "0", color: Theme.Mocha.peach },     // job-style notifs

        // Media
        "spotify":     { icon: "A", color: Theme.Mocha.green },     // mdi.music
        "mpv":         { icon: "8", color: Theme.Mocha.maroon },
        "firefox":     { icon: "0", color: Theme.Mocha.peach },
        "zen":         { icon: "0", color: Theme.Mocha.peach },

        // Dev / system
        "deploy":      { icon: "D", color: Theme.Mocha.green },     // terminal
        "journalctl":  { icon: "D", color: Theme.Mocha.yellow },
        "system":      { icon: "D", color: Theme.Mocha.subtext0 },
        "calendar":    { icon: "7", color: Theme.Mocha.lavender },
        "battery":     { icon: "4", color: Theme.Mocha.green },

        // Default (unknown apps)
        "_default":    { icon: "",  color: Theme.Mocha.overlay1 }   // bell
    })

    function for(appName) {
        if (!appName) return _registry["_default"]
        const key = appName.toLowerCase().trim()
        // Exact match first
        if (key in _registry) return _registry[key]
        // Substring fallback (e.g., "discord canary" -> "discord")
        for (const k in _registry) {
            if (k === "_default") continue
            if (key.includes(k) || k.includes(key)) return _registry[k]
        }
        return _registry["_default"]
    }

    function iconFor(appName) { return this.for(appName).icon }
    function colorFor(appName) { return this.for(appName).color }
}
```

**Note on icon codepoints**: the chosen glyphs (Material Design icons via Nerd Font) require codepoints above U+FFFF (in the MDI range like `F`). Qt6/QML supports surrogate pairs in `\uXXXX` strings automatically, OR you can use ES6 `\u{F066F}`. If MDI codepoints don't resolve in `Symbols Nerd Font Mono`, fall back to Font Awesome codepoints in the same range (verify per app).

## Files touched

| Path | Change |
|---|---|
| `config/quickshell/widgets/HeroMpris.qml` | Restructure: mantle bg + radial gradient simulation, art with gradient fallback, 13.5px Bold title, mono progress times, inverted play button |
| `config/quickshell/widgets/PlayerTabs.qml` | Restyle to V15 pill format: status dots + app icons + active highlighting + top border separator |
| `config/quickshell/widgets/Toggle.qml` | Replace with vertical layout (icon top, label below); solid blue when active |
| `config/quickshell/widgets/Slider.qml` | Smaller handle (10×10), 3px bar, V15 alignment |
| `config/quickshell/widgets/SessionTile.qml` | Replace with 5 separate small buttons, no outer tile chrome |
| `config/quickshell/widgets/NotifList.qml` | UPPERCASE mono header; CLEAR ALL action; integrate GroupCard for grouped rows |
| `config/quickshell/widgets/NCard.qml` | Major refactor: 3-col grid (icon/content/close), app-color icon, meta row with relative time, primary action accent, low-compact variant for urgency=0, V15 .toast styling |
| `config/quickshell/widgets/GroupCard.qml` | **NEW** — V15 `.n-group` structure with head/badge/chevron/expanded body |
| `config/quickshell/widgets/qmldir` | Register GroupCard |
| `config/quickshell/services/AppRegistry.qml` | **NEW** — per-app icon + accent color registry |
| `config/quickshell/services/qmldir` | Register AppRegistry singleton |
| `config/quickshell/Panel.qml` | Hero+body section no longer needs explicit divider (Hero owns its own border-bottom now); verify wrapping |

## Risks

| Risk | Mitigation |
|---|---|
| Qt `Gradient { orientation: Diagonal }` is older API; Qt6 may prefer linear-gradient via QtQuick.Shapes | Test on launch; fall back to a solid mauve color if gradient unavailable |
| Radial-gradient overlay on hero is hard in pure QtQuick — needs Shape/RadialGradient or QtGraphicalEffects | Acceptable fallback: solid mantle bg without the soft tint (lose item 1's gradient detail, keep the structure) — flag as deferred |
| MDI codepoints (F etc.) may not be in `Symbols Nerd Font Mono` | Check `fc-list ":charset=f066f"`; substitute with Font Awesome (`` style) per app where missing |
| App detection is fragile (notifications can send any appName) | Substring fallback in `AppRegistry.for()` handles common variants ("discord", "Discord", "discord canary") |
| GroupCard expanded items show only `body` snippet; some apps use multiline body | Use existing `elide: Text.ElideRight` + `maximumLineCount: 1` (snippet-style as per V15) |
| Toggle layout change affects ToggleTile grid sizing | Verify after Toggle widget rewrite — grid columns stay `1fr 1fr`, but tile height grows; rail may need adjustment |
| Critical-urgency NCard with new structure | Test: red icon bg, red 1px border, no glow (drop-shadow deferred per #61) |
| Time fields will drift without a refresh | Add a single Timer in NotifList that ticks every 30s and bumps a `tickCounter` property, which NCards read in their time computation to refresh |

## Verification checklist

- [ ] Hero shows distinct mantle background with subtle gradient + visible border-bottom divider
- [ ] Empty-state hero: surface0 art with disc icon
- [ ] Active-state hero: gradient art (mauve→blue), Bold 13.5px title, mono progress times, INVERTED play button
- [ ] Player tabs: pill style with colored status dots; active tab visually distinct
- [ ] Toggle grid: vertical icon-top label-below, blue solid fill when active
- [ ] Slider bars are thinner; handles are subtle (10×10)
- [ ] Session row: 5 SEPARATE small buttons with individual borders; power button has red accent
- [ ] NotifList header: UPPERCASE mono, "NOTIFICATIONS · N NEW" + "🗑 CLEAR ALL"
- [ ] NCard: app-color icon column on left, meta row with relative time, primary action gets blue accent, close button is 22×22 with maroon ×
- [ ] Low-priority notif (urgency=0): compact single-line variant with 26×26 icon, no body, no actions
- [ ] Group of 2+ from same app: renders as GroupCard (not NCard + pill)
- [ ] GroupCard expand: shows compact `from / text / time` rows + "Clear all" footer
- [ ] AppRegistry: discord renders mauve, mail renders sapphire, spotify renders green, unknown app renders generic
- [ ] Relative time updates as notifs age (with the 30s tick)
