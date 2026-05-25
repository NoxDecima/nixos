# Quickshell Refinement Round Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refine the existing Quickshell shell at commit `174ab8f` per the design spec at `docs/superpowers/specs/2026-05-25-quickshell-refinement-design.md` — match V15 visual mockup more closely, fix the notification body rendering bug, add grouped notifications, add inline replies, and add click-outside-to-close.

**Architecture:** All work is QML edits to existing files in `config/quickshell/`. Post-cutover, `~/.config/quickshell/` is a `mkOutOfStoreSymlink` to the repo, so edits are picked up live via `qs reload` — no NixOS rebuild needed. Tasks land as small commits per logical change.

**Tech Stack:** QML / Qt6 (Quickshell 0.3+), Wayland layer-shell, fontconfig (Inter + Symbols Nerd Font already installed).

---

## Dev workflow (read first)

`~/.config/quickshell` symlinks to `/home/nox/nixos/config/quickshell` (verified post-cutover). Edits go straight to source; reload picks them up:

```bash
qs reload                                                 # reload running instance (preferred)
# or:
pkill quickshell; sleep 0.5; quickshell &                 # full restart
```

For each task: edit → `qs reload` → verify (visual + journalctl + `notify-send` etc.) → commit.

**Commit scoping discipline** (per repo memory): always use `git commit --only -m "..." -- <paths>` to avoid sweeping up any unstaged drift in adjacent files. The user typically has uncommitted local modifications in `system/hyprland.nix` etc. that must NOT bundle into your commits.

**Verifying QML errors**: live instance writes a per-launch logfile under `/run/user/$(id -u)/quickshell/by-id/<id>/log.log`. After any `qs reload` or restart:

```bash
LATEST=$(ls -td /run/user/$(id -u)/quickshell/by-id/*/ | head -1)
tail -30 "${LATEST}log.log"
```

**Reference codebase**: the existing v1 implementation (commit `174ab8f`). Read files before editing — patterns to preserve: singleton service files in `services/`, Mocha-themed widgets in `widgets/`, icon strings use `\uXXXX` escapes (literal PUA chars get stripped by some file writes — known issue).

---

## File map

| Path | Tasks that touch it | Responsibility after refinement |
|---|---|---|
| `config/quickshell/Panel.qml` | 2.3, 2.4, 3.1 | Fullscreen layer-shell window; inner surface positioned top-center at 640×720, 12px margin, mantle@0.97 bg, surface0 border, drop shadow; backdrop closes on outside click |
| `config/quickshell/Toasts.qml` | 4.1, 6.5 | Toast stack: newest-top, oldest-bottom of visible 3; `+N` pill below for overflow; routes `__reply__` synthetic action to open panel + focus |
| `config/quickshell/widgets/NCard.qml` | 1.1, 6.2 | Notification card: body Text without wrapper Item (bug fix); `canReply` prop + `replyOpen` state + inline reply TextField + synthetic Reply button when applicable |
| `config/quickshell/widgets/HeroMpris.qml` | 2.1 | Hero MPRIS: 50×50 art, Bold title |
| `config/quickshell/widgets/ToggleTile.qml` | 2.2 | Toggle tile container with surface0 border |
| `config/quickshell/widgets/SliderTile.qml` | 2.2 | Slider tile container with surface0 border |
| `config/quickshell/widgets/SessionTile.qml` | 2.2 | Session tile container with surface0 border |
| `config/quickshell/widgets/NotifList.qml` | 5.1, 5.2, 5.3, 6.4 | Grouped notifications: widget-side group computation, group head + pill, expand state, Clear N, `focusReplyFor(id)` |
| `config/quickshell/services/Notifications.qml` | 6.1 | NotificationServer: `inlineReplySupported: true`; entry adds `hasInlineReply` + `inlineReplyPlaceholder` |

No new files. ~14 tasks across 6 phases.

---

# Phase 1 — Body bug fix

## Task 1.1: NCard body — drop Item wrapper

**Files:**
- Modify: `config/quickshell/widgets/NCard.qml`

- [ ] **Step 1: Read current NCard.qml**

```bash
cat /home/nox/nixos/config/quickshell/widgets/NCard.qml | head -100
```

Find the body-section block. It currently looks like:
```qml
        Item {
            Layout.fillWidth: true
            visible: bodyText.visible
            implicitHeight: bodyText.implicitHeight

            Text {
                id: bodyText
                anchors.fill: parent
                visible: (card.entry?.body ?? "") !== ""
                text: card.entry?.body ?? ""
                color: Theme.Mocha.subtext1
                font.family: Theme.Mocha.fontFamily
                font.pixelSize: Theme.Mocha.fontSm
                wrapMode: Text.WordWrap
                maximumLineCount: 3
                elide: Text.ElideRight
            }

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
```

- [ ] **Step 2: Replace with direct Text + nested MouseArea**

Use Edit to replace the whole `Item { ... }` block above with:

```qml
        Text {
            id: bodyText
            Layout.fillWidth: true
            visible: (card.entry?.body ?? "") !== ""
            text: card.entry?.body ?? ""
            color: Theme.Mocha.subtext1
            font.family: Theme.Mocha.fontFamily
            font.pixelSize: Theme.Mocha.fontSm
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
```

- [ ] **Step 3: Reload + verify**

```bash
qs reload
sleep 0.5
notify-send "Test Title" "Body line that should now appear"
sleep 1
LATEST=$(ls -td /run/user/$(id -u)/quickshell/by-id/*/ | head -1)
tail -10 "${LATEST}log.log" | grep -i error || echo "no errors"
```

