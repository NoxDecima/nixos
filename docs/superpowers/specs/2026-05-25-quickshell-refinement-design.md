# Quickshell Refinement Round — Design Spec

**Date:** 2026-05-25
**Status:** Approved — ready for implementation planning
**Predecessor:** `2026-05-23-quickshell-shell-design.md` (v1 spec, deleted from repo at commit `95bbe05` but available in git history)

## Goal

Refine the Quickshell shell that landed at commit `174ab8f`: bring its visuals back in line with the V15 mockup, fix a notification body rendering bug, and ship two features that were deferred from v1 (grouped notifications + inline replies).

## Non-goals (still deferred)

- Swipe-to-dismiss on toasts
- Multi-monitor toasts (still primary screen only)
- Notification persistence across reboot
- AI chat / OCR / Google Lens sidebar (future v2+ work)

## Decisions log

| # | Topic | Choice |
|---|---|---|
| 1 | Scope grouping | One spec, four areas bundled (visual polish + bug fix + grouped notifs + inline replies + side-quest click-outside) |
| 2 | Panel width | 640px (was 580) |
| 3 | Panel top margin | 12px (was 38) |
| 4 | Panel background | `Mocha.mantle` at 0.97 opacity (was `Mocha.base` at 0.94) |
| 5 | Panel border color | `Mocha.surface0` (was `surface1`) |
| 6 | Panel drop shadow | `0 14px 36px rgba(0,0,0,0.55)` (was none) |
| 7 | Left rail width | 200px (was 220, matches V15 spec) |
| 8 | Hero album-art size | 50×50 (was 56×56, matches V15) |
| 9 | Hero title font weight | Bold / 700 (was Medium / 500, matches V15) |
| 10 | Internal grid gaps | 10px (left rail spacing), 12px (main grid gap) |
| 11 | Click outside closes | Yes — panel becomes fullscreen `WlrLayerShell`, transparent backdrop closes on click |
| 12 | NCard body bug fix | Remove `Item` wrapper around body Text; MouseArea as direct child of Text |
| 13 | Grouped notifs trigger | `>= 2` notifs from same `appName` |
| 14 | Grouped notifs key | `appName` only (not `category`) |
| 15 | Grouped notifs computation | Widget-side (in `NotifList.qml`), service unchanged |
| 16 | Grouped notif head | Newest notif from that app, full NCard render |
| 17 | Grouped notif pill | `+ N more from [appName]` below the head; click to expand inline |
| 18 | Grouped notif simultaneous-expand | At most one group expanded at a time |
| 19 | Grouped notif `Clear N` | Yes — small "Clear" action on the pill clears the whole group |
| 20 | Toast stack order | Newest at top, oldest at bottom of the visible 3 (flip from current oldest-top) |
| 21 | Toast overflow pill position | Below the stack (older notifs scroll off the bottom) |
| 22 | Group expanded order | Newest just below head, descending |
| 23 | Inline replies — server | Flip `inlineReplySupported: false → true` on NotificationServer |
| 24 | Inline replies — where | Panel only (Toasts get no input field) |
| 25 | Inline replies — visibility | Hidden until user clicks the `Reply` action button |
| 26 | Inline replies — toast UX | Toast's "Reply" action opens the panel and auto-focuses that notif's reply field |

## A — Visual polish

Diff against current files:

### `Panel.qml`

- `implicitWidth: 640` (was 580)
- `margins.top: 12` (was 38)
- Surface `Rectangle`: `color: Theme.Mocha.mantle`, `opacity: 0.97`, `border.color: Theme.Mocha.surface0`
- Left rail `Layout.preferredWidth: 200` (was 220)
- Inner `ColumnLayout.spacing: Theme.Mocha.spaceSm` (was `spaceMd`) — tightens internal vertical rhythm
- Add drop shadow: wrap the inner surface in a container that applies `MultiEffect { shadowEnabled: true; shadowBlur: 1.0; shadowVerticalOffset: 14; shadowOpacity: 0.55 }` (Qt6 native; preferred over the older `DropShadow` from `QtGraphicalEffects`)

### `widgets/HeroMpris.qml`

- Art `Rectangle`: `Layout.preferredWidth: 50; Layout.preferredHeight: 50` (was 56)
- Title `Text`: `font.weight: Font.Bold` (was `Font.Medium`)

### `widgets/SliderTile.qml`, `widgets/ToggleTile.qml`, `widgets/SessionTile.qml`

- Tile `Rectangle.border.width: 1; border.color: Theme.Mocha.surface0` — gives the inner tiles definition matching V15's `.tile` rule (`border: 1px solid var(--surface0)`)

## A2 — Click-outside-closes (side requirement)

`Panel.qml` becomes a fullscreen WlrLayerShell window.

```qml
PanelWindow {
    id: panel
    // Fullscreen — backdrop is the entire screen
    anchors { top: true; left: true; right: true; bottom: true }
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    visible: isOpen
    exclusiveZone: 0

    // Backdrop: any click outside the inner surface closes
    MouseArea {
        anchors.fill: parent
        onClicked: panel.close()
    }

    // Inner surface positioned top-center, fixed size
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

        // Drop shadow via MultiEffect on a containing Item
        // ...
        // ColumnLayout with hero + body + tiles + notifs as today
    }
}
```

