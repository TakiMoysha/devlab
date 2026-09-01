#!/usr/bin/env bash
set -euo pipefail

# Определяем реального пользователя, вызвавшего sudo
REAL_USER="${SUDO_USER:-$USER}"
USER_HOME=$(eval echo "~${REAL_USER}")

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEVLAB_DIR="${SCRIPT_DIR}/.."
DOTFILES_DIR="${DEVLAB_DIR}/dotfiles"
DEVLAB_REPO="${DEVLAB_REPO:-git@github.com:takimoysha/devlab}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]  $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]  $*"; }
log_error() { echo -e "${RED}[ERROR] $*"; }
log_step()  { echo -e "${BLUE}[STEP]  $*"; }

# Запуск команд от имени пользователя с подгрузкой его Zsh-окружения (.zshenv)
run_as_user_zsh() {
    sudo -u "$REAL_USER" HOME="$USER_HOME" zsh -c "
        [[ -f \"\$HOME/.config/zsh/.zshenv\" ]] && source \"\$HOME/.config/zsh/.zshenv\"
        $*
    "
}

run_as_user() {
    sudo -u "$REAL_USER" HOME="$USER_HOME" "$@"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "Этот скрипт должен запускаться от root: sudo $0"
        exit 1
    fi
    if [[ "$REAL_USER" == "root" ]]; then
        log_error "Запускайте скрипт через: sudo $0 (не напрямую из-под root)"
        exit 1
    fi
}

install_base_packages() {
    log_step "Установка базовых пакетов..."
    pacman -S --noconfirm --needed base-devel git chezmoi cloudflared zsh
}

install_paru() {
    if command -v paru &>/dev/null; then
        log_info "paru уже установлен"
        return
    fi
    log_step "Установка paru из AUR..."
    local paru_src="/tmp/paru-build"
    rm -rf "$paru_src"
    
    run_as_user git clone https://aur.archlinux.org/paru.git "$paru_src"
    pushd "$paru_src" >/dev/null
    run_as_user makepkg -si --noconfirm
    popd >/dev/null
    rm -rf "$paru_src"
    log_info "paru установлен"
}

setup_dotfiles() {
    if [[ ! -d "$DOTFILES_DIR" ]]; then
        log_warn "Директория dotfiles не найдена: $DOTFILES_DIR"
        log_info "Клонируем devlab репозиторий..."
        run_as_user git clone "$DEVLAB_REPO" "$DEVLAB_DIR" || {
            log_error "Не удалось клонировать репозиторий"
            exit 1
        }
    fi

    log_step "Применение dotfiles через chezmoi..."
    if run_as_user chezmoi init --source="$DOTFILES_DIR" --apply; then
        log_info "Dotfiles применены"
    else
        log_warn "chezmoi init --apply не удался, пробуем по отдельности..."
        run_as_user chezmoi init --source="$DOTFILES_DIR"
        run_as_user chezmoi apply
        log_info "Dotfiles применены через chezmoi apply"
    fi
}

install_user_packages() {
    log_step "Установка пользовательских пакетов..."
    
    local pkgs=(
        # CLI & Терминальные утилиты
        tmux
        firefox
        neovim
        neovide
        ripgrep
        fd
        diffutils
        htop
        powertop
        rustup
        cloudflare-speed-cli
        obs-studio
        steam
        
        # Инфраструктура и Демоны
        caddy
        podman
        opencode
        
        # GUI & Разработка
        obsidian
        localsend-bin
        lmstudio-bin
        sublime-text-4
        sublime-merge
    )

    run_as_user paru -S --noconfirm --needed "${pkgs[@]}"

    run_as_user_zsh "rustup default stable"

    local not_implemented_pkgs=(hytale)
    echo "WIP: ${not_implemented_pkgs[@]}"
}

reboot_prompt() {
    echo ""
    log_info "Установка завершена!"
    read -r -p "Перезагрузить сейчас? (y/N) " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        reboot
    fi
}

main() {
    check_root
    install_base_packages
    install_paru
    setup_dotfiles
    install_user_packages
    reboot_prompt
}

main "$@"
