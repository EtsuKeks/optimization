#!/bin/bash

# Анализ выделенной к этой секунде памяти процесса: реальной (RSS), виртуальной (VSZ).
# rss_anon: Личная память (Heap, Stack), переменные создаваемые процессом.
# rss_file: Файловая память внутри процесса (mmap, код, либы).
# vsz: Виртуальная память.

PID=$1; LOAD_ENABLED=$2
if [ "$LOAD_ENABLED" == "true" ]; then
    OUT="./mem/rss_vsz_load_enabled.csv"
else
    OUT="./mem/rss_vsz_load_disabled.csv"
fi

echo "timestamp,rss_anon,rss_file,vsz" > $OUT

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

while kill -0 $PID 2>/dev/null; do
    sleep 1
    TS=$(date +%s)
    read -r anon file vsz <<< $(get_proc_mem $PID)
    echo "$TS,$anon,$file,$vsz" >> $OUT
done