**Accepted trade-off**: while the panel is open, clicks on the waybar area hit the backdrop and close the panel instead of falling through to the waybar bell. Practical effect: clicking the waybar bell with the panel open just closes the panel (then a second click reopens). Acceptable because the user explicitly requested any-outside-click-closes semantics.

## B — NCard body bug fix

**Root cause** (commit history reference): Task 2.7 of the v1 plan wrapped the body Text in an `Item` with `anchors.fill: parent` + `implicitHeight: bodyText.implicitHeight` to host a MouseArea for default-action click. The Item's `implicitHeight` depends on `bodyText.implicitHeight`, but `bodyText` is sized by anchors.fill, so its width during layout's first pass is 0 → wrapped text needs an unbounded height → on the first evaluation the Item gets 0 height → body stays invisible. Affects every notification with a non-empty `body` field (Discord, email, most chat apps).

**Fix**: drop the wrapper. Make the body Text a direct ColumnLayout child with `Layout.fillWidth: true`; put the MouseArea as a child of the Text widget.

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

**Verify** after fix: `notify-send "Title" "Body line here"` — both lines must render in both toast and panel.

## C — Grouped notifications

### Where the logic lives

Grouping is **computed in `NotifList.qml`**, not in the Notifications service. Rationale: the service stays a thin reactive owner of a flat list; grouping is a display concern and changes don't ripple through other consumers (the toast layer still wants a flat view).

### Computed model

```javascript
// Pseudo-code that NotifList runs on every notifs change
const seen = {}        // appName -> first index (= newest from that app)
const groups = {}      // appName -> [older notif entries] (already excludes the head)
const rows = []        // ordered list of items to render

for (const n of Services.Notifications.notifs) {
    if (seen[n.appName] === undefined) {
        seen[n.appName] = rows.length
        rows.push({ type: "notif", entry: n, appName: n.appName })
    } else {
        groups[n.appName] = (groups[n.appName] || [])
        groups[n.appName].push(n)
    }
}

// After loop: rows is the visible list (each appName appears once, as the newest).
// For each row where groups[appName].length >= 1, the row gets a pill rendered
// below it and (if expanded) the older entries unfurl as additional NCards.
```

### Expand state

```qml
property string expandedApp: ""   // empty = nothing expanded

function togglePill(appName) {
    expandedApp = (expandedApp === appName) ? "" : appName
}
```

Clicking another group's pill expands the new one (the previous collapses automatically since `expandedApp` is a single string).

### Visual

- **Group head**: standard NCard, full content (the newest notif from that app)
- **Pill** (rendered only when `groups[appName].length >= 1`): a slim Rectangle directly attached to the bottom of the group head, full-width, with `+ N more from [appName]` text on the left and a small `Clear` action on the right; click anywhere on the pill toggles expand (the `Clear` text area accepts a separate MouseArea that calls `clearGroup(appName)`)
- **Expanded list**: each older notif from the group renders as a standard NCard, stacked below the pill, newest first, descending
- When collapsed: the older entries don't render at all
- When the user dismisses an entry inside an expanded group: it removes from `notifs`; the group recomputes; if `groups[appName].length` drops to 0 the pill disappears; if the head was dismissed, the next-newest from that app becomes the new head

### Render-mode integration

The existing `mode` enum in `NotifList.qml` (`empty / single / few / grouped / many`):

- `empty`, `single`, `few` — unchanged behavior (one row per notif, no grouping when nothing to group)
- `grouped` — now actually groups (vs the v1 flat-list fallback)
- `many` — when `notifs.length > 12`, use grouped rendering inside the ScrollView (groups + ungrouped, in chronological order of newest entry)

## D — Inline replies

### Server side (Notifications.qml)

```qml
property NotificationServer server: NotificationServer {
    // ... existing flags ...
    inlineReplySupported: true        // flip from false
}

onNotification: (notification) => {
    notification.tracked = true
    const entry = {
        id: notification.id,
        appName: notification.appName,
        summary: notification.summary,
        body: notification.body,
        image: notification.image,
        urgency: notification.urgency,
        actions: notification.actions,
        hasInlineReply: notification.hasInlineReply,                  // NEW
        inlineReplyPlaceholder: notification.inlineReplyPlaceholder,  // NEW
        timestamp: Date.now(),
        notification: notification
    }
    // ... rest unchanged ...
}
```

### NCard additions

- `property bool replyOpen: false` — local state per card instance
- When `entry.hasInlineReply` is true, inject a synthetic `Reply` action button into the action button row (rendered first, before app-supplied actions). Clicking it toggles `replyOpen`
- When `replyOpen` is true, render a row below the actions containing:
  - A `TextField` with `placeholderText: entry.inlineReplyPlaceholder`, `Layout.fillWidth: true`
  - A small "Send" button (or just Enter to submit)
  - Escape key handler → `replyOpen = false`
