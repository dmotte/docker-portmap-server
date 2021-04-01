FROM alpine

RUN apk add --no-cache openssh-server
COPY sshd_config /etc/ssh
EXPOSE 22

COPY startup.sh /
RUN chmod +x /startup.sh

RUN addgroup -S portmap && adduser -S portmap -G portmap
USER portmap

WORKDIR /home/portmap
RUN mkdir .ssh && chmod 700 .ssh
RUN mkdir .ssh/keys

USER root
WORKDIR /

# Enable the portmap user to login via SSH (by setting the password field to "*"
# in the shadow file)
RUN sed -ir 's/^portmap:!/portmap:*/' /etc/shadow

ENTRYPOINT ["/startup.sh"]
