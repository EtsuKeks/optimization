#!/bin/bash

# Анализируем время ожидания CPU за прошедшую секунду. Считывая schedstat, мы суммируем время,
# которое GO воркеры провели в очереди CPU, это показывает, сколько суммарно тупили воркеры
# в прошедшую секунду.

PID=$1; LOAD_ENABLED=$2
if [ "$LOAD_ENABLED" == "true" ]; then
    OUT="./cpu/scheduler_wait_load_enabled.csv"
else
    OUT="./cpu/scheduler_wait_load_disabled.csv"
fi

echo "timestamp,run_delay_ms" > $OUT

# Функция для получения суммы ожидания исполнения по всем потокам
get_sum_delay() {
    # Суммируем run_delay (поле $2) всех потоков
    cat /proc/$1/task/*/schedstat 2>/dev/null | awk '{sum+=$2} END {print sum}'
}

PREV_WAIT=$(get_sum_delay $PID)

while kill -0 $PID 2>/dev/null; do
    sleep 1
    TS=$(date +%s)
    CURR_WAIT=$(get_sum_delay $PID); DELTA_RAW=$((CURR_WAIT - PREV_WAIT))
    TOTAL_MS=$((DELTA_RAW / 1000000))

    echo "$TS,$TOTAL_MS" >> $OUT

    PREV_WAIT=$CURR_WAIT
done