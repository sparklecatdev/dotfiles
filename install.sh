#!/usr/bin/env bash

set -euo pipefail

DOTFILES="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

source "$DOTFILES/config-dirs.sh"

install_file() {
    local src="$1"
    local dst="$2"

    [[ -f "$src" ]] || return 0

    install -Dm644 "$src" "$dst"
}

install_exec() {
    local src="$1"
    local dst="$2"

    [[ -f "$src" ]] || return 0

    install -Dm755 "$src" "$dst"
}

install_dir() {
    local src="$1"
    local dst="$2"

    [[ -d "$src" ]] || return 0

    mkdir -p "$dst"
    cp -a "$src/." "$dst/"
}

echo "Installing dotfiles..."

########################################
# Packages
########################################

if command -v paru >/dev/null 2>&1 && [[ -f "$DOTFILES/packages/pacman.txt" ]]; then
    echo "Installing packages..."

    mapfile -t PACMAN_PKGS < "$DOTFILES/packages/pacman.txt"
    ((${#PACMAN_PKGS[@]})) && paru --needed -S --noconfirm "${PACMAN_PKGS[@]}"

    if [[ -s "$DOTFILES/packages/aur.txt" ]]; then
        mapfile -t AUR_PKGS < "$DOTFILES/packages/aur.txt"
        ((${#AUR_PKGS[@]})) && paru --needed -S --noconfirm "${AUR_PKGS[@]}"
    fi
else
    echo "Skipping package installation."
fi

########################################
# User binaries
########################################

mkdir -p "$HOME/.local/bin"

if [[ -d "$DOTFILES/bin" ]]; then
    for file in "$DOTFILES"/bin/*; do
        [[ -f "$file" ]] || continue
        install_exec "$file" "$HOME/.local/bin/$(basename "$file")"
    done
fi

########################################
# Shell
########################################

install_file "$DOTFILES/shell/.zshrc" "$HOME/.zshrc"
install_file "$DOTFILES/shell/.zprofile" "$HOME/.zprofile"
install_file "$DOTFILES/shell/starship.toml" "$HOME/.config/starship.toml"

########################################
# Git
########################################

install_file "$DOTFILES/git/.gitconfig" "$HOME/.gitconfig"
install_file "$DOTFILES/git/.gitignore_global" "$HOME/.gitignore_global"

########################################
# Selected .config apps
########################################

for dir in "${CONFIG_DIRS[@]}"; do
    install_dir \
        "$DOTFILES/.config/$dir" \
        "$HOME/.config/$dir"
done

########################################
# Fastfetch
########################################

install_file \
    "$DOTFILES/fastfetch/config.jsonc" \
    "$HOME/.config/fastfetch/config.jsonc"

########################################
# KDE
########################################

for file in \
    kdeglobals \
    kglobalshortcutsrc \
    kwinrc \
    kscreenlockerrc \
    plasmarc \
    dolphinrc \
    konsolerc
do
    install_file \
        "$DOTFILES/kde/$file" \
        "$HOME/.config/$file"
done

########################################
# VS Code
########################################

install_dir \
    "$DOTFILES/vscode" \
    "$HOME/.config/Code/User"

########################################
# Fonts
########################################

install_dir \
    "$DOTFILES/fonts" \
    "$HOME/.local/share/fonts"

command -v fc-cache >/dev/null && fc-cache -fv

########################################
# Wallpapers
########################################

install_dir \
    "$DOTFILES/wallpapers" \
    "$HOME/Pictures/Wallpapers"

########################################
# Themes
########################################

install_dir \
    "$DOTFILES/themes" \
    "$HOME/.themes"

if [[ -d "$DOTFILES/themes/icons" ]]; then
    install_dir \
        "$DOTFILES/themes/icons" \
        "$HOME/.icons"
fi

########################################
# Misc config
########################################

install_file \
    "$DOTFILES/config/mimeapps.list" \
    "$HOME/.config/mimeapps.list"

########################################
# User systemd
########################################

########################################
# User systemd
########################################

install_dir \
    "$DOTFILES/systemd-user" \
    "$HOME/.config/systemd/user"

systemctl --user daemon-reload || true

if compgen -G "$HOME/.config/systemd/user/*.timer" >/dev/null; then
    while IFS= read -r timer; do
        systemctl --user enable --now "$(basename "$timer")"
    done < <(
        find "$HOME/.config/systemd/user" \
            -maxdepth 1 \
            -name '*.timer'
    )
fi

########################################
# Root scripts
########################################

if [[ -d "$DOTFILES/scripts" ]]; then
    for file in "$DOTFILES"/scripts/*; do
        [[ -f "$file" ]] || continue
        sudo install -Dm755 \
            "$file" \
            "/usr/local/bin/$(basename "$file")"
    done
fi

########################################
# Systemd
########################################

if compgen -G "$DOTFILES/systemd/*.service" >/dev/null; then
    sudo install -Dm644 \
        "$DOTFILES"/systemd/*.service \
        -t /etc/systemd/system/

    sudo systemctl daemon-reload

    while IFS= read -r service; do
        sudo systemctl enable --now "$service"
    done < <(
        find "$DOTFILES/systemd" \
            -maxdepth 1 \
            -name '*.service' \
            -printf '%f\n'
    )
fi

########################################
# SDDM
########################################

if [[ -f "$DOTFILES/sddm/sddm.conf" ]]; then
    sudo install -Dm644 \
        "$DOTFILES/sddm/sddm.conf" \
        /etc/sddm.conf
fi

if [[ -d "$DOTFILES/sddm/sddm.conf.d" ]]; then
    sudo mkdir -p /etc/sddm.conf.d
    sudo cp -a \
        "$DOTFILES/sddm/sddm.conf.d/." \
        /etc/sddm.conf.d/
fi

########################################
# Plymouth
########################################

if [[ -d "$DOTFILES/plymouth/etc" ]]; then
    sudo mkdir -p /etc/plymouth
    sudo cp -a "$DOTFILES/plymouth/etc/." /etc/plymouth/
fi

########################################
# Firefox
########################################

if [[ -f "$DOTFILES/firefox/user.js" ]]; then
    echo
    echo "Firefox user.js detected."
    echo "Copy it into your Firefox profile:"
    echo "  ~/.mozilla/firefox/<profile>/user.js"
fi

########################################
# Finished
########################################

echo
echo "Done!"
echo
echo "Choose a VPN server:"
echo "  vpn-server us-atl-wg-407"
