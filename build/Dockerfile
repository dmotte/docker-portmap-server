FROM alpine

# Install required packages
RUN apk add --no-cache openssh-server

# Copy the OpenSSH Server config
COPY --chown=root:root --chmod=644 sshd_config /etc/ssh/

# Expose the SSH port
EXPOSE 22

RUN mkdir /ssh-host-keys /ssh-client-keys

# Copy the startup script
COPY --chown=root:root --chmod=755 startup.sh /

ENTRYPOINT ["/startup.sh"]
