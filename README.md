# docker-portmap-server

TODO

TODO arm note with manual commands, and gh actions is unusable because of [this issue](https://github.community/t/docker-pull-from-public-github-package-registry-fail-with-no-basic-auth-credentials-error/16358)

keys generation with:

```bash
mkdir -p vols-portmap-server/etc/ssh
ssh-keygen -A -f vols-portmap-server
mv vols-portmap-server/etc/ssh/* vols-portmap-server
rm -r vols-portmap-server/etc
```

```bash
ssh-keygen -N "" -f vols-portmap-server/ssh_client_key
```

Developing: on-the-fly testing:
```bash
chmod 600 vols-portmap-server/ssh_client_key
ssh -i vols-portmap-server/ssh_client_key -o 'ServerAliveInterval=30' -o 'ExitOnForwardFailure=yes' portmap@localhost -p 2222 -N -R 8080:example.com:80
curl http://localhost/
```
