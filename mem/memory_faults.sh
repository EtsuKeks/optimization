#!/bin/bash

# Анализ page faults возникших за прошедшую секунду у процесса: Minor Faults 
# (выделение памяти или чтение из кэша) и Major Faults (чтение с диска/свопа).

PID=$1; LOAD_ENABLED=$2
if [ "$LOAD_ENABLED" == "true" ]; then
    OUT="./mem/memory_faults_load_enabled.csv"
else
    OUT="./mem/memory_faults_load_disabled.csv"
fi

echo "timestamp,minor_faults,major_faults" > $OUT

# Функция для получения Faults из /proc/PID/stat (поля 10 и 12)
get_mem_faults() {
    awk '{print $10, $12}' /proc/$1/stat 2>/dev/null
}

read -r minflt majflt <<< $(get_mem_faults $PID)
PREV_MINFLT=$minflt; PREV_MAJFLT=$majflt

while kill -0 $PID 2>/dev/null; do
    sleep 1
    TS=$(date +%s)
    read -r minflt majflt <<< $(get_mem_faults $PID)
    DIFF_MINFLT=$((minflt - PREV_MINFLT)); DIFF_MAJFLT=$((majflt - PREV_MAJFLT))
    
    echo "$TS,$DIFF_MINFLT,$DIFF_MAJFLT" >> $OUT
    
    PREV_MINFLT=$minflt; PREV_MAJFLT=$majflt
done