#!/bin/bash

# Анализируем тут переключения контекста по всем потокам за данную секунду. Суммируя показатели из task/*,
# мы видим реальную частоту, с которой ядро останавливает воркеры Go (из-за I/O или конкуренции).

PID=$1; LOAD_ENABLED=$2
if [ "$LOAD_ENABLED" == "true" ]; then
    OUT="./cpu/context_switches_load_enabled.csv"
else
    OUT="./cpu/context_switches_load_disabled.csv"
fi

echo "timestamp,voluntary_rate,involuntary_rate" > $OUT

# Функция для получения суммы смены контекстов по всем потокам
get_metric_sum() {
    # cat читает статусы всех потоков
    # grep находит нужную строку
    # awk '{sum+=$2} END {print sum}' пробегает по всем найденным строкам и складывает числа во второй колонке
    cat /proc/$1/task/*/status 2>/dev/null | grep "$2" | awk '{sum+=$2} END {print sum}'
}

PREV_VOL=$(get_metric_sum $PID "voluntary_ctxt_switches"); PREV_INVOL=$(get_metric_sum $PID "nonvoluntary_ctxt_switches")

while kill -0 $PID 2>/dev/null; do
    sleep 1
    TS=$(date +%s)
    VOL=$(get_metric_sum $PID "voluntary_ctxt_switches"); INVOL=$(get_metric_sum $PID "nonvoluntary_ctxt_switches")
    RATE_VOL=$((VOL - PREV_VOL)); RATE_INVOL=$((INVOL - PREV_INVOL))

    echo "$TS,$RATE_VOL,$RATE_INVOL" >> $OUT

    PREV_VOL=$VOL
    PREV_INVOL=$INVOL
done