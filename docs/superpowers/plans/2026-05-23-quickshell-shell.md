# Quickshell Shell Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace SwayNC with a custom Quickshell-based shell (control panel + priority-aware notification toasts) matching the V15 design.

**Architecture:** Greenfield Quickshell config under `config/quickshell/`, flat module layout (Panel.qml, Toasts.qml, services/, widgets/, theme/). Service singletons own all dbus/IPC/process work; UI components are pure renderers. Waybar coordination via Quickshell IPC + `SIGRTMIN+8` refresh signal. Spec: `docs/superpowers/specs/2026-05-23-quickshell-shell-design.md`.

**Tech Stack:** Quickshell (QML/Qt6), Hyprland, NixOS with home-manager. Catppuccin Mocha theme. fcitx5 for input method. WirePlumber/PipeWire for audio. NetworkManager. BlueZ. hyprsunset for night light.

---

## Dev workflow (read first)

**No QML unit-test framework is practical here.** TDD adapts to "write component → reload Quickshell → verify behavior visually or via `qs ipc call`." Each task ends with a concrete verification step.

**Side-by-side dev mode (Phases 0–5):** Quickshell is installed as a package but **NOT** auto-started. SwayNC keeps handling real notifications. To test Quickshell progress:
```bash
pkill swaync; quickshell &   # in a terminal, swap in Quickshell
notify-send "test" "body"     # trigger a notification
pkill quickshell; swaync &    # restore SwayNC when done
```

**Cutover (Phase 6):** Final commit removes SwayNC from `exec-once`, deletes `config/swaync/`, wires Quickshell into autostart. After this, hot-reload during further dev is `qs reload`.

**Reference codebases** (consult while implementing, especially for Quickshell API surface):
- end-4/dots-hyprland Quickshell branch — first-class MPRIS multi-player, IPC patterns, `Process { stdout: SplitParser }` streaming
- DankMaterialShell — notification grouping, NixOS HM integration patterns
- Quickshell docs: <https://quickshell.org/docs/>

**API caveat:** Quickshell is on v0.3+ and alpha-tagged. Some symbol names below may differ in your installed version — check `https://quickshell.org/docs/types/` if an import or property doesn't resolve.

---

## File map

| Path | Responsibility |
|---|---|
| `config/quickshell/shell.qml` | Root: ScreenWindow + LazyLoader(Panel) + Variants(Toasts) + IPC handlers |
| `config/quickshell/Panel.qml` | Top-center control panel: Hero + SectionedBody |
| `config/quickshell/Toasts.qml` | Top-right toast stack, priority-aware |
| `config/quickshell/qmldir` | QML module registration |
| `config/quickshell/theme/Mocha.qml` | Catppuccin Mocha tokens singleton |
| `config/quickshell/theme/qmldir` | Theme singleton registration |
| `config/quickshell/services/*.qml` | 14 service singletons (see Phase 3) |
| `config/quickshell/services/qmldir` | Service singleton registrations |
| `config/quickshell/widgets/NCard.qml` | One notification card (panel + toasts) |
| `config/quickshell/widgets/Toggle.qml` | One toggle tile |
| `config/quickshell/widgets/Slider.qml` | One slider row |
| `config/quickshell/widgets/HeroMpris.qml` | Album art + info + controls |
| `config/quickshell/widgets/PlayerTabs.qml` | Multi-player switcher |
| `config/quickshell/widgets/qmldir` | Widget registrations (if singletons; else direct import) |
| `system/hyprland.nix` | Add `quickshell` package, remove `swaynotificationcenter` (Phase 6) |
| `profile/nox-{desktop,work}/home.nix` | Add `.config/quickshell` symlink; drop `.config/swaync` (Phase 6) |
| `config/hypr/hyprland.conf` | Swap `swaync` → `quickshell` in `exec-once` (Phase 6) |
| `config/hypr/hypr-config/keybinds.conf` | Swap `swaync-client` → `qs ipc call` (Phase 6) |
| `config/waybar/modules/modules.jsonc` | Replace `custom/swaync` with `custom/notifications` (Phase 5/6) |
| `config/swaync/` | DELETED in Phase 6 |

---

# Phase 0 — Bootstrap

## Task 0.1: Install Quickshell package + empty config dir

**Files:**
- Create: `config/quickshell/shell.qml` (placeholder)
- Modify: `system/hyprland.nix`
- Modify: `profile/nox-desktop/home.nix`
- Modify: `profile/nox-work/home.nix`

- [ ] **Step 1: Create the directory + placeholder shell.qml**

Run:
```bash
mkdir -p /home/nox/nixos/config/quickshell
```

Create `config/quickshell/shell.qml`:
```qml
import Quickshell

ShellRoot {}
```

- [ ] **Step 2: Add Quickshell to system packages**

Edit `system/hyprland.nix`. Replace the `environment.systemPackages` block:
```nix
environment.systemPackages = with pkgs; [
    hyprpicker
    hyprpaper
    hyprsunset
    hyprshot
    swaynotificationcenter   # KEEP for now — removed in Phase 6
    inputs.nixpkgs-unstable.legacyPackages.${pkgs.system}.quickshell
    wofi
    nautilus
    hyprpolkitagent
];
```

Note: the file header is `{ inputs, settings, pkgs, ... }:` already (verified). `inputs.nixpkgs-unstable` is already a flake input.

- [ ] **Step 3: Symlink the config dir in both home profiles**

Edit `profile/nox-desktop/home.nix` and `profile/nox-work/home.nix`. In each, find the block with `.config/swaync` and add a line:
```nix
".config/quickshell".source = ../../config/quickshell;
```
(KEEP the `.config/swaync` line — removed in Phase 6.)

- [ ] **Step 4: Rebuild and verify**

Run:
```bash
sudo nixos-rebuild switch --flake /home/nox/nixos
```
Expected: success.

Then:
```bash
quickshell --version
```
Expected: prints a version number (e.g., `quickshell 0.3.x`).

```bash
ls -la ~/.config/quickshell/
```
Expected: symlink showing `shell.qml`.

- [ ] **Step 5: Commit**

```bash
cd /home/nox/nixos
git add system/hyprland.nix profile/nox-desktop/home.nix profile/nox-work/home.nix config/quickshell/shell.qml
git commit -m "Add Quickshell package and config skeleton"
```

---

## Task 0.2: Minimal floating "hello" panel

**Files:**
- Modify: `config/quickshell/shell.qml`

- [ ] **Step 1: Write a minimal PanelWindow**

Replace `config/quickshell/shell.qml`:
```qml
import Quickshell
import Quickshell.Wayland
import QtQuick

ShellRoot {
    PanelWindow {
        anchors.top: true
        margins.top: 50
        implicitWidth: 220
        implicitHeight: 80
        color: "#1e1e2e"

        Text {
            anchors.centerIn: parent
            text: "Quickshell alive"
            color: "#cdd6f4"
            font.pixelSize: 16
        }
    }
}
```

- [ ] **Step 2: Run it and verify**

In a terminal:
```bash
pkill quickshell 2>/dev/null; quickshell &
```
Expected: a small dark rectangle saying "Quickshell alive" appears centered at the top of the screen, just below the waybar.

If it doesn't appear, check `journalctl --user -e -t quickshell` for QML errors.

- [ ] **Step 3: Stop the dev instance**

```bash
pkill quickshell
```

- [ ] **Step 4: Commit**

```bash
git add config/quickshell/shell.qml
git commit -m "Wire minimal Quickshell PanelWindow"
```

---

# Phase 1 — Theme tokens

## Task 1.1: Catppuccin Mocha tokens singleton

**Files:**
- Create: `config/quickshell/theme/Mocha.qml`
- Create: `config/quickshell/theme/qmldir`

- [ ] **Step 1: Create the singleton**

Create `config/quickshell/theme/Mocha.qml`:
```qml
pragma Singleton
import QtQuick

QtObject {
    // Catppuccin Mocha palette (matches config/swaync/mocha_config.css)
    readonly property color base:      "#1e1e2e"
    readonly property color mantle:    "#181825"
    readonly property color crust:     "#11111b"
    readonly property color text:      "#cdd6f4"
    readonly property color subtext1:  "#bac2de"
    readonly property color subtext0:  "#a6adc8"
    readonly property color overlay2:  "#9399b2"
    readonly property color overlay1:  "#7f849c"
    readonly property color overlay0:  "#6c7086"
    readonly property color surface2:  "#585b70"
    readonly property color surface1:  "#45475a"
    readonly property color surface0:  "#313244"
    readonly property color blue:      "#89b4fa"
    readonly property color sapphire:  "#74c7ec"
    readonly property color sky:       "#89dceb"
    readonly property color teal:      "#94e2d5"
    readonly property color green:     "#a6e3a1"
    readonly property color yellow:    "#f9e2af"
    readonly property color peach:     "#fab387"
    readonly property color maroon:    "#eba0ac"
    readonly property color red:       "#f38ba8"
    readonly property color mauve:     "#cba6f7"
    readonly property color pink:      "#f5c2e7"
    readonly property color flamingo:  "#f2cdcd"
    readonly property color rosewater: "#f5e0dc"

    // Sizing
    readonly property int radiusSm: 6
    readonly property int radiusMd: 10
    readonly property int radiusLg: 14
    readonly property int spaceXs: 4
    readonly property int spaceSm: 8
    readonly property int spaceMd: 12
    readonly property int spaceLg: 16

    // Typography
    readonly property string fontFamily: "Inter"
    readonly property string fontMono: "JetBrains Mono"
    readonly property int fontSm: 11
    readonly property int fontMd: 13
    readonly property int fontLg: 15
}
```

