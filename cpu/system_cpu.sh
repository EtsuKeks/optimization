#!/bin/bash

# Анализ общесистемной нагрузки на CPU (System-Wide), показывает, чем занят весь сервер целиком.
# user_pct: полезная работа всех программ.
# system_pct: работа ядра (драйверы, сеть, фс).
# idle_pct: простой (сколько ресурсов свободно).
# iowait_pct: простой из-за медленного диска (важный маркер лагов).

PID=$1
LOAD_ENABLED=$2
if [ "$LOAD_ENABLED" == "true" ]; then
    OUT="./cpu/system_cpu_load_enabled.csv"
else
    OUT="./cpu/system_cpu_load_disabled.csv"
fi

echo "timestamp,user_pct,system_pct,idle_pct,iowait_pct" > $OUT

# Функция чтения /proc/stat (первая строка 'cpu')
get_cpu_stat() {
    awk '/^cpu / {print $2, $3, $4, $5, $6}' /proc/stat
}

read -r u n s i w <<< $(get_cpu_stat)
PREV_TOTAL=$((u + n + s + i + w))
PREV_U=$u; PREV_S=$s; PREV_I=$i; PREV_W=$w

while kill -0 $PID 2>/dev/null; do
    sleep 1
    TS=$(date +%s)
    read -r u n s i w <<< $(get_cpu_stat)
    CURR_TOTAL=$((u + n + s + i + w))
    DIFF_TOTAL=$((CURR_TOTAL - PREV_TOTAL))
    
    PCT_USER=$(echo "scale=2; ($u - $PREV_U) * 100 / $DIFF_TOTAL" | bc)
    PCT_SYS=$(echo "scale=2; ($s - $PREV_S) * 100 / $DIFF_TOTAL" | bc)
    PCT_IDLE=$(echo "scale=2; ($i - $PREV_I) * 100 / $DIFF_TOTAL" | bc)
    PCT_WAIT=$(echo "scale=2; ($w - $PREV_W) * 100 / $DIFF_TOTAL" | bc)
    
    echo "$TS,$PCT_USER,$PCT_SYS,$PCT_IDLE,$PCT_WAIT" >> $OUT

    PREV_TOTAL=$CURR_TOTAL
    PREV_U=$u; PREV_S=$s; PREV_I=$i; PREV_W=$w
done