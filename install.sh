#!/usr/bin/env bash

set -euo pipefail

DOTFILES="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing dotfiles..."

# User scripts
mkdir -p "$HOME/.local/bin"

install -m755 "$DOTFILES/bin/vpn-server" \
    "$HOME/.local/bin/vpn-server"

# Root scripts
sudo install -Dm755 \
    "$DOTFILES/scripts/mullvad-up" \
    /usr/local/bin/mullvad-up

# Systemd services
sudo install -Dm644 \
    "$DOTFILES/systemd/mullvad-vpnns-setup.service" \
    /etc/systemd/system/mullvad-vpnns-setup.service

sudo install -Dm644 \
    "$DOTFILES/systemd/mullvad-vpnns.service" \
    /etc/systemd/system/mullvad-vpnns.service

sudo systemctl daemon-reload

sudo systemctl enable --now mullvad-vpnns-setup.service
sudo systemctl enable --now mullvad-vpnns.service

echo
echo "Done!"
echo
echo "Choose a server:"
echo "  vpn-server us-atl-wg-407"