- Submit handler:
  ```qml
  function sendReply() {
      const text = replyField.text
      if (text.length === 0) return
      card.entry?.notification?.sendInlineReply(text)
      card.dismissed()
  }
  ```
- Visibility considerations: when the card is rendered inside a Toast (no keyboard focus available), the Reply button's click handler diverges — see toast UX below

### Toast-side handling

In `Toasts.qml`, the NCard delegate's `onActionInvoked` gets a special case:

```qml
onActionInvoked: (actionId) => {
    if (actionId === "__reply__") {
        // Synthetic "open panel and focus reply" path
        panel.open()
        NotifList.focusReplyFor(cell.entry.id)
        return
    }
    cell.entry?.notification?.invokeAction(actionId)
}
```

The synthetic action id `__reply__` is used by the NCard's Reply button when rendered in a toast (NCard knows whether it has keyboard focus via a `canReply` prop set by its container — `true` for panel use, `false` for toast use).

`NotifList.focusReplyFor(id)` (new function): finds the matching entry's NCard instance, sets `replyOpen = true` and `forceActiveFocus()` on its TextField. If the notif is inside a collapsed group, expands that group first.

### Focus model

- Panel already has `WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand` — clicking the TextField grants focus
- Backdrop MouseArea (Section A2) handles click events on press-release, so a long press inside the TextField doesn't trigger backdrop close
- Escape key inside TextField collapses the reply; Escape outside is a no-op (no global Escape-closes-panel binding in v2; can add as a follow-up)

### Risk + fallback

If layer-shell focus turns out to be flaky in practice: a fallback global keybind `SUPER+R` opens the panel and focuses the newest reply-capable notif's TextField. Don't implement upfront — flag as a known mitigation.

## Files touched

| Path | Change |
|---|---|
| `config/quickshell/Panel.qml` | Fullscreen WlrLayerShell, surface positioned top-center, 640×720, mantle@0.97, drop shadow, surface0 border, top margin 12 |
| `config/quickshell/widgets/NCard.qml` | Body bug fix (drop Item wrapper); inline reply UI (`replyOpen` state, TextField, Send, synthetic Reply action); `canReply` prop |
| `config/quickshell/widgets/HeroMpris.qml` | Art 50×50, title Bold |
| `config/quickshell/widgets/ToggleTile.qml` | `border.width: 1; border.color: surface0` on tile Rectangle |
| `config/quickshell/widgets/SliderTile.qml` | Same border treatment |
| `config/quickshell/widgets/SessionTile.qml` | Same border treatment |
| `config/quickshell/widgets/NotifList.qml` | Group computation, expand state, pill rendering, `focusReplyFor(id)` |
| `config/quickshell/services/Notifications.qml` | `inlineReplySupported: true`; entry adds `hasInlineReply` + `inlineReplyPlaceholder` |
| `config/quickshell/Toasts.qml` | Flip Repeater order to newest-first (drop `.reverse()`); overflow pill stays at bottom; special-case `__reply__` action → opens panel + focuses |

## Risks

| Risk | Mitigation |
|---|---|
| Qt `MultiEffect` not available on older Qt6 versions | Fallback to `Rectangle { border + ... }` "soft shadow" pseudo-effect, or use `QtGraphicalEffects.DropShadow` (deprecated but still works on Qt6) |
| Layer-shell keyboard focus weirdness blocks inline reply | Fallback global keybind (documented but not implemented upfront) |
| Click-outside closes during slider drag if the drag pointer ends outside the surface | Reproduce post-implementation; if it happens, suppress backdrop close while any child has `pressed === true` (rare edge case) |
| Group recompute on every notif change might thrash if user has many notifs | Computation is O(N) per change with small N; not a real concern under hundreds. Monitor only. |
| `Notification.hasInlineReply` / `inlineReplyPlaceholder` / `sendInlineReply` may have slightly different names in installed Quickshell version | Verify against `https://quickshell.org/docs/types/Quickshell.Services.Notifications/Notification/`; adjust if needed |

## Verification checklist (post-implementation)

- [ ] Panel opens centered top, 640 wide, 12px below waybar, with visible drop shadow
- [ ] Click anywhere outside the panel surface (including waybar area) closes the panel
- [ ] `notify-send "X" "Y"` shows BOTH lines in toast and panel (bug D regression test)
- [ ] Send 3+ notifs from same app (e.g., `for i in 1 2 3; do notify-send -a discord "Sender $i" "Message $i"; done`); panel shows one group with `+2 more from discord` pill; click pill expands
- [ ] Click `Clear` on the pill removes all group members
- [ ] Send toasts in sequence; visible 3 show newest at top, oldest at bottom; 4th waiting shows as `+1` pill at the very bottom
- [ ] Send a `notify-send -A "default=Default action"` and click body — invokes the action and dismisses
- [ ] (Manual, with a real chat app) inline reply field appears in NCard when "Reply" clicked; typing + Enter sends; field collapses on Escape
