# V15 Visual Fidelity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bring the Quickshell shell's visual presentation in line with the V15 mockup per spec `docs/superpowers/specs/2026-05-25-v15-fidelity-design.md`. Restyles every visible surface (hero, tabs, toggles, sliders, session row, notification list header, notification cards) and adds two new widgets (GroupCard, AppRegistry).

**Architecture:** Pure QML changes to `config/quickshell/`. `~/.config/quickshell` is a `mkOutOfStoreSymlink` to the repo, so edits go live via `pkill quickshell; quickshell &` (no NixOS rebuild). Tasks are ordered by dependency (foundation first, integration last).

**Tech Stack:** QML / Qt6 (Quickshell 0.3+), Catppuccin Mocha tokens via `theme/Mocha.qml`, Symbols Nerd Font Mono + Inter, fontconfig.

---

## Dev workflow

```bash
# After each task's edit:
pkill quickshell; sleep 0.5; quickshell &
sleep 1
LATEST=$(ls -td /run/user/$(id -u)/quickshell/by-id/*/ | head -1)
tail -20 "${LATEST}log.log" | grep -i error || echo "no errors"
```

**Commit scoping discipline**: always `git commit --only -m "..." -- <paths>`. Plain `--` is `--include` (sweeps in pre-staged extras). Repo has pre-existing drift in `system/hyprland.nix`, `system/bluetooth.nix`, `profile/nox-work/configuration.nix`, `system/captive-portal.nix`, `system/syncthing.nix` — `--only` keeps them out.

**Icon escape discipline**: literal PUA glyphs may get stripped during file writes (depending on the tool). Use `\uXXXX` escape sequences for icon strings. The plan provides hex codepoints inline; copy them verbatim.

**Icon coverage check**: before relying on a codepoint, confirm it exists in `Symbols Nerd Font Mono`:
```bash
fc-list ":charset=<hex>" | grep -i symbols
```
If empty, swap for a Font Awesome equivalent (FA codepoints are in U+F000–U+F2FF range, all covered).

---

## File map

| Path | Status | Responsibility |
|---|---|---|
| `config/quickshell/services/AppRegistry.qml` | **NEW** | Per-app icon + accent color singleton |
| `config/quickshell/services/qmldir` | Modify | Register AppRegistry singleton |
| `config/quickshell/widgets/NCard.qml` | Major refactor | V15 `.toast` structure: 3-col grid (icon/content/close), meta row with time, primary-action accent, low-compact mode for urgency=0 |
| `config/quickshell/widgets/GroupCard.qml` | **NEW** | V15 `.n-group` structure: app-icon + mono header + count badge + chevron + expanded compact rows |
| `config/quickshell/widgets/qmldir` | Modify | Register GroupCard widget |
| `config/quickshell/widgets/NotifList.qml` | Modify | Use GroupCard for grouped rows; uppercase mono header |
| `config/quickshell/widgets/HeroMpris.qml` | Major refactor | Mantle bg, gradient art fallback, mono progress times, inverted play button, border-bottom |
| `config/quickshell/widgets/PlayerTabs.qml` | Major refactor | V15 pill style with status dot + app icon + active state |
| `config/quickshell/widgets/Toggle.qml` | Replace | Vertical layout (icon top, label below), solid blue when active |
| `config/quickshell/widgets/Slider.qml` | Modify | 3px bar, 10×10 handle |
| `config/quickshell/widgets/SessionTile.qml` | Replace | 5 separate buttons with individual borders |

---

# Phase 1 — Foundation: AppRegistry

## Task 1.1: AppRegistry singleton

**Files:**
- Create: `/home/nox/nixos/config/quickshell/services/AppRegistry.qml`
- Modify: `/home/nox/nixos/config/quickshell/services/qmldir`

- [ ] **Step 1: Create AppRegistry.qml**

Create `/home/nox/nixos/config/quickshell/services/AppRegistry.qml`:

```qml
pragma Singleton
import QtQuick
import "../theme" as Theme

QtObject {
    id: root

    // Map normalizedAppName -> { icon, color }
    // All icon codepoints are Font Awesome (U+F000-U+F2FF range), covered by
    // Symbols Nerd Font Mono. Avoiding MDI 5-digit codepoints for safety.
    readonly property var _registry: ({
        // Chat / messaging
        "discord":     { icon: "", color: Theme.Mocha.mauve },     // Discord-style (puzzle)
        "vesktop":     { icon: "", color: Theme.Mocha.mauve },
        "element":     { icon: "", color: Theme.Mocha.teal },      // chat
        "signal":      { icon: "", color: Theme.Mocha.blue },
        "telegram":    { icon: "", color: Theme.Mocha.sapphire },
        "slack":       { icon: "", color: Theme.Mocha.teal },

        // Mail
        "thunderbird": { icon: "", color: Theme.Mocha.sapphire },  // envelope
        "gmail":       { icon: "", color: Theme.Mocha.sapphire },
        "mail":        { icon: "", color: Theme.Mocha.sapphire },
        "cron":        { icon: "", color: Theme.Mocha.peach },     // job-style notifs

        // Media
        "spotify":     { icon: "", color: Theme.Mocha.green },     // music note
        "mpv":         { icon: "", color: Theme.Mocha.maroon },    // video-camera
        "firefox":     { icon: "", color: Theme.Mocha.peach },     // firefox
        "zen":         { icon: "", color: Theme.Mocha.peach },

        // Dev / system
        "deploy":      { icon: "", color: Theme.Mocha.green },     // terminal
        "journalctl":  { icon: "", color: Theme.Mocha.yellow },
        "system":      { icon: "", color: Theme.Mocha.subtext0 }, // cog
        "calendar":    { icon: "", color: Theme.Mocha.lavender },  // calendar
        "battery":     { icon: "", color: Theme.Mocha.green },     // battery-full

        // Default (unknown apps)
        "_default":    { icon: "", color: Theme.Mocha.overlay1 }   // bell
    })

    function lookup(appName) {
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

    function iconFor(appName) { return lookup(appName).icon }
    function colorFor(appName) { return lookup(appName).color }
}
```

