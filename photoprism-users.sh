#!/bin/sh

# ---------------------------------------------------------------
# PhotoPrism User Management Script
# 
# Description:
# This script provides a menu-driven interface for managing users
# in a PhotoPrism instance. It allows for adding, modifying, displaying,
# and removing user accounts.
#
# Requirements:
# - Docker must be installed and running.
# - A running PhotoPrism instance in Docker.
# - At least PhotoPrism Essentials is required for user management features.
#
# Usage:
# 1. Save this script to a file, e.g., `photoprism-users.sh`.
# 2. Modify DOCKER_CONTAINER_NAME if your docker container name is not photoprism
# 3. Make the script executable: `chmod +x photoprism-users.sh`
# 4. Ensure you have the necessary privileges to interact with Docker. If not, run the script as root or use sudo.
# 5. Run the script: `./photoprism-users.sh` or `sudo ./photoprism-users.sh`
#
# Important:
# - Always ensure you have backups and understand the implications of
#   any changes you make to user accounts.
# - Ensure the user running this script has the necessary privileges to 
#   interact with Docker and PhotoPrism. If in doubt, run the script as root 
#   or with sudo.
# ---------------------------------------------------------------


# Set the name of your PhotoPrism Docker container here. Default is "photoprism".
DOCKER_CONTAINER_NAME="photoprism"


echo "---------------------------------------------------------------"
echo "PhotoPrism User Management Script"
echo "Manage, display and modify user data."
echo ""
echo "- Ensure you have backups before making changes."
echo "- Run with proper privileges or use sudo for Docker interactions."
echo "---------------------------------------------------------------"
echo ""

