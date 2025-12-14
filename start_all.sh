#!/bin/bash

BINARY="./bin/app"
CPU_MONITORS_DIR="./cpu"
MEM_MONITORS_DIR="./mem"
LOAD_ENABLED=true

chmod +x $CPU_MONITORS_DIR/*.sh
chmod +x $MEM_MONITORS_DIR/*.sh
chmod +x ./create_load.sh

cleanup() {
    # pkill -P $$ убивает всех, кого породил этот скрипт
    pkill -P $$ 
    if [ ! -z "$APP_PID" ]; then
        kill $APP_PID 2>/dev/null
        sleep 1
        kill -9 $APP_PID 2>/dev/null
    fi
    exit
}

trap cleanup SIGINT SIGTERM
$BINARY > app.log 2> err.log &
APP_PID=$!

echo -e "Application running with PID: $APP_PID"

if [ "$LOAD_ENABLED" = true ]; then
    ./create_load.sh "$APP_PID" &
fi

CPU_MONITORS=(
    "context_switches.sh"
    "core_distribution.sh"
    "process_cpu.sh"
    "scheduler_wait.sh"
    "system_cpu.sh"
    "thread_count.sh"
)

for script in "${CPU_MONITORS[@]}"; do
    "$CPU_MONITORS_DIR/$script" $APP_PID $LOAD_ENABLED &
done

MEM_MONITORS=(
    "file_locks.sh"
    "io_latency.sh"
    "iops.sh"
    "memory_faults.sh"
    "page_cache.sh"
    "rss_vsz.sh"
)

for script in "${MEM_MONITORS[@]}"; do
    "$MEM_MONITORS_DIR/$script" $APP_PID $LOAD_ENABLED &
done

echo -e "Press [Ctrl+C] to stop the test and save data."
wait