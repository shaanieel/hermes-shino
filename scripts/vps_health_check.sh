#!/usr/bin/env bash
set -euo pipefail

HOST="$(hostname)"
NOW="$(date '+%Y-%m-%d %H:%M:%S %Z')"
UPTIME="$(uptime -p)"
LOAD="$(awk '{print $1" "$2" "$3}' /proc/loadavg)"
CPU="$(top -bn1 | awk -F'id,' '/Cpu\(s\)/ {split($1,a,","); sub(/^[ \t]+/,"",a[length(a)]); printf "%.1f", 100-a[length(a)]}')"
MEM="$(free -m | awk '/^Mem:/ {printf "%d/%d MB (%.1f%%)", $3, $2, $3*100/$2}')"
SWAP="$(free -m | awk '/^Swap:/ {if ($2>0) printf "%d/%d MB (%.1f%%)", $3, $2, $3*100/$2; else print "0 MB"}')"
DISK="$(df -h / | awk 'NR==2 {print $3"/"$2" ("$5")"}')"
FAILED="$(systemctl --failed --no-pager --plain 2>/dev/null | awk 'NR>1 && $1!="0" {print}' || true)"

printf '🖥️ VPS Health Check\n'
printf 'Host      : %s\n' "$HOST"
printf 'Waktu     : %s\n' "$NOW"
printf 'Uptime    : %s\n' "$UPTIME"
printf 'Load Avg  : %s\n' "$LOAD"
printf 'CPU       : %s%%\n' "$CPU"
printf 'Memory    : %s\n' "$MEM"
printf 'Swap      : %s\n' "$SWAP"
printf 'Disk /    : %s\n' "$DISK"

if [[ -n "$FAILED" ]]; then
  printf '\n⚠️ Failed Services:\n%s\n' "$FAILED"
else
  printf '\n✅ Failed Services: tidak ada\n'
fi
