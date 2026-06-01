#!/bin/bash
# VPS Monitor — laporan status otomatis via cronjob Hermes (no_agent=true)
# Output dikirim langsung ke user oleh Hermes cron scheduler
set -o pipefail

LAST_FILE="/tmp/vps-monitor-last.json"
NOW=$(date -u +"%a %b %d %H:%M:%S UTC %Y")

# ── helpers ──────────────────────────────────────────────
fmt_uptime() {
    local s=$1 d h m
    d=$((s/86400)); h=$(((s%86400)/3600)); m=$(((s%3600)/60))
    [ "$d" -ge 1 ] && echo "${d} hari ${h} jam ${m} menit" && return
    [ "$h" -ge 1 ] && echo "${h} jam ${m} menit" && return
    echo "${m} menit"
}
to_int() { echo "$1" | tr -d -c '0-9'; }
fmt_human() {
    local b=$1
    awk "BEGIN {if ($b>=1073741824) printf \"%.1f GB\",$b/1073741824; else printf \"%.0f MB\",$b/1048576}"
}

# ── system info ──────────────────────────────────────────
UPTIME_SEC=$(awk '{print int($1)}' /proc/uptime)
UPTIME_STR=$(fmt_uptime "$UPTIME_SEC")
LOAD=$(uptime | grep -oP 'load average: \K.*')

RAM_TOTAL=$(to_int "$(free -b | awk '/^Mem:/{print $2}')")
RAM_AVAIL=$(to_int "$(free -b | awk '/^Mem:/{print $7}')")
RAM_USED=$((RAM_TOTAL - RAM_AVAIL))
RAM_PCT=$(( (RAM_USED * 100) / RAM_TOTAL ))
RAM_USED_H=$(fmt_human "$RAM_USED")
RAM_TOTAL_H=$(fmt_human "$RAM_TOTAL")
RAM_AVAIL_H=$(fmt_human "$RAM_AVAIL")

DISK_USED=$(df -B1 / | tail -1 | awk '{print $3}')
DISK_TOTAL=$(df -B1 / | tail -1 | awk '{print $2}')
DISK_PCT=$(df / | tail -1 | awk '{print $5}' | tr -d '%')
DISK_USED_H=$(fmt_human "$DISK_USED")
DISK_TOTAL_H=$(fmt_human "$DISK_TOTAL")

if [ "$RAM_PCT" -gt 85 ]; then     STATUS="🔴 RAM kritis (${RAM_PCT}%)"
elif [ "$RAM_PCT" -gt 60 ]; then   STATUS="🟡 RAM agak ketat (${RAM_PCT}%)"
else                                STATUS="🟢 Sehat & idle"
fi

