#!/bin/sh

set -ex

# Generate host keys if not already present
ssh-keygen -A

# Add all the client public keys to the authorized_keys file
for i in /ssh-client-keys/*; do
    [ -f "$i" ] || continue
    cat "$i" >> /home/portmap/.ssh/authorized_keys
done

# Set valid permissions on the authorized_keys file (if it exists)
if [ -f /home/portmap/.ssh/authorized_keys ]; then
    chown portmap:portmap /home/portmap/.ssh/authorized_keys
    chmod 600 /home/portmap/.ssh/authorized_keys
fi

# Start the OpenSSH Server
#   -D: prevent sshd from detaching and becoming a daemon
#   -e: print the log on stderr instead of syslog
# We start it with "exec" to ensure it receives all the stop signals correctly
exec /usr/sbin/sshd -De
