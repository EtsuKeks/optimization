#!/bin/bash

# Анализ пропускной способности страничного кэша. Сравниваем логический I/O за прошедшую секунду 
# (системные вызовы read/write) с физическим.
# logical_...: сколько приложение попросило за прошедшую секунду
# phys_...: сколько реально пришлось читать с диска

PID=$1; LOAD_ENABLED=$2
if [ "$LOAD_ENABLED" == "true" ]; then
    OUT="./mem/page_cache_load_enabled.csv"
else
    OUT="./mem/page_cache_load_disabled.csv"
fi

echo "timestamp,logical_read,logical_write,phys_read,phys_write" > $OUT

# Функция чтения статистик io-операций
get_io_stats() {
    awk '/rchar/ {r=$2} /wchar/ {w=$2} /read_bytes/ {rb=$2} /write_bytes/ {wb=$2} END {print r, w, rb, wb}' /proc/$1/io 2>/dev/null
}

read -r r w rb wb <<< $(get_io_stats $PID)
PREV_R=$r; PREV_W=$w; PREV_RB=$rb; PREV_WB=$wb; MB_SIZE=1048576

while kill -0 $PID 2>/dev/null; do
    sleep 1
    TS=$(date +%s)
    read -r r w rb wb <<< $(get_io_stats $PID)
    D_R=$((r - PREV_R)); D_W=$((w - PREV_W)); D_RB=$((rb - PREV_RB)); D_WB=$((wb - PREV_WB))
    LOG_R=$(echo "scale=2; $D_R / $MB_SIZE" | bc); LOG_W=$(echo "scale=2; $D_W / $MB_SIZE" | bc)
    PHYS_R=$(echo "scale=2; $D_RB / $MB_SIZE" | bc); PHYS_W=$(echo "scale=2; $D_WB / $MB_SIZE" | bc)
    
    echo "$TS,$LOG_R,$LOG_W,$PHYS_R,$PHYS_W" >> $OUT

    PREV_R=$r; PREV_W=$w; PREV_RB=$rb; PREV_WB=$wb
done