- [ ] **Step 2: Register as a singleton**

Create `config/quickshell/theme/qmldir`:
```
module theme
singleton Mocha 1.0 Mocha.qml
```

- [ ] **Step 3: Wire it into shell.qml and verify it loads**

Replace `config/quickshell/shell.qml`:
```qml
import Quickshell
import Quickshell.Wayland
import QtQuick
import "theme" as Theme

ShellRoot {
    PanelWindow {
        anchors.top: true
        margins.top: 50
        implicitWidth: 220
        implicitHeight: 80
        color: Theme.Mocha.base

        Text {
            anchors.centerIn: parent
            text: "Quickshell alive"
            color: Theme.Mocha.text
            font.family: Theme.Mocha.fontFamily
            font.pixelSize: Theme.Mocha.fontLg
        }
    }
}
```

- [ ] **Step 4: Verify**

```bash
pkill quickshell 2>/dev/null; quickshell &
```
Expected: same dark rectangle, but now in Inter font, using Mocha tokens. If the import fails, check journalctl for `Theme is not a type` — usually means `qmldir` syntax is off.

```bash
pkill quickshell
```

- [ ] **Step 5: Commit**

```bash
git add config/quickshell/theme/ config/quickshell/shell.qml
git commit -m "Add Catppuccin Mocha theme singleton"
```

---

# Phase 2 — Notifications + Toasts

## Task 2.1: DND service singleton

**Files:**
- Create: `config/quickshell/services/DND.qml`
- Create: `config/quickshell/services/qmldir`

- [ ] **Step 1: Write the singleton**

Create `config/quickshell/services/DND.qml`:
```qml
pragma Singleton
import QtQuick

QtObject {
    property bool enabled: false

    function toggle() { enabled = !enabled }
    function set(value) { enabled = !!value }
}
```

- [ ] **Step 2: Register it**

Create `config/quickshell/services/qmldir`:
```
module services
singleton DND 1.0 DND.qml
```

- [ ] **Step 3: Commit**

```bash
git add config/quickshell/services/
git commit -m "Add DND service singleton"
```

---

## Task 2.2: Notifications service (NotificationServer wrapper)

**Files:**
- Create: `config/quickshell/services/Notifications.qml`
- Modify: `config/quickshell/services/qmldir`

- [ ] **Step 1: Write the service**

Create `config/quickshell/services/Notifications.qml`:
```qml
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import "." as Services    // sibling singletons (DND)

QtObject {
    id: root

    // All notifications still on screen (panel list + active toasts).
    property var notifs: []
    property int count: notifs.length

    // The subset currently visible as toasts (max 3 in v1).
    property var activeToasts: []

    signal stateChanged()

    property NotificationServer server: NotificationServer {
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        inlineReplySupported: false  // v1: not supported
        keepOnReload: true

        onNotification: (notification) => {
            notification.tracked = true
            const entry = {
                id: notification.id,
                appName: notification.appName,
                summary: notification.summary,
                body: notification.body,
                image: notification.image,
                urgency: notification.urgency,  // 0=low, 1=normal, 2=critical
                actions: notification.actions,
                timestamp: Date.now(),
                notification: notification
            }
            root.notifs = [entry, ...root.notifs]
            if (!Services.DND.enabled) {
                root.activeToasts = [entry, ...root.activeToasts].slice(0, 10)
            }
            root.stateChanged()
        }
    }

    function dismiss(id) {
        const entry = notifs.find(n => n.id === id)
        if (entry?.notification) entry.notification.dismiss()
        notifs = notifs.filter(n => n.id !== id)
        activeToasts = activeToasts.filter(n => n.id !== id)
        stateChanged()
    }

    function clearAll() {
        notifs.forEach(n => n.notification?.dismiss())
        notifs = []
        activeToasts = []
        stateChanged()
    }

    function expireToast(id) {
        activeToasts = activeToasts.filter(n => n.id !== id)
        // notif stays in panel list until dismissed/cleared
    }

    function toggleDnd() {
        Services.DND.toggle()
        if (Services.DND.enabled) activeToasts = []
        stateChanged()
    }

    // Returns JSON string for waybar's custom/notifications module
    function waybarLine() {
        const c = count
        const dnd = Services.DND.enabled
        let icon
        if (dnd) icon = "󰂛"        // bell-slash
        else if (c === 0) icon = "󰂜" // bell-off
        else icon = "󰂚"             // bell-ring
        return JSON.stringify({
            text: c > 0 ? `${icon} ${c}` : icon,
            tooltip: dnd ? "DND on" : `${c} notification${c === 1 ? "" : "s"}`,
            class: dnd ? "dnd" : (c > 0 ? "has-notifs" : "empty")
        })
    }
}
```

- [ ] **Step 2: Register**

Append to `config/quickshell/services/qmldir`:
```
singleton Notifications 1.0 Notifications.qml
```

- [ ] **Step 3: Wire into shell.qml so the service starts**

Replace `config/quickshell/shell.qml`:
```qml
import Quickshell
import Quickshell.Wayland
import QtQuick
import "theme" as Theme
import "services" as Services

ShellRoot {
    // Force singleton instantiation
    Component.onCompleted: {
        Services.Notifications;
        Services.DND;
    }

    PanelWindow {
        anchors.top: true
        margins.top: 50
        implicitWidth: 280
        implicitHeight: 80
        color: Theme.Mocha.base

        Text {
            anchors.centerIn: parent
            text: `Notifs: ${Services.Notifications.count}, DND: ${Services.DND.enabled}`
            color: Theme.Mocha.text
            font.family: Theme.Mocha.fontFamily
            font.pixelSize: Theme.Mocha.fontMd
        }
    }
}
```

- [ ] **Step 4: Verify NotificationServer registers and counts notifications**

```bash
pkill swaync; pkill quickshell 2>/dev/null
quickshell &
sleep 1
notify-send "Test" "Hello world"
```
Expected: the panel's text updates to `Notifs: 1, DND: false`. If it shows `Notifs: 0`, the NotificationServer registration didn't take (probably SwayNC was still running).

```bash
pkill quickshell; swaync &
```

- [ ] **Step 5: Commit**

```bash
git add config/quickshell/services/Notifications.qml config/quickshell/services/qmldir config/quickshell/shell.qml
git commit -m "Add Notifications service wrapping NotificationServer"
```

---

## Task 2.3: NCard widget (basic, no progress bar)

**Files:**
- Create: `config/quickshell/widgets/NCard.qml`
- Create: `config/quickshell/widgets/qmldir`

- [ ] **Step 1: Write the card**

Create `config/quickshell/widgets/NCard.qml`:
```qml
import QtQuick
import QtQuick.Layouts
import "../theme" as Theme

Rectangle {
    id: card

    property var entry              // notification entry from Notifications service
    property bool showProgress: false
    property real progress: 1.0     // 0..1, toast-only
    property int urgency: entry?.urgency ?? 1

    signal dismissed()
    signal actionInvoked(string actionId)

    width: 380
    implicitHeight: layout.implicitHeight + Theme.Mocha.spaceMd * 2
                  + (showProgress ? 4 : 0)
    radius: Theme.Mocha.radiusMd
    color: Theme.Mocha.surface0
    border.width: urgency === 2 ? 1 : 0
    border.color: urgency === 2 ? Theme.Mocha.red : "transparent"

    ColumnLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: Theme.Mocha.spaceMd
        anchors.bottomMargin: showProgress ? Theme.Mocha.spaceMd + 4 : Theme.Mocha.spaceMd
        spacing: Theme.Mocha.spaceXs

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.Mocha.spaceSm

            Text {
                text: entry?.appName ?? ""
                color: Theme.Mocha.subtext0
                font.family: Theme.Mocha.fontFamily
                font.pixelSize: Theme.Mocha.fontSm
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
            Text {
                text: "×"
                color: Theme.Mocha.overlay0
                font.pixelSize: Theme.Mocha.fontMd
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: card.dismissed()
                }
            }
        }

        Text {
            text: entry?.summary ?? ""
            color: Theme.Mocha.text
            font.family: Theme.Mocha.fontFamily
            font.pixelSize: Theme.Mocha.fontMd
            font.weight: Font.Medium
            Layout.fillWidth: true
            elide: Text.ElideRight
        }

        Text {
            visible: (entry?.body ?? "") !== ""
            text: entry?.body ?? ""
            color: Theme.Mocha.subtext1
            font.family: Theme.Mocha.fontFamily
            font.pixelSize: Theme.Mocha.fontSm
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            maximumLineCount: 3
            elide: Text.ElideRight
        }
    }

    // Progress bar — toast-only
    Rectangle {
        visible: card.showProgress
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 0
        height: 2
        color: Theme.Mocha.surface1
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

- [ ] **Step 2: Register the widget directory (no singleton, just module)**

Create `config/quickshell/widgets/qmldir`:
```
module widgets
NCard 1.0 NCard.qml
```

- [ ] **Step 3: Commit**

```bash
git add config/quickshell/widgets/
git commit -m "Add NCard notification widget"
```

---

## Task 2.4: Basic Toasts layer (top-right stack of up to 3)

**Files:**
- Create: `config/quickshell/Toasts.qml`
- Modify: `config/quickshell/shell.qml`

- [ ] **Step 1: Write Toasts.qml**

Create `config/quickshell/Toasts.qml`:
```qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "theme" as Theme
import "services" as Services
import "widgets" as Widgets