Note: function is named `lookup` not `for` because `for` is a JavaScript reserved word.

- [ ] **Step 2: Register in services/qmldir**

Append to `/home/nox/nixos/config/quickshell/services/qmldir`:

```
singleton AppRegistry 1.0 AppRegistry.qml
```

- [ ] **Step 3: Verify load**

```bash
pkill quickshell; sleep 0.5; quickshell &
sleep 1
LATEST=$(ls -td /run/user/$(id -u)/quickshell/by-id/*/ | head -1)
tail -10 "${LATEST}log.log" | grep -i error || echo "no errors"
```

Expected: clean load. No consumers yet so no functional test.

- [ ] **Step 4: Commit**

```bash
cd /home/nox/nixos
git add config/quickshell/services/AppRegistry.qml config/quickshell/services/qmldir
git commit --only -m "Add AppRegistry singleton (per-app icon + accent color)" -- config/quickshell/services/AppRegistry.qml config/quickshell/services/qmldir
git log -1 --stat
```

Expected: 2 files.

---

# Phase 2 — NCard refactor to V15 `.toast` structure

## Task 2.1: NCard major refactor

**Files:**
- Modify: `/home/nox/nixos/config/quickshell/widgets/NCard.qml` (full replace)

The current NCard has: header row (app name + ×), summary, body, action buttons, optional reply input, progress bar.

V15's `.toast` structure: 3-column grid with [icon][content][close], plus optional progress bar. Low priority gets a compact variant (smaller icon, no body, no actions).

- [ ] **Step 1: Read current NCard.qml**

```bash
cat /home/nox/nixos/config/quickshell/widgets/NCard.qml
```

Note the current property declarations (entry, showProgress, progress, urgency, canReply, replyOpen) and signals (dismissed, actionInvoked) — they all stay.

- [ ] **Step 2: Replace NCard.qml entirely with the V15 structure**

Use Write to replace the file. Full content:

```qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../theme" as Theme
import "../services" as Services

Rectangle {
    id: card

    property var entry
    property bool showProgress: false
    property real progress: 1.0
    property int urgency: entry?.urgency ?? 1
    property bool canReply: false
    property bool replyOpen: false

    // V15: low priority gets compact single-line variant
    readonly property bool lowCompact: urgency === 0

    // Per-app icon + accent color
    readonly property var appInfo: Services.AppRegistry.lookup(entry?.appName ?? "")
    readonly property color iconBg:
        urgency === 2  ? Theme.Mocha.red                       // critical
      : lowCompact     ? Theme.Mocha.surface0                  // low
      :                  (appInfo.color ?? Theme.Mocha.overlay1)
    readonly property color iconFg: lowCompact ? Theme.Mocha.subtext0 : Theme.Mocha.base

    signal dismissed()
    signal actionInvoked(string actionId)

    function sendReply() {
        const text = replyField.text
        if (!text || text.length === 0) return
        if (card.entry?.notification?.sendInlineReply) {
            card.entry.notification.sendInlineReply(text)
        }
        replyField.text = ""
        card.replyOpen = false
        card.dismissed()
    }

    function _relativeTime(ts) {
        if (!ts) return ""
        const dt = Math.max(0, Math.floor((Date.now() - ts) / 1000))
        if (dt < 60) return "now"
        if (dt < 3600) return Math.floor(dt / 60) + "m"
        if (dt < 86400) return Math.floor(dt / 3600) + "h"
        return Math.floor(dt / 86400) + "d"
    }

    width: 380
    implicitHeight: layout.implicitHeight + (lowCompact ? 18 : 24) + (showProgress ? 4 : 0)
    color: Qt.rgba(0.094, 0.094, 0.145, lowCompact ? 0.94 : 0.97)   // mantle@0.94 or 0.97
    opacity: lowCompact ? 0.92 : 1.0
    radius: 12
    border.width: 1
    border.color: urgency === 2 ? Theme.Mocha.red : Theme.Mocha.surface0

    GridLayout {
        id: layout
        anchors.fill: parent
        anchors.topMargin: lowCompact ? 9 : 12
        anchors.bottomMargin: lowCompact ? 9 : 12 + (card.showProgress ? 4 : 0)
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
                text: card.appInfo.icon ?? ""   // bell fallback
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

            // Meta row: app · subject (left) + time (right) — hidden in low compact
            RowLayout {
                Layout.fillWidth: true
                visible: !card.lowCompact
                spacing: 8
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

            // Body (hidden in low compact)
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
                    onClicked: {
                        card.actionInvoked("default")
                        card.dismissed()
                    }
                }
            }

            // Action row (Reply synthetic + app-provided actions) — hidden in low compact
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 8
                visible: !card.lowCompact && (actionRepeater.count > 0 || (card.entry?.hasInlineReply ?? false))
                spacing: 6

                // Synthetic Reply button (when notif supports inline reply)
                Rectangle {
                    visible: card.entry?.hasInlineReply ?? false
                    Layout.preferredHeight: 24
                    implicitWidth: replyBtnText.implicitWidth + 20
                    radius: 6
                    color: replyBtnMa.containsMouse ? Theme.Mocha.surface1 : Theme.Mocha.mantle
                    border.width: 1
                    border.color: Qt.rgba(0.537, 0.706, 0.980, 0.3)   // blue@0.3
                    Text {
                        id: replyBtnText
                        anchors.centerIn: parent
                        text: "Reply"
                        color: Theme.Mocha.blue
                        font.family: Theme.Mocha.fontFamily
                        font.pixelSize: 11
                    }
                    MouseArea {
                        id: replyBtnMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (card.canReply) {
                                card.replyOpen = !card.replyOpen
                            } else {
                                card.actionInvoked("__reply__")
                            }
                        }
                    }
                }

                Repeater {
                    id: actionRepeater
                    model: (card.entry?.actions ?? []).filter(a => a.identifier !== "default")
                    delegate: Rectangle {
                        property bool isPrimary: index === 0 && !(card.entry?.hasInlineReply ?? false)
                        Layout.preferredHeight: 24
                        implicitWidth: actionText.implicitWidth + 20
                        radius: 6
                        color: btnMa.containsMouse ? Theme.Mocha.surface1 : Theme.Mocha.mantle
                        border.width: 1
                        border.color: isPrimary
                            ? Qt.rgba(0.537, 0.706, 0.980, 0.3)   // blue@0.3
                            : Theme.Mocha.surface1

                        Text {
                            id: actionText
                            anchors.centerIn: parent
                            text: modelData.text ?? modelData.identifier
                            color: isPrimary ? Theme.Mocha.blue : Theme.Mocha.text
                            font.family: Theme.Mocha.fontFamily
                            font.pixelSize: 11
                        }
                        MouseArea {
                            id: btnMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                card.actionInvoked(modelData.identifier)
                                card.dismissed()
                            }
                        }
                    }
                }
            }

            // Inline reply input — only when canReply && replyOpen
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 6
                visible: card.canReply && card.replyOpen
                spacing: 6

                TextField {
                    id: replyField
                    objectName: "replyField"
                    Layout.fillWidth: true
                    placeholderText: card.entry?.inlineReplyPlaceholder ?? "Reply..."
                    font.family: Theme.Mocha.fontFamily
                    font.pixelSize: 11
                    color: Theme.Mocha.text
                    background: Rectangle {
                        color: Theme.Mocha.surface0
                        border.width: 1
                        border.color: Theme.Mocha.surface1
                        radius: 6
                    }
                    Keys.onReturnPressed: card.sendReply()
                    Keys.onEnterPressed: card.sendReply()
                    Keys.onEscapePressed: { card.replyOpen = false }
                }

                Rectangle {
                    Layout.preferredWidth: 56
                    Layout.preferredHeight: 24
                    radius: 6
                    color: sendBtnMa.containsMouse ? Theme.Mocha.blue : Theme.Mocha.surface1
                    Text {
                        anchors.centerIn: parent
                        text: "Send"
                        color: sendBtnMa.containsMouse ? Theme.Mocha.base : Theme.Mocha.text
                        font.family: Theme.Mocha.fontFamily
                        font.pixelSize: 11
                    }
                    MouseArea {
                        id: sendBtnMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: card.sendReply()
                    }
                }
            }
        }

        // [Col 3] Close button
        Rectangle {
            Layout.preferredWidth: 22
            Layout.preferredHeight: 22
            Layout.alignment: card.lowCompact ? Qt.AlignVCenter : Qt.AlignTop
            radius: 6
            color: closeMa.containsMouse ? Theme.Mocha.surface1 : Theme.Mocha.surface0
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
                id: closeMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: card.dismissed()
            }
        }
    }

    // Progress bar — toast-only, inset from rounded corners
    Rectangle {
        visible: card.showProgress
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Theme.Mocha.radiusMd
        anchors.rightMargin: Theme.Mocha.radiusMd
        anchors.bottomMargin: 4
        height: 2
        color: Qt.rgba(1, 1, 1, 0.04)
        radius: 1

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width * card.progress
            color: card.urgency === 2 ? Theme.Mocha.red : Theme.Mocha.blue
            radius: 1
        }
    }
}
```

- [ ] **Step 3: Reload + verify**

```bash
pkill quickshell; sleep 0.5; quickshell &
sleep 1
notify-send "Test app" "Body line — should render with icon column, meta row, summary, body"
sleep 0.5
notify-send -u low "Low priority" "Compact form — should be single-line, smaller icon"
sleep 0.5
LATEST=$(ls -td /run/user/$(id -u)/quickshell/by-id/*/ | head -1)
tail -20 "${LATEST}log.log" | grep -i error || echo "no errors"
```

Expected: clean QML load. User will visually verify icon column + content + close button structure.

