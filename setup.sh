#!/usr/bin/env bash
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

#### Install Packages
install () {
    if [[ $(dpkg-query -l $1 > /dev/null 2>&1) -eq 0 ]]
    then
        echo "[-] '$1' is already installed! Skipping..."
    else
        echo "[*] Installing '$1'"
        sudo apt install $1 -y
    fi
}

#### Get User Feedback
prompt () {
    read -p "[!] Would you like to $1? [Y/n] " -n 1 -r
    echo    # (optional) move to a new line
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        prompt_result=1
    else
        prompt_result=0
    fi
}

# TODO make submodule folder in setup
#### zsh / powerlevel 10k
echo -e "\n==================== zsh / powerlevel 10k ===================="
prompt "install zsh / powerlevel10k"

if [[ $prompt_result -eq 1 ]]
then
    install "zsh"

    if [[ `echo $SHELL` == '/usr/bin/zsh' ]]
    then
        echo "[-] 'zsh' is already the default shell! Skipping..."
    else
        echo "[*] Changing 'zsh' to default shell"
        chsh -s $(which zsh)
        echo "***Please log out and log back in for changes to take effect***"
        sleep 1
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

    # TODO Install FONTS https://github.com/romkatv/powerlevel10k#meslo-nerd-font-patched-for-powerlevel10k
else
    echo "[-] Skipping..."
fi


#### Gnome Customizations
echo -e "\n==================== Gnome Customizations ===================="
prompt "install Gnome Customizations"

if [[ $prompt_result -eq 1 ]]
then
    install "gnome-tweaks"
    install "gnome-shell-extensions"
    install "papirus-icon-theme"

    # Check if repo already hasn't added
    if [[ $(grep ^ /etc/apt/sources.list /etc/apt/sources.list.d/* | grep papirus/papirus > /dev/null) -eq 1 ]]
    then
        echo "[*] Adding repo 'ppa:papirus/papirus'"
        sudo add-apt-repository ppa:papirus/papirus
    fi

    if [[ -d "/usr/share/themes/Orchis" ]] # lazy check
    then 
        echo "[-] 'Orchis-theme' is already the default shell! Skipping..."
    else
        echo "[*] Installing 'Orchis-theme'"
        sudo $SCRIPT_DIR/Orchis-theme/install.sh -d /usr/share/themes --tweaks compact > /dev/null 2>&1
    fi

    DEST_DIR="/usr/share/icons/"
    if [[ -d $DEST_DIR/Vimix-cursors ]] # lazy check
    then
        echo "[-] 'Vimix-cursors' is already the default shell! Skipping..."
    else
        echo "[*] Installing 'Vimix-cursors'"
        sudo cp -r $SCRIPT_DIR/Vimix-cursors/dist $DEST_DIR/Vimix-cursors
        sudo cp -r $SCRIPT_DIR/Vimix-cursors/dist-white $DEST_DIR/Vimix-white-cursors
    fi

    # echo "[*] Installing 'grub2-themes'" && sudo $SCRIPT_DIR/grub2-themes/install.sh -s 1080p -t tela
 
    # TODO add support for:
        # https://extensions.gnome.org/extension/1503/tray-icons/
        # https://extensions.gnome.org/extension/921/multi-monitors-add-on/
        # https://extensions.gnome.org/extension/307/dash-to-dock/
        # https://extensions.gnome.org/extension/906/sound-output-device-chooser/
else
    echo "[-] Skipping..."
fi


#### Copy dotfiles
echo -e "\n========================== dotfiles =========================="
prompt "upload dotfiles"

if [[ $prompt_result -eq 1 ]]
then
    echo "[*] Symlinking dotfiles to '$(eval echo ~$USER)'"
    FILES_TO_SYMLINK=$(find $SCRIPT_DIR/dotfiles -maxdepth 1 -name ".*" -not -name .git)
    OLD_VIM_DIR=$HOME/.vim

    # not symlink file && is directory file
    if [[ ! -L $OLD_VIM_DIR ]] && [[ -d $OLD_VIM_DIR ]]
    then
        echo "[!] Removing old '.vim' directory..."
        sudo rm -rf $HOME/.vim
    fi 

    # is a symlink file && matches correct location
    if [[ -L $OLD_VIM_DIR ]] && [[ $(readlink -f $OLD_VIM_DIR) != "$SCRIPT_DIR/dotfiles/.vim" ]]
    then
        echo "[!] Removing old '.vim' symlink"
        rm $HOME/.vim
    fi

    # overwrite symlinks
    for file in $FILES_TO_SYMLINK; do
        if [[ $(readlink -f $HOME/$(basename $file)) == $file ]]
        then
            echo -e "\t[!] '$HOME/$(basename $file)' already properly linked. Skipping..."
        else
            echo -e "\t[+] '$HOME/$(basename $file)' -> '$file'"
            ln -s -f $file $HOME/$(basename $file)
        fi  
    done
else
    echo "[-] Skipping..."
fi

# TODO check on vim plugins, especially https://github.com/ycm-core/YouCompleteMe

sleep 1
