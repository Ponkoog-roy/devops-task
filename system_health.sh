#!/usr/bin/env bash
# system_health.sh - log CPU, memory and disk usage; warn if disk > 80%.
set -euo pipefail

LOG_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/health_log.txt"
DISK_THRESHOLD=80

# CPU usage (%): sample /proc/stat twice, 1 second apart
get_cpu_usage() {
  local u1 n1 s1 i1 w1 q1 sq1 u2 n2 s2 i2 w2 q2 sq2
  read -r _ u1 n1 s1 i1 w1 q1 sq1 _ < /proc/stat
  sleep 1
  read -r _ u2 n2 s2 i2 w2 q2 sq2 _ < /proc/stat
  local idle1=$((i1 + w1)) idle2=$((i2 + w2))
  local total1=$((u1 + n1 + s1 + i1 + w1 + q1 + sq1))
  local total2=$((u2 + n2 + s2 + i2 + w2 + q2 + sq2))
  local dt=$((total2 - total1)) di=$((idle2 - idle1))
  if [ "$dt" -le 0 ]; then echo "0.0"; return; fi
  awk -v dt="$dt" -v di="$di" 'BEGIN { printf "%.1f", (dt - di) * 100 / dt }'
}

# Memory usage (%): (total - available) / total
get_mem_usage() {
  free | awk '/^Mem:/ { printf "%.1f", ($2 - $7) * 100 / $2 }'
}

# Disk usage (%) of the root filesystem, as an integer
get_disk_usage() {
  df -P / | awk 'NR==2 { gsub("%", "", $5); print $5 }'
}

TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"
CPU="$(get_cpu_usage)"
MEM="$(get_mem_usage)"
DISK="$(get_disk_usage)"

ENTRY="[$TIMESTAMP] CPU: ${CPU}% | Memory: ${MEM}% | Disk: ${DISK}%"
echo "$ENTRY" >> "$LOG_FILE"
echo "$ENTRY"

if [ "$DISK" -gt "$DISK_THRESHOLD" ]; then
  echo "[WARNING] Disk space high!"
  echo "[$TIMESTAMP] [WARNING] Disk space high! (${DISK}% > ${DISK_THRESHOLD}%)" >> "$LOG_FILE"
fi
