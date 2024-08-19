#!/bin/bash

#set up thresholds
#check for system resources
#get cpu, memory and disk usage
#compared usage to threshold
#display results
#set up exit

#Setting up functions to check for cpu, memory and disk usage.

# Function to check for cpu usage
check_cpu() {
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}') #Looks at system resource consumption logs and specifically isolates the cpu usage number and stores the result in the variable 'cpu_usage'.
    cpu_threshold=70

    if (( $(echo "$cpu_usage > $cpu_threshold" | bc -l) )); then #Compares the cpu usage numbers to the set threshold.
        echo "CPU usage is high: $cpu_usage%"    
        return 1 #If cpu usage exceeds threshold exit function with error code.
    else
        echo "CPU usage is normal: $cpu_usage%"
        return 0 #If cpu usage DOES NOT exceed threshold exit function with success code.
    fi
}

# Function to check memory usage
check_memory() {
    memory_usage=$(free | grep Mem | awk '{print $3/$2 * 100.0}') #Looks at the memory usage numbers and calculates the usage dividing used memory by total memory and stores the result in the variable 'memory_usage'.
    memory_threshold=90 

    if (( $(echo "$memory_usage > $memory_threshold" | bc -l) )); then #Compares memory usage numbers to the threshold.
        echo "Memory usage is high: $memory_usage%"
        return 1  #If mem usage exceeds threshold exit function with error code.
    else
        echo "Memory usage is normal: $memory_usage%"
        return 0  #If mem usage DOES NOT exceed threshold exit function with success code.
    fi
}

# Function to check disk usage
check_disk() {
    disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')  #Retrieves the disk usage percentage of the root ("/"), removes the "%" sign, and stores the value in the variable 'disk_usage'.
    disk_threshold=70

    if (( disk_usage > disk_threshold )); then #compares disk usage to theshold.
        echo "Disk usage is high: $disk_usage%"
        return 1 #If disk usage exceeds threshold exit function with error code.
    else
        echo "Disk usage is normal: $disk_usage%"
        return 0 #If disk usage DOES NOT exceed threshold exit function with success code.
    fi
}

# Main script
#Since functions have already been set, the main script only needs to check for 1's and 0's (which is pretty cool)
echo "Checking system resources..."

check_cpu # Runs the check_cpu function and stores its exit status in the variable 'cpu_status'.
cpu_status=$?

check_memory # Runs the check_memory function and stores its exit status in the variable 'memory_status'.
memory_status=$?

check_disk # Runs the check_disk function and stores its exit status in the variable 'disk_status'.
disk_status=$?

# Check if any resource exceeded the threshold
if [ $cpu_status -eq 1 ] || [ $memory_status -eq 1 ] || [ $disk_status -eq 1 ]; then # If any of the conditions (cpu, memory, or disk status) is true, the script will post a warning and exit.
    echo "One or more system resources exceeded the threshold."
    exit 1
else
    echo "All system resources are within normal limits."
    exit 0
fi
