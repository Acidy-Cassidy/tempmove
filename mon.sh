#!/bin/bash

# Define log files and their counters
declare -A logs
logs[dns]="/usr/local/zeek/logs/current/dns.log"
logs[notice]="/usr/local/zeek/logs/current/notice.log"
logs[capture_loss]="/usr/local/zeek/logs/current/capture_loss.log"
logs[conn]="/usr/local/zeek/logs/current/conn.log"
logs[loaded_scripts]="/usr/local/zeek/logs/current/loaded_scripts.log"
logs[packet_filter]="/usr/local/zeek/logs/current/packet_filter.log"
logs[stats]="/usr/local/zeek/logs/current/stats.log"
logs[telemetry]="/usr/local/zeek/logs/current/telemetry.log"
logs[weird]="/usr/local/zeek/logs/current/weird.log"
declare -A last_sizes
declare -A updates

# Initialize sizes and updates flags
for log in "${!logs[@]}"; do
    last_sizes[$log]=0
    updates[$log]=0
    if [ -f "${logs[$log]}" ]; then
        last_sizes[$log]=$(stat -c %s "${logs[$log]}")
    fi
done

# Function to check for file size changes and update flags
update_counters() {
    while true; do
        for log in "${!logs[@]}"; do
            if [ -f "${logs[$log]}" ]; then
                current_size=$(stat -c %s "${logs[$log]}")
                if [ $current_size -gt ${last_sizes[$log]} ]; then
                    updates[$log]=1  # Set flag that there's an update
                    last_sizes[$log]=$current_size
                fi
            fi
        done
        sleep 1  # check every second
    done
}

# Start updating counters in the background
update_counters &

# User interaction to view logs
control_c() {
    echo -e "\nExiting and cleaning up..."
    kill $(jobs -p) # Kill all background jobs
    exit
}

trap control_c INT

while true; do
    echo "Select a log file to view or exit:"
    i=1
    for log in "${!logs[@]}"; do
        if [ ${updates[$log]} -eq 1 ]; then
            echo "[$i] $log *"
        else
            echo "[$i] $log"
        fi
        ((i++))
    done
    echo "[$i] exit"

    read choice
    choice=$((choice-1))
    
    if [ "$choice" -eq "${#logs[@]}" ]; then
        control_c
    elif [ "$choice" -ge 0 ] && [ "$choice" -lt "${#logs[@]}" ]; then
        logname=$(echo "${!logs[@]}" | tr ' ' '\n' | sed -n "${choice}p")
        updates[$logname]=0  # Reset update flag
        less +F "${logs[$logname]}"
    else
        echo "Invalid option. Try another one."
    fi
done
