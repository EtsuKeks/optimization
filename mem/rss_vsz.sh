#!/bin/bash

# Анализ новой выделенной за секунду памяти процесса: реальной (RSS), виртуальной (VSZ) и полученной
# теневым путем - вызовы read в Go не учитывают память как использованную процессом, а засчитывают всей
# системе в целом, но не процессу.
# rss_anon: Личная память (Heap, Stack), переменные создаваемые процессом.
# rss_file: Файловая память внутри процесса (mmap, код, либы).
# rss_unconsidered_but_process_related: Файловая память снаружи процесса. Это данные, которые процесс
# прочитал через read(), они лежат в RAM, но в RSS не входят.
# vsz: Виртуальная память.

PID=$1; LOAD_ENABLED=$2
if [ "$LOAD_ENABLED" == "true" ]; then
    OUT="./mem/rss_vsz_load_enabled.csv"
else
    OUT="./mem/rss_vsz_load_disabled.csv"
fi

echo "timestamp,rss_anon,rss_file,rss_unconsidered_but_process_related,vsz" > $OUT

# Функция подсчета используемой памяти процессом, у строк с RssAnon, RssFile и VmSize берем второй элемент -
# это и есть значение соответствующей памяти
get_proc_mem() {
    awk '
    /RssAnon:/ {anon=$2}
    /RssFile:/ {file=$2}
    /VmSize:/ {vsz=$2}
    END {print anon, file, vsz}
    ' /proc/$1/status 2>/dev/null
}

# Функция подсчета глобального кэша, берем "Cached" из meminfo, это весь страничный кэш системы.
get_sys_mem() {
    awk '/^Cached:/ {print $2}' /proc/meminfo
}

read -r anon file vsz <<< $(get_proc_mem $PID)
sys_cached=$(get_sys_mem); unconsidered=$((sys_cached - file))
PREV_ANON=$anon; PREV_FILE=$file; PREV_UNCONSIDERED=$unconsidered; PREV_VSZ=$vsz

while kill -0 $PID 2>/dev/null; do
    sleep 1
    TS=$(date +%s)
    read -r anon file vsz <<< $(get_proc_mem $PID)
    sys_cached=$(get_sys_mem); unconsidered=$((sys_cached - file))
    DIFF_ANON=$((anon - PREV_ANON)); DIFF_FILE=$((file - PREV_FILE)); DIFF_UNCONSIDERED=$((unconsidered - PREV_UNCONSIDERED)); DIFF_VSZ=$((vsz - PREV_VSZ))

    read -r GROWTH_ANON GROWTH_FILE GROWTH_UNCONS GROWTH_VSZ <<< $(awk -v da="$DIFF_ANON" -v df="$DIFF_FILE" -v du="$DIFF_UNCONSIDERED" -v dv="$DIFF_VSZ" '
        function calc(val) {
            res = val / 1024
            if (res < 0) res = 0
            return res
        }
        BEGIN {
            printf "%.2f %.2f %.2f %.2f", calc(da), calc(df), calc(du), calc(dv)
        }
    ')

    echo "$TS,$GROWTH_ANON,$GROWTH_FILE,$GROWTH_UNCONS,$GROWTH_VSZ" >> $OUT

    PREV_ANON=$anon; PREV_FILE=$file; PREV_UNCONSIDERED=$unconsidered; PREV_VSZ=$vsz
done