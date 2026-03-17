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

ASSETS_DIR="$HOME/fancy-desktop/assets"
DOTFILES_DIR="$ASSETS_DIR/dotfiles"
FONTS_DIR="$ASSETS_DIR/fonts"

# DCONF_BACKUP="$ASSETS_DIR/dconf-backup.ini"
# WLOGOUT_CONFIG="$ASSETS_DIR/wlogout"

# ─────────────────────────────────────────────
#  COLORS
# ─────────────────────────────────────────────

CYAN='\033[38;5;51m'
MAGENTA='\033[38;5;201m'
YELLOW='\033[38;5;226m'
RED='\033[38;5;196m'
GREEN='\033[38;5;82m'
DIM='\033[2m'
RESET='\033[0m'
BOLD='\033[1m'

# ─────────────────────────────────────────────
#  HELPERS
# ─────────────────────────────────────────────

banner() {
    echo ""
    if command -v lolcat &>/dev/null; then
        figlet -f standard "$1" | lolcat --freq 0.3 --seed 42
    else
        echo -e "${CYAN}${BOLD}"
        figlet -f standard "$1"
        echo -e "${RESET}"
    fi
    echo ""
}

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

# ── silent spinner — fully automated commands with no useful output ──
run_spin() {
    local title="$1"
    shift
    gum spin \
        --spinner=dot \
        --spinner.foreground="#00eeff" \
        --title.foreground="#888888" \
        --title=" $title" \
        -- "$@"
}

# ── live output — title line then output flows below ──
run_with_output() {
    local title="$1"
    shift

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

# ── for commands that need user interaction — no spinner, fully visible ──
run_direct() {
    local title="$1"
    shift
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
#  GUARD — install gum if missing (Fedora/dnf)
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
            figlet rubygem-lolcat
        success "system updated and dependencies installed"
    else
        skip "system update"
    fi
}

# ─────────────────────────────────────────────
module_shell() {
    section "Shell Setup"
    if confirm "Set fish as your default shell?"; then

        # robustly get full path — check common locations as fallback
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

        # ensure fish is listed in /etc/shells (required by chsh)
        grep -qxF "$FISH_PATH" /etc/shells || echo "$FISH_PATH" | sudo tee -a /etc/shells > /dev/null

        run_direct "setting fish as default shell" chsh -s "$FISH_PATH"
        if [[ $? -eq 0 ]]; then
            success "fish set as default for $USER"

            if confirm "Also set fish as default for root?"; then
                grep -qxF "$FISH_PATH" /etc/shells || echo "$FISH_PATH" | sudo tee -a /etc/shells > /dev/null
                run_direct "setting fish for root" sudo chsh -s "$FISH_PATH" root
                [[ $? -eq 0 ]] && success "fish set as default for root" || fail "could not set fish for root"
            else
                skip "root shell"
            fi
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
            git clone https://github.com/ChrisTitusTech/Top-5-Bootloader-Themes
        cd Top-5-Bootloader-Themes
        run_direct "running bootloader installer" sudo ./install.sh
        cd ..
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
