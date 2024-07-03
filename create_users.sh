#!/bin/bash

mkdir -p /var/secure && chmod 750 /var/secure


# Script arguments
user_file="$1"

# Log file and password file paths
log_file="/var/log/user_management.log"
password_file="/var/secure/user_passwords.csv"

# Function to check and create directories if needed
create_directories() {
  local log_dir="${log_file%/*}"  # Extract directory path for log file
  local password_dir="${password_file%/*}"  # Extract directory path for password file

  if [ ! -d "$log_dir" ]; then
    sudo mkdir -p "$log_dir" &>> "$log_file"  # Create log directory with sudo
  fi

  if [ ! -d "$password_dir" ]; then
    sudo mkdir -p "$password_dir" &>> "$password_file"  # Create password directory with sudo
  fi
}


# Function to generate a random password
generate_password() {
  length=16  # Adjust password length as needed
  cat /dev/urandom | tr -dc 'A-Za-z0-9!@#$%^&*()' | fold -w $length | head -n 1
}

# Function to create a user and groups
create_user_and_groups() {
  username="$1"
  user_groups="$2"

  # Create the user's primary group with the same name as the username
  groupadd "$username" &>> "$log_file"

  # Generate a random password
  password=$(generate_password)

  # Check if user already exists
  if id "$username" &> /dev/null; then
    echo "User '$username' already exists, skipping." >> "$log_file"
  else
    # Create the user with home directory and set permissions
    useradd -m -s /bin/bash -G "$username" "$username" &>> "$log_file"
    chown -R "$username:$username" "/home/$username" &>> "$log_file"
    chmod 700 "/home/$username" &>> "$log_file"

    # Set the user's password and store it securely
    echo "$username:$password" >> "$password_file"
    echo "  - Created user '$username' with password '$password'" >> "$log_file"
    echo "$password" | passwd --stdin "$username" &>> "$log_file"

    # Add user to additional groups (if any)
    for group in $(echo "$user_groups" | tr ',' ' '); do
      if ! grep -q "$group" /etc/group; then
        echo "Group '$group' does not exist, skipping." >> "$log_file"
      else
        usermod -aG "$group" "$username" &>> "$log_file"
      fi
    done
  fi
}

# Check if user file exists
if [ ! -f "$user_file" ]; then
  echo "Error: User file '$user_file' not found." >&2
  exit 1
fi

# Check and create log and password files if needed
touch "$log_file" "$password_file"
chmod 600 "$password_file"  # Only owner can read password file


# Loop through each line in the user file
while IFS=';' read -r username user_groups; do
  
  # Add header row (only on the first iteration)
  if [[ "$line_number" -eq 1 ]]; then
    echo "username,password" >> "$password_file"
    line_number=2
  fi

  # Generate password
  password=$(generate_password)

  # Write username and password to CSV (comma separated)
  echo "$username,$password" >> "$password_file"
done < "$user_file"

# Reset line number variable
line_number=1


echo "User creation completed. See log file '$log_file' for details."