PanelWindow {
    id: toastWindow

    anchors.top: true
    anchors.right: true
    margins.top: 38   // below waybar
    margins.right: 12
    implicitWidth: 400
    implicitHeight: column.implicitHeight + 8
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    visible: column.children.length > 0

    ColumnLayout {
        id: column
        anchors.fill: parent
        anchors.margins: 4
        spacing: Theme.Mocha.spaceSm

        Repeater {
            model: Services.Notifications.activeToasts.slice(0, 3)
            delegate: Widgets.NCard {
                entry: modelData
                onDismissed: Services.Notifications.dismiss(modelData.id)
            }
        }
    }
}
```

- [ ] **Step 2: Wire Toasts into shell.qml**

Replace `config/quickshell/shell.qml`:
```qml
import Quickshell
import Quickshell.Wayland
import QtQuick
import "theme" as Theme
import "services" as Services

ShellRoot {
    Component.onCompleted: {
        Services.Notifications;
        Services.DND;
    }

    Toasts {}
}
```

(`Toasts {}` resolves to `Toasts.qml` in the same directory.)

- [ ] **Step 3: Verify a toast appears**

```bash
pkill swaync; pkill quickshell 2>/dev/null
quickshell &
sleep 1
notify-send "Test" "Hello from Quickshell"
```
Expected: a dark Catppuccin-styled card appears top-right with "Test" + body.

```bash
notify-send "Second" "Another"
notify-send "Third"  "Three"
notify-send "Fourth" "Should not show — only 3 visible"
```
Expected: 3 visible cards stacked vertically. Fourth doesn't render yet (overflow handled in Task 2.6).

Dismiss the × on a card → it disappears.

```bash
pkill quickshell; swaync &
```

- [ ] **Step 4: Commit**

```bash
git add config/quickshell/Toasts.qml config/quickshell/shell.qml
git commit -m "Add basic Toasts layer (top-right stack of 3)"
```

---

## Task 2.5: Toast auto-dismiss with progress bar + priority timeouts

**Files:**
- Modify: `config/quickshell/Toasts.qml`

- [ ] **Step 1: Rewrite Toasts.qml with per-toast timer + progress**

Replace `config/quickshell/Toasts.qml`:
```qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "theme" as Theme
import "services" as Services
import "widgets" as Widgets

PanelWindow {
    id: toastWindow

    anchors.top: true
    anchors.right: true
    margins.top: 38
    margins.right: 12
    implicitWidth: 400
    implicitHeight: column.implicitHeight + 8
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    visible: column.children.length > 0

    function timeoutFor(urgency) {
        if (urgency === 0) return 4000   // low
        if (urgency === 2) return 0      // critical: never
        return 8000                       // normal
    }

    ColumnLayout {
        id: column
        anchors.fill: parent
        anchors.margins: 4
        spacing: Theme.Mocha.spaceSm

        Repeater {
            model: Services.Notifications.activeToasts.slice(0, 3)

            delegate: Item {
                id: cell
                Layout.fillWidth: true
                implicitHeight: card.implicitHeight

                property var entry: modelData
                property int duration: toastWindow.timeoutFor(entry?.urgency ?? 1)
                property real progress: duration === 0 ? 0 : 1
                property bool paused: hover.hovered

                Timer {
                    id: tickTimer
                    interval: 50
                    repeat: true
                    running: cell.duration > 0 && !cell.paused
                    onTriggered: {
                        cell.progress -= (50 / cell.duration)
                        if (cell.progress <= 0) {
                            Services.Notifications.expireToast(cell.entry.id)
                        }
                    }
                }

                HoverHandler { id: hover }

                Widgets.NCard {
                    id: card
                    anchors.fill: parent
                    entry: cell.entry
                    showProgress: cell.duration > 0
                    progress: cell.progress
                    urgency: cell.entry?.urgency ?? 1
                    onDismissed: Services.Notifications.dismiss(cell.entry.id)
                }
            }
        }
    }
}
```

- [ ] **Step 2: Verify timeouts**

```bash
pkill swaync; pkill quickshell 2>/dev/null
quickshell &
sleep 1
notify-send -u low      "Low"      "Should expire in ~4s"
notify-send -u normal   "Normal"   "Should expire in ~8s"
notify-send -u critical "Critical" "Never auto-dismisses"
```
Expected:
- All three appear with progress bars
- Low fades after ~4s
- Normal fades after ~8s
- Critical has 1px red border, no bar countdown, stays forever
- Hover any toast → progress bar pauses; un-hover → resumes

```bash
pkill quickshell; swaync &
```

- [ ] **Step 3: Commit**

```bash
git add config/quickshell/Toasts.qml
git commit -m "Add toast auto-dismiss timer with priority timeouts"
```

---

## Task 2.6: Toast overflow pill (+N more) + click-to-open

**Files:**
- Modify: `config/quickshell/Toasts.qml`

- [ ] **Step 1: Add the overflow pill**

In `config/quickshell/Toasts.qml`, add after the `Repeater {...}` block, still inside the `ColumnLayout`:
```qml
Rectangle {
    visible: Services.Notifications.activeToasts.length > 3
    Layout.alignment: Qt.AlignHCenter
    implicitWidth: pillText.implicitWidth + Theme.Mocha.spaceMd * 2
    implicitHeight: pillText.implicitHeight + Theme.Mocha.spaceXs * 2
    radius: height / 2
    color: Theme.Mocha.surface1

    Text {
        id: pillText
        anchors.centerIn: parent
        text: `+ ${Services.Notifications.activeToasts.length - 3} more`
        color: Theme.Mocha.subtext0
        font.family: Theme.Mocha.fontFamily
        font.pixelSize: Theme.Mocha.fontSm
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        // Panel toggle wired in Phase 5; for now just clear the overflow
        onClicked: {
            Services.Notifications.activeToasts =
                Services.Notifications.activeToasts.slice(0, 3)
        }
    }
}
```

- [ ] **Step 2: Verify**

```bash
pkill swaync; pkill quickshell 2>/dev/null
quickshell &
sleep 1
for i in 1 2 3 4 5; do notify-send "Test $i" "body $i"; sleep 0.1; done
```
Expected: 3 cards visible + a small `+ 2 more` pill below. Click the pill → overflow clears.

```bash
pkill quickshell; swaync &
```

- [ ] **Step 3: Commit**

```bash
git add config/quickshell/Toasts.qml
git commit -m "Add toast overflow +N pill"
```

---

## Task 2.7: NCard actions (default-click body + action buttons row)

**Files:**
- Modify: `config/quickshell/widgets/NCard.qml`
- Modify: `config/quickshell/Toasts.qml`

- [ ] **Step 1: Add the body click-handler + action buttons row to NCard**

In `config/quickshell/widgets/NCard.qml`, find the body Text element:
```qml
Text {
    visible: (entry?.body ?? "") !== ""
    text: entry?.body ?? ""
    color: Theme.Mocha.subtext1
    font.family: Theme.Mocha.fontFamily
    font.pixelSize: Theme.Mocha.fontSm
    Layout.fillWidth: true
    wrapMode: Text.WordWrap
    maximumLineCount: 3
    elide: Text.ElideRight
}
```
Replace it with the same Text wrapped in click handling, and add an action-buttons RowLayout right after it:
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

RowLayout {
    Layout.fillWidth: true
    spacing: Theme.Mocha.spaceXs
    visible: actionRepeater.count > 0

    Repeater {
        id: actionRepeater
        model: (card.entry?.actions ?? []).filter(a => a.identifier !== "default")
        delegate: Rectangle {
            Layout.fillWidth: true
            implicitHeight: 28
            radius: Theme.Mocha.radiusSm
            color: btnMa.containsMouse ? Theme.Mocha.surface1 : Theme.Mocha.surface0
            border.width: 1
            border.color: Theme.Mocha.surface1

            Text {
                anchors.centerIn: parent
                text: modelData.text ?? modelData.identifier
                color: Theme.Mocha.text
                font.family: Theme.Mocha.fontFamily
                font.pixelSize: Theme.Mocha.fontSm
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
```

Note: the Quickshell API for invoking notification actions is `notification.invokeAction(identifier)`. Verify the exact method name in your installed version — older releases may use `dispatchAction()` or `action()` instead.

- [ ] **Step 2: Wire actionInvoked in Toasts.qml**

In `config/quickshell/Toasts.qml`, find the `Widgets.NCard { ... }` delegate inside the cell and add the `onActionInvoked` handler:
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

(NotifList.qml in Task 4.7 will mirror this; we wire it there.)

- [ ] **Step 3: Verify actions render and click**

```bash
pkill swaync; pkill quickshell 2>/dev/null
quickshell &
sleep 1
notify-send -A reply=Reply -A close=Dismiss "Action test" "click an action below"
```
Expected: toast appears with two buttons (`Reply`, `Dismiss`) below the body. Clicking either invokes the action and dismisses the toast. `notify-send -A` syntax may not invoke on real apps — better to test with a real notification source (Telegram, Slack, etc.).

```bash
pkill quickshell; swaync &
```

- [ ] **Step 4: Commit**

```bash
git add config/quickshell/widgets/NCard.qml config/quickshell/Toasts.qml
git commit -m "Add notification action buttons and default-click on body"
```

---

# Phase 3 — Service singletons

Each service follows the same pattern: a `Singleton` QtObject exposing read-only state + `toggle()`/`set()`/`refresh()` methods, registered in `services/qmldir`.

After each task in this phase, append the singleton to `services/qmldir`. Verification for each is `qs ipc call` or a minimal text panel update in `shell.qml`.

