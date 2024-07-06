#!/bin/bash

# Function to log messages
log_message() {
    echo "$(date): $1" >> /var/log/user_management.log
}

# Function to generate a random password
generate_password() {
    tr -dc 'A-Za-z0-9!@#$%^&*()_+' < /dev/urandom | head -c 12
}

# Check if the script is run with root privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Check if a filename is provided as an argument
if [ $# -eq 0 ]; then
    echo "Usage: $0 <filename>"
    exit 1
fi

input_file="$1"

# Check if the input file exists
if [ ! -f "$input_file" ]; then
    echo "Input file not found: $input_file"
    exit 1
fi

# Create log file if it doesn't exist
touch /var/log/user_management.log

# Create secure password file if it doesn't exist
touch /var/secure/user_passwords.csv
chmod 600 /var/secure/user_passwords.csv

# Process each line in the input file
while IFS=';' read -r username groups || [[ -n "$username" ]]; do
    # Remove leading/trailing whitespace
    username=$(echo "$username" | xargs)
    groups=$(echo "$groups" | xargs)

    # Create personal group for the user
    if ! getent group "$username" > /dev/null 2>&1; then
        groupadd "$username"
        log_message "Created personal group: $username"
    else
        log_message "Personal group already exists: $username"
    fi

    # Create user if not exists
    if ! id "$username" &>/dev/null; then
        useradd -m -g "$username" "$username"
        log_message "Created user: $username"
    else
        log_message "User already exists: $username"
    fi

    # Generate and set password
    password=$(generate_password)
    echo "$username:$password" | chpasswd
    echo "$username,$password" >> /var/secure/user_passwords.csv
    log_message "Set password for user: $username"

    # Add user to additional groups
    IFS=',' read -ra group_array <<< "$groups"
    for group in "${group_array[@]}"; do
        group=$(echo "$group" | xargs)
        if [ -n "$group" ]; then
            if ! getent group "$group" > /dev/null 2>&1; then
                groupadd "$group"
                log_message "Created group: $group"
            fi
            usermod -a -G "$group" "$username"
            log_message "Added user $username to group: $group"
        fi
    done

    # Set appropriate permissions for home directory
    chown -R "$username:$username" "/home/$username"
    chmod 700 "/home/$username"
    log_message "Set permissions for /home/$username"

done < "$input_file"

echo "User creation process completed. Check /var/log/user_management.log for details."
