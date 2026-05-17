#!/usr/bin/env bash
inhibit="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/idle-suspend.inhibit"

print_status() {
  if [ -e "$inhibit" ]; then
    printf '{"text":"󰒳","tooltip":"Idle suspend: OFF (stay-awake)","class":"inhibited"}\n'
  else
    printf '{"text":"󰒲","tooltip":"Idle suspend: ON (suspend after 30 min)","class":"active"}\n'
  fi
}

case "${1:-status}" in
toggle)
  if [ -e "$inhibit" ]; then
    rm -f "$inhibit"
  else
    : >"$inhibit"
  fi
  print_status
  ;;
status | *)
  print_status
  ;;
esac
