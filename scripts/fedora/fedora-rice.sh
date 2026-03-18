#!/bin/bash
# =============================================================================
#  Fancy Desktop Rice Script for Fedora + GNOME
#  modular · gum-powered · cyberpunk flavored
#  deps: gum, figlet, lolcat
# =============================================================================

# ─────────────────────────────────────────────
#  CONFIG
# ─────────────────────────────────────────────

EXTENSIONS=(
    "arcmenu@arcmenu.com"
    "blur-my-shell@aunetx"
    "just-perfection-desktop@just-perfection"
    "dash2dock-lite@icedman.github.com"
    "burn-my-windows@schneegans.github.com"
    "compiz-windows-effect@hermes83.github.com"
    "kiwi@kemma"
)

# Paths are relative to this script's location — no hardcoded ~/fancy-desktop
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS_DIR="$SCRIPT_DIR/../../assets"
DOTFILES_DIR="$ASSETS_DIR/dotfiles"
FONTS_DIR="$ASSETS_DIR/fonts"

# DCONF_BACKUP="$ASSETS_DIR/dconf-backup.ini"

# ─────────────────────────────────────────────
#  COLORS
# ─────────────────────────────────────────────

CYAN='\033[38;5;51m'
DIM='\033[2m'
RESET='\033[0m'
BOLD='\033[1m'

# ─────────────────────────────────────────────
#  HELPERS
# ─────────────────────────────────────────────

section() {
    gum style \
        --foreground="#00eeff" \
        --border=rounded \
        --border-foreground="#00eeff" \
        --padding="0 2" \
        --margin="1 0" \
        "⚡ $1"
}

success() { gum style --foreground="#00c878" "  ✓ $1"; }
skip()    { gum style --foreground="#888888" "  ─ skipping: $1"; }
fail()    { gum style --foreground="#ff2d5a" "  ✗ $1"; }
info()    { gum style --foreground="#3399ff" "  → $1"; }

confirm() {
    gum confirm "$1" \
        --prompt.foreground="#00eeff" \
        --selected.background="#00eeff" \
        --selected.foreground="#000000" \
        --unselected.foreground="#888888"
}

run_spin() {
    local title="$1"; shift
    gum spin \
        --spinner=dot \
        --spinner.foreground="#00eeff" \
        --title.foreground="#888888" \
        --title=" $title" \
        -- "$@"
}

run_with_output() {
    local title="$1"; shift

    echo ""
    echo -e "  ${CYAN}⠿  ${title}${RESET}"
    echo -e "  ${DIM}──────────────────────────────────────${RESET}"

    "$@" 2>&1 | while IFS= read -r line; do
        echo -e "  ${DIM}${line}${RESET}"
    done
    local cmd_exit=${PIPESTATUS[0]}

    echo -e "  ${DIM}──────────────────────────────────────${RESET}"
    if [ "$cmd_exit" -eq 0 ]; then
        success "$title done"
    else
        fail "$title failed (exit $cmd_exit)"
    fi
    echo ""
    return "$cmd_exit"
}

run_direct() {
    local title="$1"; shift
    gum style \
        --foreground="#00eeff" \
        --border=rounded \
        --border-foreground="#00eeff" \
        --padding="0 2" \
        "  ▶  $title"
    echo ""
    "$@"
    local exit_code=$?
    echo ""
    if [ "$exit_code" -eq 0 ]; then
        success "$title done"
    else
        fail "$title failed (exit $exit_code)"
    fi
    return "$exit_code"
}

# ─────────────────────────────────────────────
#  SUDO — cache credentials upfront
# ─────────────────────────────────────────────

prime_sudo() {
    gum style --foreground="#00eeff" "  ⚡ sudo access needed — enter your password:"
    sudo -v
    while true; do sudo -n true; sleep 50; kill -0 "$$" || exit; done 2>/dev/null &
    SUDO_KEEPALIVE_PID=$!
}

cleanup() {
    kill "$SUDO_KEEPALIVE_PID" 2>/dev/null
}
trap cleanup EXIT

# ─────────────────────────────────────────────
#  GUARD — install gum if missing
# ─────────────────────────────────────────────

install_gum() {
    if ! command -v gum &>/dev/null; then
        echo -e "${CYAN}  installing gum first...${RESET}"
        echo '[charm]
name=Charm
baseurl=https://repo.charm.sh/yum/
enabled=1
gpgcheck=1
gpgkey=https://repo.charm.sh/yum/gpg.key' | sudo tee /etc/yum.repos.d/charm.repo > /dev/null
        sudo dnf install -y gum
    fi
}

# =============================================================================
#  MODULES
# =============================================================================

module_system_update() {
    section "System Update"
    if confirm "Upgrade system and install all dependencies?"; then
        run_with_output "dnf update" sudo dnf update -y
        run_with_output "installing dependencies" sudo dnf install -y \
            fish fastfetch curl \
            gnome-menus \
            python3-gobject \
            pipx wlogout \
            figlet lolcat
        success "system updated and dependencies installed"
    else
        skip "system update"
    fi
}

