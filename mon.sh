#!/bin/bash

# Define color codes for better visibility
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Define the log files to monitor
declare -a logs=(
    "/usr/local/zeek/logs/current/notice.log"
    "/usr/local/zeek/logs/current/weird.log"
    "/usr/local/zeek/logs/current/conn.log"
)

# Function to handle file modifications
on_log_update() {
    local log_file=$1
    local base_log_file=$(basename "$log_file")

    # Determine the color based on the log type
    local color="$GREEN"
    local prefix="Update"

    if [[ "$base_log_file" == "notice.log" ]]; then
        color="$RED"
        prefix="Alert"
    elif [[ "$base_log_file" == "weird.log" ]]; then
        color="$YELLOW"
        prefix="Warning"
    fi

    # Print the message with the chosen color and prefix
    echo -e "${color}${prefix} in ${base_log_file}:${NC} A new entry has been detected."
}

# Use inotifywait to monitor the logs
while true; do
    inotifywait -e modify "${logs[@]}" --format '%w' | while read file; do
        on_log_update "$file"
    done
done
