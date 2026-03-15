#!/bin/bash
# ─────────────────────────────────────────
#  Package Manager Detector & Script Runner
# ─────────────────────────────────────────

# ── Colors ────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
LAVENDER='\033[38;5;183m'; RESET='\033[0m'

# ── Logging ───────────────────────────────
log()   { echo -e "${GREEN}[INFO]${RESET}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
error() { echo -e "${RED}[ERROR]${RESET} $*"; exit 1; }

# ── Install figlet if not present ─────────
if ! command -v figlet &>/dev/null; then
    if command -v apt &>/dev/null; then
        sudo apt install -y figlet gum &>/dev/null
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y figlet gum &>/dev/null
    fi
fi

# ── Banner ────────────────────────────────
echo -e "${LAVENDER}"
figlet -w 100 "Fancy  Desktop"
echo -e "${RESET}"

log "Detecting your system..."

# ── Detection ─────────────────────────────
detect_package_manager() {
    if command -v apt &>/dev/null; then
        echo "apt"
    elif command -v dnf &>/dev/null; then
        echo "dnf"
    else
        echo "unknown"
    fi
}

# ── Main ──────────────────────────────────
PKG_MANAGER=$(detect_package_manager)
log "Setting things up for you, sit back and relax..."

case "$PKG_MANAGER" in
    apt)
        log "Preparing your desktop..."
        bash ~/fancy-desktop/scripts/debian/debian-rice.sh
#               bash debian-rice.sh
        ;;
    dnf)
        log "Preparing your desktop..."
        bash ~/fancy-desktop/scripts/fedora/fedora-rice.sh
#               bash fedora-rice.sh
        ;;
    *)
        error "Oops! Your system is not supported yet."
        ;;
esac

log "All done! Enjoy your fancy desktop :)"
