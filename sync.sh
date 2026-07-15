#!/usr/bin/env bash

set -euo pipefail

DOTFILES="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

source "$DOTFILES/config-dirs.sh"

copy_file() {
    local src="$1"
    local dst="$2"

    [[ -f "$src" ]] || return 0

    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
}

copy_dir() {
    local src="$1"
    local dst="$2"

    [[ -d "$src" ]] || return 0

    mkdir -p "$dst"
    cp -a "$src/." "$dst/"
}

echo "Syncing dotfiles..."

########################################
# Packages
########################################

mkdir -p "$DOTFILES/packages"

pacman -Qqe > "$DOTFILES/packages/pacman.txt"
pacman -Qqm > "$DOTFILES/packages/aur.txt"
pacman -Q > "$DOTFILES/packages/all-packages.txt"

########################################
# User binaries
########################################

REAL=$(readlink -f "$HOME/.local/bin/vpn-server" 2>/dev/null || true)

if [[ "$REAL" != "$DOTFILES/bin/vpn-server" ]]; then
    copy_file \
        "$HOME/.local/bin/vpn-server" \
        "$DOTFILES/bin/vpn-server"
fi

########################################
# Shell
########################################

copy_file "$HOME/.zshrc" "$DOTFILES/shell/.zshrc"
copy_file "$HOME/.zprofile" "$DOTFILES/shell/.zprofile"
copy_file "$HOME/.config/starship.toml" "$DOTFILES/shell/starship.toml"

########################################
# Git
########################################

copy_file "$HOME/.gitconfig" "$DOTFILES/git/.gitconfig"
copy_file "$HOME/.gitignore_global" "$DOTFILES/git/.gitignore_global"

########################################
# Selected .config apps
########################################

for dir in "${CONFIG_DIRS[@]}"; do
    copy_dir \
        "$HOME/.config/$dir" \
        "$DOTFILES/.config/$dir"
done

########################################
# Fastfetch
########################################

copy_file \
    "$HOME/.config/fastfetch/config.jsonc" \
    "$DOTFILES/fastfetch/config.jsonc"

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
    copy_file \
        "$HOME/.config/$file" \
        "$DOTFILES/kde/$file"
done

########################################
# VS Code
########################################

copy_dir \
    "$HOME/.config/Code/User" \
    "$DOTFILES/vscode"

########################################
# Fonts
########################################

copy_dir \
    "$HOME/.local/share/fonts" \
    "$DOTFILES/fonts"

########################################
# Wallpapers
########################################

copy_dir \
    "$HOME/Pictures/Wallpapers" \
    "$DOTFILES/wallpapers"

########################################
# Themes
########################################

copy_dir "$HOME/.themes" "$DOTFILES/themes"
copy_dir "$HOME/.icons" "$DOTFILES/themes/icons"

########################################
# Misc config
########################################

copy_file \
    "$HOME/.config/mimeapps.list" \
    "$DOTFILES/config/mimeapps.list"

########################################
# User systemd
########################################

copy_dir \
    "$HOME/.config/systemd/user" \
    "$DOTFILES/systemd-user"

########################################
# Root scripts
########################################

copy_file \
    "/usr/local/bin/mullvad-up" \
    "$DOTFILES/scripts/mullvad-up"

########################################
# Systemd
########################################

copy_file \
    "/etc/systemd/system/mullvad-vpnns.service" \
    "$DOTFILES/systemd/mullvad-vpnns.service"

copy_file \
    "/etc/systemd/system/mullvad-vpnns-setup.service" \
    "$DOTFILES/systemd/mullvad-vpnns-setup.service"

########################################
# SDDM
########################################

mkdir -p "$DOTFILES/sddm"

copy_file \
    "/etc/sddm.conf" \
    "$DOTFILES/sddm/sddm.conf"

copy_dir \
    "/etc/sddm.conf.d" \
    "$DOTFILES/sddm/sddm.conf.d"

########################################
# Plymouth
########################################

mkdir -p "$DOTFILES/plymouth"

copy_dir \
    "/etc/plymouth" \
    "$DOTFILES/plymouth/etc"

########################################
# Firefox
########################################

if [[ -d "$HOME/.mozilla/firefox" ]]; then
    PROFILE=$(find "$HOME/.mozilla/firefox" \
        -maxdepth 1 \
        -type d \
        -name "*.default*" \
        | head -n1)

    if [[ -n "$PROFILE" ]]; then
        copy_file \
            "$PROFILE/user.js" \
            "$DOTFILES/firefox/user.js"
    fi
fi

########################################
# Git
########################################

cd "$DOTFILES"

if git diff --quiet && git diff --cached --quiet && [[ -z "$(git ls-files --others --exclude-standard)" ]]; then
    echo
    echo "No changes to commit."
    exit 0
fi

git add .

git commit -m "Sync $(date '+%Y-%m-%d %H:%M:%S')"

git push

echo
echo "✓ Dotfiles synced and pushed!"

echo
echo "Sync complete!"
echo
echo "Review changes:"
echo "  git status"
