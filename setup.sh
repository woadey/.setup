#!/usr/bin/env bash

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# --- Helper Functions ---

# Function to print messages
msg() {
    echo "[*] $1"
}

warn() {
    echo "[!] $1"
}

success() {
    echo "[+] $1"
}

error() {
    echo "[ERROR] $1"
}

skip() {
    echo "[-] $1"
}

# Check command success and print error if failed
check_status() {
    local status=$?
    local command_name=$1
    if [ $status -ne 0 ]; then
        error "$command_name failed with status $status."
        # Return the status so the caller can decide whether to proceed
        return $status
    fi
    return 0
}

# Install packages using apt
install_pkg() {
    local pkg_name=$1
    if dpkg -l | grep -q "^ii\s*$pkg_name"; then
        skip "'$pkg_name' is already installed!"
    else
        msg "Installing '$pkg_name'"
        sudo apt install "$pkg_name" -y
        check_status "apt install $pkg_name"
    fi
}

# Install Ruby gems
install_gem() {
    local gem_name=$1
    if sudo gem list -i "$gem_name" > /dev/null; then
        skip "'$gem_name' gem is already installed!"
    else
        msg "Installing '$gem_name' gem"
        sudo gem install "$gem_name"
        check_status "gem install $gem_name"
    fi
}

# Prompt user for Yes/No
# Returns 0 for Yes, 1 for No
prompt() {
    local question=$1
    read -p "[?] Would you like to $question? [Y/n] " -n 1 -r
    echo # Move to a new line
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then # Default to Yes
        return 0
    else
        return 1
    fi
}

# --- Setup Sections ---

setup_git() {
    echo -e "\n==================== Git Configuration ===================="
    msg "Updating Git submodules"
    cd "$SCRIPT_DIR" || return 1 # Exit function if cd fails
    git submodule update --init --recursive
    check_status "git submodule update"
    
    msg "Configuring global Git user"
    git config --global user.email ssmits@asu.edu
    check_status "git config user.email"
    git config --global user.name woadey
    check_status "git config user.name"
    
    cd - > /dev/null # Go back to previous directory quietly
}

setup_dotfiles() {
    echo -e "\n====================== Dotfiles Setup ======================"
    if prompt "symlink dotfiles"; then
        local dotfiles_dir="$SCRIPT_DIR/dotfiles"
        local target_dir="$HOME"
        
        if [[ ! -d "$dotfiles_dir" ]]; then
            error "Dotfiles directory not found: $dotfiles_dir"
            return 1
        fi

        msg "Symlinking dotfiles from '$dotfiles_dir' to '$target_dir'"
        local files_to_symlink
        files_to_symlink=$(find "$dotfiles_dir" -maxdepth 1 -name ".*" -not -name .git -not -name . -not -name ..)
        local old_vim_dir="$target_dir/.vim"

        # Handle existing .vim directory specifically
        if [[ ! -L "$old_vim_dir" ]] && [[ -d "$old_vim_dir" ]]; then
            warn "Removing existing '.vim' directory..."
            sudo rm -rf "$old_vim_dir"
            check_status "rm -rf $old_vim_dir"
        fi

        # Create symlinks
        for file in $files_to_symlink; do
            local base_name
            base_name=$(basename "$file")
            local target_link="$target_dir/$base_name"
            
            # Check if link exists and points correctly
            if [[ -L "$target_link" ]] && [[ "$(readlink -f "$target_link")" == "$file" ]]; then
                skip "'$target_link' already properly linked."
            else
                msg "Linking '$target_link' -> '$file'"
                # Use -f to overwrite existing files/links at the target
                ln -s -f "$file" "$target_link"
                check_status "ln -s -f $file $target_link"
            fi
        done
        success "Dotfiles symlinked."
    else
        skip "Skipping dotfiles setup."
    fi
}

setup_base_packages() {
    echo -e "\n================== Base Packages & Fonts =================="
    if prompt "install base packages and fonts"; then
        msg "Installing essential packages..."
        install_pkg "build-essential" # Common build tools (make, gcc, etc.)
        install_pkg "curl"            # Tool for transferring data with URLs
        install_pkg "vim"             # Text editor
        install_pkg "tmux"            # Terminal multiplexer
        install_pkg "xsel"            # Clipboard access tool
        install_pkg "zsh"             # Z shell
        install_pkg "fontconfig"      # Library for font customization/config (needed for fc-cache)

        msg "Installing Meslo Nerd Font..."
        local font_dir="$HOME/.local/share/fonts"
        mkdir -p "$font_dir"
        check_status "mkdir -p $font_dir"
        cp "$SCRIPT_DIR"/fonts/Meslo* "$font_dir/"
        if check_status "cp fonts"; then
            msg "Updating font cache..."
            fc-cache -fv > /dev/null # Rebuild font cache, hide verbose output
            check_status "fc-cache -fv"
            warn "*** Please change Terminal Preferences Font to Meslo ***"
        fi
        success "Base packages and fonts installed."
    else
        skip "Skipping base package and font installation."
    fi
}