- [ ] **Step 4: Commit**

```bash
cd /home/nox/nixos
git add config/quickshell/widgets/NCard.qml
git commit --only -m "NCard: refactor to V15 .toast structure (icon column, meta row, time, primary action accent, low-compact variant)" -- config/quickshell/widgets/NCard.qml
git log -1 --stat
```

Expected: 1 file in commit.

---

# Phase 3 — Grouped notifications

## Task 3.1: GroupCard new widget

**Files:**
- Create: `/home/nox/nixos/config/quickshell/widgets/GroupCard.qml`
- Modify: `/home/nox/nixos/config/quickshell/widgets/qmldir`

- [ ] **Step 1: Create GroupCard.qml**

Create `/home/nox/nixos/config/quickshell/widgets/GroupCard.qml`:

```qml
import QtQuick
import QtQuick.Layouts
import "../theme" as Theme
import "../services" as Services

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
    clip: true
    implicitHeight: headArea.implicitHeight + (expanded ? bodyArea.implicitHeight : 0)

    readonly property var appInfo: Services.AppRegistry.lookup(appName)
    readonly property int totalCount: 1 + (older?.length ?? 0)

    function _relTime(ts) {
        if (!ts) return ""
        const dt = Math.max(0, Math.floor((Date.now() - ts) / 1000))
        if (dt < 60) return "now"
        if (dt < 3600) return Math.floor(dt / 60) + "m"
        if (dt < 86400) return Math.floor(dt / 3600) + "h"
        return Math.floor(dt / 86400) + "d"
    }

    // [Head area]
    Item {
        id: headArea
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

            // App icon (34×34, app-color bg)
            Rectangle {
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                radius: 8
                color: groupCard.appInfo.color
                Text {
                    anchors.centerIn: parent
                    text: groupCard.appInfo.icon
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

            // Chevron (right when collapsed, down when expanded)
            Text {
                text: groupCard.expanded ? "" : ""   // chevron-down / chevron-right (FA)
                color: Theme.Mocha.overlay1
                font.family: Theme.Mocha.iconFamily
                font.pixelSize: 11
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: groupCard.toggleExpand()
        }
    }

    // [Body area — visible when expanded]
    Item {
        id: bodyArea
        anchors.top: headArea.bottom
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

            // Head row first (so user can dismiss head from expanded view)
            ItemRow {
                fromText: groupCard.head?.summary ?? ""
                bodyText: groupCard.head?.body ?? ""
                timeText: groupCard._relTime(groupCard.head?.timestamp)
                onDismissedRow: groupCard.headDismissed()
            }

            Repeater {
                model: groupCard.older ?? []
                delegate: ItemRow {
                    fromText: modelData.summary ?? ""
                    bodyText: modelData.body ?? ""
                    timeText: groupCard._relTime(modelData.timestamp)
                    onDismissedRow: groupCard.olderDismissed(index)
                }
            }

            // "Clear all" footer
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 2
                implicitHeight: 24
                radius: 6
                color: clearMa.containsMouse ? Theme.Mocha.surface1 : Theme.Mocha.mantle
                Text {
                    anchors.centerIn: parent
                    text: "  Clear all"   // trash-o + label
                    color: Theme.Mocha.overlay1
                    font.family: Theme.Mocha.iconFamily
                    font.pixelSize: 11
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

    // Reusable item row component (V15 .g-item)
    component ItemRow: Rectangle {
        property string fromText
        property string bodyText
        property string timeText
        signal dismissedRow()
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
                text: fromText
                color: Theme.Mocha.lavender
                font.family: Theme.Mocha.fontMono
                font.pixelSize: 10
            }
            Text {
                Layout.fillWidth: true
                text: bodyText
                color: Theme.Mocha.subtext1
                font.family: Theme.Mocha.fontFamily
                font.pixelSize: 11
                elide: Text.ElideRight
            }
            Text {
                text: timeText
                color: Theme.Mocha.overlay0
                font.family: Theme.Mocha.fontMono
                font.pixelSize: 9
            }
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.dismissedRow()
        }
    }
}
```

- [ ] **Step 2: Register in widgets/qmldir**

Append to `/home/nox/nixos/config/quickshell/widgets/qmldir`:

```
GroupCard 1.0 GroupCard.qml
```

- [ ] **Step 3: Reload + verify (no consumers yet)**

```bash
pkill quickshell; sleep 0.5; quickshell &
sleep 1
LATEST=$(ls -td /run/user/$(id -u)/quickshell/by-id/*/ | head -1)
tail -10 "${LATEST}log.log" | grep -i error || echo "no errors"
```

Expected: clean load. GroupCard isn't instantiated until Task 3.2.

- [ ] **Step 4: Commit**

```bash
cd /home/nox/nixos
git add config/quickshell/widgets/GroupCard.qml config/quickshell/widgets/qmldir
git commit --only -m "Add GroupCard widget (V15 .n-group: app-icon head + count badge + chevron + expanded compact rows)" -- config/quickshell/widgets/GroupCard.qml config/quickshell/widgets/qmldir
git log -1 --stat
```

---

## Task 3.2: NotifList — integrate GroupCard + restyle header

**Files:**
- Modify: `/home/nox/nixos/config/quickshell/widgets/NotifList.qml`

