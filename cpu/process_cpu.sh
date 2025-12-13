#!/bin/bash

# Анализируем накопленное время потребления CPU процессом (User/System Time).
# В Linux файл /proc/PID/stat автоматически суммирует тики процессора для всех потоков (воркеров),
# поэтому utime/stime показывают реальную утилизацию ресурсов всем Go-приложением целиком.
# Скрипт считает мгновенную нагрузку (дельта тиков к дельте времени) и переводит накопленные тики
# в проценты от полной секунды.

PID=$1
OUT="./cpu/process_cpu.csv"

# Получаем частоту процессора (ticks per second)
CLK_TCK=$(getconf CLK_TCK)

echo "timestamp,user_pct,system_pct" > $OUT

# Функция для получения utime (14 поле) и stime (15 поле) в тиках
get_cpu_ticks() {
    awk '{print $14, $15}' /proc/$1/stat 2>/dev/null
}

# Читаем текущие user и system тики
read -r utime stime <<< $(get_cpu_ticks $PID)
PREV_UTIME=$utime
PREV_STIME=$stime
PREV_TIME=$(date +%s%N)

while kill -0 $PID 2>/dev/null; do
    sleep 1
    TS=$(date +%s) # Для CSV (секунды)
    NOW=$(date +%s%N) # Для расчетов (наносекунды)
    read -r utime stime <<< $(get_cpu_ticks $PID)
    DIFF_UTIME=$((utime - PREV_UTIME))
    DIFF_STIME=$((stime - PREV_STIME))
    DIFF_TIME=$((NOW - PREV_TIME))
    USER_PCT=$(echo "scale=2; ($DIFF_UTIME / $CLK_TCK) / ($DIFF_TIME / 1000000000) * 100" | bc)
    SYSTEM_PCT=$(echo "scale=2; ($DIFF_STIME / $CLK_TCK) / ($DIFF_TIME / 1000000000) * 100" | bc)

    echo "$TS,$USER_PCT,$SYSTEM_PCT" >> $OUT

    PREV_UTIME=$utime
    PREV_STIME=$stime
    PREV_TIME=$NOW
done