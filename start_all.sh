#!/bin/bash

BINARY="./bin/app"
CPU_MONITORS_DIR="./cpu"
MEM_MONITORS_DIR="./mem"
NET_MONITORS_DIR="./net"
LOAD_ENABLED=true

chmod +x $CPU_MONITORS_DIR/*.sh

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
    "$CPU_MONITORS_DIR/$script" $APP_PID &
done

MEM_MONITORS=(
    # ""
)

for script in "${MEM_MONITORS[@]}"; do
    "$MEM_MONITORS_DIR/$script" $APP_PID &
done

NET_MONITORS=(
    # ""
)

for script in "${NET_MONITORS[@]}"; do
    "$NET_MONITORS_DIR/$script" $APP_PID &
done

echo -e "Press [Ctrl+C] to stop the test and save data."
wait