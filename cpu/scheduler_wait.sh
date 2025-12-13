#!/bin/bash

# Анализируем среднее время ожидания CPU на один поток.
# В Go горутины исполняются на пуле системных потоков (воркерах).
# Считывая schedstat, мы суммируем время, которое воркеры провели в очереди CPU,
# и делим на их количество. Это показывает, сколько в среднем тупил каждый воркер
# в прошедшую секунду. Значение 1000 мс означает полную остановку (Starvation).

PID=$1
OUT="./cpu/scheduler_wait.csv"

echo "timestamp,run_delay_ms" > $OUT

# Функция для получения суммы ожидания исполнения по всем потокам
get_sum_delay() {
    # Суммируем run_delay (поле $2) всех потоков
    cat /proc/$1/task/*/schedstat 2>/dev/null | awk '{sum+=$2} END {print sum}'
}

# Функция для подсчета количества потоков (нужна для деления)
get_thread_count() {
    # Считаем количество директорий в task/
    ls /proc/$1/task/ 2>/dev/null | wc -l
}

PREV_WAIT=$(get_sum_delay $PID)

while kill -0 $PID 2>/dev/null; do
    sleep 1
    TS=$(date +%s)
    CURR_WAIT=$(get_sum_delay $PID)
    NUM_THREADS=$(get_thread_count $PID)
    DELTA_RAW=$((CURR_WAIT - PREV_WAIT))

    # --- ОБРАБОТКА СМЕРТИ ПОТОКОВ ---
    # Если один из потоков умер, его накопительный счетчик пропадает из суммы, и DELTA может стать отрицательн.
    # Мы принимаем эту погрешность и просто обнуляем значение, чтобы не ломать график.
    if [ $DELTA_RAW -lt 0 ]; then
        DELTA_MS=0
    else
        TOTAL_MS=$((DELTA_RAW / 1000000))
        # Делим общую задержку на количество потоков.
        DELTA_MS=$((TOTAL_MS / NUM_THREADS))
    fi

    echo "$TS,$DELTA_MS" >> $OUT

    PREV_WAIT=$CURR_WAIT
done