Manual visual check: the toast should now show BOTH "Test Title" AND "Body line that should now appear". Open panel (`qs ipc call panel toggle`) — the panel-list NCard should also show both lines.

- [ ] **Step 4: Commit**

```bash
cd /home/nox/nixos
git add config/quickshell/widgets/NCard.qml
git commit --only -m "Fix NCard body rendering (remove Item wrapper that broke implicit sizing)" -- config/quickshell/widgets/NCard.qml
git log -1 --stat
```

Expected: 1 file in commit.

---

# Phase 2 — Visual polish (small file edits)

## Task 2.1: HeroMpris — 50px art, Bold title

**Files:**
- Modify: `config/quickshell/widgets/HeroMpris.qml`

- [ ] **Step 1: Read the file to find the art Rectangle and title Text**

```bash
grep -n "preferredWidth\|preferredHeight\|Font.Medium" /home/nox/nixos/config/quickshell/widgets/HeroMpris.qml
```

- [ ] **Step 2: Shrink art to 50×50**

Find and Edit:
```qml
        Rectangle {
            id: art
            Layout.preferredWidth: 56; Layout.preferredHeight: 56
            radius: Theme.Mocha.radiusSm
```
to:
```qml
        Rectangle {
            id: art
            Layout.preferredWidth: 50; Layout.preferredHeight: 50
            radius: Theme.Mocha.radiusSm
```

- [ ] **Step 3: Bump title weight to Bold**

Find the title Text (the one with `text: hero.player?.trackTitle`) and Edit `font.weight: Font.Medium` → `font.weight: Font.Bold`.

- [ ] **Step 4: Reload + verify**

```bash
qs reload
# Need a running MPRIS player to see the hero (e.g., spotify/mpv/firefox)
# If none active, just verify no QML errors:
LATEST=$(ls -td /run/user/$(id -u)/quickshell/by-id/*/ | head -1)
tail -10 "${LATEST}log.log" | grep -i error || echo "no errors"
```

Visual (with active MPRIS): art is slightly smaller, title is heavier.

- [ ] **Step 5: Commit**

```bash
cd /home/nox/nixos
git add config/quickshell/widgets/HeroMpris.qml
git commit --only -m "Hero: 50px art + Bold title to match V15 mockup" -- config/quickshell/widgets/HeroMpris.qml
git log -1 --stat
```

---

## Task 2.2: Tile borders (Toggle, Slider, Session)

**Files:**
- Modify: `config/quickshell/widgets/ToggleTile.qml`
- Modify: `config/quickshell/widgets/SliderTile.qml`
- Modify: `config/quickshell/widgets/SessionTile.qml`

V15 specifies each tile container has `border: 1px solid var(--surface0)`. Currently borderless.

- [ ] **Step 1: Edit ToggleTile.qml**

Find the outer `Rectangle { id: tile ... color: Theme.Mocha.mantle ... radius: Theme.Mocha.radiusMd ... }` and add two properties (typical placement: right after `radius`):

```qml
    border.width: 1
    border.color: Theme.Mocha.surface0
```

- [ ] **Step 2: Edit SliderTile.qml**

Find the outer `Rectangle { color: Theme.Mocha.mantle ... radius: Theme.Mocha.radiusMd ... }` (no `id` in this one) and add the same two lines.

- [ ] **Step 3: Edit SessionTile.qml**

Find the outer `Rectangle { color: Theme.Mocha.mantle ... radius: Theme.Mocha.radiusMd ... }` and add the same two lines.

- [ ] **Step 4: Reload + verify**

```bash
qs reload
qs ipc call panel toggle    # open panel; you'll see thin surface0 borders on each tile
qs ipc call panel toggle    # close
LATEST=$(ls -td /run/user/$(id -u)/quickshell/by-id/*/ | head -1)
tail -10 "${LATEST}log.log" | grep -i error || echo "no errors"
```

- [ ] **Step 5: Commit**

```bash
cd /home/nox/nixos
git add config/quickshell/widgets/ToggleTile.qml config/quickshell/widgets/SliderTile.qml config/quickshell/widgets/SessionTile.qml
git commit --only -m "Add 1px surface0 border to ToggleTile/SliderTile/SessionTile" -- config/quickshell/widgets/ToggleTile.qml config/quickshell/widgets/SliderTile.qml config/quickshell/widgets/SessionTile.qml
git log -1 --stat
```

Expected: 3 files in commit.

---

## Task 2.3: Panel — width 640, top margin 12, mantle@0.97, surface0 border, 200px rail

**Files:**
- Modify: `config/quickshell/Panel.qml`

This task does NOT yet make Panel fullscreen (Task 3.1 does). It only adjusts dimensions and colors of the existing structure.

- [ ] **Step 1: Apply 5 edits in Panel.qml**

Use Edit to change:

```qml
    margins.top: 38
    implicitWidth: 580
    implicitHeight: 720
```
to:
```qml
    margins.top: 12
    implicitWidth: 640
    implicitHeight: 720
```

Then change the inner Rectangle:
```qml
        color: Theme.Mocha.base
        opacity: 0.94
        radius: Theme.Mocha.radiusLg
        border.width: 1
        border.color: Theme.Mocha.surface1
```
to:
```qml
        color: Theme.Mocha.mantle
        opacity: 0.97
        radius: Theme.Mocha.radiusLg
        border.width: 1
        border.color: Theme.Mocha.surface0
```

Then change the left rail width:
```qml
                ColumnLayout {
                    Layout.preferredWidth: 220
```
to:
```qml
                ColumnLayout {
                    Layout.preferredWidth: 200
                    spacing: Theme.Mocha.spaceSm
```

