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
declare -A counters
counters[dns]=0
counters[notice]=0
counters[capture_loss]=0
counters[conn]=0
counters[loaded_scripts]=0
counters[packet_filter]=0
counters[stats]=0
counters[telemetry]=0
counters[weird]=0

# Function to monitor a log file and update counters
monitor_log() {
    local log_name=$1
    local log_file=${logs[$log_name]}
    tail -n0 -F "$log_file" | while read line; do
        counters[$log_name]=$(( ${counters[$log_name]} + 1 ))
    done
}

# Start monitoring each log in the background
for log in "${!logs[@]}"; do
    monitor_log "$log" &
done

# User interaction to view logs
control_c() {
    echo -e "\nExiting and cleaning up..."
    kill $(jobs -p) # Kill all background jobs
    exit
}

trap control_c INT

while true; do
    echo "Select a log file to view or exit:"
    for log in "${!logs[@]}"; do
        echo "$log (${counters[$log]} new entries)"
    done
    echo "exit"
    
    read choice

    if [[ $choice == "exit" ]]; then
        control_c
    elif [[ -n "${logs[$choice]}" ]]; then
        less +F "${logs[$choice]}"
    else
        echo "Invalid option. Try another one."
    fi
done
