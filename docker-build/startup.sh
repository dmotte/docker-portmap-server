#!/bin/sh

set -ex

# Generate host keys if not already present
ssh-keygen -A

# Add all the clients' public keys to the authorized_keys file
for i in "/home/portmap/.ssh/keys"/*; do
    cat $i >> "/home/portmap/.ssh/authorized_keys"
done

# Set valid permissions on the authorized_keys file
chown portmap:portmap "/home/portmap/.ssh/authorized_keys"
chmod 600 "/home/portmap/.ssh/authorized_keys"

# Start the OpenSSH Server
#   -D: prevent sshd from detaching and becoming a daemon
#   -e: print the log on stderr instead of syslog
/usr/sbin/sshd -De
