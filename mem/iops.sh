#!/bin/bash

# Анализ количества IOPS ввода-вывода за прошедшую секунду с целью найти частые операции записи/чтения,
# которые убивают производительность диска.

PID=$1; LOAD_ENABLED=$2
if [ "$LOAD_ENABLED" == "true" ]; then
    OUT="./mem/iops_load_enabled.csv"
else
    OUT="./mem/iops_load_disabled.csv"
fi

echo "timestamp,read_iops,write_iops" > $OUT

# Функция подсчета вызовов, берем данные из /proc/PID/io
get_io_pattern() {
    awk '
    /syscr/ {rc=$2} 
    /syscw/ {wc=$2} 
    END {print rc, wc}
    ' /proc/$1/io 2>/dev/null
}

read -r rc wc <<< $(get_io_pattern $PID)
PREV_RC=$rc; PREV_WC=$wc

while kill -0 $PID 2>/dev/null; do
    sleep 1
    TS=$(date +%s)
    read -r rc wc <<< $(get_io_pattern $PID)
    D_ROPS=$((rc - PREV_RC)); D_WOPS=$((wc - PREV_WC))

    echo "$TS,$D_ROPS,$D_WOPS" >> $OUT

    PREV_RC=$rc; PREV_WC=$wc
done