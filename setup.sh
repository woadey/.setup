#!/usr/bin/env bash
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

#### Install Packages
install () {
    if dpkg -l | grep -q "^ii\s*$1"
    then
        echo "[-] '$1' is already installed! Skipping..."
    else
        echo "[*] Installing '$1'"
        sudo apt install $1 -y
    fi
}

gemstall () {
    if gem list -i "$1" > /dev/null; then
        echo "[-] '$1' gem is already installed! Skipping..."
    else
        echo "[*] Installing '$1' gem"
        sudo gem install "$1"
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

#### Install GitHub Submodules
echo "==================== Installing submodules ==================="
cd $SCRIPT_DIR
git submodule update --init --recursive
git config --global user.email ssmits@asu.edu
git config --global user.name woadey
cd - &>/dev/null



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



#### setup
echo -e "\n========================= init setup ========================="
prompt "install all packages"
if [[ $prompt_result -eq 1 ]]
then
    install "build-essential"
    install "curl"
    install "vim"
    install "tmux"
    install "xsel"
    install "zsh"

    mkdir -p ~/.local/share/fonts && cp $SCRIPT_DIR/fonts/Meslo* ~/.local/share/fonts
    echo "***Please change Terminal Preferences Font to Meslo***"
else
    echo "[-] Skipping..."
fi



#### zsh / powerlevel 10k
echo -e "\n==================== zsh / powerlevel 10k ===================="
prompt "install zsh / powerlevel10k"

if [[ $prompt_result -eq 1 ]]; then
    OH_MY_ZSH_PATH="$HOME/.oh-my-zsh"
    ZSH_CUSTOM_PATH="${ZSH_CUSTOM:-$OH_MY_ZSH_PATH/custom}"

    if [[ -e "$OH_MY_ZSH_PATH/oh-my-zsh.sh" ]]; then
        echo "[-] 'oh-my-zsh' is already installed! Skipping..."
    else
        echo "[*] Installing 'oh-my-zsh'"
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended &> /dev/null
    fi
    
    if [[ $SHELL == '/usr/bin/zsh' ]]; then
        echo "[-] 'zsh' is already the default shell! Skipping..."
    else
        echo "[*] Changing 'zsh' to default shell"
        chsh -s "$(which zsh)"
        echo "***Please log out and log back in for changes to take effect***"
        sleep 1
    fi

    function install_plugin_or_theme {
        local name=$1
        local git_url=$2
        local path="$ZSH_CUSTOM_PATH/$name"
        
        if [[ -d $path ]]; then
            echo "[-] '$name' is already installed! Skipping..."
        elif [[ -e "$OH_MY_ZSH_PATH/oh-my-zsh.sh" ]]; then
            echo "[*] Installing '$name'"
            git clone --depth=1 $git_url $path &> /dev/null
        fi
    }

    install_plugin_or_theme "themes/powerlevel10k" "https://github.com/romkatv/powerlevel10k.git"
    install_plugin_or_theme "plugins/zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions"
    install_plugin_or_theme "plugins/zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting"
    install 'bat'
    install 'ruby-dev'
    gemstall 'colorls'
    install 'fzf'
else
    echo "[-] Skipping..."
fi


#### edit Vim
echo -e "\n========================= vim config ========================="
prompt "configure vim"

if [[ $prompt_result -eq 1 ]]
then
    echo "[*] Installing vim plugins"
    vim +'PlugInstall --sync' +qa &>/dev/null
    echo "[*] Installing 'YouCompleteMe' dependencies"
    install "cmake" 
    install "vim-nox" 
    install "python3-dev"
    python3 $SCRIPT_DIR/dotfiles/.vim/plugged/YouCompleteMe/install.py --all &> /dev/null
else
    echo "[-] Skipping..."
fi
