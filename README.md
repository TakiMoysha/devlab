## devlab.rs

Inspired by [Dev Home](https://learn.microsoft.com/en-us/windows/dev-home/).

## Devlab

- Keycloak/Authentik - SSO
- FreeIPA - LDAP

- https://github.com/kubernetes-sigs/external-dns + https://github.com/cloudflare/cloudflared

- **Media-server**
- **Service Cluster**

Pi-Hole

## Nix

Create backup for proxmox:

```shell
nix run github:/nix-community/nixos-generators -- --format proxmox -c config.nix
```

After that, nix created `/nix/store/**/**.vma.zst`

```shell
scp /nix/store/<target>.vma.zst <user>@<address>:/home/<user>/
```

Connect to the server, unpack and import the backup:

```shell
unzstd <target>.vma.zst
vma extract vzdump
pct restore /mnt/backup/<target>.vma <id> # for lxc
qmrestore /mnt/backup/<target>.vma <id> # for VM
```

## Terraform & Tofu

Используется tofu. Потенциально расширить с terragrrunt.

- https://github.com/sergelogvinov/terraform-talos/tree/main/proxmox

## TODO

### Environment management

```.env
$DEVLAB_CODING_DIR
$DEVLAB_CONTAINERS_DIR

# inspect
$DEVLAB_VOLUMES_DIR
```

### Docker & Podman integrations

- tui for inspect-json

### Scaffolding (baker)

**[Baker](https://github.com/aliev/baker)** - cli tool for scaffolding new projects
