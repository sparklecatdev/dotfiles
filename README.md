# Dotfiles

## Install

git clone https://github.com/sparklecatdev/dotfiles.git
cd dotfiles
chmod +x install.sh
./install.sh

## Sync

./sync.sh

## VPN

Choose a server:

vpn-server us-atl-wg-407

Run apps inside the namespace:

sudo ip netns exec vpn <command>