## Task 3.1: Built-in re-exports (Hyprland, SystemTray, SystemClock, UPower)

**Files:**
- Create: `config/quickshell/services/Hyprland.qml`
- Create: `config/quickshell/services/SystemTray.qml`
- Create: `config/quickshell/services/SystemClock.qml`
- Create: `config/quickshell/services/UPower.qml`
- Modify: `config/quickshell/services/qmldir`

- [ ] **Step 1: Hyprland singleton**

Create `config/quickshell/services/Hyprland.qml`:
```qml
pragma Singleton
import QtQuick
import Quickshell.Hyprland

QtObject {
    readonly property var workspaces: Hyprland.workspaces
    readonly property var activeWorkspace: Hyprland.focusedWorkspace

    function dispatch(cmd) { Hyprland.dispatch(cmd) }
}
```

- [ ] **Step 2: SystemTray singleton**

Create `config/quickshell/services/SystemTray.qml`:
```qml
pragma Singleton
import QtQuick
import Quickshell.Services.SystemTray

QtObject {
    readonly property var items: SystemTray.items
}
```

- [ ] **Step 3: SystemClock singleton**

Create `config/quickshell/services/SystemClock.qml`:
```qml
pragma Singleton
import QtQuick
import Quickshell

QtObject {
    readonly property SystemClock clock: SystemClock {
        precision: SystemClock.Seconds
    }
    readonly property date now: clock.date
}
```

- [ ] **Step 4: UPower singleton**

Create `config/quickshell/services/UPower.qml`:
```qml
pragma Singleton
import QtQuick
import Quickshell.Services.UPower

QtObject {
    readonly property var device: UPower.displayDevice
    readonly property real percentage: device?.percentage ?? 0
    readonly property bool charging: device?.state === UPowerDeviceState.Charging
}
```

- [ ] **Step 5: Register all four**

Append to `config/quickshell/services/qmldir`:
```
singleton Hyprland 1.0 Hyprland.qml
singleton SystemTray 1.0 SystemTray.qml
singleton SystemClock 1.0 SystemClock.qml
singleton UPower 1.0 UPower.qml
```

- [ ] **Step 6: Verify no QML errors**

```bash
pkill quickshell 2>/dev/null; quickshell &
sleep 1
journalctl --user -t quickshell --since "10 seconds ago" | grep -iE "error|warning" || echo "clean"
```
Expected: "clean" (no QML errors). If a UPower or SystemTray import fails, the module name may differ in your Quickshell version — check `https://quickshell.org/docs/types/`.

```bash
pkill quickshell
```

- [ ] **Step 7: Commit**

```bash
git add config/quickshell/services/
git commit -m "Add built-in service singletons (Hyprland, SystemTray, Clock, UPower)"
```

---

## Task 3.2: Audio service (PipeWire)

**Files:**
- Create: `config/quickshell/services/Audio.qml`
- Modify: `config/quickshell/services/qmldir`

- [ ] **Step 1: Write the service**

Create `config/quickshell/services/Audio.qml`:
```qml
pragma Singleton
import QtQuick
import Quickshell.Services.Pipewire

QtObject {
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property bool micMuted: source?.audio?.muted ?? false

    function setVolume(v) {
        if (sink?.audio) sink.audio.volume = Math.max(0, Math.min(1, v))
    }
    function toggleMute() {
        if (sink?.audio) sink.audio.muted = !sink.audio.muted
    }
    function toggleMicMute() {
        if (source?.audio) source.audio.muted = !source.audio.muted
    }

    // Track default sink/source so reactivity works
    PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource] }
}
```

- [ ] **Step 2: Register**

Append to `config/quickshell/services/qmldir`:
```
singleton Audio 1.0 Audio.qml
```

- [ ] **Step 3: Verify**

```bash
pkill quickshell 2>/dev/null; quickshell &
sleep 1
journalctl --user -t quickshell --since "10 seconds ago" | grep -iE "error|warning" || echo "clean"
pkill quickshell
```
Expected: clean. (Functional test happens once the panel surfaces the slider in Phase 4.)

- [ ] **Step 4: Commit**

```bash
git add config/quickshell/services/Audio.qml config/quickshell/services/qmldir
git commit -m "Add Audio service singleton (PipeWire)"
```

---

## Task 3.3: Brightness service

**Files:**
- Create: `config/quickshell/services/Brightness.qml`
- Modify: `config/quickshell/services/qmldir`

- [ ] **Step 1: Write the service**

Create `config/quickshell/services/Brightness.qml`:
```qml
pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root
    property real value: 0   // 0..1
    property int _max: 1
    property int _current: 0

    Process {
        id: readMax
        command: ["sh", "-c", "brightnessctl m"]
        stdout: StdioCollector { onStreamFinished: root._max = parseInt(text) }
        running: true
    }
    Process {
        id: readCur
        command: ["sh", "-c", "brightnessctl g"]
        stdout: StdioCollector { onStreamFinished: {
            root._current = parseInt(text)
            root.value = root._current / Math.max(root._max, 1)
        }}
        running: true
    }
    Timer {
        interval: 2000; repeat: true; running: true
        onTriggered: readCur.running = true
    }

    function setValue(v) {
        const target = Math.round(Math.max(0, Math.min(1, v)) * 100)
        const p = Qt.createQmlObject(`
            import Quickshell.Io
            Process { command: ["brightnessctl", "set", "${target}%"]; running: true }
        `, root)
        readCur.running = true
    }
}
```

- [ ] **Step 2: Register**

Append to `config/quickshell/services/qmldir`:
```
singleton Brightness 1.0 Brightness.qml
```

- [ ] **Step 3: Verify**

```bash
pkill quickshell 2>/dev/null; quickshell &
sleep 1
journalctl --user -t quickshell --since "10 seconds ago" | grep -iE "error|warning" || echo "clean"
pkill quickshell
```

- [ ] **Step 4: Commit**

```bash
git add config/quickshell/services/Brightness.qml config/quickshell/services/qmldir
git commit -m "Add Brightness service via brightnessctl"
```

---

## Task 3.4: Network service (nmcli)

**Files:**
- Create: `config/quickshell/services/Network.qml`
- Modify: `config/quickshell/services/qmldir`

- [ ] **Step 1: Write the service**

Create `config/quickshell/services/Network.qml`:
```qml
pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root
    property bool wifiEnabled: false
    property string activeSsid: ""

    Process {
        id: poll
        command: ["sh", "-c",
                  "nmcli -t -f WIFI,WIFI-HW general && nmcli -t -f ACTIVE,SSID dev wifi"]
        stdout: StdioCollector { onStreamFinished: root._parse(text) }
    }
    Timer {
        interval: 5000; repeat: true; running: true; triggeredOnStart: true
        onTriggered: poll.running = true
    }

    function _parse(out) {
        const lines = out.split("\n")
        wifiEnabled = lines[0]?.startsWith("enabled")
        const active = lines.slice(2).find(l => l.startsWith("yes:"))
        activeSsid = active ? active.split(":")[1] : ""
    }

    function toggleWifi() {
        const p = Qt.createQmlObject(`
            import Quickshell.Io
            Process { command: ["nmcli", "radio", "wifi", "${wifiEnabled ? "off" : "on"}"]; running: true }
        `, root)
        Qt.callLater(() => poll.running = true)
    }

    function refresh() { poll.running = true }
}
```

- [ ] **Step 2: Register**

Append to `config/quickshell/services/qmldir`:
```
singleton Network 1.0 Network.qml
```

- [ ] **Step 3: Verify**

```bash
pkill quickshell 2>/dev/null; quickshell &
sleep 6
journalctl --user -t quickshell --since "10 seconds ago" | grep -iE "error|warning" || echo "clean"
pkill quickshell
```

- [ ] **Step 4: Commit**

```bash
git add config/quickshell/services/Network.qml config/quickshell/services/qmldir
git commit -m "Add Network service via nmcli polling"
```

---

## Task 3.5: Bluetooth service

**Files:**
- Create: `config/quickshell/services/Bluetooth.qml`
- Modify: `config/quickshell/services/qmldir`

- [ ] **Step 1: Write the service**

Create `config/quickshell/services/Bluetooth.qml`:
```qml
pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root
    property bool powered: false

    Process {
        id: poll
        command: ["sh", "-c", "bluetoothctl show | grep -E 'Powered:' | awk '{print $2}'"]
        stdout: StdioCollector { onStreamFinished: root.powered = text.trim() === "yes" }
    }
    Timer {
        interval: 5000; repeat: true; running: true; triggeredOnStart: true
        onTriggered: poll.running = true
    }

    function toggle() {
        const p = Qt.createQmlObject(`
            import Quickshell.Io
            Process { command: ["bluetoothctl", "power", "${powered ? "off" : "on"}"]; running: true }
        `, root)
        Qt.callLater(() => poll.running = true)
    }
}
```

Note: prefer `Quickshell.Bluetooth` (if present in your version) — check docs. Falls back to `bluetoothctl` here.

- [ ] **Step 2: Register**

Append to `config/quickshell/services/qmldir`:
```
singleton Bluetooth 1.0 Bluetooth.qml
```

- [ ] **Step 3: Verify**

```bash
pkill quickshell 2>/dev/null; quickshell &
sleep 6
journalctl --user -t quickshell --since "10 seconds ago" | grep -iE "error|warning" || echo "clean"
pkill quickshell
```

- [ ] **Step 4: Commit**