NotifList currently renders every row as `NCard + pill`. Switch to: `GroupCard` for grouped rows (olderCount > 0), `NCard` alone for ungrouped rows. Also restyle the header to UPPERCASE mono.

- [ ] **Step 1: Read NotifList.qml**

```bash
cat /home/nox/nixos/config/quickshell/widgets/NotifList.qml
```

- [ ] **Step 2: Restyle the header**

Find the existing header RowLayout:

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
            text: " clear"
            color: Theme.Mocha.subtext0
            font.family: Theme.Mocha.iconFamily
            font.pixelSize: Theme.Mocha.fontSm
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Services.Notifications.clearAll()
            }
        }
    }
```

Replace with:

```qml
    RowLayout {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 4
        anchors.rightMargin: 4
        spacing: Theme.Mocha.spaceSm

        Text {
            text: `NOTIFICATIONS · ${root.count} NEW`
            color: Theme.Mocha.subtext0
            font.family: Theme.Mocha.fontMono
            font.pixelSize: 11
            font.letterSpacing: 0.88   // 0.08em on 11px ≈ 0.88
            Layout.fillWidth: true
        }
        Text {
            text: " CLEAR ALL"
            color: Theme.Mocha.overlay1
            font.family: Theme.Mocha.iconFamily
            font.pixelSize: 11
            font.letterSpacing: 0.88
            visible: root.count > 0
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Services.Notifications.clearAll()
            }
        }
    }
```

- [ ] **Step 3: Replace the Repeater delegate to branch on grouped vs solo**

Find the current Repeater (lines ~95-160 with `model: root.displayRows`, delegate is `ColumnLayout` with NCard + pill):

```qml
            Repeater {
                id: cardRepeater
                model: root.displayRows
                delegate: ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Theme.Mocha.spaceXs

                    NCard {
                        Layout.fillWidth: true
                        canReply: true
                        entry: modelData.entry
                        onDismissed: Services.Notifications.dismiss(modelData.entry.id)
                        onActionInvoked: (actionId) => modelData.entry.notification?.invokeAction(actionId)
                    }

                    // Group pill: only on a "head" row with >=1 older entry
                    Rectangle {
                        visible: modelData.type === "head" && (modelData.olderCount ?? 0) > 0
                        /* ... entire pill block ... */
                    }
                }
            }
```

Replace with:

```qml
            Repeater {
                id: cardRepeater
                model: root.displayRows
                delegate: Item {
                    Layout.fillWidth: true
                    readonly property bool useGroup: modelData.type === "head" && (modelData.olderCount ?? 0) > 0
                    implicitHeight: useGroup ? groupCard.implicitHeight : ncardWrap.implicitHeight

                    GroupCard {
                        id: groupCard
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        visible: parent.useGroup
                        head: modelData.entry
                        older: modelData.older
                        appName: modelData.appName
                        expanded: root.expandedApp === modelData.appName
                        onToggleExpand: {
                            root.expandedApp = (root.expandedApp === modelData.appName)
                                ? "" : modelData.appName
                        }
                        onClearGroup: {
                            const ids = [modelData.entry.id]
                            for (const o of (modelData.older ?? [])) {
                                ids.push(o.id)
                            }
                            for (const id of ids) {
                                Services.Notifications.dismiss(id)
                            }
                        }
                        onHeadDismissed: Services.Notifications.dismiss(modelData.entry.id)
                        onOlderDismissed: (idx) => Services.Notifications.dismiss(modelData.older[idx].id)
                    }

                    Item {
                        id: ncardWrap
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        visible: !parent.useGroup
                        implicitHeight: visible ? card.implicitHeight : 0
                        NCard {
                            id: card
                            anchors.fill: parent
                            canReply: true
                            entry: modelData.entry
                            onDismissed: Services.Notifications.dismiss(modelData.entry.id)
                            onActionInvoked: (actionId) => modelData.entry.notification?.invokeAction(actionId)
                        }
                    }
                }
            }
```

- [ ] **Step 4: Update `_focusCardById` to handle the new delegate shape**

The previous `_focusCardById` assumed `delegate.children[0]` is the NCard. Now the delegate is an Item with two children (GroupCard, ncardWrap). For inline reply focus, we need to find the NCard inside the ncardWrap.

Find:

```qml
    function _focusCardById(id) {
        for (let i = 0; i < cardRepeater.count; i++) {
            const delegate = cardRepeater.itemAt(i)
            if (!delegate) continue
            // delegate is the ColumnLayout; first child is the NCard.
            const ncard = delegate.children[0]
            if (ncard && ncard.entry?.id === id) {
                ncard.replyOpen = true
                root._focusTextFieldIn(ncard)
                return
            }
        }
    }
```

Replace with:

```qml
    function _focusCardById(id) {
        for (let i = 0; i < cardRepeater.count; i++) {
            const delegate = cardRepeater.itemAt(i)
            if (!delegate) continue
            // delegate is an Item with GroupCard + ncardWrap. We only support
            // inline-reply focus on the ungrouped NCard (inside ncardWrap).
            // For grouped entries, find the NCard via tree walk.
            const ncard = root._findNCardWithId(delegate, id)
            if (ncard) {
                ncard.replyOpen = true
                root._focusTextFieldIn(ncard)
                return
            }
        }
    }

    function _findNCardWithId(node, id) {
        if (!node) return null
        if (node.entry !== undefined && node.entry?.id === id && node.canReply !== undefined) {
            return node
        }
        const kids = node.children
        if (!kids) return null
        for (let i = 0; i < kids.length; i++) {
            const found = root._findNCardWithId(kids[i], id)
            if (found) return found
        }
        return null
    }
