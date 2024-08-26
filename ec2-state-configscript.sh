#!/bin/bash

# Function to display usage
usage() {
    echo "Usage: $0 <no_of_instances> <1|0>"
    echo "no_of_instances: Number of instances you want to manage"
    echo "1: Start instances"
    echo "0: Stop instances"
    exit 1
}

# Check if exactly two arguments are passed
if [ "$#" -ne 2 ]; then
    usage
fi

# Extract the number of instances and operation
no_of_instances=$1
operation=$2

# Validate the operation
if [ "$operation" -ne 1 ] && [ "$operation" -ne 0 ]; then
    echo "Invalid operation: $operation"
    usage
fi

# Prompt the user to enter the instance IDs
instance_ids=()
for (( i=1; i<=$no_of_instances; i++ )); do
    read -p "Enter Instance ID $i: " instance_id
    instance_ids+=("$instance_id")
done

# Loop through each instance ID provided by the user
for instance_id in "${instance_ids[@]}"; do
    # Check if the instance exists and get its state and name
    instance_info=$(aws ec2 describe-instances --instance-ids "$instance_id" --query "Reservations[].Instances[].{ID:InstanceId,State:State.Name,Name:Tags[?Key=='Name'].Value|[0]}" --output text 2>/dev/null)

    if [ -z "$instance_info" ]; then
        echo "Instance ID $instance_id does not exist or could not be retrieved."
        continue
    fi

    instance_state=$(echo "$instance_info" | awk '{print $3}')
    instance_name=$(echo "$instance_info" | awk '{print $2}')

    # Handle cases where the instance might not have a Name tag
    if [ -z "$instance_name" ]; then
        instance_name="(No Name)"
    fi

    echo "Instance ID: $instance_id"
    echo "Instance Name: $instance_name"
    echo "Current State: $instance_state"

    if [ "$operation" -eq 1 ]; then
        # Start the instance if it's stopped
        if [ "$instance_state" = "stopped" ]; then
            echo "Starting instance $instance_id ($instance_name)..."
            aws ec2 start-instances --instance-ids "$instance_id" --output text
        else
            echo "Instance $instance_id ($instance_name) is already running or in a state where it can't be started."
        fi
    elif [ "$operation" -eq 0 ]; then
        # Stop the instance if it's running
        if [ "$instance_state" = "running" ]; then
            echo "Stopping instance $instance_id ($instance_name)..."
            aws ec2 stop-instances --instance-ids "$instance_id" --output text
        else
            echo "Instance $instance_id ($instance_name) is already stopped or in a state where it can't be stopped."
        fi
    fi

    echo ""
done