```bash
git add config/quickshell/services/Bluetooth.qml config/quickshell/services/qmldir
git commit -m "Add Bluetooth service via bluetoothctl"
```

---

## Task 3.6: MPRIS service (multi-player)

**Files:**
- Create: `config/quickshell/services/Mpris.qml`
- Modify: `config/quickshell/services/qmldir`

- [ ] **Step 1: Write the service**

Create `config/quickshell/services/Mpris.qml`:
```qml
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
```

- [ ] **Step 2: Register**

Append to `config/quickshell/services/qmldir`:
```
singleton Mpris 1.0 Mpris.qml
```

- [ ] **Step 3: Verify**

```bash
pkill quickshell 2>/dev/null; quickshell &
sleep 1
journalctl --user -t quickshell --since "10 seconds ago" | grep -iE "error|warning" || echo "clean"
pkill quickshell
```
(Visual verification happens with the Hero in Phase 4.)

- [ ] **Step 4: Commit**

```bash
git add config/quickshell/services/Mpris.qml config/quickshell/services/qmldir
git commit -m "Add Mpris service with multi-player tracking"
```

---

## Task 3.7: Idle inhibitor service

**Files:**
- Create: `config/quickshell/services/Idle.qml`
- Modify: `config/quickshell/services/qmldir`

- [ ] **Step 1: Write the service**

Create `config/quickshell/services/Idle.qml`:
```qml
pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root
    readonly property string markerPath:
        Quickshell.env("XDG_RUNTIME_DIR") + "/idle-suspend.inhibit"

    property bool inhibited: false

    FileView {
        id: marker
        path: root.markerPath
        watchChanges: true
        onLoaded: root.inhibited = true
        onLoadFailed: root.inhibited = false
        onFileChanged: reload()
        Component.onCompleted: reload()
    }

    function toggle() {
        const p = Qt.createQmlObject(inhibited
            ? `import Quickshell.Io; Process { command: ["rm", "-f", "${root.markerPath}"]; running: true }`
            : `import Quickshell.Io; Process { command: ["touch", "${root.markerPath}"]; running: true }`,
            root)
        Qt.callLater(() => marker.reload())
    }
}
```

- [ ] **Step 2: Register**

Append to `config/quickshell/services/qmldir`:
```
singleton Idle 1.0 Idle.qml
```

- [ ] **Step 3: Verify**

```bash
pkill quickshell 2>/dev/null; quickshell &
sleep 1
journalctl --user -t quickshell --since "10 seconds ago" | grep -iE "error|warning" || echo "clean"
ls -la /run/user/$(id -u)/idle-suspend.inhibit 2>&1
pkill quickshell
```

- [ ] **Step 4: Commit**

```bash
git add config/quickshell/services/Idle.qml config/quickshell/services/qmldir
git commit -m "Add Idle inhibitor service via marker file"
```

---

## Task 3.8: Night light service (hyprsunset)

**Files:**
- Create: `config/quickshell/services/NightLight.qml`
- Modify: `config/quickshell/services/qmldir`

- [ ] **Step 1: Write the service**

Create `config/quickshell/services/NightLight.qml`:
```qml
pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root
    property bool active: false

    Process {
        id: check
        command: ["sh", "-c", "pgrep -x hyprsunset >/dev/null && echo on || echo off"]
        stdout: StdioCollector { onStreamFinished: root.active = text.trim() === "on" }
    }
    Timer {
        interval: 3000; repeat: true; running: true; triggeredOnStart: true
        onTriggered: check.running = true
    }

    function toggle() {
        const cmd = active
            ? "pkill -x hyprsunset"
            : "hyprsunset >/dev/null 2>&1 &"
        const p = Qt.createQmlObject(`
            import Quickshell.Io
            Process { command: ["sh", "-c", "${cmd}"]; running: true }
        `, root)
        Qt.callLater(() => check.running = true)
    }
}
```

- [ ] **Step 2: Register**

Append to `config/quickshell/services/qmldir`:
```
singleton NightLight 1.0 NightLight.qml
```

- [ ] **Step 3: Verify**

```bash
pkill quickshell 2>/dev/null; quickshell &
sleep 4
journalctl --user -t quickshell --since "10 seconds ago" | grep -iE "error|warning" || echo "clean"
pkill quickshell
```

- [ ] **Step 4: Commit**

```bash
git add config/quickshell/services/NightLight.qml config/quickshell/services/qmldir
git commit -m "Add NightLight service for hyprsunset"
```

---

## Task 3.9: InputMethod service (fcitx5 dbus)

**Files:**
- Create: `config/quickshell/services/InputMethod.qml`
- Modify: `config/quickshell/services/qmldir`

- [ ] **Step 1: Write the service**

Create `config/quickshell/services/InputMethod.qml`:
```qml
pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root
    property string currentIm: ""     // e.g. "keyboard-us" or "mozc"
    property string shortLabel: "EN"

    Process {
        id: query
        command: ["fcitx5-remote", "-n"]
        stdout: StdioCollector { onStreamFinished: {
            root.currentIm = text.trim()
            root.shortLabel = root._labelFor(root.currentIm)
        }}
    }
    Timer {
        interval: 1500; repeat: true; running: true; triggeredOnStart: true
        onTriggered: query.running = true
    }

    function _labelFor(im) {
        if (im.startsWith("mozc")) return "あ"
        if (im.startsWith("keyboard-jp")) return "JP"
        return "EN"
    }

    function toggle() {
        const p = Qt.createQmlObject(`
            import Quickshell.Io
            Process { command: ["fcitx5-remote", "-t"]; running: true }
        `, root)
        Qt.callLater(() => query.running = true)
    }
}
```

Note: a pure-dbus version (`org.fcitx.Fcitx5 /controller Toggle/CurrentInputMethod`) would avoid spawning `fcitx5-remote` every 1.5s. Acceptable for v1; revisit if it shows up in CPU profiles.

- [ ] **Step 2: Register**

Append to `config/quickshell/services/qmldir`:
```
singleton InputMethod 1.0 InputMethod.qml
```

- [ ] **Step 3: Verify**

```bash
pkill quickshell 2>/dev/null; quickshell &
sleep 3
journalctl --user -t quickshell --since "10 seconds ago" | grep -iE "error|warning" || echo "clean"
fcitx5-remote -n   # should print currentIm
pkill quickshell
```

- [ ] **Step 4: Commit**

```bash
git add config/quickshell/services/InputMethod.qml config/quickshell/services/qmldir
git commit -m "Add InputMethod service via fcitx5-remote"
```

---

# Phase 4 — Panel UI

## Task 4.1: Panel.qml scaffolding (top-center layer + backdrop close + open IPC)

**Files:**
- Create: `config/quickshell/Panel.qml`
- Modify: `config/quickshell/shell.qml`

- [ ] **Step 1: Write Panel.qml**

Create `config/quickshell/Panel.qml`:
```qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "theme" as Theme
import "services" as Services

PanelWindow {
    id: panel

    property bool isOpen: false

    anchors.top: true
    margins.top: 38
    implicitWidth: 580
    implicitHeight: 720
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    visible: isOpen
    exclusiveZone: 0

    function open()   { isOpen = true }
    function close()  { isOpen = false }
    function toggle() { isOpen = !isOpen; if (isOpen) Services.Notifications.activeToasts = [] }

    // Backdrop click-outside-to-close (covers the screen behind the panel)
    Item {
        anchors.fill: parent
        MouseArea {
            anchors.fill: parent
            onClicked: panel.close()
        }
    }

    Rectangle {
        id: surface
        anchors.fill: parent
        anchors.margins: 8
        color: Theme.Mocha.base
        opacity: 0.94
        radius: Theme.Mocha.radiusLg
        border.width: 1
        border.color: Theme.Mocha.surface1

        Text {
            anchors.centerIn: parent
            text: "Panel — content coming in tasks 4.2+"
            color: Theme.Mocha.text
            font.family: Theme.Mocha.fontFamily
        }
    }
}
```

- [ ] **Step 2: Wire panel into shell.qml**

Replace `config/quickshell/shell.qml`:
```qml
import Quickshell
import Quickshell.Wayland
import QtQuick
import "theme" as Theme
import "services" as Services

ShellRoot {
    id: root

    Component.onCompleted: {
        Services.Notifications;
        Services.DND;
    }

    Panel { id: panel }
    Toasts {}
}
```

- [ ] **Step 3: Add a temporary keybind to open the panel during dev**

Edit `config/hypr/hypr-config/keybinds.conf`. Add (do NOT remove the existing swaync line yet — that happens in Phase 6):
```
# DEV ONLY — remove during Phase 6 cutover
bind = $mainMod SHIFT, n, exec, qs ipc call panel toggle
```

Quickshell IPC isn't set up until Phase 5, so this binding won't work yet. As an interim, you can call `panel.toggle()` from a debug button. **Skip step 3 if you'd rather wait for Phase 5** — it's optional convenience.

- [ ] **Step 4: Verify the panel shows**

For now, add a manual trigger to `shell.qml` for testing — e.g., set `panel.isOpen: true` directly, run quickshell, see it.

```bash
pkill quickshell 2>/dev/null; quickshell &
sleep 1
# Edit Panel.qml temporarily so visible: true
qs reload
```
Expected: a 580×720 centered card appears at the top with placeholder text. Click anywhere outside the card → it should close (when `isOpen` is wired up).

Revert any `visible: true` debug change before committing.

```bash
pkill quickshell
```

- [ ] **Step 5: Commit**

