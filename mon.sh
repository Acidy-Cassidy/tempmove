#!/bin/bash

# Install inotify-tools if not already installed
# sudo apt-get install inotify-tools

# Define the log files to monitor
declare -a logs=(
    "/usr/local/zeek/logs/current/notice.log"
    "/usr/local/zeek/logs/current/weird.log"
    "/usr/local/zeek/logs/current/conn.log"
)

# Function to handle file modifications
on_log_update() {
    local log_file=$1
    echo "New activity detected in $(basename $log_file)."
}

# Use inotifywait to monitor the logs
while true; do
    inotifywait -e modify "${logs[@]}" --format '%w' | while read file; do
        on_log_update "$file"
    done
done
