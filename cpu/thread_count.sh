#!/bin/bash

# Анализируем количество активных системных потоков в данную секунду. В Go это количество N 
# — машин/воркеров, которые исполняют горутины. Обычно это число близко к GOMAXPROCS, но
# может расти, если горутины блокируются  в системных вызовах (I/O, CGO), или библиотеки
# маунтят себе поток, тогда го заспавнит новый тоже вроде как.

PID=$1; LOAD_ENABLED=$2
if [ "$LOAD_ENABLED" == "true" ]; then
    OUT="./cpu/thread_count_load_enabled.csv"
else
    OUT="./cpu/thread_count_load_disabled.csv"
fi

echo "timestamp,total_num,state_R,state_S,state_D,state_Z,state_T" > $OUT

# Функция для подсчета количества потоков
get_thread_count() {
    # Считаем количество директорий в task/
    ls /proc/$1/task/ 2>/dev/null | wc -l
}

# Функция сбора статистики состояний по потокам
get_thread_states() {
    # cat вываливает содержимое stat всех потоков. awk берет 3-е поле ($3) — это буква состояния, складывает их в массив count.
    # +0 нужно, чтобы если состояние не встретилось, напечатался 0, а не пустота.
    cat /proc/$1/task/*/stat 2>/dev/null | awk '
    {
        state = $3
        count[state]++
    }
    END {
        # Выводим в порядке: Running, Sleeping, Disk/Uninterruptible, Zombie, Stopped
        print count["R"]+0, count["S"]+0, count["D"]+0, count["Z"]+0, count["T"]+0
    }
    '
}

while kill -0 $PID 2>/dev/null; do
    sleep 1
    TS=$(date +%s)

    NUM_THREADS=$(get_thread_count $PID); read -r R S D Z T <<< $(get_thread_states $PID)

    echo "$TS,$NUM_THREADS,$R,$S,$D,$Z,$T" >> $OUT
done