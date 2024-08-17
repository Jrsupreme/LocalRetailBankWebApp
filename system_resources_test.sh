#!/bin/bash

#set up thresholds
#check for system resources
#get cpu, memory and disk usage
#compared usage to threshold
#display results
#set up exit

#Lets set up a few  functions to check the cpu, memory and disk usage

# Function to check for cpu usage
check_cpu() {
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
    cpu_threshold=70

    if (( $(echo "$cpu_usage > $cpu_threshold" | bc -l) )); then
        echo "CPU usage is high: $cpu_usage%"
        return 1
    else
        echo "CPU usage is normal: $cpu_usage%"
        return 0
    fi
}

# Function to check memory usage
check_memory() {
    memory_usage=$(free | grep Mem | awk '{print $3/$2 * 100.0}')
    memory_threshold=90

    if (( $(echo "$memory_usage > $memory_threshold" | bc -l) )); then
        echo "Memory usage is high: $memory_usage%"
        return 1
    else
        echo "Memory usage is normal: $memory_usage%"
        return 0
    fi
}

# Function to check disk usage
check_disk() {
    disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    disk_threshold=80

    if (( disk_usage > disk_threshold )); then
        echo "Disk usage is high: $disk_usage%"
        return 1
    else
        echo "Disk usage is normal: $disk_usage%"
        return 0
    fi
}

# Main script
echo "Checking system resources..."

check_cpu
cpu_status=$?

check_memory
memory_status=$?

check_disk
disk_status=$?

# Check if any resource exceeded the threshold
if [ $cpu_status -eq 1 ] || [ $memory_status -eq 1 ] || [ $disk_status -eq 1 ]; then #we use || here because the moment one of the statement is true the script will post warning and exist  
    echo "One or more system resources exceeded the threshold."
    exit 1
else
    echo "All system resources are within normal limits."
    exit 0
fi
