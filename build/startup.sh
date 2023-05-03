#!/bin/sh

set -ex

# Generate host keys if not already present
ssh-keygen -A

# Generate the authorized_keys file
cat /ssh-client-keys/*.pub > /home/portmap/.ssh/authorized_keys 2>/dev/null || true
chown portmap:portmap /home/portmap/.ssh/authorized_keys
chmod 600 /home/portmap/.ssh/authorized_keys

# Start the OpenSSH Server
#   -D: prevent sshd from detaching and becoming a daemon
#   -e: print the log on stderr instead of syslog
# We start it with "exec" to ensure it receives all the stop signals correctly
exec /usr/sbin/sshd -De
