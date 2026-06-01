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

echo "🖥️ VPS Health Check"
echo "Host      : $HOST"
echo "Waktu     : $NOW"
echo "Uptime    : $UPTIME"
echo "Load Avg  : $LOAD"
echo "CPU       : ${CPU}%"
echo "Memory    : $MEM"
echo "Swap      : $SWAP"
echo "Disk /    : $DISK"

if [[ -n "$FAILED" ]]; then
  echo
  echo "⚠️ Failed Services:"
  echo "$FAILED"
else
  echo
  echo "✅ Failed Services: tidak ada"
fi