```bash
git add config/quickshell/Panel.qml config/quickshell/shell.qml
git commit -m "Add Panel scaffolding with backdrop close"
```

---

## Task 4.2: Toggle widget

**Files:**
- Create: `config/quickshell/widgets/Toggle.qml`
- Modify: `config/quickshell/widgets/qmldir`

- [ ] **Step 1: Write the toggle**

Create `config/quickshell/widgets/Toggle.qml`:
```qml
import QtQuick
import QtQuick.Layouts
import "../theme" as Theme

Rectangle {
    id: tile

    property string label: ""
    property string icon: ""      // unicode glyph (Nerd Font / Material)
    property bool active: false
    property bool warn: false
    signal clicked()

    implicitWidth: 100
    implicitHeight: 56
    radius: Theme.Mocha.radiusMd
    color: warn ? Qt.alpha(Theme.Mocha.peach, 0.25)
         : active ? Qt.alpha(Theme.Mocha.blue, 0.25)
         : Theme.Mocha.surface0
    border.width: 1
    border.color: warn ? Theme.Mocha.peach
                : active ? Theme.Mocha.blue
                : Theme.Mocha.surface1

    RowLayout {
        anchors.fill: parent
        anchors.margins: Theme.Mocha.spaceSm
        spacing: Theme.Mocha.spaceXs

        Text {
            text: tile.icon
            color: tile.warn ? Theme.Mocha.peach
                 : tile.active ? Theme.Mocha.blue
                 : Theme.Mocha.subtext0
            font.pixelSize: 16
        }
        Text {
            text: tile.label
            color: Theme.Mocha.text
            font.family: Theme.Mocha.fontFamily
            font.pixelSize: Theme.Mocha.fontSm
            Layout.fillWidth: true
            elide: Text.ElideRight
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: tile.clicked()
    }
}
```

- [ ] **Step 2: Register**

Append to `config/quickshell/widgets/qmldir`:
```
Toggle 1.0 Toggle.qml
```

- [ ] **Step 3: Commit**

```bash
git add config/quickshell/widgets/Toggle.qml config/quickshell/widgets/qmldir
git commit -m "Add Toggle widget"
```

---

## Task 4.3: Slider widget

**Files:**
- Create: `config/quickshell/widgets/Slider.qml`
- Modify: `config/quickshell/widgets/qmldir`

- [ ] **Step 1: Write the slider**

Create `config/quickshell/widgets/Slider.qml`:
```qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../theme" as Theme

RowLayout {
    id: row

    property string icon: ""
    property real value: 0       // 0..1
    property color tint: Theme.Mocha.blue
    signal changed(real v)

    spacing: Theme.Mocha.spaceSm

    Text {
        text: row.icon
        color: Theme.Mocha.subtext0
        font.pixelSize: 14
    }

    Slider {
        id: s
        Layout.fillWidth: true
        from: 0
        to: 1
        value: row.value
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
            width: 12; height: 12; radius: 6
            color: row.tint
        }
    }

    Text {
        text: Math.round(row.value * 100) + "%"
        color: Theme.Mocha.subtext0
        font.family: Theme.Mocha.fontFamily
        font.pixelSize: Theme.Mocha.fontSm
        Layout.preferredWidth: 36
        horizontalAlignment: Text.AlignRight
    }
}
```

- [ ] **Step 2: Register**

Append to `config/quickshell/widgets/qmldir`:
```
Slider 1.0 Slider.qml
```

- [ ] **Step 3: Commit**

```bash
git add config/quickshell/widgets/Slider.qml config/quickshell/widgets/qmldir
git commit -m "Add Slider widget"
```

---

## Task 4.4: ToggleTile (2×4 grid of 8 toggles)

**Files:**
- Create: `config/quickshell/widgets/ToggleTile.qml`
- Modify: `config/quickshell/widgets/qmldir`

- [ ] **Step 1: Write the tile**

Create `config/quickshell/widgets/ToggleTile.qml`:
```qml
import QtQuick
import QtQuick.Layouts
import "../theme" as Theme
import "../services" as Services

Rectangle {
    id: tile
    color: Theme.Mocha.mantle
    radius: Theme.Mocha.radiusMd
    implicitHeight: grid.implicitHeight + Theme.Mocha.spaceSm * 2

    GridLayout {
        id: grid
        anchors.fill: parent
        anchors.margins: Theme.Mocha.spaceSm
        columns: 2
        rowSpacing: Theme.Mocha.spaceXs
        columnSpacing: Theme.Mocha.spaceXs

        Toggle {
            Layout.fillWidth: true
            icon: ""; label: "Wi-Fi"
            active: Services.Network.wifiEnabled
            onClicked: Services.Network.toggleWifi()
        }
        Toggle {
            Layout.fillWidth: true
            icon: ""; label: "Bluetooth"
            active: Services.Bluetooth.powered
            onClicked: Services.Bluetooth.toggle()
        }
        Toggle {
            Layout.fillWidth: true
            icon: ""; label: "DND"
            active: Services.DND.enabled
            onClicked: Services.Notifications.toggleDnd()
        }
        Toggle {
            Layout.fillWidth: true
            icon: ""; label: "Night"
            warn: Services.NightLight.active
            onClicked: Services.NightLight.toggle()
        }
        Toggle {
            Layout.fillWidth: true
            icon: ""; label: "Mute"
            active: Services.Audio.muted
            onClicked: Services.Audio.toggleMute()
        }
        Toggle {
            Layout.fillWidth: true
            icon: ""; label: "Mic"
            active: Services.Audio.micMuted
            onClicked: Services.Audio.toggleMicMute()
        }
        Toggle {
            Layout.fillWidth: true
            icon: "󰒳"; label: "Idle"
            active: Services.Idle.inhibited
            onClicked: Services.Idle.toggle()
        }
        Toggle {
            Layout.fillWidth: true
            icon: ""; label: Services.InputMethod.shortLabel
            onClicked: Services.InputMethod.toggle()
        }
    }
}
```

- [ ] **Step 2: Register**

Append to `config/quickshell/widgets/qmldir`:
```
ToggleTile 1.0 ToggleTile.qml
```

- [ ] **Step 3: Commit**

```bash
git add config/quickshell/widgets/ToggleTile.qml config/quickshell/widgets/qmldir
git commit -m "Add ToggleTile (2x4 grid of 8 toggles)"
```

---

## Task 4.5: SliderTile (volume + brightness)

**Files:**
- Create: `config/quickshell/widgets/SliderTile.qml`
- Modify: `config/quickshell/widgets/qmldir`

- [ ] **Step 1: Write the tile**

Create `config/quickshell/widgets/SliderTile.qml`:
```qml
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
            icon: ""
            tint: Theme.Mocha.sapphire
            value: Services.Audio.volume
            onChanged: (v) => Services.Audio.setVolume(v)
        }
        Slider {
            Layout.fillWidth: true
            icon: ""
            tint: Theme.Mocha.peach
            value: Services.Brightness.value
            onChanged: (v) => Services.Brightness.setValue(v)
        }
    }
}
```

- [ ] **Step 2: Register**

Append to `config/quickshell/widgets/qmldir`:
```
SliderTile 1.0 SliderTile.qml
```

- [ ] **Step 3: Commit**

```bash
git add config/quickshell/widgets/SliderTile.qml config/quickshell/widgets/qmldir
git commit -m "Add SliderTile (volume + brightness)"
```

---

## Task 4.6: SessionTile (5 power buttons)

**Files:**
- Create: `config/quickshell/widgets/SessionTile.qml`
- Modify: `config/quickshell/widgets/qmldir`

- [ ] **Step 1: Write the tile**

Create `config/quickshell/widgets/SessionTile.qml`:
```qml
import QtQuick
import QtQuick.Layouts
import "../theme" as Theme
import "../services" as Services

Rectangle {
    color: Theme.Mocha.mantle
    radius: Theme.Mocha.radiusMd
    implicitHeight: row.implicitHeight + Theme.Mocha.spaceSm * 2

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.margins: Theme.Mocha.spaceSm
        spacing: Theme.Mocha.spaceXs

        component PwrBtn: Rectangle {
            property string icon: ""
            property bool danger: false
            signal clicked()
            Layout.fillWidth: true
            implicitHeight: 36
            radius: Theme.Mocha.radiusSm
            color: ma.containsMouse
                ? (danger ? Qt.alpha(Theme.Mocha.red, 0.25) : Theme.Mocha.surface0)
                : "transparent"
            Text {
                anchors.centerIn: parent
                text: parent.icon
                color: parent.danger ? Theme.Mocha.red : Theme.Mocha.subtext0
                font.pixelSize: 14
            }
            MouseArea {
                id: ma
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: parent.clicked()
            }
        }

        PwrBtn { icon: "";  onClicked: Services.Hyprland.dispatch("exec hyprlock") }
        PwrBtn { icon: "󰍃"; onClicked: Services.Hyprland.dispatch("exit") }
        PwrBtn { icon: "󰤄"; onClicked: Services.Hyprland.dispatch("exec systemctl suspend") }
        PwrBtn { icon: "";  onClicked: Services.Hyprland.dispatch("exec reboot") }
        PwrBtn { icon: "";  danger: true; onClicked: Services.Hyprland.dispatch("exec shutdown now") }
    }
}
```

- [ ] **Step 2: Register**

Append to `config/quickshell/widgets/qmldir`:
```
SessionTile 1.0 SessionTile.qml
```

- [ ] **Step 3: Commit**

```bash
git add config/quickshell/widgets/SessionTile.qml config/quickshell/widgets/qmldir
git commit -m "Add SessionTile (lock/logout/sleep/reboot/power)"
```

