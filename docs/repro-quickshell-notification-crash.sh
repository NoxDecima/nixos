#!/usr/bin/env bash
# Regression repro for the Quickshell notification-server SIGSEGV fixed in
# config/quickshell/services/Notifications.qml (dangling NotificationAction
# QObject cached in entries -> use-after-free during Repeater delegate
# incubation). Against the OLD code this crashes quickshell within ~10-20
# iterations; against the fixed code it survives indefinitely.
#
# Usage:  ./repro-quickshell-notification-crash.sh
# Restart the panel afterwards if needed:  quickshell &
set -u
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${UID:-1000}/bus"
DEST=org.freedesktop.Notifications; OBJ=/org/freedesktop/Notifications; IF=org.freedesktop.Notifications

P=$(busctl --user status "$DEST" 2>/dev/null | awk -F= '/^PID=/{print $2}')
echo "notification-server (quickshell) pid = $P"

# Notify(app, replaces_id, icon, summary, body, actions[], hints{}, timeout)
# signature susssasa{sv}i ; 4 action strings => 2 actions (id,label pairs).
# NOTE: busctl parses a bare "-1" timeout as an option; use a positive value.
N(){ busctl --user call "$DEST" "$OBJ" "$IF" Notify susssasa{sv}i \
       "Discord" "$1" "" "$2" "message body" \
       4 "default" "Open" "reply" "Reply" \
       1 "urgency" y 1 \
       8000 2>/dev/null | awk '{print $2}'; }
C(){ busctl --user call "$DEST" "$OBJ" "$IF" CloseNotification u "$1" >/dev/null 2>&1; }

# Zero-delay burst of notifications-with-actions, each interleaved with a close
# of a slightly older one -> frees action QObjects while new delegates incubate.
ids=()
for i in $(seq 1 200); do
  id=$(N 0 "burst $i"); ids+=("$id")
  (( i > 2 )) && C "${ids[$((i-3))]}"
  if ! kill -0 "$P" 2>/dev/null; then
    echo ">>> quickshell CRASHED at iteration $i (freed notification id=${ids[$((i-3))]:-?})"
    exit 7
  fi
done
echo "survived 200 iterations without crashing (fix is working)"
