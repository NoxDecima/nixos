# Quickshell Shell — Design Spec

**Date:** 2026-05-23
**Status:** Approved — ready for implementation planning
**Replaces:** SwayNC (control center + notification daemon)

## Goal

Replace SwayNC with a custom Quickshell-based control panel and notification system that implements the V15 design ("MPRIS hero + sectioned Mocha body") from the SwayNC brainstorm zip, with priority-aware top-right toasts and grouped notifications.

## Non-goals (deferred to vN)

- AI chat sidebar (service-singleton boundary planned, no implementation in v1)
- On-screen translation / Google Lens visual search
- Replacing Waybar (Waybar continues to own the top bar)
- Multi-monitor toasts (v1 = primary screen only)
- Inline-reply text input on toasts (action buttons work; the text-entry field is a known Quickshell focus-grab footgun, deferred)

## Decisions log

| # | Decision | Choice |
|---|---|---|
| 1 | Build approach | Study end-4 + DankMaterialShell patterns, write greenfield |
| 2 | v1 scope | Full V15 visual fidelity (panel + toasts + priority variants + grouping) |
| 3 | Service boundaries | Waybar-shareable singletons from day one (clock, tray, UPower registered, not rendered) |
| 4 | Rollout | Hard cutover; one commit; both profiles |
| 5 | Toggle grid layout | 2×4 grid, 8 toggles (added Idle, fcitx5 input method) |
| 6 | Quickshell pinning | Track `nixpkgs-unstable`, no pin; rollback via git/nixos-rebuild |
| 7 | Module organization | Flat (`config/quickshell/{Panel.qml, Toasts.qml, services/, widgets/, theme/}`) |
| 8 | NixOS wiring | Symlink `config/quickshell/` via `home.file`, matches existing pattern (no upstream HM module) |
| 9 | Panel anchor | Top-center (under the waybar center-group "NixOS" button) |
| 10 | Toast anchor | Top-right, 12px from edge, below waybar |
| 11 | Waybar bridge | IPC + `SIGRTMIN+8` signal (instant refresh, zero polling) |
| 12 | Input method (8th toggle) | fcitx5 dbus toggle (EN ↔ JA via Mozc), not xkb layouts |

## Architecture

### Directory layout

```
config/quickshell/
├── shell.qml                   # entry: ScreenWindow + layer-shell wiring + IPC handlers
├── Panel.qml                   # control center (hero + sectioned body)
├── Toasts.qml                  # toast layer (priority-aware)
├── services/
│   ├── Mpris.qml               # multi-player MPRIS singleton
│   ├── Notifications.qml       # notification server + DND + clearAll + waybar JSON
│   ├── Audio.qml               # PipeWire (volume, mute, mic)
│   ├── Brightness.qml          # backlight via brightnessctl
│   ├── Network.qml             # NetworkManager via nmcli
│   ├── Bluetooth.qml           # BlueZ
│   ├── Idle.qml                # idle-suspend.inhibit marker file
│   ├── NightLight.qml          # hyprsunset process state
│   ├── DND.qml                 # local boolean, gates toast rendering
│   ├── InputMethod.qml         # fcitx5 dbus (Activate/Deactivate/Toggle, CurrentInputMethod)
│   ├── Hyprland.qml            # Quickshell.Hyprland wrapper, dispatchers
│   ├── SystemTray.qml          # registered, not rendered in v1
│   ├── SystemClock.qml         # registered, not rendered in v1
│   └── UPower.qml              # registered, not rendered in v1
├── widgets/
│   ├── NCard.qml               # one notification card (shared by panel + toasts)
│   ├── Toggle.qml              # one tile in the 2×4 grid
│   ├── Slider.qml              # volume / brightness row
│   ├── HeroMpris.qml           # album-art + info + controls + tabs
│   └── (more as needed)
└── theme/
    └── Mocha.qml               # Catppuccin Mocha tokens singleton
```

### Entry point — `shell.qml`

