#!/usr/bin/env bash

#
# Rollback To Previous Version
#
# Pulls and deploys the previous version of the current branch from remote origin.
#

# Import common functions
source ./common.sh

# Print header
clear
echo "====================================="
echo "      Revert To Previous Version"
echo

# Check user is root
check_errs $EUID "This script must be run as root"

# Check if required packages are installed
echo "Checking required packages"
check_package pwgen
check_package docker
check_package docker-compose
echo

# Determine previous version git hash
previous=$(git log --format=%H | sed -n 2p)
check_errs $? "Unable to determine previous git version hash"

# Rollback previous version
git reset $previous
check_errs $? "Unable to git-reset previous version from repository"

# Create a directory to store passwords
if [ -e secrets ]
then
    echo "secrets directory already exists"
else
    echo "Creating secrets directory"
    mkdir secrets
    check_errs $? "Failed creating secrets directory"
fi
chmod 660 secrets
check_errs $? "Failed setting secret directory permissions"

# Create passwords
#create_password secrets/postgres_password.txt 27
#create_password secrets/django_secret_key.txt 47
#create_password secrets/django_admin_pass.txt 27

# Get email address for LetsEncrypt certbot
file=secrets/certbot_email.txt
if [ -e $file ]
then
    echo "LetsEncrypt certbot administrator email already exists"
else
    echo
    echo "Enter administrators email for LetsEncrypt certbot certificate creation"
    read email
    echo $email >> $file
    check_errs $? "Failed storing LetsEncrypt certbot email"
fi

# Ensure docker is running
service docker start
check_errs $? "Failed starting docker"

# Stop containers
docker-compose down
check_errs $? "Failed stopping containers"

# Rebuild containers
echo
echo "Building containers"
docker-compose build
check_errs $? "Failed building containers"

# Run containers in background
echo
echo "Starting containers"
docker-compose up -d &
check_errs $? "Failed starting containers"

# Allow for startup
sleep 5

echo
echo "Rollback Completed"
echo "Project is running"
echo
