#!/bin/bash

# ============================================
# Arch Linux Post-Installation Script
# Author: Martin
# Description: Automated post-install setup
# ============================================

set -e  # Exit on error

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_status() {
    echo -e "${BLUE}[*]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_error "Please do not run as root. Run as normal user."
    exit 1
fi

# ============================================
# UPDATE SYSTEM
# ============================================
print_status "Updating system..."
sudo pacman -Syu --noconfirm

# ============================================
# INSTALL YAY (AUR HELPER)
# ============================================
if ! command -v yay &> /dev/null; then
    print_status "Installing yay..."
    sudo pacman -S --needed --noconfirm base-devel git
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay
    makepkg -si --noconfirm
    cd ~
    rm -rf /tmp/yay
    print_success "yay installed"
else
    print_success "yay already installed"
fi

# ============================================
# INSTALL ESSENTIAL PACKAGES
# ============================================
print_status "Installing essential packages..."

PACKAGES=(
    # Audio
    pipewire pipewire-pulse pipewire-alsa wireplumber
    bluez bluez-utils
    
    # Terminal
    kitty zsh starship neovim btop neofetch
    bat exa ripgrep fd fzf
    
    # Development
    git github-cli python nodejs npm
    
    # Utilities
    unzip zip 7zip wget curl
    
    # Fonts
    noto-fonts noto-fonts-emoji ttf-firacode-nerd
)

sudo pacman -S --needed --noconfirm "${PACKAGES[@]}"
print_success "Essential packages installed"

# ============================================
# ENABLE SERVICES
# ============================================
print_status "Enabling services..."

sudo systemctl enable --now bluetooth
systemctl --user enable --now pipewire pipewire-pulse wireplumber

print_success "Services enabled"

# ============================================
# CONFIGURE ZSH
# ============================================
print_status "Setting up Zsh..."

if [ "$SHELL" != "/usr/bin/zsh" ]; then
    chsh -s /usr/bin/zsh
    print_success "Default shell changed to Zsh"
fi

# ============================================
# CREATE CONFIG DIRECTORIES
# ============================================
print_status "Creating config directories..."

mkdir -p ~/.config/{hypr,waybar,kitty,nvim}

print_success "Config directories created"

# ============================================
# SUMMARY
# ============================================
echo ""
echo "============================================"
print_success "Post-installation complete!"
echo "============================================"
echo ""
echo "Next steps:"
echo "1. Reboot your system"
echo "2. Configure your desktop environment"
echo "3. Install additional packages as needed"
echo ""
print_warning "Remember to log out and back in for shell changes"
