# docker-portmap-server

![icon](icon-149.png)

[![GitHub main workflow](https://img.shields.io/github/actions/workflow/status/dmotte/docker-portmap-server/main.yml?branch=main&logo=github&label=main&style=flat-square)](https://github.com/dmotte/docker-portmap-server/actions)
[![Docker Pulls](https://img.shields.io/docker/pulls/dmotte/portmap-server?logo=docker&style=flat-square)](https://hub.docker.com/r/dmotte/portmap-server)

This is a :whale: **Docker image** containing an **OpenSSH server** that can be used for **remote port forwarding** only.

It is meant to act as a server for the [dmotte/portmap-client](https://github.com/dmotte/docker-portmap-client) image, but should work with any OpenSSH client.

If you want a **rootless** version of this image, check out [dmotte/docker-portmap-server-rootless](https://github.com/dmotte/docker-portmap-server-rootless).

> :package: This image is also on **Docker Hub** as [`dmotte/portmap-server`](https://hub.docker.com/r/dmotte/portmap-server) and runs on **several architectures** (e.g. amd64, arm64, ...). To see the full list of supported platforms, please refer to the [`.github/workflows/main.yml`](.github/workflows/main.yml) file. If you need an architecture which is currently unsupported, feel free to open an issue.

## Usage

> **Note**: this Docker image uses **unprivileged users** to perform the remote port forwarding stuff. As a result, it will only be possible to use **port numbers > 1024**. However this is not a problem at all, since you can still leverage the **Docker port exposure feature** to bind to any port you want on your host (e.g. `-p "80:8080"`).

The first thing you need are **host keys** for the OpenSSH server. You can generate them with the following commands:

```bash
mkdir -p hostkeys/etc/ssh
ssh-keygen -Af hostkeys
mv -thostkeys hostkeys/etc/ssh/*
rm -r hostkeys/etc
```

This creates a folder named :file_folder: `hostkeys` which has to be mounted to `/ssh-host-keys` inside the container. If you omit this step, the startup script will generate the host keys internally and try to copy them to `/ssh-host-keys`.

Then you'll have to generate an **SSH key pair** for each client. For example:

```bash
ssh-keygen -t ed25519 -C myclient -N '' -f myclientkey
```

This will create two files:

- :page_facing_up: `myclientkey`: the client's **private** SSH key, which should be given to the client
- :page_facing_up: `myclientkey.pub`: the client's **public** SSH key, which is used by the OpenSSH server running inside the container to authenticate the client

This image supports **multiple users** and **permissions** on [which ports can be bound](https://man.openbsd.org/sshd_config#PermitListen) by the users. For each user you have to:

- Specify the username and permissions in the container **command** (mandatory). Example for two users: `alice:8001,8002 bob:any`
- Mount the SSH public client key(s) to `/ssh-client-keys/myuser/myclientkey.pub`. If you don't do this, a keypair will be generated and put into the `/ssh-client-keys/myuser` directory

> **Note**: you can also specify [key options](https://man.openbsd.org/OpenBSD-current/man8/sshd.8#AUTHORIZED_KEYS_FILE_FORMAT) in the public key file, e.g. `permitlisten="8080" ssh-ed25519 AAAAC3Nza...`

When you have everything ready, you can start the server with:

```bash
docker run -it --rm \
    -v "$PWD/hostkeys:/ssh-host-keys" \
    -v "$PWD/myclientkey.pub:/ssh-client-keys/myuser/myclientkey.pub:ro" \
    -p80:8080 -p2222:22 \
    dmotte/portmap-server myuser:8080
```

To test the server on-the-fly, you can connect to it and setup a remote port forwarding tunnel, by running the following OpenSSH command in another shell:

```bash
ssh -i myclientkey myuser@localhost -p2222 -NvR8080:google.it:80
```

This will serve `http://google.it/` on port `8080` of the server container, which is exposed to port `80` of your host machine due to the `-p 80:8080` docker run flag specified before. Note that, for this to work, the `myclientkey` must have **`600` permissions**. If this isn't the case, you can achieve it with:

```bash
chmod 600 myclientkey
```

You can now test that your remote port forwarding tunnel is working with _cURL_:

```bash
curl http://localhost/
```

For a more complex example, refer to the [`docker-compose.yml`](docker-compose.yml) file.

### Environment variables

List of supported **environment variables**:

| Variable             | Required         | Description                                                      |
| -------------------- | ---------------- | ---------------------------------------------------------------- |
| `KEEPALIVE_INTERVAL` | No (default: 30) | Value for the `ClientAliveInterval` option of the OpenSSH server |

## Development

If you want to contribute to this project, you can use the following one-liner to **rebuild the image** and bring up the **Docker-Compose stack** every time you make a change to the code:

```bash
docker-compose down && docker-compose up --build
```
