#!/bin/bash

set -e

DOTFILES="$HOME/dotfiles"

echo "Installing dotfiles..."

# User scripts
mkdir -p "$HOME/.local/bin"

ln -sf "$DOTFILES/bin/vpn-server" "$HOME/.local/bin/vpn-server"
ln -sf "$DOTFILES/bin/vpn-servers" "$HOME/.local/bin/vpn-servers"

# Root scripts
sudo cp "$DOTFILES/scripts/mullvad-up" /usr/local/bin/mullvad-up
sudo chmod +x /usr/local/bin/mullvad-up

# Systemd services
sudo cp "$DOTFILES/systemd/"*.service /etc/systemd/system/

sudo systemctl daemon-reload

echo "Done."
