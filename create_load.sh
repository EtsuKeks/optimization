#!/bin/bash

PID=$1
while kill -0 $PID 2>/dev/null; do
    sleep 10
    curl http://localhost:8080/ > /dev/null 2> /dev/null
done