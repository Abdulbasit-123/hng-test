This Bash script automates user account management tasks, streamlining the onboarding process for new employees, users, or accounts. It creates users, assigns them to groups, and generates secure passwords. The script also logs actions for transparency and auditability.

#How to Use

Prerequisites: This script requires Bash execution privileges. Ensure you have permission to run Bash scripts on your system.

Configuration: Edit the script to configure variables like log file path (log_file), password file path (password_file), and user file path (user_file).

User File Format: The user file should contain user information on each line, separated by semicolons (;). Each line should follow the format username;group1,group2,.... The script will create the user with the specified username, add them to the listed groups, and generate a random password.

Run the Script: Once configured, execute the script using bash create_users.sh

Here is a link to a detailed documentation of the script <a/>https://basitt.hashnode.dev/automating-user-and-group-creation-with-bash-scripts<a/>
