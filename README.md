## devlab.rs

Inspired by [Dev Home](https://learn.microsoft.com/en-us/windows/dev-home/).

## OS — настройка новой системы

### CachyOS (i7-9750H, x86-64-v4)

Для развертывания devlab-системы на чистой CachyOS:

```bash
sudo ./os/setup.sh
```

Скрипт выполняет:
1. Устанавливает `cachyos-keyring` и mirrorlist
2. Настраивает CachyOS репозитории (x86-64-v4)
3. Устанавливает `git`, `chezmoi`, `paru`
4. Инициализирует chezmoi и применяет dotfiles
5. Устанавливает пользовательские пакеты через paru

#### Структура dotfiles (chezmoi)

```
dotfiles/
├── chezmoi.toml              # конфигурация chezmoi
├── dot_bashrc                # → ~/.bashrc
├── dot_zshrc                 # → ~/.zshrc
├── dot_config/
│   ├── nvim/init.vim         # → ~/.config/nvim/init.vim
│   ├── tmux/tmux.conf        # → ~/.config/tmux/tmux.conf
│   ├── zsh/zshrc             # → ~/.config/zsh/zshrc
│   ├── ghostty/config        # → ~/.config/ghostty/config
│   ├── git/config            # → ~/.config/git/config
│   ├── git/ignore            # → ~/.config/git/ignore
│   └── ssh/config            # → ~/.ssh/config
```

#### Ручная инициализация chezmoi

```bash
# Клонировать репозиторий
git clone git@github.com:takimoysha/devlab
cd devlab

# Инициализировать chezmoi (dry-run)
chezmoi init --source=./dotfiles --dry-run

# Применить
chezmoi init --source=./dotfiles --apply

# Добавить файл
chezmoi edit ~/.config/nvim/init.vim
```

## Devlab

- Keycloak/Authentik/PocketID/Rauthy - SSO
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

### OS - файлы и скрипты для миграции\настройки devlab-системы



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
