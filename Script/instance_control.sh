#!/bin/bash

# Path to the file containing the instance IDs
INSTANCE_FILE="instance_ids.txt"

# Check if the file exists
if [[ ! -f "$INSTANCE_FILE" ]]; then
  echo "File $INSTANCE_FILE not found!"
  exit 1
fi

# Function to start instances
start_instances() {
  echo "Starting EC2 instances..."
  while IFS= read -r instance_id; do
    if [[ -n "$instance_id" ]]; then
      echo "Starting instance ID: $instance_id"
      output=$(aws ec2 start-instances --instance-ids "$instance_id" 2>&1)
      status=$?
      echo "AWS CLI Output: $output"
      if [[ $status -eq 0 ]]; then
        echo "Instance $instance_id started successfully."
      else
        echo "Failed to start instance $instance_id. AWS CLI returned status $status" >&2
      fi
    else
      echo "Empty instance ID encountered." >&2
    fi
  done < "$INSTANCE_FILE"
}

# Function to stop instances
stop_instances() {
  echo "Stopping EC2 instances..."
  while IFS= read -r instance_id; do
    if [[ -n "$instance_id" ]]; then
      echo "Stopping instance ID: $instance_id"
      output=$(aws ec2 stop-instances --instance-ids "$instance_id" 2>&1)
      status=$?
      echo "AWS CLI Output: $output"
      if [[ $status -eq 0 ]]; then
        echo "Instance $instance_id stopped successfully."
      else
        echo "Failed to stop instance $instance_id. AWS CLI returned status $status" >&2
      fi
    else
      echo "Empty instance ID encountered." >&2
    fi
  done < "$INSTANCE_FILE"
}

# Prompt user for action
echo "Do you want to start or stop the instances? (start/stop)"
read -r ACTION

case $ACTION in
  start)
    start_instances
    ;;
  stop)
    stop_instances
    ;;
  *)
    echo "Invalid option. Please choose 'start' or 'stop'."
    exit 1
    ;;
esac

echo "Action $ACTION completed."
