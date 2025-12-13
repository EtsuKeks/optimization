#!/bin/bash

# Анализируем количество активных системных потоков.
# В Go это количество N — машин/воркеров, которые исполняют горутины.
# Обычно это число близко к GOMAXPROCS, но может расти, если горутины блокируются 
# в системных вызовах (I/O, CGO), или библиотеки маунтят себе поток, тогда го 
# заспавнит новый тоже вроде как.

PID=$1
OUT="./cpu/thread_count.csv"

echo "timestamp,num_threads" > $OUT

# Функция для подсчета количества потоков
get_thread_count() {
    # Считаем количество директорий в task/
    ls /proc/$1/task/ 2>/dev/null | wc -l
}

while kill -0 $PID 2>/dev/null; do
    sleep 1
    TS=$(date +%s)
    NUM_THREADS=$(get_thread_count $PID)
    echo "$TS,$NUM_THREADS" >> $OUT
done