- One `LazyLoader` for `Panel.qml` (constructed on first open; keeps startup fast)
- One always-on `Variants` over `Quickshell.primaryScreen` for `Toasts.qml` (v1 = primary only)
- All service singletons registered eagerly
- IPC handlers: `panel.toggle`, `notifications.toggleDnd`, `notifications.clearAll`, `notifications.waybar` (returns JSON for waybar's exec field)

### Layer-shell positioning

| Window | Layer | Anchor | Margin |
|---|---|---|---|
| Panel | `WlrLayerShell.Overlay` | top only (centers horizontally) | top: waybar_height + 8 |
| Toasts | `WlrLayerShell.Overlay` | top + right | top: waybar_height + 4, right: 12 |

Panel anchors top-only (no left/right) so it centers naturally under the waybar center group where the open button lives. Overlay layer keeps both above waybar's top layer, matching current swaync behavior.

### Open / close

- **Keybind**: `SUPER+N` → `qs ipc call panel toggle` (replaces current `swaync-client -t -sw` binding at `config/hypr/hypr-config/keybinds.conf:104`)
- **Keybind**: `SUPER+C` → `qs ipc call notifications clearAll` (replaces current `swaync-client -C -sw` at line 107)
- **Waybar button click**: `qs ipc call panel toggle`
- **Waybar button right-click**: `qs ipc call notifications toggleDnd`
- **Click-outside-to-close**: transparent backdrop layer behind the panel, MouseArea closes on click

### Data flow

UI components are pure renderers. They read from singleton properties via `import "services" as Services` and emit intents back via service methods. No component touches dbus/IPC/processes directly. Same pattern end-4 uses in `services/Ai.qml`.

## Service layer

### Categories

**Quickshell built-ins (thin wrappers, ~5 lines each):**
- `Mpris.qml` wraps `Quickshell.Services.Mpris.MprisWatcher` for the multi-player switcher (Spotify / Firefox / mpv tabs). Exposes a reactive list of players + per-player position polling (working around spec-violating players, per Quickshell MPRIS docs).
- `Notifications.qml` wraps `Quickshell.Services.Notifications.NotificationServer`. Owns:
  - in-memory list of past notifications (panel display)
  - active toasts list (toast display, subset)
  - DND flag (mirrors `DND.qml`)
  - `clearAll()`, `dismiss(id)`, `toggleDnd()` methods
  - `waybarLine()` method returning `{text, tooltip, class}` JSON for waybar
- `Hyprland.qml` wraps `Quickshell.Hyprland` for workspace state + `dispatch()` (powers session row)
- `SystemTray.qml`, `SystemClock.qml`, `UPower.qml` — registered, not rendered in v1

**Dbus / hardware:**
- `Audio.qml` — `Quickshell.Services.Pipewire`, default-sink volume + mute, default-source mic-mute
- `Brightness.qml` — `brightnessctl` via `Process` (no clean QML binding)
- `Network.qml` — `nmcli` via `Process`, polls every 5s + on demand
- `Bluetooth.qml` — `Quickshell.Services.UPower`-style dbus binding or `bluetoothctl` fallback
- `InputMethod.qml` — fcitx5 over dbus (`org.fcitx.Fcitx5 /controller`): `Toggle()`, `CurrentInputMethod()`, state-change signal subscription. Fallback CLI: `fcitx5-remote -t`.

**Local custom state:**
- `Idle.qml` — `FileView` watching `${XDG_RUNTIME_DIR}/idle-suspend.inhibit`. Toggle creates/removes the marker directly from QML. Same file the existing waybar custom module reads.
- `NightLight.qml` — `pgrep hyprsunset` for state, `pkill hyprsunset || hyprsunset &` for toggle (mirroring current swaync button at `config/swaync/config.json:78`)
- `DND.qml` — local boolean property. Notifications service reads it before rendering toasts.

### Shared singleton invariant

Each service exposes a read-only state property + `toggle()` / `set()` methods. No service knows about any other service. `Panel.qml` and `Toasts.qml` are the only things that compose them.

## UI components

### Panel

`Panel.qml` is 580×720 (matching current swaync), centered top.

```
Panel.qml
├── Hero.qml                   (collapses to height 0 when no MPRIS player)
│   ├── HeroArt                (album art, falls back to disc icon)
│   ├── HeroInfo               (title + artist + position bar with current/total)
│   ├── HeroControls           (prev / play-pause / next → MprisService)
│   └── PlayerTabs             (renders only when >1 active player)
│
└── SectionedBody              (2-col grid, 220px left rail + flex right)
    ├── Left rail
    │   ├── ToggleTile         (2×4 grid)
    │   ├── SliderTile         (volume row + brightness row)
    │   └── SessionTile        (lock | logout | sleep | reboot | power)
    │
    └── Right column
        ├── NotifHeader        ("Notifications · N new" + clear-all)
        └── NotifList          (5 render modes — see below)
```

**Toggle grid (2×4):**

| Row | Left | Right |
|---|---|---|
| 1 | Wi-Fi | Bluetooth |
| 2 | DND | Night light |
| 3 | Mute (sink) | Mic mute (source) |
| 4 | Idle suspend | Input method (EN / あ) |

Each toggle props: `icon`, `label`, `active`, `warn`, `onClick`. States: default / on / warn (the orange "Night" state in V15).

**NotifList render modes** (picked by NotifService state):
- `empty` — bell icon + "No notifications" centered
- `single` — one NCard
- `few` — list of NCard, 8px gap
- `grouped` — collapsed by app when >3 from same source; expand on click
- `many` — virtual scroll with sticky day separators when >12 total

### Toast layer

`Toasts.qml` is a separate layer-shell window, top-right, 12px from edge, below waybar.

- Vertical column, 8px gap, up to 3 visible NCards
- Stack grows downward (newest top, oldest bottom)
- When >3 queued, oldest collapse to a `+N more` pill; click → opens panel
- Hover any toast → pause its progress bar
- Swipe-right → dismiss
- Click body → invoke default action + dismiss
- Click action button → invoke + dismiss

**Priority variants:**

| Urgency | Visual | Timeout |
|---|---|---|
| low | compact single-line, no body, no actions, dim icon, no progress bar | 4s (matches current `timeout-low`) |
| normal | full NCard with body + actions + thin progress bar | 8s (matches current `timeout`) |
| critical | full NCard + 1px red ring + soft red glow + no progress bar | 0 (never auto-dismiss; requires click) |

**Progress bar scope:** `NCard.showProgress` defaults to `false`. Only `Toasts.qml` passes `showProgress: true`. Panel `NotifList` renders cards without a bar — they don't auto-dismiss in the panel, so a countdown there would be a lie.

**Panel-toast coordination:**
- Panel opens → all visible toasts hide immediately
- New notifications while panel open → go straight to panel `NotifList`, no toast
- DND on → no toasts render; notifications still accumulate silently in the panel list

## Waybar coordination

### The bridge pattern (IPC + signal)

For state that Quickshell owns but Waybar displays (DND, notif count, panel-toggle clicks), Quickshell exposes IPC handlers and signals waybar to refresh:

**Quickshell side** — on every DND or notif-count change:
```qml
Process {
    command: ["pkill", "-SIGRTMIN+8", "waybar"]
}
```

**Waybar side** — replace `custom/swaync` in `config/waybar/modules/modules.jsonc:207-214` with:
```jsonc
"custom/notifications": {
  "exec":           "qs ipc call notifications waybar",   // returns JSON
  "on-click":       "qs ipc call panel toggle",
  "on-click-right": "qs ipc call notifications toggleDnd",
  "signal":         8,
  "return-type":    "json",
  "format":         "{}"
}
```

`SIGRTMIN+8` is **not killing waybar** — it's the real-time signal waybar listens for as a refresh trigger for `custom` modules with `"signal": 8` set ([waybar custom module docs](https://github.com/Alexays/Waybar/wiki/Module:-Custom)). Same pattern end-4 / DMS / many shells use.

### Shared sources (no bridge needed)

These read the same canonical state from waybar and Quickshell; no risk of drift:

| Service | Canonical source |
|---|---|
| Audio (vol/mute, mic-mute) | PipeWire dbus |
| Brightness | `/sys/class/backlight/` |
| Network | NetworkManager dbus |
| Bluetooth | BlueZ dbus |
| MPRIS | MPRIS2 dbus |
| Idle inhibitor | `${XDG_RUNTIME_DIR}/idle-suspend.inhibit` |
| Night light | `pgrep hyprsunset` |

## Theming

`theme/Mocha.qml` is a `Singleton` exposing Catppuccin Mocha tokens as QML properties (colors, radii, spacings). Direct port of `config/swaync/mocha_config.css`.

**Hard rule:** no hardcoded colors in any other QML file. Every component imports `theme/Mocha.qml` and references via `Theme.Mocha.<token>`. Catppuccin Frappe / Latte variants become a one-file swap.

**Typography:** Inter (UI) + JetBrains Mono (any numeric / monospace). Already in `home/gtk.nix` / system fonts.

**Blur:** Qt `MultiEffect`-based gaussian blur, 24px radius behind panel and toast surfaces. Panel surface = `Mocha.base` at ~88% opacity. The V15 glass feel.

## NixOS integration & cutover

### Files changed (one commit)

| File | Change |
|---|---|
| `config/quickshell/` | **NEW** — directory with all QML files |
| `config/swaync/` | **REMOVED** entirely |
| `config/waybar/modules/modules.jsonc` | **EDIT** — replace `custom/swaync` block with `custom/notifications` |
| `config/hypr/hyprland.conf:53` | **EDIT** — `exec-once`: `swaync` → `quickshell` |
| `config/hypr/hypr-config/keybinds.conf:104,107` | **EDIT** — `swaync-client` → `qs ipc call` |
| `system/hyprland.nix` | **EDIT** — drop `swaynotificationcenter`, add `quickshell` from `nixpkgs-unstable` |
| `profile/nox-desktop/home.nix` | **EDIT** — drop `.config/swaync` symlink, add `.config/quickshell` |
| `profile/nox-work/home.nix` | **EDIT** — same |

### Package pull

```nix
# system/hyprland.nix
environment.systemPackages = with pkgs; [
    hyprpicker hyprpaper hyprsunset hyprshot
    inputs.nixpkgs-unstable.legacyPackages.${pkgs.system}.quickshell
    wofi nautilus hyprpolkitagent
];
```

### Rollback path

Single commit; `nixos-rebuild --rollback` restores the prior generation (SwayNC working). Git history holds `config/swaync/` for restoration.

## Known gaps in v1

- **Inline-reply text input** on toasts — action buttons work, but the inline-reply field is deferred (focus-grab footgun in layer-shell)
- **Multi-monitor toasts** — v1 renders on primary screen only
- **Notification persistence across reboot** — v1 keeps in-memory only; not persisted to disk
- **AI chat / OCR / Lens** — explicitly out of scope; service-singleton boundary leaves room

## Risks

| Risk | Mitigation |
|---|---|
| Qt 6.x upgrade in nixpkgs-unstable segfaults Quickshell ([end-4 #3159](https://github.com/end-4/dots-hyprland/issues/3159)) | User update cadence is low; rollback via `nixos-rebuild --rollback`. Escalation path: pin Quickshell to a known-good `nixpkgs-unstable` rev as a separate flake input. |
| Hard cutover with no notifications until rebuild succeeds | One-command rollback; user accepted explicitly |
| Quickshell tooling (LSP, formatter) widely reported as poor ([ctOS discussion](https://github.com/TSM-061/ctOS/discussions/2)) | Affects dev experience, not runtime. Lean on `qs reload` hot-loop. |
| `Network.qml` is the heaviest non-first-party singleton (`nmcli` polling) | Poll every 5s, refresh-on-demand from panel open; not on the hot path |
| `astal-mpris` ↔ `Quickshell.Services.Mpris` parity for multi-player switcher | Verified: Quickshell's `MprisWatcher` exposes the player list reactively per [docs](https://quickshell.org/docs/v0.2.1/types/Quickshell.Services.Mpris/) |

## References

- V15 design source: `/tmp/swaync-design/` (extracted from `~/Downloads/SwayNC(1).zip`)
- end-4/dots-hyprland Quickshell branch — pattern reference
- DankMaterialShell — pattern reference, NixOS HM module reference
- Quickshell docs: <https://quickshell.org/docs/>