(The `spacing: Theme.Mocha.spaceSm` line is new — tighter vertical rhythm between the 3 tiles in the left rail. The left ColumnLayout's existing `spacing: Theme.Mocha.spaceSm` line might already be present; if so, no change. The MAIN ColumnLayout inside the inner surface stays at `spacing: Theme.Mocha.spaceMd`.)

- [ ] **Step 2: Reload + verify**

```bash
qs reload
qs ipc call panel toggle
# Visual: wider panel, tighter to waybar, darker bg (mantle vs base), darker border
# Notification list column is ~80px wider than before
qs ipc call panel toggle
```

- [ ] **Step 3: Commit**

```bash
cd /home/nox/nixos
git add config/quickshell/Panel.qml
git commit --only -m "Panel: 640x720, top margin 12, mantle@0.97 background, surface0 border, 200px rail" -- config/quickshell/Panel.qml
git log -1 --stat
```

---

## Task 2.4: Panel drop shadow via MultiEffect

**Files:**
- Modify: `config/quickshell/Panel.qml`

V15 specifies `box-shadow: 0 14px 36px rgba(0,0,0,0.55)`. Apply via Qt6's `MultiEffect` element.

- [ ] **Step 1: Add MultiEffect import + wrap inner surface**

Add to imports (if not present):
```qml
import Qt5Compat.GraphicalEffects     // fallback path
import QtQuick.Effects                 // preferred (Qt6 native MultiEffect)
```

Find the inner `Rectangle { ... color: Theme.Mocha.mantle ... }` (the surface) and add a sibling `MultiEffect` immediately AFTER the Rectangle closing brace (still inside the PanelWindow), targeting the Rectangle by id. If the Rectangle has no id, add `id: surface`:

```qml
    Rectangle {
        id: surface
        anchors.fill: parent
        anchors.margins: 8
        color: Theme.Mocha.mantle
        opacity: 0.97
        radius: Theme.Mocha.radiusLg
        border.width: 1
        border.color: Theme.Mocha.surface0
        layer.enabled: true          // required for MultiEffect to attach

        ColumnLayout { /* unchanged */ }
    }

    MultiEffect {
        source: surface
        anchors.fill: surface
        shadowEnabled: true
        shadowBlur: 1.0
        shadowVerticalOffset: 14
        shadowHorizontalOffset: 0
        shadowOpacity: 0.55
        shadowColor: "black"
        z: surface.z - 1            // render behind the surface
    }
```

- [ ] **Step 2: Reload + verify**

```bash
qs reload
qs ipc call panel toggle
# Visual: subtle dark shadow extends below and slightly around the panel surface
LATEST=$(ls -td /run/user/$(id -u)/quickshell/by-id/*/ | head -1)
tail -20 "${LATEST}log.log" | grep -i "error\|MultiEffect" || echo "no errors"
qs ipc call panel toggle
```

**Fallback**: if `MultiEffect` errors out (older Qt6 builds), replace with:
```qml
DropShadow {
    source: surface
    anchors.fill: surface
    horizontalOffset: 0
    verticalOffset: 14
    radius: 36
    samples: 24
    color: "#8c000000"   // ~0.55 alpha black
    z: surface.z - 1
}
```
Using the deprecated `QtGraphicalEffects.DropShadow` (works via `Qt5Compat.GraphicalEffects`).

- [ ] **Step 3: Commit**

```bash
cd /home/nox/nixos
git add config/quickshell/Panel.qml
git commit --only -m "Panel: add drop shadow via MultiEffect" -- config/quickshell/Panel.qml
git log -1 --stat
```

---

# Phase 3 — Click-outside-closes (Panel fullscreen restructure)

## Task 3.1: Panel becomes fullscreen, surface positioned top-center

**Files:**
- Modify: `config/quickshell/Panel.qml`

This is a structural change: the PanelWindow stops being a sized 640×720 window and instead fills the screen, with the inner surface positioned manually. The existing backdrop MouseArea (which currently checks coordinates) becomes a simple any-click-closes handler.

- [ ] **Step 1: Replace the PanelWindow root with fullscreen anchors**

Edit:
```qml
PanelWindow {
    id: panel
    property bool isOpen: false

    anchors.top: true
    margins.top: 12
    implicitWidth: 640
    implicitHeight: 720
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    visible: isOpen
    exclusiveZone: 0
```
to:
```qml
PanelWindow {
    id: panel
    property bool isOpen: false

    // Fullscreen layer-shell window: backdrop fills the screen so any click
    // outside the inner surface closes the panel.
    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    visible: isOpen
    exclusiveZone: 0
```

- [ ] **Step 2: Simplify backdrop MouseArea (drop coord check)**

Edit:
```qml
    MouseArea {
        anchors.fill: parent
        onClicked: function(mouse) {
            if (mouse.x < 8 || mouse.x > width - 8
                || mouse.y < 8 || mouse.y > height - 8) {
                panel.close()
            }
        }
    }
```
to:
```qml
    // Any click that reaches this MouseArea is outside the inner surface
    // (children of the surface consume their own clicks before bubbling here).
    MouseArea {
        anchors.fill: parent
        onClicked: panel.close()
    }
```

- [ ] **Step 3: Position the inner surface explicitly (drop anchors.fill+margins)**

Edit the surface `Rectangle`:
```qml
    Rectangle {
        id: surface
        anchors.fill: parent
        anchors.margins: 8
        color: Theme.Mocha.mantle
        opacity: 0.97
        radius: Theme.Mocha.radiusLg
        border.width: 1
        border.color: Theme.Mocha.surface0
        layer.enabled: true
```
to:
```qml
    Rectangle {
        id: surface
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 12
        width: 640
        height: 720
        color: Theme.Mocha.mantle
        opacity: 0.97
        radius: Theme.Mocha.radiusLg
        border.width: 1
        border.color: Theme.Mocha.surface0
        layer.enabled: true
```

(Also update the `MultiEffect`'s `anchors.fill: surface` — it should still work because it follows surface; verify.)

- [ ] **Step 4: Reload + verify**

```bash
qs reload
qs ipc call panel toggle
# Panel appears top-center, 640x720, 12px below waybar.
# Click on the wallpaper area (anywhere outside the panel surface):
#   panel closes
# Click the waybar bell while panel is open:
#   panel closes (waybar bell doesn't toggle because the click is consumed
#   by the backdrop — accepted trade-off)
qs ipc call panel toggle
# Click ON a toggle inside the panel: should toggle, not close panel
# Click on a slider handle and drag: should work, not close
LATEST=$(ls -td /run/user/$(id -u)/quickshell/by-id/*/ | head -1)
tail -20 "${LATEST}log.log" | grep -i error || echo "no errors"
```

**If any interactive widget (toggle, slider, button) accidentally triggers panel close on click**: it means the widget's MouseArea isn't consuming the event. Verify by checking that the widget's `MouseArea { onClicked: ... }` exists and isn't accidentally `propagateComposedEvents: true`. The Qt default is to consume — should work.

- [ ] **Step 5: Commit**

```bash
cd /home/nox/nixos
git add config/quickshell/Panel.qml
git commit --only -m "Panel: fullscreen layer-shell with click-outside-closes backdrop" -- config/quickshell/Panel.qml
git log -1 --stat
```

---

# Phase 4 — Toast order flip

## Task 4.1: Toasts — newest at top, oldest at bottom of visible 3

**Files:**
- Modify: `config/quickshell/Toasts.qml`

Currently the Repeater reverses the slice (`activeToasts.slice(0, 3).reverse()`) to put oldest first. Drop the `.reverse()` so newest stays at top of the visible 3.

- [ ] **Step 1: Find and edit the Repeater**

Locate (likely lines ~35-50):
```qml
        Repeater {
            // Display oldest at top, newest at bottom. activeToasts is
            // newest-first; take the 3 newest, then reverse for display.
            model: Services.Notifications.activeToasts.slice(0, 3).reverse()
```

Change to:
```qml
        Repeater {
            // Display newest at top, oldest at bottom of the visible stack.
            // activeToasts is already newest-first; no transformation needed.
            model: Services.Notifications.activeToasts.slice(0, 3)
```

- [ ] **Step 2: Verify pill is at the bottom (it should already be)**

The overflow pill in Toasts.qml is rendered AFTER the Repeater (so it appears below the stack in ColumnLayout flow). Confirm visually after reload. If it's above for some reason, move it after the Repeater block.

- [ ] **Step 3: Reload + verify**

```bash
qs reload
sleep 0.5
notify-send "First"  "should appear at top initially"
notify-send "Second" "appears above First; First moves down"
notify-send "Third"  "appears at top; Second/First push down"
notify-send "Fourth" "Fourth at top, First scrolls off → +1 more pill at bottom"
sleep 1
# Visual: top-to-bottom = 4, 3, 2 and a "+1 more" pill below them
LATEST=$(ls -td /run/user/$(id -u)/quickshell/by-id/*/ | head -1)
tail -10 "${LATEST}log.log" | grep -i error || echo "no errors"
```

- [ ] **Step 4: Commit**

```bash
cd /home/nox/nixos
git add config/quickshell/Toasts.qml
git commit --only -m "Toasts: newest at top, oldest at bottom (drop reverse on slice)" -- config/quickshell/Toasts.qml
git log -1 --stat
```

---

# Phase 5 — Grouped notifications

## Task 5.1: NotifList — refactor model to grouped rows

**Files:**
- Modify: `config/quickshell/widgets/NotifList.qml`

Replace the flat Repeater over `Services.Notifications.notifs` with a model derived by widget-side grouping. Each row is either `{type: "notif", entry, appName, groupSize: N}` (where N = additional older entries from same app, can be 0) or `{type: "extra", entry}` (older entries shown when the group is expanded).

- [ ] **Step 1: Add the grouping function + computed model property**

Inside the root `Item { id: root ... }` in NotifList.qml, after the existing `function _groupedCount()` (or wherever fits), add:

```qml
    property string expandedApp: ""

    function _buildRows() {
        const rows = []
        const seen = {}    // appName -> head index in rows
        const groups = {}  // appName -> [older entries]

        for (const n of Services.Notifications.notifs) {
            const a = n.appName ?? ""
            if (!(a in seen)) {
                seen[a] = rows.length
                rows.push({ type: "head", entry: n, appName: a, older: [] })
            } else {
                rows[seen[a]].older.push(n)
            }
        }

        // Flatten: each head, followed by its older entries IF expanded
        const out = []
        for (const r of rows) {
            out.push({ type: "head", entry: r.entry, appName: r.appName, olderCount: r.older.length, older: r.older })
            if (r.older.length > 0 && root.expandedApp === r.appName) {
                for (const o of r.older) out.push({ type: "older", entry: o, appName: r.appName })
            }
        }
        return out
    }

    readonly property var displayRows: _buildRows()
```

Note: `displayRows` is bound to `_buildRows()` which references `Services.Notifications.notifs` and `root.expandedApp` — both reactive properties — so it auto-recomputes.

- [ ] **Step 2: Replace the existing Repeater body**

Find the existing Repeater inside the ScrollView:
```qml
            Repeater {
                model: Services.Notifications.notifs
                delegate: NCard {
                    Layout.fillWidth: true
                    entry: modelData
                    onDismissed: Services.Notifications.dismiss(modelData.id)
                    onActionInvoked: (actionId) => modelData.notification?.invokeAction(actionId)
                }
            }
```

Replace with:
```qml
            Repeater {
                model: root.displayRows
                delegate: ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Theme.Mocha.spaceXs

                    NCard {
                        Layout.fillWidth: true
                        entry: modelData.entry
                        onDismissed: Services.Notifications.dismiss(modelData.entry.id)
                        onActionInvoked: (actionId) => modelData.entry.notification?.invokeAction(actionId)
                    }

                    // Group pill: rendered only after a head with >=1 older entry
                    Rectangle {
                        visible: modelData.type === "head" && (modelData.olderCount ?? 0) > 0
                        Layout.fillWidth: true
                        implicitHeight: 22
                        radius: Theme.Mocha.radiusSm
                        color: Theme.Mocha.surface0

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.Mocha.spaceSm
                            anchors.rightMargin: Theme.Mocha.spaceSm

                            Text {
                                Layout.fillWidth: true
                                text: (root.expandedApp === modelData.appName
                                       ? "collapse"
                                       : `+ ${modelData.olderCount} more from ${modelData.appName}`)
                                color: Theme.Mocha.subtext0
                                font.family: Theme.Mocha.fontFamily
                                font.pixelSize: Theme.Mocha.fontSm
                            }
                            Text {
                                text: "Clear"
                                color: Theme.Mocha.overlay1
                                font.family: Theme.Mocha.fontFamily
                                font.pixelSize: Theme.Mocha.fontSm
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        // clear all in this group (head + older)
                                        Services.Notifications.dismiss(modelData.entry.id)
                                        for (const o of (modelData.older ?? [])) {
                                            Services.Notifications.dismiss(o.id)
                                        }
                                    }
                                }
                            }
                        }

                        // Click anywhere on the pill (except Clear) toggles expand
                        MouseArea {
                            anchors.fill: parent
                            anchors.rightMargin: 60   // leave space for the Clear hit-area
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.expandedApp = (root.expandedApp === modelData.appName)
                                    ? "" : modelData.appName
                            }
                        }
                    }
                }
            }
```

- [ ] **Step 3: Reload + verify**

```bash
qs reload
sleep 0.5
# Single app, multiple notifs:
for i in 1 2 3; do notify-send -a "discord" "Sender $i" "Message $i"; sleep 0.1; done
qs ipc call panel toggle
# Expect: one NCard ("Sender 3 / Message 3") + a pill below it saying "+ 2 more from discord" with "Clear" on the right
# Click the pill: should expand and show Sender 2 + Sender 1 as their own NCards
# Click again (now says "collapse"): collapses
# Click "Clear": removes all 3
qs ipc call panel toggle
LATEST=$(ls -td /run/user/$(id -u)/quickshell/by-id/*/ | head -1)
tail -20 "${LATEST}log.log" | grep -i error || echo "no errors"
```

- [ ] **Step 4: Commit**

```bash
cd /home/nox/nixos
git add config/quickshell/widgets/NotifList.qml
git commit --only -m "NotifList: group notifications by appName with expandable pill" -- config/quickshell/widgets/NotifList.qml
git log -1 --stat
```

---

# Phase 6 — Inline replies

## Task 6.1: Notifications service — inlineReplySupported + entry fields

**Files:**
- Modify: `config/quickshell/services/Notifications.qml`

- [ ] **Step 1: Flip the server flag**

Find:
```qml
        inlineReplySupported: false  // v1: not supported
```

Change to:
```qml
        inlineReplySupported: true   // v2: TextField in NCard handles input
```

- [ ] **Step 2: Add two fields to the entry object built in `onNotification`**

Find the entry construction:
```qml
            const entry = {
                id: notification.id,
                appName: notification.appName,
                summary: notification.summary,
                body: notification.body,
                image: notification.image,
                urgency: notification.urgency,
                actions: notification.actions,
                timestamp: Date.now(),
                notification: notification
            }
```

Add two new properties after `actions`:
```qml
            const entry = {
                id: notification.id,
                appName: notification.appName,
                summary: notification.summary,
                body: notification.body,
                image: notification.image,
                urgency: notification.urgency,
                actions: notification.actions,
                hasInlineReply: notification.hasInlineReply ?? false,
                inlineReplyPlaceholder: notification.inlineReplyPlaceholder ?? "",
                timestamp: Date.now(),
                notification: notification
            }
```

The `?? false` / `?? ""` guard against older Quickshell versions that may not expose those properties.

- [ ] **Step 3: Reload + verify**

```bash
qs reload
notify-send "Sanity check" "Server flag flipped — existing notifs still work"
sleep 0.5
LATEST=$(ls -td /run/user/$(id -u)/quickshell/by-id/*/ | head -1)
tail -10 "${LATEST}log.log" | grep -i error || echo "no errors"
```

Functional verification of the inline reply itself comes after Task 6.2 (which adds the UI).

- [ ] **Step 4: Commit**

```bash
cd /home/nox/nixos
git add config/quickshell/services/Notifications.qml
git commit --only -m "Notifications: enable inlineReplySupported + carry hasInlineReply/placeholder into entry" -- config/quickshell/services/Notifications.qml
git log -1 --stat
```

---

## Task 6.2: NCard — canReply prop + Reply button + replyOpen state + TextField

**Files:**
- Modify: `config/quickshell/widgets/NCard.qml`

Add a new `canReply` property (whether this NCard is in a context that can accept keyboard input — i.e., the panel, not toasts), a `replyOpen` boolean state, a synthetic "Reply" button in the action row when `entry.hasInlineReply` is true, and a TextField + Send below the actions row when `replyOpen` is true.

- [ ] **Step 1: Add the canReply + replyOpen properties at the top of NCard**

In the property declarations block near the top:
```qml
    property var entry
    property bool showProgress: false
    property real progress: 1.0
    property int urgency: entry?.urgency ?? 1

    signal dismissed()
    signal actionInvoked(string actionId)
```

Add two more:
```qml
    property var entry
    property bool showProgress: false
    property real progress: 1.0
    property int urgency: entry?.urgency ?? 1
    property bool canReply: false      // true only when rendered inside the panel
    property bool replyOpen: false     // toggled by the synthetic Reply button

    signal dismissed()
    signal actionInvoked(string actionId)
```

- [ ] **Step 2: Add the import for QtQuick.Controls (for TextField + Button)**

Top of file, after existing imports:
```qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../theme" as Theme
```

(If `QtQuick.Controls` is already imported, skip.)

- [ ] **Step 3: Inject a synthetic Reply button into the action row**

Find the action buttons row:
```qml
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.Mocha.spaceXs
            visible: actionRepeater.count > 0

            Repeater {
                id: actionRepeater
                model: (card.entry?.actions ?? []).filter(a => a.identifier !== "default")
                ...
            }
        }
```

Modify the `visible` and add a Reply button child BEFORE the Repeater:

```qml
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.Mocha.spaceXs
            visible: actionRepeater.count > 0 || (card.entry?.hasInlineReply ?? false)

            // Synthetic Reply button — shown only when the notif supports inline reply.
            // In panel context (canReply=true): toggles replyOpen.
            // In toast context (canReply=false): emits __reply__ so Toasts.qml
            // can route to opening the panel + focusing the right card's reply field.
            Rectangle {
                visible: card.entry?.hasInlineReply ?? false
                Layout.fillWidth: true
                implicitHeight: 28
                radius: Theme.Mocha.radiusSm
                color: replyBtnMa.containsMouse ? Theme.Mocha.surface1 : Theme.Mocha.surface0
                border.width: 1
                border.color: Theme.Mocha.surface1

                Text {
                    anchors.centerIn: parent
                    text: "Reply"
                    color: Theme.Mocha.text
                    font.family: Theme.Mocha.fontFamily
                    font.pixelSize: Theme.Mocha.fontSm
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
                /* ... existing delegate unchanged ... */
            }
        }
```

- [ ] **Step 4: Add the reply input row (TextField + Send) below the actions row**

Inside the main `ColumnLayout { id: layout ... }`, AFTER the actions RowLayout block, add:

```qml
        // Inline reply input — only when this NCard is in panel context and user opened reply
        RowLayout {
            Layout.fillWidth: true
            visible: card.canReply && card.replyOpen
            spacing: Theme.Mocha.spaceXs

            TextField {
                id: replyField
                Layout.fillWidth: true
                placeholderText: card.entry?.inlineReplyPlaceholder ?? "Reply..."
                font.family: Theme.Mocha.fontFamily
                font.pixelSize: Theme.Mocha.fontSm
                color: Theme.Mocha.text
                background: Rectangle {
                    color: Theme.Mocha.surface0
                    border.width: 1
                    border.color: Theme.Mocha.surface1
                    radius: Theme.Mocha.radiusSm
                }
                Keys.onReturnPressed: card.sendReply()
                Keys.onEnterPressed: card.sendReply()
                Keys.onEscapePressed: { card.replyOpen = false }
            }

            Rectangle {
                Layout.preferredWidth: 56
                Layout.preferredHeight: 28
                radius: Theme.Mocha.radiusSm
                color: sendBtnMa.containsMouse ? Theme.Mocha.blue : Theme.Mocha.surface1
                Text {
                    anchors.centerIn: parent
                    text: "Send"
                    color: sendBtnMa.containsMouse ? Theme.Mocha.base : Theme.Mocha.text
                    font.family: Theme.Mocha.fontFamily
                    font.pixelSize: Theme.Mocha.fontSm
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
```

- [ ] **Step 5: Add the sendReply() function on the NCard root**

Near the top of the root Rectangle (after the signals), add:

```qml
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
```

The `if (card.entry?.notification?.sendInlineReply)` guard handles older Quickshell versions that might not expose the method.

**Note:** `replyField` is referenced as if it's accessible from the root scope; in QML it is, because `id`s are file-scoped. The function will reference whichever TextField has `id: replyField` in the same component.

- [ ] **Step 6: Reload + verify (limited — full test needs a real chat app or toast wiring)**

```bash
qs reload
LATEST=$(ls -td /run/user/$(id -u)/quickshell/by-id/*/ | head -1)
tail -20 "${LATEST}log.log" | grep -i error || echo "no errors"
```

Functional test of the reply field happens once you have a `hasInlineReply: true` notification (typically only sent by chat apps). For now, just verify no QML errors. Toast→panel routing comes in Task 6.5.

- [ ] **Step 7: Commit**

```bash
cd /home/nox/nixos
git add config/quickshell/widgets/NCard.qml
git commit --only -m "NCard: inline reply UI (canReply prop, Reply button, TextField, Send, sendReply)" -- config/quickshell/widgets/NCard.qml
git log -1 --stat
```

---

## Task 6.3: NotifList — pass canReply=true to all NCards + add focusReplyFor()

**Files:**
- Modify: `config/quickshell/widgets/NotifList.qml`

NotifList renders NCards in the panel; they should all have `canReply: true` so the Reply button toggles inline rather than emitting `__reply__`. Also add a `focusReplyFor(id)` function the toast layer can call.

- [ ] **Step 1: Set canReply on the NCard delegates**

Find the two NCard usages in NotifList.qml (both from Task 5.1's edits — one for the head, one for the older entries inside the ColumnLayout delegate). Add `canReply: true` to each:

```qml
                    NCard {
                        Layout.fillWidth: true
                        canReply: true
                        entry: modelData.entry
                        onDismissed: Services.Notifications.dismiss(modelData.entry.id)
                        onActionInvoked: (actionId) => modelData.entry.notification?.invokeAction(actionId)
                    }
```

Repeat for any other NCard instances in NotifList.

- [ ] **Step 2: Add a `focusReplyFor(id)` function on the NotifList root**

Inside `Item { id: root ... }`, alongside the existing functions:

```qml
    // Called by Toasts.qml when the user clicks "Reply" on a toast.
    // Expands the relevant group if needed, opens the matching NCard's reply,
    // and gives the TextField keyboard focus.
    function focusReplyFor(id) {
        const entry = Services.Notifications.notifs.find(n => n.id === id)
        if (!entry) return
        // If this entry is inside a group of >=2 from same app, expand that group
        const sameAppCount = Services.Notifications.notifs.filter(n => n.appName === entry.appName).length
        if (sameAppCount >= 2) {
            root.expandedApp = entry.appName
        }
        // Defer to next event loop tick so the Repeater has time to instantiate
        // the corresponding NCard before we try to find and focus it.
        Qt.callLater(() => root._focusCardById(id))
    }

    function _focusCardById(id) {
        // Walk the rendered children to find the NCard with matching entry.id
        // and toggle replyOpen + focus its TextField.
        for (let i = 0; i < cardRepeater.count; i++) {
            const delegate = cardRepeater.itemAt(i)
            if (!delegate) continue
            // delegate is the ColumnLayout from Task 5.1; first child is the NCard
            const ncard = delegate.children[0]
            if (ncard && ncard.entry?.id === id) {
                ncard.replyOpen = true
                // Find the TextField inside the NCard and focus it
                _focusTextFieldIn(ncard)
                return
            }
        }
    }

    function _focusTextFieldIn(node) {
        if (!node) return
        if (node.objectName === "replyField" || (node.placeholderText !== undefined && node.text !== undefined)) {
            node.forceActiveFocus()
            return true
        }
        for (let i = 0; i < (node.children?.length ?? 0); i++) {
            if (_focusTextFieldIn(node.children[i])) return true
        }
        return false
    }
```

For `_focusTextFieldIn` to find the TextField reliably, also add `objectName: "replyField"` to the TextField in `NCard.qml`. Open NCard.qml and add to the TextField:
```qml
            TextField {
                id: replyField
                objectName: "replyField"
                /* ... rest unchanged ... */
            }
```

Then give the Repeater a known id so we can iterate it. Find the Repeater added in Task 5.1 inside NotifList:
```qml
            Repeater {
                model: root.displayRows
                delegate: ColumnLayout {
                    ...
                }
            }
```

Add `id: cardRepeater`:
```qml
            Repeater {
                id: cardRepeater
                model: root.displayRows
                delegate: ColumnLayout {
                    ...
                }
            }
```

- [ ] **Step 3: Reload + verify**

```bash
qs reload
LATEST=$(ls -td /run/user/$(id -u)/quickshell/by-id/*/ | head -1)
tail -20 "${LATEST}log.log" | grep -i error || echo "no errors"
```

Functional test of `focusReplyFor` requires Task 6.4. For now just verify clean QML load.

- [ ] **Step 4: Commit**

```bash
cd /home/nox/nixos
git add config/quickshell/widgets/NotifList.qml config/quickshell/widgets/NCard.qml
git commit --only -m "NotifList: pass canReply=true to NCards; add focusReplyFor(id); NCard TextField gets objectName" -- config/quickshell/widgets/NotifList.qml config/quickshell/widgets/NCard.qml
git log -1 --stat
```

---

## Task 6.4: Toasts — pass canReply=false to NCards + handle __reply__ action

**Files:**
- Modify: `config/quickshell/Toasts.qml`

Toasts render NCards but they have no keyboard focus, so `canReply: false`. When the toast's NCard emits `actionInvoked("__reply__")`, we open the panel and focus the matching reply field.

The Panel's `id` is `panel` (declared in Panel.qml). The NotifList's id needs to be reachable from Toasts.qml. Cleanest path: expose a function via shell.qml or pass `panel.contentNotifList` reference. Simpler: bind to the panel via top-level ShellRoot, find NotifList by traversal.

Easier pragmatic approach: add a function on the Panel that wraps the focus dance:

- [ ] **Step 1: Add an `openWithReply(id)` function on Panel.qml**

In Panel.qml (after the existing `open() / close() / toggle()` functions), add:

```qml
    function openWithReply(id) {
        isOpen = true
        Services.Notifications.activeToasts = []
        // Defer so the panel's NotifList has rendered before we focus
        Qt.callLater(() => {
            if (notifList) notifList.focusReplyFor(id)
        })
    }
```

Also add an `id: notifList` to the NotifList instance in Panel.qml:
```qml
                Widgets.NotifList {
                    id: notifList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
```

- [ ] **Step 2: In Toasts.qml, pass canReply=false and special-case __reply__**

Find the NCard delegate inside the Repeater (the version after the per-delegate Timer):

```qml
                Widgets.NCard {
                    id: card
                    anchors.fill: parent
                    entry: cell.entry
                    showProgress: cell.duration > 0
                    progress: cell.progress
                    urgency: cell.entry?.urgency ?? 1
                    onDismissed: Services.Notifications.dismiss(cell.entry.id)
                    onActionInvoked: (actionId) => cell.entry?.notification?.invokeAction(actionId)
                }
```

Replace the `onActionInvoked` and add `canReply: false`:

```qml
                Widgets.NCard {
                    id: card
                    anchors.fill: parent
                    canReply: false
                    entry: cell.entry
                    showProgress: cell.duration > 0
                    progress: cell.progress
                    urgency: cell.entry?.urgency ?? 1
                    onDismissed: Services.Notifications.dismiss(cell.entry.id)
                    onActionInvoked: (actionId) => {
                        if (actionId === "__reply__") {
                            panel.openWithReply(cell.entry.id)
                            return
                        }
                        cell.entry?.notification?.invokeAction(actionId)
                    }
                }
```

For this to work, Toasts.qml must be able to reference `panel`. Looking at shell.qml: it instantiates `Panel { id: panel }` and `Toasts {}` as sibling children of ShellRoot. QML ids are scoped to the QML file they're defined in, so Toasts.qml cannot reference `panel` directly.

Workaround: expose `panel` via a property on ShellRoot OR pass it explicitly.

**Cleanest path**: update `shell.qml` to expose the panel via a singleton-like reference, OR pass it as a property to Toasts.

Simplest: in `shell.qml`, give the Panel an id and have Toasts accept a Panel reference:

Edit `shell.qml`:
```qml
ShellRoot {
    id: root
    Component.onCompleted: {
        Services.Notifications;
        Services.DND;
    }

    Panel { id: panel }
    Toasts { panelRef: panel }       // pass reference

    /* existing IPC handlers unchanged */
}
```

In `Toasts.qml`, add at the top of `PanelWindow { id: toastWindow ... }`:
```qml
PanelWindow {
    id: toastWindow
    property var panelRef            // injected from shell.qml
    ...
}
```

Then the NCard delegate inside Toasts.qml uses `toastWindow.panelRef.openWithReply(cell.entry.id)`:

```qml
                    onActionInvoked: (actionId) => {
                        if (actionId === "__reply__") {
                            if (toastWindow.panelRef) {
                                toastWindow.panelRef.openWithReply(cell.entry.id)
                            }
                            return
                        }
                        cell.entry?.notification?.invokeAction(actionId)
                    }
```

- [ ] **Step 3: Reload + verify**

```bash
qs reload
LATEST=$(ls -td /run/user/$(id -u)/quickshell/by-id/*/ | head -1)
tail -20 "${LATEST}log.log" | grep -i error || echo "no errors"
```

Functional test: needs a real chat app sending a notification with `hasInlineReply: true`. Most chat apps (Discord, Element, K-9 Mail) do this for replyable messages. Send a message that should be replyable:
- Click "Reply" on the toast → panel should open + focus that notif's reply field
- Type a reply → press Enter → message sends back to the app, notif dismisses

If no chat app handy, can simulate via dbus (advanced, skip unless needed).

- [ ] **Step 4: Commit**

```bash
cd /home/nox/nixos
git add config/quickshell/Panel.qml config/quickshell/Toasts.qml config/quickshell/shell.qml
git commit --only -m "Inline reply routing: Toast Reply opens panel and focuses card's TextField" -- config/quickshell/Panel.qml config/quickshell/Toasts.qml config/quickshell/shell.qml
git log -1 --stat
```

---

# Known v2 gaps (carried from v1, NOT addressed here)

- Swipe-to-dismiss on toasts
- Multi-monitor toasts (still primary screen only)
- Notification persistence across reboot
- AI chat / OCR / Google Lens sidebar
- Global `SUPER+R` "focus newest reply-capable" fallback (only if layer-shell focus turns out flaky in practice)

---

# Done — verification checklist

After all tasks land, smoke-test:

- [ ] Panel opens centered top, 640 wide, 12px below waybar, with visible drop shadow
- [ ] Click anywhere outside the panel surface (wallpaper, waybar area, other windows) closes the panel
- [ ] Clicking on a slider handle and dragging works (doesn't close panel)
- [ ] Clicking on a toggle changes its state (doesn't close panel)
- [ ] `notify-send "X" "Y"` shows BOTH lines in toast and panel (bug D regression test)
- [ ] Send 3+ notifs from same app (`for i in 1 2 3; do notify-send -a discord "Sender $i" "Message $i"; done`); panel shows one group with `+2 more from discord` pill; click pill expands; click "Clear" removes all 3
- [ ] Toast stack: send 4 toasts in sequence; visible 3 show newest at top, oldest at bottom; 4th waiting shows as `+1` pill at bottom
- [ ] Tile borders visible on ToggleTile / SliderTile / SessionTile
- [ ] Hero (when MPRIS active): art is 50×50, title bold
- [ ] (Manual, with a real chat app) Reply field appears in NCard when "Reply" clicked; typing + Enter sends; field collapses on Escape
- [ ] (Manual, with chat app) "Reply" on a toast opens the panel and focuses the matching notif's reply field
