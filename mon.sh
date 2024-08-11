#!/bin/bash

# Define log files
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

# Temporary file for storing updates
temp_updates="/tmp/zeek_log_updates.txt"
echo "" > "$temp_updates"  # Clear or create the temp file

# Initialize last sizes
declare -A last_sizes
for log in "${!logs[@]}"; do
    if [ -f "${logs[$log]}" ]; then
        last_sizes[$log]=$(stat -c %s "${logs[$log]}")
        echo "$log 0" >> "$temp_updates"  # Initialize with no updates
    fi
done

# Function to check for file size changes and update temp file
update_counters() {
    local update_info=""
    while true; do
        update_info=""  # Reset info for this loop
        for log in "${!logs[@]}"; do
            if [ -f "${logs[$log]}" ]; then
                current_size=$(stat -c %s "${logs[$log]}")
                if [ $current_size -gt ${last_sizes[$log]} ]; then
                    last_sizes[$log]=$current_size
                    update_info+="$log 1\n"
                else
                    update_info+="$log 0\n"
                fi
            else
                update_info+="$log 0\n"  # No file found, no update
            fi
        done
        echo -e "$update_info" > "$temp_updates"  # Write all updates at once
        sleep 1  # Check every second
    done
}

# Start updating counters in the background
update_counters &

# User interaction to view logs
control_c() {
    echo -e "\nExiting and cleaning up..."
    kill $(jobs -p)  # Kill all background jobs
    rm -f "$temp_updates"  # Remove temporary file
    exit
}

trap control_c INT

while true; do
    clear  # Clear the screen to refresh the menu
    echo "Select a log file to view or exit:"
    i=1
    options=()  # To store log names for indexing
    declare -A updates  # Local array to read updates into

    # Read updates from the temp file
    while IFS=' ' read -r log updated; do
        updates[$log]=$updated
    done < "$temp_updates"

    for log in "${!logs[@]}"; do
        options+=("$log")
        if [ "${updates[$log]}" -eq 1 ]; then
            echo "[$i] $log *"
        else
            echo "[$i] $log"
        fi
        ((i++))
    done
    options+=("exit")  # Add exit option at the end
    echo "[$i] exit"

    read choice
    choice=$((choice - 1))

    if [ "$choice" -eq "${#logs[@]}" ]; then
        control_c
    elif [ "$choice" -ge 0 ] && [ "$choice" -lt "${#logs[@]}" ]; then
        selected_log=${options[$choice]}
        echo "$selected_log 0" > "$temp_updates"  # Reset update flag
        less +F "${logs[$selected_log]}"
    else
        echo "Invalid option. Try another one."
    fi
done
