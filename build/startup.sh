#!/bin/sh

set -ex

# Get host keys from /ssh-host-keys
rm -f /etc/ssh/ssh_host_*_key /etc/ssh/ssh_host_*_key.pub
cp /ssh-host-keys/ssh_host_*_key /etc/ssh/ 2>/dev/null || true
cp /ssh-host-keys/ssh_host_*_key.pub /etc/ssh/ 2>/dev/null || true

# Generate the missing host keys
ssh-keygen -A

# Set correct permissions on host keys
chown root:root /etc/ssh/ssh_host_*_key /etc/ssh/ssh_host_*_key.pub
chmod 600 /etc/ssh/ssh_host_*_key
chmod 644 /etc/ssh/ssh_host_*_key.pub

# Copy the (previously missing) generated host keys to /ssh-host-keys
cp -n /etc/ssh/ssh_host_*_key /ssh-host-keys/ 2>/dev/null || true
cp -n /etc/ssh/ssh_host_*_key.pub /ssh-host-keys/ 2>/dev/null || true

# Generate the authorized_keys file and set correct permissions
cat /ssh-client-keys/*.pub > /home/portmap/.ssh/authorized_keys 2>/dev/null || true
chown portmap:portmap /home/portmap/.ssh/authorized_keys
chmod 600 /home/portmap/.ssh/authorized_keys

# Start the OpenSSH Server
#   -D: prevent sshd from detaching and becoming a daemon
#   -e: print the log on stderr instead of syslog
# We start it with "exec" to ensure it receives all the stop signals correctly
exec /usr/sbin/sshd -De
