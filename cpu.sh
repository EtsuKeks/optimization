#!/bin/bash

BINARY="./bin/app"
MONITOR_DIR="./cpu"

chmod +x $MONITOR_DIR/*.sh

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

MONITORS=(
    "context_switches.sh"
    "core_distribution.sh"
    "process_cpu.sh"
    "scheduler_wait.sh"
    "system_cpu.sh"
    "thread_count.sh"
)

for script in "${MONITORS[@]}"; do
    "$MONITOR_DIR/$script" $APP_PID &
done

echo -e "Press [Ctrl+C] to stop the test and save data."
wait