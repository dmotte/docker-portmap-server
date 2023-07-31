#!/bin/sh

set -ex

################################################################################

# Get host keys from the volume
rm -f /etc/ssh/ssh_host_*_key /etc/ssh/ssh_host_*_key.pub
cp /ssh-host-keys/ssh_host_*_key /etc/ssh/ 2>/dev/null || :
cp /ssh-host-keys/ssh_host_*_key.pub /etc/ssh/ 2>/dev/null || :

# Generate the missing host keys
ssh-keygen -A

# Set correct permissions on host keys
chown root:root /etc/ssh/ssh_host_*_key /etc/ssh/ssh_host_*_key.pub
chmod 600 /etc/ssh/ssh_host_*_key
chmod 644 /etc/ssh/ssh_host_*_key.pub

# Copy the (previously missing) generated host keys to the volume
cp -n /etc/ssh/ssh_host_*_key /ssh-host-keys/ 2>/dev/null || :
cp -n /etc/ssh/ssh_host_*_key.pub /ssh-host-keys/ 2>/dev/null || :

################################################################################

if [ $# -eq 0 ]; then
    echo "You must specify at least one user" 1>&2
    exit 1
fi

:> /etc/ssh/sshd_config_users # Empty file

for arg in "$@"; do
    user="$(echo "$arg" | cut -d: -f1)"
    permits="$(echo "$arg" | cut -d: -f2- | tr ',' ' ')"

    # If the user doesn't exist
    if ! id "$user" >/dev/null 2>&1; then
        addgroup -S "$user" && adduser -S "$user" -G "$user"

        # Enable the user to login via SSH (by setting the password field
        # to "*" in the shadow file)
        sed -Ei "s/^$user:!/$user:*/" /etc/shadow

        mkdir "/home/$user/.ssh"
        chown "$user:$user" "/home/$user/.ssh"
        chmod 700 "/home/$user/.ssh"
    fi

    {
        echo "Match User $user"
        echo "    AllowTcpForwarding remote"
        echo "    PermitListen $permits"
        echo "    GatewayPorts yes"
    } >> /etc/ssh/sshd_config_users
done

for dir in /home/*; do
    user="$(basename "$dir")"

    if [ ! -d "/ssh-client-keys/$user" ]; then
        # If mkdir fails, the /ssh-client-keys directory is probably mounted in
        # read-only mode
        mkdir "/ssh-client-keys/$user" || continue
        ssh-keygen -t ed25519 -C "$user" -N "" \
            -f "/ssh-client-keys/$user/ssh_client_key"
    fi

    cat "/ssh-client-keys/$user"/*.pub > "/home/$user/.ssh/authorized_keys" \
        2>/dev/null || :
    chown "$user:$user" "/home/$user/.ssh/authorized_keys"
    chmod 600 "/home/$user/.ssh/authorized_keys"
done

################################################################################

# Start the OpenSSH Server with "exec" to ensure it receives all the stop
# signals correctly
exec /usr/sbin/sshd -De
