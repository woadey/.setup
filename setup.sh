#!/usr/bin/env bash

echo "[*] Installing zsh" && sudo apt install zsh -y
echo "[*] Changing zsh to default shell" && chsh -s $(which zsh)
echo "[*] Installing oh-my-zsh" && sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
echo "[*] Installing powerlevel10k" && git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
echo "[*] Copying contents to $(eval echo ~$USER)" && cp ./{.gdbinit,.gdbinit-gef.py,.p10k.zsh,.zshrc} ..
echo "[!] Please log out and log back in for changes to take effect..."