# ─────────────────────────────────────────────
module_shell() {
    section "Shell Setup"
    if confirm "Set fish as your default shell?"; then

        FISH_PATH="$(command -v fish 2>/dev/null)"
        if [[ -z "$FISH_PATH" ]]; then
            for p in /usr/bin/fish /usr/local/bin/fish /bin/fish; do
                [[ -x "$p" ]] && FISH_PATH="$p" && break
            done
        fi

        if [[ -z "$FISH_PATH" ]]; then
            fail "fish not found — is it installed?"
            return 1
        fi

        grep -qxF "$FISH_PATH" /etc/shells || echo "$FISH_PATH" | sudo tee -a /etc/shells > /dev/null

        run_direct "setting fish as default shell" chsh -s "$FISH_PATH"
        success "fish set as default for $USER"

        if confirm "Also set fish as default for root?"; then
            run_direct "setting fish for root" sudo chsh -s "$FISH_PATH" root
            success "fish set as default for root"
        else
            skip "root shell"
        fi
    else
        skip "shell setup"
    fi
}

# ─────────────────────────────────────────────
module_dotfiles() {
    section "Dotfiles + Starship"
    if confirm "Copy dotfiles and install starship?"; then
        run_spin "copying dotfiles to ~/.config" \
            cp -r "$DOTFILES_DIR/.config/." "$HOME/.config/"
        run_spin "copying dotfiles to /root/.config" \
            sudo cp -r "$DOTFILES_DIR/.config/." /root/.config/
        run_direct "installing starship" \
            gsettings set 'org.gnome.Ptyxis.Profile:/org/gnome/Ptyxis/Profiles/'$PTYXIS_PROFILE'/' 'opacity' '0.55'
            bash -c "curl -sS https://starship.rs/install.sh | sh"
        success "dotfiles and starship ready"
    else
        skip "dotfiles + starship"
    fi
}

# ─────────────────────────────────────────────
module_fonts() {
    section "Fonts"
    if confirm "Install fonts?"; then
        run_with_output "installing fonts" \
            sudo cp -r "$FONTS_DIR/." /usr/share/fonts/
        run_with_output "rebuilding font cache" fc-cache -fv
        success "fonts installed"
    else
        skip "fonts"
    fi
}

# ─────────────────────────────────────────────
module_extensions() {
    section "GNOME Extensions"
    if confirm "Install and enable GNOME extensions?"; then
        if ! command -v gext &>/dev/null; then
            run_with_output "installing gnome-extensions-cli" \
                pipx install gnome-extensions-cli
            export PATH="$PATH:$HOME/.local/bin"
        fi

        for ext in "${EXTENSIONS[@]}"; do
            run_with_output "installing $ext" gext install "$ext"
        done

        for ext in "${EXTENSIONS[@]}"; do
            run_spin "enabling $ext" gext enable "$ext" 2>/dev/null
        done

        success "all extensions installed and enabled"
    else
        skip "gnome extensions"
    fi
}

# ─────────────────────────────────────────────
module_bootloader() {
    section "Bootloader Theme"
    if confirm "Install bootloader theme?"; then
        run_with_output "cloning bootloader themes" \
            git clone https://github.com/ChrisTitusTech/Top-5-Bootloader-Themes /tmp/bootloader-themes
        cd /tmp/bootloader-themes
        run_direct "running bootloader installer" sudo ./install.sh
        run_with_output "updating grub config" \
            sudo grub2-mkconfig -o /boot/grub2/grub.cfg
        cd "$SCRIPT_DIR"
        success "bootloader theme installed"
    else
        skip "bootloader"
    fi
}

# ─────────────────────────────────────────────
# module_dconf() {
#     section "Dconf Settings"
#     if confirm "Load dconf backup?"; then
#         run_spin "loading dconf" bash -c "dconf load / < '$DCONF_BACKUP'"
#         success "dconf settings loaded"
#     else
#         skip "dconf"
#     fi
# }

# ─────────────────────────────────────────────
module_reboot() {
    section "All Done!"

    figlet -f standard "Fancy Desktop" | while IFS= read -r line; do
        echo -e "\033[38;5;183m${line}${RESET}"
    done
    echo ""

    gum style \
        --foreground="#00eeff" \
        --border=double \
        --border-foreground="#c060ff" \
        --padding="1 4" \
        --margin="1 0" \
        --align=center \
        "🎉 rice applied successfully" \
        "" \
        "log out or reboot for everything to take effect"

    if confirm "Reboot now?"; then
        gum style --foreground="#ff2d5a" "  rebooting... see you on the other side!"
        sleep 1
        sudo reboot
    else
        gum style --foreground="#888888" "  okay! log out and back in when ready."
    fi
}

# =============================================================================
#  MAIN
# =============================================================================

main() {
    clear
    install_gum

    figlet -f standard "Fancy Desktop" | while IFS= read -r line; do
        echo -e "\033[38;5;183m${line}${RESET}"
    done
    echo ""

    gum style \
        --foreground="#888888" \
        --margin="0 2" \
        "fedora · gnome · cyberpunk edition"
    echo ""

    prime_sudo

    module_system_update
    module_shell
    module_dotfiles
    module_fonts
    module_extensions
    module_bootloader
    # module_dconf
    module_reboot
}

main