# ── top processes ────────────────────────────────────────
TOP_PROCS=$(ps -eo rss,pcpu,comm --sort=-rss 2>/dev/null | head -11 | tail -10 | awk '{
    rss=$1/1024; cpu=$2; cmd=$3;
    gsub(/.*\//,"",cmd);
    if(length(cmd)>26) cmd=substr(cmd,1,23)"...";
    printf "| %-26s | %5.0f MB | %5.1f%%%% |\n", cmd, rss, cpu
}')

# ── docker ───────────────────────────────────────────────
DOCKER_COUNT=0; DOCKER_OUT=""
if command -v docker &>/dev/null && docker info &>/dev/null 2>&1; then
    DOCKER_OUT=$(docker ps --format '  - {{.Names}} | {{.Status}}' 2>/dev/null)
    DOCKER_COUNT=$(echo "$DOCKER_OUT" | grep -c . 2>/dev/null || echo 0)
fi

# ── services ─────────────────────────────────────────────
USER_SVCS=$(systemctl list-units --type=service --state=running --no-legend 2>/dev/null \
    | grep -iE "shaa|webstream|cloudflare|uptime|hermes" \
    | awk '{print "  - "$1" ✅"}')
[ -z "$USER_SVCS" ] && USER_SVCS="  _(gak ada service user terdeteksi)_"

CORE_SVCS=""
for svc in docker ssh fail2ban cron mysql mariadb bt; do
    systemctl is-active --quiet "$svc" 2>/dev/null && CORE_SVCS="${CORE_SVCS}  - ${svc}.service ✅"$'\n'
done

# ── ports ────────────────────────────────────────────────
LISTEN_PORTS=$(ss -tlnp 2>/dev/null | awk '
/LISTEN/{
    # extract port: last colon-separated field
    n=split($4,a,":"); port=a[n]; addr=$4; sub(/:[0-9]+$/,"",addr)
    # normalize addr: * = 0.0.0.0 = public; 127.* and ::1 = local
    is_public=0; if(addr=="0.0.0.0"||addr=="*") is_public=1
    # record best address per port: prefer public over private
    if(!(port in seen) || (is_public && !public[port])) {
        seen[port]=addr; public[port]=is_public
    }
}
END {
    n=split("22 80 443 3000 4000 8788 8789 8888 3306 8080 8188 888 7080",ports)
    for(i=1;i<=n;i++){
        p=ports[i]; addr=seen[p]; if(addr=="") continue
        if(p==22)   svc="SSH"
        else if(p==80)   svc="HTTP"
        else if(p==443)  svc="HTTPS"
        else if(p==3000) svc="WAHA API"
        else if(p==4000) svc="unknown service"
        else if(p==8788) svc="webstream-dev"
        else if(p==8789) svc="webstream-prod"
        else if(p==8888) svc="aaPanel"
        else if(p==3306) svc="MySQL"
        else if(p==8080) svc="alt-HTTP"
        else if(p==8188) svc="ComfyUI?"
        else if(p==888)  svc="aaPanel admin"
        else if(p==7080) svc="unknown admin"
        else svc="unknown"
        warn=""
        if(public[p] && p!=22 && p!=80 && p!=443) warn=" ⚠️ public"
        if(!public[p]) warn=" _(localhost)_"
        printf "  - :%s — %s%s\n",p,svc,warn
    }
}')

# ── SSH sessions ─────────────────────────────────────────
SSH_COUNT=$(who -u 2>/dev/null | grep -c .)
NOW_EPOCH=$(date +%s)
SSH_SESSIONS=$(who -u 2>/dev/null | while read -r user tty date time idle pid ip; do
    ip_clean=$(echo "$ip" | tr -d '()')
    # who -u: $3=date(2026-05-29) $4=time(03:19) $7=(ip)
    when_epoch=$(date -d "${date} ${time}" +%s 2>/dev/null || echo 0)
    age_str=""
    if [ "$when_epoch" != "0" ] 2>/dev/null; then
        age=$(( NOW_EPOCH - when_epoch ))
        d=$((age/86400)); h=$(((age%86400)/3600)); m=$(((age%3600)/60))
        if [ "$d" -ge 1 ]; then age_str="~${d} hari ${h} jam"
        elif [ "$h" -ge 1 ]; then age_str="~${h} jam ${m} menit"
        else age_str="~${m} menit"
        fi
    fi
    echo "  - ${user} dari ${ip_clean} (${age_str})"
done)

# ── WAHA ─────────────────────────────────────────────────
WAHA_BLOCK=""
WAHA_CR=$(ps aux | grep "[c]hromium" | awk '{s+=$6}END{printf "%.0f",s/1024}')
WAHA_NODE=$(ps aux | grep "[n]ode" | grep -iE "wa|waha" | awk '{s+=$6}END{printf "%.0f",s/1024}')
WAHA_TOT=$((WAHA_CR + WAHA_NODE))
[ "$WAHA_TOT" -gt 100 ] 2>/dev/null && WAHA_BLOCK="🔥 WAHA masih nyala
- Total RAM Chromium + Node.js: ~${WAHA_TOT} MB
- Chromium: ${WAHA_CR} MB | Node.js: ${WAHA_NODE} MB
"

# ── 9router ──────────────────────────────────────────────
ROUTER9_BLOCK=""
if docker ps --format '{{.Names}}' 2>/dev/null | grep -q "9router"; then
    S=$(docker inspect -f '{{.State.Status}}' 9router 2>/dev/null)
    U=$(docker inspect -f '{{.State.StartedAt}}' 9router 2>/dev/null | cut -d. -f1 | sed 's/T/ /')
    ROUTER9_BLOCK="⚡ 9router: ${S} (sejak ${U})
"
fi

# ── changes ──────────────────────────────────────────────
CHANGES=""
if [ -f "$LAST_FILE" ] && command -v jq &>/dev/null; then
    LAST_RAM=$(jq -r '.ram_used // 0' "$LAST_FILE" 2>/dev/null)
    LAST_TS=$(jq -r '.timestamp // 0' "$LAST_FILE" 2>/dev/null)
    if [ "$LAST_RAM" != "0" ] && [ "$LAST_TS" != "0" ] 2>/dev/null; then
        MINS=$(( ($(date +%s) - LAST_TS) / 60 ))
        DIFF=$((RAM_USED - LAST_RAM))
        DIFF_H=$(fmt_human "${DIFF#-}")
        if [ "$DIFF" -gt 104857600 ]; then
            CHANGES="  - RAM naik ${DIFF_H} sejak ${MINS} menit lalu"
        elif [ "$DIFF" -lt -104857600 ]; then
            CHANGES="  - RAM turun ${DIFF_H} sejak ${MINS} menit lalu"
        else
            CHANGES="  - RAM stabil sejak ${MINS} menit lalu"
        fi
    fi
fi
printf '{"ram_used":%d,"timestamp":%d}\n' "$RAM_USED" "$NOW_EPOCH" > "$LAST_FILE"

# ── recommendations ──────────────────────────────────────
RECS=""; idx=1
if [ "$RAM_PCT" -gt 70 ]; then
    RECS="${RECS}${idx}. RAM udah ${RAM_PCT}% — kalau ada service yg gak kepake, mending stop"$'\n'; idx=$((idx+1))
fi
if echo "$LISTEN_PORTS" | grep -q "⚠️"; then
    RECS="${RECS}${idx}. Port non-SSH/HTTP masih public — \`sudo ufw deny 3000 && sudo ufw deny 4000\`"$'\n'; idx=$((idx+1))
fi
if [ "$DISK_PCT" -gt 80 ]; then
    RECS="${RECS}${idx}. Disk udah ${DISK_PCT}% — bersihin log/cache"$'\n'; idx=$((idx+1))
fi
if [ "$SSH_COUNT" -gt 3 ]; then
    RECS="${RECS}${idx}. ${SSH_COUNT} SSH session — cek legitimacy"$'\n'; idx=$((idx+1))
fi
[ -z "$RECS" ] && RECS="  ✅ Semua udah optimal, gak ada yang perlu diubah"

# ── render ───────────────────────────────────────────────
cat <<EOF
Nih status VPS terbaru, Bos Sholeh:

${STATUS}
- Uptime: ${UPTIME_STR}
- Load: ${LOAD}
- RAM: ${RAM_USED_H} / ${RAM_TOTAL_H} (${RAM_PCT}%), available ${RAM_AVAIL_H}
- Disk: ${DISK_USED_H} / ${DISK_TOTAL_H} (${DISK_PCT}%)
- Waktu VPS: ${NOW}

📊 Top RAM consumer

| Proses | RAM | CPU |
|---|---|---|
${TOP_PROCS}
🐳 Docker containers (${DOCKER_COUNT} running)
${DOCKER_OUT}

${ROUTER9_BLOCK}\
🔧 Service yang jalan

App kamu:
${USER_SVCS}
Infrastructure:
${CORE_SVCS}
📡 Port listening
${LISTEN_PORTS}

👥 Active SSH sessions (${SSH_COUNT})
${SSH_SESSIONS}

${WAHA_BLOCK}\
📈 Perubahan sejak cek terakhir
${CHANGES:-  - Cek pertama — belum ada history}

⚠️ Rekomendasi
${RECS}

---
🕐 Auto-generated tiap jam oleh Shino
EOF
