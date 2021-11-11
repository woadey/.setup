#!/usr/bin/env bash
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

#### zsh / powerlevel 10k
echo -e "\n==================== zsh / powerlevel 10k ===================="
if [[ $(dpkg-query -l zsh > /dev/null) -eq 0 ]]
then
    echo "[-] 'zsh' is already installed! Skipping..."
else
    echo "[*] Installing 'zsh'"
    sudo apt install zsh -y
fi

if [[ `echo $SHELL` == '/usr/bin/zsh' ]]
then
    echo "[-] 'zsh' is already the default shell! Skipping..."
else
    echo "[*] Changing 'zsh' to default shell"
    chsh -s $(which zsh)
fi

if [[ -e $HOME/.oh-my-zsh/oh-my-zsh.sh ]]
then
    echo "[-] 'oh-my-zsh' is already installed! Skipping..."
else
    echo "[*] Installing 'oh-my-zsh'"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

if [[ -d ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k ]]
then    
    echo "[-] 'powerlevel10k' is already installed! Skipping..."
else
    if [[ -e $HOME/.oh-my-zsh/oh-my-zsh.sh ]]
    then
        echo "[*] Installing 'powerlevel10k'"
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
    fi
fi

if [[ -d ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions ]]
then    
    echo "[-] 'zsh-autosuggestions' is already installed! Skipping..."
else
    if [[ -e $HOME/.oh-my-zsh/oh-my-zsh.sh ]]
    then
        echo "[*] Installing 'zsh-autosuggestions'"
        git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    fi
fi


#### Gnome Customizations
echo -e "\n==================== Gnome Customizations ===================="
read -p "[!] Would you like to install Gnome Customizations? [Y/n] " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    if [[ $(dpkg-query -l gnome-tweaks > /dev/null) -eq 0 ]]
    then
        echo "[-] 'gnome-tweaks' is already installed! Skipping..."
    else
        echo "[*] Installing 'gnome-tweaks'"
        sudo apt install gnome-tweaks -y
    fi

    if [[ $(dpkg-query -l gnome-shell-extensions > /dev/null) -eq 0 ]]
    then
        echo "[-] 'gnome-shell-extensions' is already installed! Skipping..."
    else
        echo "[*] Installing 'gnome-shell-extensions'"
        sudo apt install gnome-shell-extensions -y
    fi

    # Check if repo already hasn't added
    if [[ $(grep ^ /etc/apt/sources.list /etc/apt/sources.list.d/* | grep papirus/papirus > /dev/null) -eq 1 ]]
    then
        echo "[*] Adding repo 'ppa:papirus/papirus'"
        sudo add-apt-repository ppa:papirus/papirus
    fi

    if [[ $(dpkg-query -l papirus-icon-theme > /dev/null) -eq 0 ]]
    then
        echo "[-] 'papirus-icon-theme' is already installed! Skipping..."
    else
        echo "[*] Installing 'papirus-icon-theme'"
        sudo apt install papirus-icon-theme -y
    fi

    echo "[*] Installing 'Orchis-theme'" && sudo $SCRIPT_DIR/Orchis-theme/install.sh -d /usr/share/themes --tweaks compact
    echo "[*] Installing 'Vimix-cursors'" && sudo $SCRIPT_DIR/Vimix-cursors/install.sh
    echo "[*] Installing 'grub2-themes'" && sudo $SCRIPT_DIR/grub2-themes/install.sh -s 1080p -t tela
else
    echo "[-] Skipping..."
fi


#### Copy dotfiles
echo -e "\n==================== Uploading .dotfiles ===================="
echo "[*] Copying dotfiles to '$(eval echo ~$USER)'" && cp $SCRIPT_DIR/{.gdbinit,.gdbinit-gef.py,.p10k.zsh,.zshrc} $HOME


echo -e "\nPlease log out and log back in for changes to take effect..."
sleep 3
