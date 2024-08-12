#!/bin/bash

# Define color codes for better visibility
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'  # Adding blue for other types of logs
NC='\033[0m' # No Color

# Define bold and underline text for emphasis
BOLD='\033[1m'
UNDERLINE='\033[4m'

# Define the log files to monitor
declare -a logs=(
    "/usr/local/zeek/logs/current/notice.log",
    "/usr/local/zeek/logs/current/weird.log",
    "/usr/local/zeek/logs/current/conn.log"
)

# Function to handle file modifications
on_log_update() {
    local log_file=$1
    local base_log_file=$(basename "$log_file")

    # Determine the color and prefix based on the log type
    local color="$GREEN"
    local prefix="${BOLD}Update"

    case "$base_log_file" in
        "notice.log")
            color="$RED"
            prefix="${BOLD}${UNDERLINE}Alert"
            ;;
        "weird.log")
            color="$YELLOW"
            prefix="${BOLD}Warning"
            ;;
        "conn.log")
            color="$BLUE"
            prefix="${BOLD}Connection Update"
            ;;
    esac

    # Print the message with the chosen color and prefix, including timestamp
    echo -e "${color}$(date '+%Y-%m-%d %H:%M:%S') - ${prefix} in ${base_log_file}:${NC} A new entry has been detected."
}

# Use inotifywait to monitor the logs for modifications
while true; do
    inotifywait -e modify "${logs[@]}" --format '%w' | while read file; do
        on_log_update "$file"
    done
done
