#!/bin/bash

# Анализ contention за доступ к файлам диска в данную секунду. io_latency.sh не дает полного понимания причин, по которым время io операций
# большое - такое может возникать и из-за конкуренции, наличие которой и проверяет скрипт. Мы считаем тут что запускаемся в изолированной
# среде и кроме нас самих же вызвать блокирвоку больше никто не мог.

PID=$1; LOAD_ENABLED=$2
if [ "$LOAD_ENABLED" == "true" ]; then
    OUT="./mem/file_locks_load_enabled.csv"
else
    OUT="./mem/file_locks_load_disabled.csv"
fi

echo "timestamp,threads_waiting_lock" > $OUT

# Функция сканирования всех потоков на предмет зависания на ожидании разблокировки файла
get_thread_stats() {
    local locked_count=0
    # Используем nullglob, чтобы цикл не сломался если папка пуста
    shopt -s nullglob
    for task_dir in /proc/$1/task/*; do
        if [ -f "$task_dir/wchan" ]; then
            wchan=$(cat "$task_dir/wchan" 2>/dev/null)
            case "$wchan" in
                *lock_inode_wait*|*locks_remove_flock*|*posix_lock_inode_wait*)
                    ((locked_count++))
                    ;;
            esac
        fi
    done
    shopt -u nullglob
    echo $locked_count
}

while kill -0 $PID 2>/dev/null; do
    sleep 1
    TS=$(date +%s)
    read -r waiting <<< $(get_thread_stats $PID)

    echo "$TS,$waiting" >> $OUT
done