---

## Task 4.7: NotifList (5 render modes: empty / single / few / grouped / many)

**Files:**
- Create: `config/quickshell/widgets/NotifList.qml`
- Modify: `config/quickshell/widgets/qmldir`

- [ ] **Step 1: Write the list**

Create `config/quickshell/widgets/NotifList.qml`:
```qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../theme" as Theme
import "../services" as Services

Item {
    id: root
    implicitHeight: 360

    // Compute render mode
    readonly property int count: Services.Notifications.notifs.length
    readonly property string mode:
          count === 0 ? "empty"
        : count === 1 ? "single"
        : count > 12  ? "many"
        : root._groupedCount() > 0 ? "grouped"
        : "few"

    function _groupedCount() {
        const apps = new Set(Services.Notifications.notifs.map(n => n.appName))
        return Services.Notifications.notifs.length - apps.size > 0 ? apps.size : 0
    }

    // Header
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
            text: "󰆴 clear"
            color: Theme.Mocha.subtext0
            font.family: Theme.Mocha.fontFamily
            font.pixelSize: Theme.Mocha.fontSm
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Services.Notifications.clearAll()
            }
        }
    }

    // Empty state
    Item {
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        visible: root.mode === "empty"
        Column {
            anchors.centerIn: parent
            spacing: Theme.Mocha.spaceSm
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: ""
                color: Theme.Mocha.overlay0
                font.pixelSize: 48
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "No notifications"
                color: Theme.Mocha.overlay0
                font.family: Theme.Mocha.fontFamily
                font.pixelSize: Theme.Mocha.fontSm
            }
        }
    }

    // List (single / few / many / grouped — all render as scrollable list)
    ScrollView {
        anchors.top: header.bottom
        anchors.topMargin: Theme.Mocha.spaceSm
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        visible: root.mode !== "empty"
        clip: true

        ColumnLayout {
            width: root.width
            spacing: Theme.Mocha.spaceSm

            Repeater {
                model: Services.Notifications.notifs
                delegate: NCard {
                    Layout.fillWidth: true
                    entry: modelData
                    onDismissed: Services.Notifications.dismiss(modelData.id)
                    onActionInvoked: (actionId) => modelData.notification?.invokeAction(actionId)
                }
            }
        }
    }
}
```

Note: grouped collapse-by-app is a v1.x polish — for now `grouped` mode renders as a flat list. Mark this in the spec's "Known gaps" if needed.

- [ ] **Step 2: Register**

Append to `config/quickshell/widgets/qmldir`:
```
NotifList 1.0 NotifList.qml
```

- [ ] **Step 3: Commit**

```bash
git add config/quickshell/widgets/NotifList.qml config/quickshell/widgets/qmldir
git commit -m "Add NotifList widget (empty/list render modes)"
```

---

## Task 4.8: HeroMpris widget (album art + info + controls)

**Files:**
- Create: `config/quickshell/widgets/HeroMpris.qml`
- Modify: `config/quickshell/widgets/qmldir`

- [ ] **Step 1: Write the hero**

Create `config/quickshell/widgets/HeroMpris.qml`:
```qml
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
            Layout.preferredWidth: 56; Layout.preferredHeight: 56
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
                text: ""
                color: Theme.Mocha.overlay0
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
                font.weight: Font.Medium
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
                Text { anchors.centerIn: parent; text: parent.icon; color: Theme.Mocha.text }
                MouseArea { id: ma2; anchors.fill: parent; hoverEnabled: true; onClicked: parent.clicked() }
            }
            PB { icon: ""; onClicked: hero.player?.previous() }
            PB { icon: hero.player?.playbackState === 1 ? "" : "";
                 onClicked: hero.player?.togglePlaying() }
            PB { icon: ""; onClicked: hero.player?.next() }
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
```

Note: `playbackState === 1` assumes `MprisPlaybackState.Playing === 1`. Verify against Quickshell docs — names may be `MprisPlaybackState.Playing` directly.

- [ ] **Step 2: Register**

Append to `config/quickshell/widgets/qmldir`:
```
HeroMpris 1.0 HeroMpris.qml
```

- [ ] **Step 3: Commit**

```bash
git add config/quickshell/widgets/HeroMpris.qml config/quickshell/widgets/qmldir
git commit -m "Add HeroMpris widget"
```

---

## Task 4.9: PlayerTabs (multi-player switcher)

**Files:**
- Create: `config/quickshell/widgets/PlayerTabs.qml`
- Modify: `config/quickshell/widgets/qmldir`

- [ ] **Step 1: Write the tabs**

Create `config/quickshell/widgets/PlayerTabs.qml`:
```qml
import QtQuick
import QtQuick.Layouts
import "../theme" as Theme
import "../services" as Services

Item {
    visible: Services.Mpris.players.length > 1
    implicitHeight: visible ? 22 : 0

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.Mocha.spaceMd
        spacing: Theme.Mocha.spaceSm

        Repeater {
            model: Services.Mpris.players
            delegate: Rectangle {
                property bool isActive: modelData === Services.Mpris.activePlayer
                implicitWidth: tabText.implicitWidth + 16
                implicitHeight: 20
                radius: 10
                color: isActive ? Theme.Mocha.surface0 : "transparent"

                Text {
                    id: tabText
                    anchors.centerIn: parent
                    text: modelData.identity ?? "Player"
                    color: isActive ? Theme.Mocha.text : Theme.Mocha.subtext0
                    font.family: Theme.Mocha.fontFamily
                    font.pixelSize: Theme.Mocha.fontSm - 1
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

- [ ] **Step 2: Register**

Append to `config/quickshell/widgets/qmldir`:
```
PlayerTabs 1.0 PlayerTabs.qml
```

- [ ] **Step 3: Commit**

```bash
git add config/quickshell/widgets/PlayerTabs.qml config/quickshell/widgets/qmldir
git commit -m "Add PlayerTabs multi-player switcher"
```

---

## Task 4.10: Panel final assembly

**Files:**
- Modify: `config/quickshell/Panel.qml`

- [ ] **Step 1: Replace Panel.qml with the full composition**

Replace `config/quickshell/Panel.qml`:
```qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "theme" as Theme
import "services" as Services
import "widgets" as Widgets

PanelWindow {
    id: panel
    property bool isOpen: false

    anchors.top: true
    margins.top: 38
    implicitWidth: 580
    implicitHeight: 720
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    visible: isOpen
    exclusiveZone: 0

    function open()   { isOpen = true; Services.Notifications.activeToasts = [] }
    function close()  { isOpen = false }
    function toggle() { isOpen ? close() : open() }

    // Backdrop
    MouseArea { anchors.fill: parent; onClicked: panel.close() }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 8
        color: Theme.Mocha.base
        opacity: 0.94
        radius: Theme.Mocha.radiusLg
        border.width: 1
        border.color: Theme.Mocha.surface1

        MouseArea { anchors.fill: parent; onClicked: {} /* swallow */ }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.Mocha.spaceMd
            spacing: Theme.Mocha.spaceMd

            Widgets.HeroMpris { Layout.fillWidth: true }
            Widgets.PlayerTabs { Layout.fillWidth: true }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Theme.Mocha.spaceMd

                // Left rail
                ColumnLayout {
                    Layout.preferredWidth: 220
                    Layout.fillHeight: true
                    spacing: Theme.Mocha.spaceSm

                    Widgets.ToggleTile { Layout.fillWidth: true }
                    Widgets.SliderTile { Layout.fillWidth: true }
                    Widgets.SessionTile { Layout.fillWidth: true }
                    Item { Layout.fillHeight: true }
                }

                // Right column (notifications)
                Widgets.NotifList {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }
        }
    }
}
```

- [ ] **Step 2: Verify visually**

For testing, temporarily set `isOpen: true` in Panel.qml, then:
```bash
pkill swaync; pkill quickshell 2>/dev/null
quickshell &
sleep 1
notify-send "Test" "Notification body"
mpv --no-video https://example.com/something.mp3 &   # for MPRIS hero
```
Expected: full panel renders — hero (with art/title/controls if MPRIS active), 2×4 toggle grid (with live state), 2 sliders, 5 power buttons, notification list on the right.

Revert `isOpen: true` before committing.

```bash
pkill quickshell; pkill mpv; swaync &
```

- [ ] **Step 3: Commit**

```bash
git add config/quickshell/Panel.qml
git commit -m "Assemble full Panel (hero + sectioned body + notification column)"
```

---

# Phase 5 — IPC + Waybar bridge

## Task 5.1: IPC handlers + signal emitter on state change

**Files:**
- Modify: `config/quickshell/shell.qml`
- Modify: `config/quickshell/services/Notifications.qml`

- [ ] **Step 1: Add IPC handlers in shell.qml**

Replace `config/quickshell/shell.qml`:
```qml
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import "theme" as Theme
import "services" as Services

ShellRoot {
    id: root

    Component.onCompleted: {
        Services.Notifications;
        Services.DND;
    }

    Panel { id: panel }
    Toasts {}

    IpcHandler {
        target: "panel"
        function toggle(): void { panel.toggle() }
        function open(): void { panel.open() }
        function close(): void { panel.close() }
    }

    IpcHandler {
        target: "notifications"
        function toggleDnd(): void { Services.Notifications.toggleDnd() }
        function clearAll(): void { Services.Notifications.clearAll() }
        function waybar(): string { return Services.Notifications.waybarLine() }
    }
}
```

- [ ] **Step 2: Add SIGRTMIN+8 emitter in Notifications.qml**

Append to `config/quickshell/services/Notifications.qml` inside the root `QtObject`:
```qml
Process {
    id: waybarSignal
    command: ["pkill", "-SIGRTMIN+8", "waybar"]
}

