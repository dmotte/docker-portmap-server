FROM alpine

# Install required packages
RUN apk add --no-cache openssh-server

# Copy the OpenSSH Server config
COPY sshd_config /etc/ssh

# Expose the SSH port
EXPOSE 22

# Copy the startup script
COPY startup.sh /
RUN chmod +x /startup.sh

# Create the portmap user
RUN addgroup -S portmap && adduser -S portmap -G portmap

# Enable the portmap user to login via SSH (by setting the password field to "*"
# in the shadow file)
RUN sed -ir 's/^portmap:!/portmap:*/' /etc/shadow

# As the portmap user, create the .ssh directory
USER portmap
WORKDIR /home/portmap

RUN mkdir .ssh && chmod 700 .ssh

# Become the root user again and declare the entrypoint
USER root
WORKDIR /

ENTRYPOINT ["/startup.sh"]
