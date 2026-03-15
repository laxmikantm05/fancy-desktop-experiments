#!/bin/bash
# =============================================================================
#  Fancy Desktop Rice Script for Debian + GNOME
#  Run this after a fresh Debian install
# =============================================================================

CYAN='\033[96m'
RESET='\033[0m'

banner() {
    echo -e "${CYAN}"
    figlet "$1"
    echo -e "${RESET}"
}

ask() {
    read -p "  → Do you want to $1? (y/n): " choice
    [[ "$choice" == "y" || "$choice" == "Y" ]]
}

# ─────────────────────────────────────────────
# 🎨 GNOME EXTENSIONS — Add or remove from this list
# ─────────────────────────────────────────────
EXTENSIONS=(
    "arcmenu@arcmenu.com"
    "blur-my-shell@aunetx"
    "just-perfection-desktop@just-perfection"
    "dash2dock-lite@icedman.github.com"
    "burn-my-windows@schneegans.github.com"
    "compiz-windows-effect@hermes83.github.com"
    "kiwi@kemma"
    "openbar@neuromorph"
)
# ─────────────────────────────────────────────

# ─────────────────────────────────────────────
# 📁 DCONF BACKUP — Add your backup file path below
#    then remove the # from the dconf lines
# ─────────────────────────────────────────────
# DCONF_BACKUP="/path/to/your/dconf-backup.ini"
# ─────────────────────────────────────────────

# ─────────────────────────────────────────────
# 🚪 WLOGOUT CONFIG — Add your config file/folder path below
#    then remove the # from the wlogout line
# ─────────────────────────────────────────────
# WLOGOUT_CONFIG="/path/to/your/wlogout/config"
# ─────────────────────────────────────────────


# =============================================================================

banner "Updating the System"
if ask "Shall we proceed with upgrading the system and Installing all Dependecies sir ?? [Y/n]"; then
    sudo apt update -y
    sudo apt upgrade
    sudo apt install -y fish fastfetch curl libgnome-menu-3-0 gir1.2-gmenu-3.0 ptyxis pipx wlogout gnome-extensions-app gnome-shell-extension-caffeine gnome-shell-extension-gsconnect gnome-shell-extension-user-theme gnome-shell-extension-launch-new-instance gnome-shell-extensions-extra
fi

# =============================================================================

#banner "Dependencies"
#if ask "install all dependencies"; then
#    sudo apt install -y fish fastfetch libgnome-menu-3-0 gir1.2-gmenu-3.0 ptyxis pipx wlogout
    # sudo cp -r "$WLOGOUT_CONFIG"/* /etc/wlogout/
#fi

# =============================================================================

banner "Installing Starship"
if ask "Should I set fish as your default shell, Sir ??"; then
    chsh -s $(which fish)

    read -p "  → Do you also want fish as default for root? (y/n): " root_fish
    if [[ "$root_fish" == "y" || "$root_fish" == "Y" ]]; then
        sudo chsh -s $(which fish) root
        echo "  ✅ Fish set as default for root too"
    else
        echo "  Skipping root — fish only set for $USER"
    fi
fi

# =============================================================================

# banner "Starship"
if ask "May I proceed to prepare your terminal kind sir ?? [Y/n]"; then
    mkdir -p ~/.config
    sudo mkdir -p /root/.config
    cp -r ~/fancy-desktop/assets/dotfiles/.config/* ~/.config
    sudo cp -r ~/fancy-desktop/assets/dotfiles/.config/* /root/.config
    curl -sS https://starship.rs/install.sh | sh
fi

# =============================================================================

banner "Installing Fonts"
if ask "Shall I install the fonts gentleman ?? [Y/n]"; then
    sudo cp -r ~/fancy-desktop/assets/fonts/* /usr/share/fonts
    fc-cache -fv
fi

# =============================================================================

banner "GNOME Extensions"
if ask "Let's install the gnome extensions, Shall we ?? [Y/n]"; then
    if ! command -v gext &>/dev/null; then
        pipx install gnome-extensions-cli
        export PATH="$PATH:$HOME/.local/bin"
    fi

    for ext in "${EXTENSIONS[@]}"; do
        echo "  → Installing $ext"
        gext install "$ext"
    done

    for ext in "${EXTENSIONS[@]}"; do
        echo "  → Enabling $ext"
        gext enable "$ext"
    done
fi

# =============================================================================

# banner "Dconf"
# if ask "load your dconf backup"; then
#     dconf load / < "$DCONF_BACKUP"
# fi

# =============================================================================

banner "Installing Bootloader"
if ask "install the bootloader theme"; then
#    git clone https://github.com/ChrisTitusTech/Top-5-Bootloader-Themes
    git clone https://github.com/ChrisTitusTech/Top-5-Bootloader-Themes
    cd Top-5-Bootloader-Themes
    sudo ./install.sh
    cd ..
fi

# =============================================================================

banner "Fancy  Desktop"
echo -e "${CYAN}  Everything is set up. Time to reboot...${RESET}"
read -p "  → Do you want the system to reboot right now, Sir ?? (y/n): " reboot_choice
if [[ "$reboot_choice" == "y" || "$reboot_choice" == "Y" ]]; then
    echo -e "${CYAN}  Rebooting... see you on the other side!${RESET}"
    sudo reboot
else
    echo -e "${CYAN}  Okay! Log out and back in for everything to take full effect 🎉${RESET}"
fi