Connections {
    target: root
    function onStateChanged() { waybarSignal.running = true }
}

property Connections _dndWatch: Connections {
    target: Services.DND
    function onEnabledChanged() { root.stateChanged() }
}
```

(Place the `Process { id: waybarSignal ... }` and the two `Connections` inside the `QtObject {}` block; QML allows multiple non-property children.)

- [ ] **Step 3: Verify IPC works**

```bash
pkill quickshell 2>/dev/null; quickshell &
sleep 1
qs ipc call panel toggle      # panel should appear
qs ipc call panel toggle      # and disappear
qs ipc call notifications waybar    # should print a JSON line
notify-send test body
qs ipc call notifications waybar    # JSON now shows count: 1
qs ipc call notifications toggleDnd
qs ipc call notifications waybar    # JSON now shows dnd:true class
qs ipc call notifications clearAll
pkill quickshell
```
Expected: each call works without error.

- [ ] **Step 4: Commit**

```bash
git add config/quickshell/shell.qml config/quickshell/services/Notifications.qml
git commit -m "Add IPC handlers (panel + notifications) and waybar refresh signal"
```

---

## Task 5.2: Replace waybar custom/swaync with custom/notifications

**Files:**
- Modify: `config/waybar/modules/modules.jsonc`

- [ ] **Step 1: Replace the swaync block**

Edit `config/waybar/modules/modules.jsonc`. Find the `"custom/swaync": { ... }` block (currently lines 207-214) and replace with:
```jsonc
"custom/notifications": {
    "exec":           "qs ipc call notifications waybar",
    "on-click":       "qs ipc call panel toggle",
    "on-click-right": "qs ipc call notifications toggleDnd",
    "signal":         8,
    "return-type":    "json",
    "format":         "{}",
    "tooltip":        true
}
```

Also find any reference in `modules-center` (config.jsonc) or the `group/middle` block. In `modules.jsonc:179`, replace `"custom/swaync"` with `"custom/notifications"`.

- [ ] **Step 2: Add a style rule (optional)**

Edit `config/waybar/style.css`. Find the existing `#custom-swaync` rules (around lines 92-108) and either:
- Rename them to `#custom-notifications` and adjust state classes from `dnd-inhibited-notification` to `dnd`, from `inhibited-notification` to `has-notifs`, etc.
- Or leave the swaync rules in place and add new `#custom-notifications` rules.

For now, add minimal rules that match the new class names. Append:
```css
#custom-notifications {
    padding: 0 8px;
}
#custom-notifications.dnd {
    color: #6c7086;
}
#custom-notifications.has-notifs {
    color: #f9e2af;
}
```

- [ ] **Step 3: Verify (deferred until Phase 6 — needs Quickshell running)**

We'll verify the bridge end-to-end in Phase 6 once Quickshell is the only notifications daemon.

- [ ] **Step 4: Commit**

```bash
git add config/waybar/modules/modules.jsonc config/waybar/style.css
git commit -m "Switch waybar to custom/notifications driven by Quickshell IPC"
```

---

# Phase 6 — Cutover

## Task 6.1: Cutover commit (autostart, keybinds, package removal, dir deletion)

**Files:**
- Modify: `config/hypr/hyprland.conf`
- Modify: `config/hypr/hypr-config/keybinds.conf`
- Modify: `system/hyprland.nix`
- Modify: `profile/nox-desktop/home.nix`
- Modify: `profile/nox-work/home.nix`
- Delete: `config/swaync/` (entire directory)

- [ ] **Step 1: Swap exec-once in hyprland.conf**

Edit `config/hypr/hyprland.conf:53`. Replace:
```
exec-once = waybar & hyprpaper & swaync & hypridle & hyprsunset & nextcloud & blueman-applet & nm-applet & voxd --tray
```
with:
```
exec-once = waybar & hyprpaper & quickshell & hypridle & hyprsunset & nextcloud & blueman-applet & nm-applet & voxd --tray
```

- [ ] **Step 2: Update keybinds**

Edit `config/hypr/hypr-config/keybinds.conf`. Replace lines 103-107:
```
# Toggle notifications
bind = $mainMod, n, exec, qs ipc call panel toggle

# Clear notifications
bind = $mainMod, c, exec, qs ipc call notifications clearAll
```
Also remove the `# DEV ONLY` line added in Task 4.1 if it's still there.

- [ ] **Step 3: Remove swaync from system packages**

Edit `system/hyprland.nix`. In `environment.systemPackages`, remove the `swaynotificationcenter` line:
```nix
environment.systemPackages = with pkgs; [
    hyprpicker
    hyprpaper
    hyprsunset
    hyprshot
    # swaynotificationcenter   ← DELETE this line
    inputs.nixpkgs-unstable.legacyPackages.${pkgs.system}.quickshell
    wofi
    nautilus
    hyprpolkitagent
];
```

- [ ] **Step 4: Remove .config/swaync symlinks**

Edit `profile/nox-desktop/home.nix` and `profile/nox-work/home.nix`. In each, delete the line:
```nix
".config/swaync".source = ../../config/swaync;
```

- [ ] **Step 5: Delete the swaync config directory**

```bash
rm -rf /home/nox/nixos/config/swaync
```

- [ ] **Step 6: Stage everything and rebuild**

```bash
cd /home/nox/nixos
git add -A config/swaync   # captures the deletion
git add config/hypr/hyprland.conf \
        config/hypr/hypr-config/keybinds.conf \
        system/hyprland.nix \
        profile/nox-desktop/home.nix \
        profile/nox-work/home.nix
```

Verify with `git status` that only the cutover-related files are staged. **Pre-existing staged files like `system/captive-portal.nix` and `system/syncthing.nix` should NOT be in this commit — leave them staged but uncommitted.**

```bash
sudo nixos-rebuild switch --flake /home/nox/nixos
```
Expected: rebuild succeeds. Hyprland is currently still running the old session; the changes apply on next launch or reload.

- [ ] **Step 7: Reload Hyprland to apply autostart change**

Easiest: log out and log back in (cleanest test of `exec-once`).

Alternative: kill swaync manually, start quickshell, reload hyprland config for the keybind:
```bash
pkill swaync
quickshell &
hyprctl reload
```

- [ ] **Step 8: Smoke test**

- Press `SUPER+N` → panel opens at top-center, click outside → closes
- `notify-send "Hello" "Body"` → toast appears top-right, auto-dismisses after 8s
- `notify-send -u critical "Alert" "stays"` → red-bordered toast that doesn't auto-dismiss
- Click waybar notification icon → panel toggles
- Right-click waybar notification icon → DND toggles (waybar icon changes immediately, confirming SIGRTMIN+8 works)
- `SUPER+C` → clears all notifications
- Click each toggle in the panel → state reflects in waybar / system (volume changes, idle inhibitor toggles `${XDG_RUNTIME_DIR}/idle-suspend.inhibit`, etc.)

- [ ] **Step 9: Commit only the cutover files**

```bash
git commit -m "Cut over from SwayNC to Quickshell" -- \
    config/hypr/hyprland.conf \
    config/hypr/hypr-config/keybinds.conf \
    system/hyprland.nix \
    profile/nox-desktop/home.nix \
    profile/nox-work/home.nix \
    config/swaync
```

Verify with `git log -1 --stat` that the commit only contains those files (plus all the deleted `config/swaync/*` files).

- [ ] **Step 10: Tag or note the rollback point**

If anything breaks later, `nixos-rebuild --rollback` reverts the system generation. The previous git commit (HEAD~1) is the last working pre-cutover state if you want to `git revert` instead.

---

# Known v1 gaps (deferred)

These match the spec's Non-goals + a few discovered during planning. None block shipping.

| Gap | Why deferred | Workaround |
|---|---|---|
| Inline-reply text input on toasts | Layer-shell focus-grab footgun (spec non-goal) | Action buttons still work |
| Grouped notifications (collapse-by-app) | Real implementation work; flat list works | Right column renders all notifs flat; user can `clear all` |
| Swipe-to-dismiss on toasts | Non-trivial PointerHandler + animation | `×` button on each card dismisses |
| Multi-monitor toasts | v1 = primary only | Toasts appear on primary screen always |
| Notification persistence across reboot | In-memory only | Reboot clears notification list |
| AI chat / OCR / Lens sidebar | Out of scope per spec | Future v2+ work; service-singleton boundary leaves room |
| Quickshell + Qt-update Qt churn | User update cadence is low; rollback path documented | `nixos-rebuild --rollback` |

Each gap can be a discrete follow-up task. None require structural changes to v1.

---

# Done

V15 shell is live on both profiles. Verification covered:
- Panel opens centered top, closes on outside click
- Toasts appear top-right with priority-aware variants (low / normal / critical) and auto-dismiss
- Waybar notification icon reflects count + DND state instantly (via SIGRTMIN+8)
- All 8 toggles functional (Wi-Fi, BT, DND, Night, Mute, Mic, Idle, IM)
- Both sliders adjust volume / brightness
- Session row dispatches lock / logout / sleep / reboot / shutdown
- MPRIS hero shows for any active player; tabs show when >1 player
- `SUPER+N` opens panel, `SUPER+C` clears notifications
- SwayNC fully removed; rollback path is `nixos-rebuild --rollback` or `git revert HEAD`