# Loading animation as docker can take some time to respond
spinner() {
    local pid=$1
    local delay=0.75
    local spinstr='|/-\'
    echo -n "Processing"
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

while true; do
    echo "PhotoPrism User Management Menu:"
    echo "1. Add a new user"
    echo "2. List existing user accounts"
    echo "3. Display account information of a specific user"
    echo "4. Modify an existing user account"
    echo "5. Remove a user account"
    echo "6. Exit"
    echo "Enter your choice:"
    read CHOICE

    case $CHOICE in
        1)
            # Add a new user
            echo "Enter a display name for the interface:"
            read NAME

            echo "Enter a unique email address of the user:"
            read EMAIL

            echo "Enter a password for authentication:"
            read PASSWORD

            echo "Should the user be an admin? (y/N, 'N' or empty = 'user'):"
            read IS_ADMIN

            if [ -z "$IS_ADMIN" ] || [ "$IS_ADMIN" = "n" ] || [ "$IS_ADMIN" = "N" ]; then
                ROLE="user"
                SUPERADMIN_FLAG=""
            else
                ROLE="admin"
                echo "Should the user be a super admin with full access? (y/N):"
                read SUPERADMIN
                if [ "$SUPERADMIN" = "y" ] || [ "$SUPERADMIN" = "Y" ]; then
                    SUPERADMIN_FLAG="-s"
                else
                    SUPERADMIN_FLAG=""
                fi
            fi

            # WebDAV is always allowed
            WEBDAV_FLAG="-w"

            # Prompt for sub-directory until a valid value is entered
            while [ -z "$UPLOAD_PATH" ]; do
                echo "Enter a new sub-directory for uploads without /:		# subdirectory of the 'Originals' folder set in PhotoPrism config"
				echo ""
                read UPLOAD_PATH
            done

            UPLOAD_PATH_FLAG="-u $UPLOAD_PATH"

            # Construct the full command
            CMD="docker exec $DOCKER_CONTAINER_NAME photoprism users add -n \"$NAME\" -m \"$EMAIL\" -p \"$PASSWORD\" -r \"$ROLE\" $SUPERADMIN_FLAG $WEBDAV_FLAG $UPLOAD_PATH_FLAG"
			$CMD & spinner $!
			echo ""
            ;;

        2)
            # List existing user accounts
            CMD="docker exec photoprism photoprism users ls"
			$CMD & spinner $!
			echo ""
            ;;

        3)
            # Display user account information
            echo "Enter a username to display information for:"
            read USERNAME
            CMD="docker exec $DOCKER_CONTAINER_NAME photoprism users show $USERNAME"
			$CMD & spinner $!
			echo ""
            ;;

        4)
            # Modify an existing user account
            echo "Enter a username to modify:"
            read USERNAME

            echo "Enter a new display name (or press Enter to skip):"
            read NAME
            NAME_FLAG=""
            if [ ! -z "$NAME" ]; then
                NAME_FLAG="-n $NAME"
            fi

            echo "Enter a new email (or press Enter to skip):"
            read EMAIL
            EMAIL_FLAG=""
            if [ ! -z "$EMAIL" ]; then
                EMAIL_FLAG="-m $EMAIL"
            fi

            echo "Enter a new password (or press Enter to skip):"
            read PASSWORD
            PASSWORD_FLAG=""
            if [ ! -z "$PASSWORD" ]; then
                PASSWORD_FLAG="-p $PASSWORD"
            fi

            echo "Should the user be an admin? (y/n, press Enter to skip):"
			read IS_ADMIN
			ROLE_FLAG=""
			SUPERADMIN_FLAG=""
			if [ "$IS_ADMIN" = "y" ] || [ "$IS_ADMIN" = "Y" ]; then
				ROLE_FLAG="-r admin"
				echo "Should the user be a super admin with full access? (y/n, press Enter to skip):"
				read SUPERADMIN
				if [ "$SUPERADMIN" = "y" ] || [ "$SUPERADMIN" = "Y" ]; then
					SUPERADMIN_FLAG="-s"
				fi
			elif [ "$IS_ADMIN" = "n" ] || [ "$IS_ADMIN" = "N" ]; then
				ROLE_FLAG="-r user"
			fi

			# Prompt for WebDAV
			echo "Should the user be allowed to sync files via WebDAV? (y/N, press Enter to skip):"
			read WEBDAV
			WEBDAV_FLAG=""
			if [ "$WEBDAV" = "y" ] || [ "$WEBDAV" = "Y" ]; then
				WEBDAV_FLAG="-w"
			fi

			# Prompt for login
			echo "Should the user be allowed to login on the web interface? (y/N, press Enter to skip):"
			read LOGIN
			LOGIN_FLAG=""
			if [ "$LOGIN" = "n" ] || [ "$LOGIN" = "N" ]; then
				LOGIN_FLAG="-l"
			fi

            # Prompt for sub-directory
            echo "Enter a new sub-directory for uploads without / (or press Enter to skip):"
            read UPLOAD_PATH
            UPLOAD_PATH_FLAG=""
            if [ ! -z "$UPLOAD_PATH" ]; then
                UPLOAD_PATH_FLAG="-u $UPLOAD_PATH"
            fi

            # Construct the full command
            CMD="docker exec $DOCKER_CONTAINER_NAME photoprism users mod $NAME_FLAG $EMAIL_FLAG $PASSWORD_FLAG $ROLE_FLAG $SUPERADMIN_FLAG $WEBDAV_FLAG $LOGIN_FLAG $UPLOAD_PATH_FLAG $USERNAME"
			$CMD & spinner $!
			echo ""
            ;;

        5)
            # Remove a user account
            echo "Enter a username to remove:"
            read USERNAME

            echo "For confirmation, please re-enter the username:"
            read CONFIRM_USERNAME

            if [ "$USERNAME" = "$CONFIRM_USERNAME" ]; then
                CMD="docker exec $DOCKER_CONTAINER_NAME photoprism users rm $USERNAME"
				$CMD & spinner $!
				echo ""
            else
                echo "Usernames do not match. User not removed."
            fi
            ;;

        6)
            # Exit the script
            exit 0
            ;;

        *)
            echo "Invalid choice. Please select a valid option."
            ;;
    esac
done