```

Note: for grouped notifs, `focusReplyFor` may not find a reply-capable NCard (groups don't render NCards). That's acceptable — toast-Reply-from-grouped-app would just expand the group + open panel, no focus. Not a regression.

- [ ] **Step 5: Reload + verify**

```bash
pkill quickshell; sleep 0.5; quickshell &
sleep 1
qs ipc call panel toggle
sleep 0.5
for i in 1 2 3; do notify-send -a discord "Sender $i" "Message $i"; sleep 0.1; done
sleep 0.5
notify-send -a thunderbird "New mail" "Standalone notif"
sleep 0.5
LATEST=$(ls -td /run/user/$(id -u)/quickshell/by-id/*/ | head -1)
tail -20 "${LATEST}log.log" | grep -i error || echo "no errors"
```

Expected: panel shows one GroupCard for the 3 discord notifs + one NCard for the thunderbird notif. Header reads "NOTIFICATIONS · 4 NEW".

- [ ] **Step 6: Commit**

```bash
cd /home/nox/nixos
git add config/quickshell/widgets/NotifList.qml
git commit --only -m "NotifList: integrate GroupCard for grouped rows; uppercase mono header" -- config/quickshell/widgets/NotifList.qml
git log -1 --stat
```

Expected: 1 file in commit.

---

# Phase 4 — Hero refactor

## Task 4.1: HeroMpris refactor

**Files:**
- Modify: `/home/nox/nixos/config/quickshell/widgets/HeroMpris.qml` (full replace)

V15 hero: distinct mantle bg, radial gradient overlay (soft mauve+blue tints), 50×50 art with linear-gradient fallback, Bold 13.5px title, mono progress times, 30px circle controls with INVERTED play button, border-bottom divider.

- [ ] **Step 1: Replace HeroMpris.qml**

Use Write. Full content:

```qml
import QtQuick
import QtQuick.Layouts
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

        // [Col 1] Art — 50×50 with mauve→blue diagonal gradient fallback
        Rectangle {
            id: art
            Layout.preferredWidth: 50
            Layout.preferredHeight: 50
            radius: 10
            // Diagonal gradient (approximates V15's linear-gradient 135deg, mauve, blue)
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: Theme.Mocha.mauve }
                GradientStop { position: 1.0; color: Theme.Mocha.blue }
            }
            // Album art image overlay when available
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
                text: ""   // music note (FA)
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
                font.pixelSize: 14   // V15 says 13.5; Qt rounds to integer
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

            // Progress row (V15: mono 9.5px subtext0)
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 6
                spacing: 8

                Text {
                    text: hero._fmt(hero.player?.position ?? 0)
                    color: Theme.Mocha.subtext0
                    font.family: Theme.Mocha.fontMono
                    font.pixelSize: 10   // V15 9.5; Qt rounds
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
                    text: ""   // step-backward (FA)
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
                    text: hero.player?.playbackState === 1 ? "" : ""   // pause / play
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
                    text: ""   // step-forward (FA)
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
```

Note: V15's radial-gradient overlay (soft mauve+blue tints behind the hero) is omitted — pure-QtQuick radial gradients require `QtQuick.Shapes` and add complexity. The mantle bg + diagonal art gradient already gives a noticeable visual lift. Risk is flagged in the spec.

- [ ] **Step 2: Reload + verify**

```bash
pkill quickshell; sleep 0.5; quickshell &
sleep 1
# Start an MPRIS player if not already (e.g. start spotify, or run mpv with audio)
LATEST=$(ls -td /run/user/$(id -u)/quickshell/by-id/*/ | head -1)
tail -10 "${LATEST}log.log" | grep -i error || echo "no errors"
qs ipc call panel toggle
```

Expected: clean QML load. User visually verifies the hero shows: mantle bg + bottom divider + gradient art square + Bold title + mono progress times + 3 circle controls (middle one INVERTED).

- [ ] **Step 3: Commit**

```bash
cd /home/nox/nixos
git add config/quickshell/widgets/HeroMpris.qml
git commit --only -m "HeroMpris: V15 layout (mantle bg, gradient art, Bold title, mono times, inverted play button, border-bottom)" -- config/quickshell/widgets/HeroMpris.qml
git log -1 --stat
```

---

## Task 4.2: PlayerTabs restyle to V15 pills

**Files:**
- Modify: `/home/nox/nixos/config/quickshell/widgets/PlayerTabs.qml` (full replace)

V15 player tabs: pill style with status dot (5×5 colored circle) + small app icon + name. Active tab gets surface0 bg + inset border. Status dot color: green=playing, peach=paused, overlay0=idle.

- [ ] **Step 1: Replace PlayerTabs.qml**

Use Write. Full content:

```qml
import QtQuick
import QtQuick.Layouts
import "../theme" as Theme
import "../services" as Services

