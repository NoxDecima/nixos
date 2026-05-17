#!/usr/bin/env bash
inhibit="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/idle-suspend.inhibit"
[ -e "$inhibit" ] && exit 0
systemctl suspend
