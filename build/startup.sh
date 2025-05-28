#!/bin/sh

set -ex

keepalive_interval=${KEEPALIVE_INTERVAL:-30}

################################################################################

# Get host keys from the volume
rm -f /etc/ssh/ssh_host_*_key /etc/ssh/ssh_host_*_key.pub
install -m600 -t/etc/ssh /ssh-host-keys/ssh_host_*_key 2>/dev/null || :
install -m644 -t/etc/ssh /ssh-host-keys/ssh_host_*_key.pub 2>/dev/null || :

# Generate the missing host keys
ssh-keygen -A

# Copy the (previously missing) generated host keys to the volume
cp -nt/ssh-host-keys /etc/ssh/ssh_host_*_key 2>/dev/null || :
cp -nt/ssh-host-keys /etc/ssh/ssh_host_*_key.pub 2>/dev/null || :

################################################################################

[ $# -gt 0 ] || { echo 'You must specify at least one user' >&2; exit 1; }

:> /etc/ssh/sshd_config_users # Empty file

for arg; do
    user=$(echo "$arg" | cut -d: -f1)
    permits=$(echo "$arg" | cut -d: -f2- | tr , ' ')

    # If the user doesn't exist
    if ! id "$user" >/dev/null 2>&1; then
        addgroup -S "$user"; adduser -S "$user" -G "$user"

        # Enable the user to login via SSH (by setting the password field
        # to "*" in the shadow file)
        sed -Ei "s/^$user:!/$user:*/" /etc/shadow

        install -o"$user" -g"$user" -dm700 "/home/$user/.ssh"
    fi

    {
        echo "Match User $user"
        echo "    AllowTcpForwarding remote"
        echo "    PermitListen $permits"
        echo "    GatewayPorts yes"
    } >> /etc/ssh/sshd_config_users
done

for dir in /home/*; do
    user=$(basename "$dir")

    if [ ! -d "/ssh-client-keys/$user" ]; then
        # If mkdir fails, the /ssh-client-keys directory is probably mounted in
        # read-only mode
        mkdir "/ssh-client-keys/$user" || continue
        ssh-keygen -t ed25519 -C "$user" -N '' \
            -f "/ssh-client-keys/$user/ssh_client_key"
    fi

    # Note: not using install's "-T" flag as it's not supported in Alpine
    # shellcheck disable=SC3001
    install -o"$user" -g"$user" -m600 \
        <(cat "/ssh-client-keys/$user"/*.pub 2>/dev/null || :) \
        "/home/$user/.ssh/authorized_keys"
done

################################################################################

# Start the OpenSSH Server with "exec" to ensure it receives all the stop
# signals correctly
exec /usr/sbin/sshd -De -oClientAliveInterval="$keepalive_interval"
