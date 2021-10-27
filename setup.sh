#!/usr/bin/env bash
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

dpkg-query -l zsh > /dev/null
FINAL=$?

echo $FINAL
if [[ $FINAL -eq 0 ]]
then
    echo "[-] zsh is already installed! Skipping..."
else
    echo "[*] Installing zsh"
    sudo apt install zsh -y
fi

if [[ `echo $SHELL` == '/usr/bin/zsh' ]]
then
    echo "[-] zsh is already the default shell! Skipping..."
else
    echo "[*] Changing zsh to default shell"
    chsh -s $(which zsh)
fi

if [[ -e $HOME/.oh-my-zsh/oh-my-zsh.sh ]]
then
    echo "[-] oh-my-zsh is already installed! Skipping..."
else
    echo "[*] Installing oh-my-zsh"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

if [[ -d ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k ]]
then    
    echo "[-] powerlevel10k is already installed! Skipping..."
else
    echo "[*] Installing powerlevel10k"
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
fi

echo "[*] Copying contents to $(eval echo ~$USER)" && cp $SCRIPT_DIR/{.gdbinit,.gdbinit-gef.py,.p10k.zsh,.zshrc} $HOME
echo "[!] Please log out and log back in for changes to take effect..."
