#!/bin/bash

# Анализ задержек диска - считаем время (в миллисекундах), которое все потоки в рамках данного процесса провели в состоянии 
# ожидания физического диска за последнюю секунду.

PID=$1; LOAD_ENABLED=$2
if [ "$LOAD_ENABLED" == "true" ]; then
    OUT="./mem/io_latency_load_enabled.csv"
else
    OUT="./mem/io_latency_load_disabled.csv"
fi

echo "timestamp,io_latency_ms" > $OUT

# Функция подсчета задержки суммарно по всем потокам
get_blkio_ticks() {
    # 1. /proc/$1/task/*/stat — раскрывает файлы статистики для ВСЕХ потоков
    # 2. awk пробегает по ним и складывает 42-е поле (delayacct_blkio_ticks)
    cat /proc/$1/task/*/stat 2>/dev/null | awk '{sum += $42} END {print sum+0}'
}

CLK_TCK=$(getconf CLK_TCK)
ticks=$(get_blkio_ticks $PID); PREV_TICKS=$ticks

while kill -0 $PID 2>/dev/null; do
    sleep 1
    TS=$(date +%s)
    ticks=$(get_blkio_ticks $PID)
    DIFF_TICKS=$((ticks - PREV_TICKS)); DELAY_MS=$(echo "scale=2; ($DIFF_TICKS / $CLK_TCK) * 1000" | bc)

    echo "$TS,$DELAY_MS" >> $OUT

    PREV_TICKS=$ticks
done