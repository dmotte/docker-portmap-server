#!/bin/sh

set -ex

# Generate host keys if not already present
ssh-keygen -A

if [ ! -d "/authorized_keys" ]; then
    echo "ERROR: the /authorized_keys directory doesn't exist"
    exit 1
fi

# Add all the clients' public keys to the authorized_keys file
for i in "/authorized_keys"/*; do
    cat $i >> "/home/portmap/.ssh/authorized_keys"
done

# Set valid permissions on the authorized_keys file
chown portmap:portmap "/home/portmap/.ssh/authorized_keys"
chmod 600 "/home/portmap/.ssh/authorized_keys"

# Start the OpenSSH Server
#   -D: prevent sshd from detaching and becoming a daemon
#   -e: print the log on stderr instead of syslog
/usr/sbin/sshd -De