Item {
    id: tabs
    visible: Services.Mpris.players.length > 1
    implicitHeight: visible ? 32 : 0

    // V15: 1px top border (rgba(205,214,244,0.06))
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Qt.rgba(0.804, 0.839, 0.957, 0.06)
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.topMargin: 11    // 1 (border) + 10 (V15 padding-top)
        spacing: 4

        Repeater {
            model: Services.Mpris.players
            delegate: Rectangle {
                id: tab
                property bool isActive: modelData === Services.Mpris.activePlayer
                property int state: modelData?.playbackState ?? 0   // 0=stopped, 1=playing, 2=paused

                Layout.preferredHeight: 22
                implicitWidth: tabRow.implicitWidth + 20    // 10px L/R padding
                radius: 6
                color: isActive ? Theme.Mocha.surface0
                                : Qt.rgba(0.804, 0.839, 0.957, 0.04)
                border.width: isActive ? 1 : 0
                border.color: Theme.Mocha.surface1

                RowLayout {
                    id: tabRow
                    anchors.centerIn: parent
                    spacing: 6

                    // Status dot
                    Rectangle {
                        Layout.preferredWidth: 5
                        Layout.preferredHeight: 5
                        radius: 2.5
                        color: tab.state === 1 ? Theme.Mocha.green
                             : tab.state === 2 ? Theme.Mocha.peach
                                                : Theme.Mocha.overlay0
                    }

                    // App icon (from AppRegistry)
                    Text {
                        text: Services.AppRegistry.iconFor(modelData?.identity ?? "")
                        color: tab.isActive ? Theme.Mocha.text : Theme.Mocha.subtext0
                        font.family: Theme.Mocha.iconFamily
                        font.pixelSize: 11
                    }

                    // App name
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
```

- [ ] **Step 2: Reload + verify**

```bash
pkill quickshell; sleep 0.5; quickshell &
sleep 1
LATEST=$(ls -td /run/user/$(id -u)/quickshell/by-id/*/ | head -1)
tail -10 "${LATEST}log.log" | grep -i error || echo "no errors"
```

Visual: if 2+ MPRIS players active, see pill-style tabs with colored dots + app icons.

- [ ] **Step 3: Commit**

```bash
cd /home/nox/nixos
git add config/quickshell/widgets/PlayerTabs.qml
git commit --only -m "PlayerTabs: V15 pill style with status dots + app icons + active highlighting" -- config/quickshell/widgets/PlayerTabs.qml
git log -1 --stat
```

---

# Phase 5 — Left rail polish

## Task 5.1: Toggle widget — vertical icon-top label-below, solid blue active

**Files:**
- Modify: `/home/nox/nixos/config/quickshell/widgets/Toggle.qml` (full replace)

- [ ] **Step 1: Replace Toggle.qml**

Use Write. Full content:

```qml
import QtQuick
import QtQuick.Layouts
import "../theme" as Theme

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
            color: tile.active ? Theme.Mocha.base
                 : tile.warn   ? Theme.Mocha.peach
                                : Theme.Mocha.text
            font.family: Theme.Mocha.iconFamily
            font.pixelSize: 14
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: tile.label
            color: tile.active ? Theme.Mocha.base
                 : tile.warn   ? Theme.Mocha.peach
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

- [ ] **Step 2: Reload + verify**

```bash
pkill quickshell; sleep 0.5; quickshell &
sleep 1
qs ipc call panel toggle
LATEST=$(ls -td /run/user/$(id -u)/quickshell/by-id/*/ | head -1)
tail -10 "${LATEST}log.log" | grep -i error || echo "no errors"
```

Visual: 8 toggles now have vertical layout (icon top, label below). Active toggles show solid blue with base-color icon+label.

- [ ] **Step 3: Commit**

```bash
cd /home/nox/nixos
git add config/quickshell/widgets/Toggle.qml
git commit --only -m "Toggle: vertical icon-top label-below layout, solid blue active state" -- config/quickshell/widgets/Toggle.qml
git log -1 --stat
```

---

## Task 5.2: Slider polish — smaller subtler handle

**Files:**
- Modify: `/home/nox/nixos/config/quickshell/widgets/Slider.qml`

- [ ] **Step 1: Read Slider.qml**

```bash
cat /home/nox/nixos/config/quickshell/widgets/Slider.qml
```

- [ ] **Step 2: Edit handle dimensions**

Find:

```qml
        handle: Rectangle {
            x: s.leftPadding + s.visualPosition * (s.availableWidth - width)
            y: s.topPadding + s.availableHeight / 2 - height / 2
            width: 16; height: 16; radius: 8
            color: row.tint
            border.width: 2
            border.color: Theme.Mocha.base
        }
```

Change to:

```qml
        handle: Rectangle {
            x: s.leftPadding + s.visualPosition * (s.availableWidth - width)
            y: s.topPadding + s.availableHeight / 2 - height / 2
            width: 10; height: 10; radius: 5
            color: row.tint
            border.width: 0
        }
```

Also reduce slider implicit height from 28 to 22:

Find:
```qml
        implicitHeight: 28
```
Change to:
```qml
        implicitHeight: 22
```

- [ ] **Step 3: Reload + verify**

```bash
pkill quickshell; sleep 0.5; quickshell &
sleep 1
qs ipc call panel toggle
LATEST=$(ls -td /run/user/$(id -u)/quickshell/by-id/*/ | head -1)
tail -10 "${LATEST}log.log" | grep -i error || echo "no errors"
```

Visual: sliders are slimmer; handles are smaller (10px) with no border ring.

- [ ] **Step 4: Commit**

```bash
cd /home/nox/nixos
git add config/quickshell/widgets/Slider.qml
git commit --only -m "Slider: smaller subtler handle (10x10 no border), slimmer hit area" -- config/quickshell/widgets/Slider.qml
git log -1 --stat
```

---

## Task 5.3: SessionTile — 5 separate buttons

**Files:**
- Modify: `/home/nox/nixos/config/quickshell/widgets/SessionTile.qml` (full replace)

V15: 5 separate 30×28 buttons each with surface0 bg + surface1 border + radius 7. Power button (last) gets red color + red@0.25 border. No outer tile chrome — just the buttons in a row.

- [ ] **Step 1: Replace SessionTile.qml**

Use Write. Full content:

```qml
import QtQuick
import QtQuick.Layouts
import "../theme" as Theme
import "../services" as Services

Item {
    implicitHeight: row.implicitHeight

    RowLayout {
        id: row
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 6
        layoutDirection: Qt.LeftToRight

        component PwrBtn: Rectangle {
            property string icon: ""
            property bool danger: false
            signal clicked()
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            radius: 7
            color: ma.containsMouse
                ? (danger ? Qt.rgba(0.953, 0.545, 0.659, 0.18) : Theme.Mocha.surface1)
                : Theme.Mocha.surface0
            border.width: 1
            border.color: danger
                ? Qt.rgba(0.953, 0.545, 0.659, 0.25)   // red@0.25
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

        PwrBtn { icon: ""; onClicked: Services.Hyprland.dispatch("exec hyprlock") }            // lock
        PwrBtn { icon: ""; onClicked: Services.Hyprland.dispatch("exit") }                     // sign-out
        PwrBtn { icon: ""; onClicked: Services.Hyprland.dispatch("exec systemctl suspend") }   // bed
        PwrBtn { icon: ""; onClicked: Services.Hyprland.dispatch("exec reboot") }              // refresh
        PwrBtn { icon: ""; danger: true; onClicked: Services.Hyprland.dispatch("exec shutdown now") }  // power-off
    }
}
```

Note: dropped the outer tile chrome (no mantle bg, no border on the container) — each button now stands alone per V15.

- [ ] **Step 2: Reload + verify**

```bash
pkill quickshell; sleep 0.5; quickshell &
sleep 1
qs ipc call panel toggle
LATEST=$(ls -td /run/user/$(id -u)/quickshell/by-id/*/ | head -1)
tail -10 "${LATEST}log.log" | grep -i error || echo "no errors"
```

Visual: 5 separate small buttons in a row, each with its own surface0 bg + thin border. Last (power) has red hue on icon + border.

- [ ] **Step 3: Commit**

```bash
cd /home/nox/nixos
git add config/quickshell/widgets/SessionTile.qml
git commit --only -m "SessionTile: 5 separate buttons with individual borders, no outer tile chrome" -- config/quickshell/widgets/SessionTile.qml
git log -1 --stat
```

---

# Done — final smoke test

After all 9 tasks land:

- [ ] **Visual checklist** (open panel via `qs ipc call panel toggle`)

```bash
# Hero (with active MPRIS):
#   - mantle bg, border-bottom divider
#   - 50×50 art with gradient or album image
#   - Bold title, artist below, mono progress times
#   - 3 circle controls, MIDDLE one inverted (text bg, base color)
# Player tabs (when >1 player):
#   - pill style with status dot + app icon + name
#   - active tab has surface0 bg + inset border

# Left rail:
#   - Toggle grid: vertical icon-top label-below, solid blue when active
#   - Sliders: slim, 10×10 handles, no popping circle
#   - Session row: 5 separate buttons, last has red border + icon

# Notification list:
#   - Header "NOTIFICATIONS · N NEW" in UPPERCASE mono, "🗑 CLEAR ALL" right
#   - Single notif: NCard with icon column (app-color), meta row (mono with time), summary, body, action buttons (first = blue primary)
#   - Critical notif: red icon bg + red border
#   - Low-priority notif: compact form (smaller icon, single-line, no body)
#   - Grouped notif (3+ from same app): GroupCard with app-color icon, mono header "app · N messages", "× N" badge, chevron → expand inline
```

Test commands:

```bash
notify-send -a discord "kirby_x" "lgtm, merging it"
notify-send -a thunderbird "New mail" "Body line"
notify-send -u low "Spotify" "Now playing: Aviators — Welcome to the Dark Side"
notify-send -u critical "Alert" "Critical message"
for i in 1 2 3; do notify-send -a discord "Sender $i" "Msg $i"; sleep 0.1; done
```

Should produce: ungrouped NCard for thunderbird/critical, LowToast-style compact for spotify, GroupCard for the 3 discord notifs.

---

# Known v3 gaps (still deferred)

- Panel drop shadow (followup #61 — needs qt5compat on QML path)
- Hero radial-gradient overlay (kept simple mantle for now — `QtQuick.Shapes` not used)
- Swipe-to-dismiss on toasts
- Multi-monitor toasts
- Notification persistence across reboot
- AI chat / OCR / Lens
- Relative-time auto-refresh ticker (current implementation shows time at instantiation; doesn't tick. Each Notifications state change re-renders so time gets updated then. Acceptable for v3.)
