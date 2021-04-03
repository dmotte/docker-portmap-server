# docker-portmap-server

![](portmap-server-icon-149.png)

[![Docker Pulls](https://img.shields.io/github/workflow/status/dmotte/docker-portmap-server/docker?logo=github&style=flat-square)](https://hub.docker.com/r/dmotte/portmap-server)
[![Docker Pulls](https://img.shields.io/docker/pulls/dmotte/portmap-server?logo=docker&style=flat-square)](https://hub.docker.com/r/dmotte/portmap-server)

This is a :whale: **Docker image** containing an **OpenSSH server** that can be used for **remote port forwarding** only.

> :package: This image is also on **Docker Hub** as [`dmotte/portmap-server`](https://hub.docker.com/r/dmotte/portmap-server) and runs on **several architectures** (e.g. amd64, arm64, ...). To see the full list of supported platforms, please refer to the `.github/workflows/docker.yml` file. If you need an architecture which is currently unsupported, feel free to open an issue.

## Usage

> **Note**: this Docker image uses a **built-in unprivileged user** (called `portmap`) to perform the remote port forwarding stuff. As a result, it will only be possible to use **port numbers < 1024**. However this is not a problem at all, since you can still leverage the **Docker port exposure feature** to bind to any port you want on your host (e.g. `-p "80:8080"`).

The first thing you'll need are **host keys** for the OpenSSH server. You can generate them with the following commands:

```bash
mkdir -p hostkeys/etc/ssh
ssh-keygen -A -f hostkeys
mv hostkeys/etc/ssh/* hostkeys
rm -r hostkeys/etc
```

If you omit this step, this image will generate them internally, but they will be different each time and of course container startup will also be a little slower.

Then you'll have to generate an **SSH key pair** for each client:

```bash
ssh-keygen -N "" -f ssh_client_key
```

This will create two files:

- :page_facing_up: `ssh_client_key`: the client's **private** SSH key, which should be given to the client
- :page_facing_up: `ssh_client_key.pub`: the client's **public** SSH key, which should be mounted at `/ssh_client_key.pub` inside the container

Now you can start the server with:

```bash
docker run -it --rm \
    -v $PWD/hostkeys/ssh_host_dsa_key:/etc/ssh/ssh_host_dsa_key:ro \
    -v $PWD/hostkeys/ssh_host_dsa_key.pub:/etc/ssh/ssh_host_dsa_key.pub:ro \
    -v $PWD/hostkeys/ssh_host_ecdsa_key:/etc/ssh/ssh_host_ecdsa_key:ro \
    -v $PWD/hostkeys/ssh_host_ecdsa_key.pub:/etc/ssh/ssh_host_ecdsa_key.pub:ro \
    -v $PWD/hostkeys/ssh_host_ed25519_key:/etc/ssh/ssh_host_ed25519_key:ro \
    -v $PWD/hostkeys/ssh_host_ed25519_key.pub:/etc/ssh/ssh_host_ed25519_key.pub:ro \
    -v $PWD/hostkeys/ssh_host_rsa_key:/etc/ssh/ssh_host_rsa_key:ro \
    -v $PWD/hostkeys/ssh_host_rsa_key.pub:/etc/ssh/ssh_host_rsa_key.pub:ro \
    -v $PWD/ssh_client_key.pub:/authorized_keys/ssh_client_key.pub:ro \
    -p 80:8080 \
    -p 2222:22 \
    dmotte/portmap-server
```

For a more complex example, please refer to the `docker-compose.yml` file.

## Development

If you want to contribute to this project, the first thing you have to do is to **clone this repository** on your local machine:

```bash
git clone https://github.com/dmotte/docker-portmap-server.git
```

Then you'll have to create your **host keys** and `ssh_client_key` **keypair** inside the `vols-portmap-server` directory and run:

```bash
docker-compose up --build
```

This will automatically **build the Docker image** using the `docker-build` directory as build context and then the **Docker-Compose stack** will be started.

If you prefer to run the stack in daemon (detached) mode:

```bash
docker-compose up -d
```

In this case, you can view the logs using the `docker-compose logs` command:

```bash
docker-compose logs -ft
```

To test the server on-the-fly, you can connect to it and setup a remote port forwarding tunnel with the following OpenSSH command:

```bash
ssh \
    -i vols-portmap-server/ssh_client_key \
    portmap@localhost \
    -p 2222 \
    -N \
    -R 8080:google.it:80
```

This will serve `http://google.it/` on port `8080` of the server container. Note that, for this to work, the `vols-portmap-server/ssh_client_key` must have **`600` permissions**. You can achieve this with:

```bash
chmod 600 vols-portmap-server/ssh_client_key
```

You can now test that your remote port forwarding tunnel is working with *cURL*:

```bash
curl http://localhost/
```
