#!/bin/bash

# Анализируем тут переключения контекста по всем потокам, для которых PID является Thread Group Leader-ом,
# ведь в го горутины скедулятся по N ядрам ОС, и собирая только с PID мы узнаем переключения контекста
# у лидера, а про горящие под нагрузкой горутины нам будет ничего неизвестно. Суммируя показатели из task/*,
# мы видим реальную частоту, с которой ядро останавливает воркеры Go (из-за I/O или конкуренции). Сумма
# переключений зависит от количества воркеров, поэтому абсолютные числа сложно интерпретировать и
# мы делим сумму переключений на количество потоков, чтобы понять, как часто дергают каждый конкретный 
# воркер в среднем.

PID=$1
OUT="./cpu/context_switches.csv"

echo "timestamp,voluntary_rate,involuntary_rate" > $OUT

# Функция для получения суммы смены контекстов по всем потокам
get_metric_sum() {
    # cat читает статусы всех потоков
    # grep находит нужную строку
    # awk '{sum+=$2} END {print sum}' пробегает по всем найденным строкам и складывает числа во второй колонке
    cat /proc/$1/task/*/status 2>/dev/null | grep "$2" | awk '{sum+=$2} END {print sum}'
}

# Функция для подсчета количества потоков (нужна для деления)
get_thread_count() {
    # Считаем количество директорий в task/
    ls /proc/$1/task/ 2>/dev/null | wc -l
}

PREV_VOL=$(get_metric_sum $PID "voluntary_ctxt_switches")
PREV_INVOL=$(get_metric_sum $PID "nonvoluntary_ctxt_switches")

while kill -0 $PID 2>/dev/null; do
    sleep 1
    TS=$(date +%s)
    VOL=$(get_metric_sum $PID "voluntary_ctxt_switches")
    INVOL=$(get_metric_sum $PID "nonvoluntary_ctxt_switches")
    RATE_VOL=$((VOL - PREV_VOL))
    RATE_INVOL=$((INVOL - PREV_INVOL))
    NUM_THREADS=$(get_thread_count $PID)

    # --- ОБРАБОТКА СМЕРТИ ПОТОКОВ ---
    # Если один из потоков умер, его накопительный счетчик пропадает из суммы, и RATE может стать отрицательным.
    # Мы принимаем эту погрешность и просто обнуляем значение, чтобы не ломать график.
    if [ $RATE_VOL -lt 0 ]; then
        AVG_VOL=0
    else
        # Делим общее количество смены контекста на количество потоков.
        AVG_VOL=$((RATE_VOL / NUM_THREADS))
    fi

    if [ $RATE_INVOL -lt 0 ]; then
        AVG_INVOL=0
    else
        # Делим общее количество смены контекста на количество потоков.
        AVG_INVOL=$((RATE_INVOL / NUM_THREADS))
    fi

    echo "$TS,$AVG_VOL,$AVG_INVOL" >> $OUT

    PREV_VOL=$VOL
    PREV_INVOL=$INVOL
done