setup_zsh() {
    echo -e "\n==================== Zsh / Powerlevel10k ==================="
    if prompt "install Zsh goodies (Oh My Zsh, P10k, plugins)"; then
        local oh_my_zsh_path="$HOME/.oh-my-zsh"
        local zsh_custom_path="${ZSH_CUSTOM:-$oh_my_zsh_path/custom}"

        # Install Oh My Zsh if not present
        if [[ -e "$oh_my_zsh_path/oh-my-zsh.sh" ]]; then
            skip "'oh-my-zsh' is already installed!"
        else
            msg "Installing 'oh-my-zsh'"
            # Run unattended, redirect stdout only to hide success message, keep errors
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended > /dev/null
            check_status "oh-my-zsh install script"
        fi

        # Change default shell to zsh if not already set
        if [[ "$SHELL" == '/usr/bin/zsh' ]] || [[ "$SHELL" == '/bin/zsh' ]]; then
            skip "'zsh' is already the default shell!"
        else
            if command -v zsh &> /dev/null; then
                msg "Changing default shell to 'zsh'"
                chsh -s "$(which zsh)"
                if check_status "chsh -s zsh"; then
                     warn "*** Please log out and log back in for shell change to take effect ***"
                     sleep 1
                fi
            else
                error "zsh command not found. Cannot set as default shell."
            fi
        fi

        # Function to install plugins/themes
        install_zsh_plugin_or_theme() {
            local name=$1 # e.g., "themes/powerlevel10k"
            local git_url=$2
            local install_path="$zsh_custom_path/$name"
            local display_name # e.g. "powerlevel10k"
            display_name=$(basename "$name") 

            if [[ -d "$install_path" ]]; then
                skip "'$display_name' is already installed!"
            elif [[ -d "$zsh_custom_path" ]]; then # Ensure custom path exists
                msg "Installing '$display_name'"
                git clone --depth=1 "$git_url" "$install_path" > /dev/null # Hide cloning output
                check_status "git clone $display_name"
            else
                 error "Oh My Zsh custom path not found: $zsh_custom_path. Cannot install $display_name."
            fi
        }

        # Install P10k theme and plugins
        install_zsh_plugin_or_theme "themes/powerlevel10k" "https://github.com/romkatv/powerlevel10k.git"
        install_zsh_plugin_or_theme "plugins/zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions"
        install_zsh_plugin_or_theme "plugins/zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting"

        # Install additional tools often used with Zsh setups
        msg "Installing related tools (bat, colorls, fzf)..."
        install_pkg 'bat'        # Cat clone with syntax highlighting
        install_pkg 'ruby-dev'   # Needed to build native extensions for some gems like colorls
        install_gem 'colorls'    # LS replacement with colors and icons
        install_pkg 'fzf'        # Command-line fuzzy finder
        
        success "Zsh setup complete."
    else
        skip "Skipping Zsh setup."
    fi
}

setup_vim() {
    echo -e "\n========================= Vim Config ========================="
    if prompt "configure vim (install plugins, YCM)"; then
        msg "Installing vim plugins using PlugInstall"
        # Run vim non-interactively, hide normal output, show errors
        vim +'PlugInstall --sync' +qa > /dev/null 
        check_status "vim +PlugInstall"

        msg "Installing 'YouCompleteMe' dependencies and compiling"
        install_pkg "cmake"       # Build tool needed by YCM
        install_pkg "vim-nox"     # Vim build with Python3 support (often needed for YCM)
        install_pkg "python3-dev" # Python 3 development headers
        
        local ycm_install_script="$SCRIPT_DIR/dotfiles/.vim/plugged/YouCompleteMe/install.py"
        if [[ -f "$ycm_install_script" ]]; then
            # Run YCM install script, hide normal output, show errors
            python3 "$ycm_install_script" --all
            check_status "YouCompleteMe install.py"
            success "Vim configuration complete."
        else
            error "YouCompleteMe install script not found at $ycm_install_script"
        fi
    else
        skip "Skipping Vim configuration."
    fi
}

# --- Main Execution ---

main() {
    setup_git
    setup_dotfiles
    setup_base_packages
    setup_zsh
    setup_vim

    echo -e "\n===================== Setup Complete ====================="
    success "All requested setup tasks finished."
    warn "Remember to log out and log back in if the default shell was changed."
    warn "Remember to set 'MesloLGS NF' as your terminal font if you installed it."
}

# Run the main function
main
