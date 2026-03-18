#!/bin/bash

# Niruv Shell - Multi-Distro Installation Script
# Supports: Arch, Fedora, Debian/Ubuntu, openSUSE, Void Linux

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BLUE}${BOLD}"
echo "  ╔═══════════════════════════════════════════════════════╗"
echo "  ║      निरव · Niruv Shell Installer                      ║"
echo "  ║      A minimal, Gruvbox-themed shell for Niri         ║"
echo "  ╚═══════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NIRUV_DIR="$SCRIPT_DIR"

# ========================================
# Detect Distribution
# ========================================
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO_ID="$ID"
        DISTRO_LIKE="$ID_LIKE"
    elif [ -f /etc/arch-release ]; then
        DISTRO_ID="arch"
    elif [ -f /etc/debian_version ]; then
        DISTRO_ID="debian"
    elif [ -f /etc/fedora-release ]; then
        DISTRO_ID="fedora"
    else
        DISTRO_ID="unknown"
    fi

    # Normalize distro families
    case "$DISTRO_ID" in
        arch|endeavouros|manjaro|cachyos|garuda|arco*)
            DISTRO_FAMILY="arch"
            PKG_MANAGER="pacman"
            ;;
        fedora|rhel|centos|rocky|alma)
            DISTRO_FAMILY="fedora"
            PKG_MANAGER="dnf"
            ;;
        debian|ubuntu|pop|mint|elementary|zorin|kali)
            DISTRO_FAMILY="debian"
            PKG_MANAGER="apt"
            ;;
        opensuse*|suse)
            DISTRO_FAMILY="suse"
            PKG_MANAGER="zypper"
            ;;
        void)
            DISTRO_FAMILY="void"
            PKG_MANAGER="xbps"
            ;;
        alpine)
            DISTRO_FAMILY="alpine"
            PKG_MANAGER="apk"
            ;;
        nixos)
            DISTRO_FAMILY="nix"
            PKG_MANAGER="nix"
            ;;
        *)
            # Check ID_LIKE for derivatives
            if [[ "$DISTRO_LIKE" == *"arch"* ]]; then
                DISTRO_FAMILY="arch"
                PKG_MANAGER="pacman"
            elif [[ "$DISTRO_LIKE" == *"debian"* ]] || [[ "$DISTRO_LIKE" == *"ubuntu"* ]]; then
                DISTRO_FAMILY="debian"
                PKG_MANAGER="apt"
            elif [[ "$DISTRO_LIKE" == *"fedora"* ]] || [[ "$DISTRO_LIKE" == *"rhel"* ]]; then
                DISTRO_FAMILY="fedora"
                PKG_MANAGER="dnf"
            else
                DISTRO_FAMILY="unknown"
                PKG_MANAGER="unknown"
            fi
            ;;
    esac

    echo -e "${BLUE}Detected:${NC} $DISTRO_ID ($DISTRO_FAMILY family, $PKG_MANAGER)"

    # Special handling for partially supported distros
    if [ "$DISTRO_FAMILY" = "nix" ]; then
        echo -e "${YELLOW}Note: NixOS detected. Package installation will be skipped.${NC}"
        echo -e "${YELLOW}      Please add dependencies to your configuration.nix manually.${NC}"
    elif [ "$DISTRO_FAMILY" = "alpine" ]; then
        echo -e "${YELLOW}Note: Alpine Linux has limited Wayland support. Some features may not work.${NC}"
    fi
}

# ========================================
# Package Installation Functions
# ========================================
install_packages() {
    local packages=("$@")
    
    case "$DISTRO_FAMILY" in
        arch)
            sudo pacman -S --needed --noconfirm "${packages[@]}"
            ;;
        fedora)
            sudo dnf install -y "${packages[@]}"
            ;;
        debian)
            sudo apt update
            sudo apt install -y "${packages[@]}"
            ;;
        suse)
            sudo zypper install -y "${packages[@]}"
            ;;
        void)
            sudo xbps-install -Sy "${packages[@]}"
            ;;
        alpine)
            sudo apk add "${packages[@]}"
            ;;
        nix)
            echo -e "${YELLOW}NixOS detected. Please add packages to your configuration.nix${NC}"
            return 1
            ;;
        *)
            echo -e "${RED}Unknown package manager. Please install manually: ${packages[*]}${NC}"
            return 1
            ;;
    esac
}

# Map generic package names to distro-specific names
get_package_name() {
    local generic_name="$1"
    
    case "$DISTRO_FAMILY" in
        arch)
            case "$generic_name" in
                libnotify) echo "libnotify" ;;
                wl-clipboard) echo "wl-clipboard" ;;
                nerd-fonts) echo "ttf-jetbrains-mono-nerd" ;;
                bluez) echo "bluez-utils" ;;
                wireplumber) echo "wireplumber" ;;
                pulseaudio-utils) echo "libpulse" ;;
                *) echo "$generic_name" ;;
            esac
            ;;
        fedora)
            case "$generic_name" in
                libnotify) echo "libnotify" ;;
                wl-clipboard) echo "wl-clipboard" ;;
                nerd-fonts) echo "jetbrains-mono-fonts" ;;
                bluez) echo "bluez" ;;
                wireplumber) echo "wireplumber" ;;
                pulseaudio-utils) echo "pulseaudio-utils" ;;
                brightnessctl) echo "brightnessctl" ;;
                *) echo "$generic_name" ;;
            esac
            ;;
        debian)
            case "$generic_name" in
                libnotify) echo "libnotify-bin" ;;
                wl-clipboard) echo "wl-clipboard" ;;
                nerd-fonts) echo "fonts-jetbrains-mono" ;;
                bluez) echo "bluez" ;;
                wireplumber) echo "wireplumber" ;;
                pulseaudio-utils) echo "pulseaudio-utils" ;;
                brightnessctl) echo "brightnessctl" ;;
                cava) echo "cava" ;;
                *) echo "$generic_name" ;;
            esac
            ;;
        suse)
            case "$generic_name" in
                libnotify) echo "libnotify-tools" ;;
                wl-clipboard) echo "wl-clipboard" ;;
                nerd-fonts) echo "jetbrains-mono-fonts" ;;
                bluez) echo "bluez" ;;
                *) echo "$generic_name" ;;
            esac
            ;;
        void)
            case "$generic_name" in
                libnotify) echo "libnotify" ;;
                wl-clipboard) echo "wl-clipboard" ;;
                nerd-fonts) echo "font-jetbrains-mono-ttf" ;;
                bluez) echo "bluez" ;;
                *) echo "$generic_name" ;;
            esac
            ;;
        *)
            echo "$generic_name"
            ;;
    esac
}

# ========================================
# 1. Detect Distribution
# ========================================
echo -e "\n${BLUE}[1/6]${NC} Detecting distribution..."
detect_distro

if [ "$DISTRO_FAMILY" = "unknown" ]; then
    echo -e "${RED}Unsupported distribution: $DISTRO_ID${NC}"
    echo -e "${YELLOW}You can still proceed, but you'll need to install dependencies manually.${NC}"
    read -p "Continue anyway? [y/N] " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
fi

# ========================================
# 2. Check Core Dependencies
# ========================================
echo -e "\n${BLUE}[2/6]${NC} Checking core dependencies..."

# Check for quickshell
if ! command -v qs &> /dev/null && ! command -v quickshell &> /dev/null; then
    echo -e "${YELLOW}Quickshell not found.${NC}"
    echo -e "${YELLOW}Quickshell must be built from source or installed via:${NC}"
    case "$DISTRO_FAMILY" in
        arch)
            echo -e "  ${GREEN}yay -S quickshell-git${NC}"
            ;;
        fedora)
            echo -e "  ${GREEN}# Build from source: https://github.com/outfoxxed/quickshell${NC}"
            ;;
        *)
            echo -e "  ${GREEN}# Build from source: https://github.com/outfoxxed/quickshell${NC}"
            ;;
    esac
    echo
fi

# Check for niri
if ! command -v niri &> /dev/null; then
    echo -e "${YELLOW}Niri not found.${NC}"
    case "$DISTRO_FAMILY" in
        arch)
            echo -e "  ${GREEN}yay -S niri${NC}"
            ;;
        fedora)
            echo -e "  ${GREEN}sudo dnf copr enable yalter/niri && sudo dnf install niri${NC}"
            ;;
        *)
            echo -e "  ${GREEN}# Build from source: https://github.com/YaLTeR/niri${NC}"
            ;;
    esac
    echo
else
    echo -e "${GREEN}✓ Niri found${NC}"
fi

# ========================================
# 3. Install Optional Dependencies
# ========================================
echo -e "\n${BLUE}[3/6]${NC} Checking optional dependencies..."

# Generic package names (will be mapped to distro-specific names)
optional_generic=(
    "brightnessctl"
    "wlsunset"
    "wl-clipboard"
    "cava"
    "libnotify"
    "grim"
    "slurp"
    "swaybg"
    "nerd-fonts"
)

# Map generic package names to their actual command names for detection
get_command_for_package() {
    local generic_name="$1"
    case "$generic_name" in
        libnotify) echo "notify-send" ;;
        wl-clipboard) echo "wl-copy" ;;
        nerd-fonts) echo "" ;;  # No command, check font dir
        *) echo "$generic_name" ;;
    esac
}

# Check if a font is installed (for nerd-fonts)
check_nerd_font() {
    fc-list 2>/dev/null | grep -qi "jetbrains.*nerd\|nerd.*jetbrains" && return 0
    fc-list 2>/dev/null | grep -qi "jetbrainsmono" && return 0
    return 1
}

missing_optional=()
for generic in "${optional_generic[@]}"; do
    pkg=$(get_package_name "$generic")
    cmd_name=$(get_command_for_package "$generic")
    
    # Special case for fonts
    if [ "$generic" = "nerd-fonts" ]; then
        if ! check_nerd_font; then
            missing_optional+=("$pkg")
        fi
    elif [ -n "$cmd_name" ] && ! command -v "$cmd_name" &> /dev/null 2>&1; then
        missing_optional+=("$pkg")
    fi
done

if [ ${#missing_optional[@]} -ne 0 ]; then
    echo -e "${YELLOW}Optional dependencies missing: ${missing_optional[*]}${NC}"
    read -p "Install optional dependencies? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        install_packages "${missing_optional[@]}" || true
    fi
else
    echo -e "${GREEN}✓ All optional dependencies found${NC}"
fi

# ========================================
# 4. Setup Configuration Directories
# ========================================
echo -e "\n${BLUE}[4/6]${NC} Setting up configuration directories..."

mkdir -p "$HOME/.config/niruv"
mkdir -p "$HOME/.cache/niruv"
echo -e "${GREEN}✓ Created ~/.config/niruv and ~/.cache/niruv${NC}"

# Initialize settings.json with projectRoot
# Get the parent directory of Niruv (the project root)
PROJECT_ROOT="$(dirname "$NIRUV_DIR")"
SETTINGS_FILE="$HOME/.config/niruv/settings.json"

if [ ! -f "$SETTINGS_FILE" ]; then
    echo -e "${BLUE}Initializing settings with project root: $PROJECT_ROOT${NC}"
    cat > "$SETTINGS_FILE" << EOF
{
  "general": {
    "projectRoot": "$PROJECT_ROOT/",
    "scaleRatio": 1.0,
    "animationSpeed": 1.0,
    "radiusRatio": 1.0,
    "screenRadiusRatio": 1.0,
    "shadowOffsetX": 2,
    "shadowOffsetY": 2,
    "animationDisabled": false
  },
  "bar": {
    "enabled": true,
    "position": "top",
    "density": "default",
    "showCapsule": true,
    "capsuleOpacity": 0.5
  }
}
EOF
    echo -e "${GREEN}✓ Created settings.json with projectRoot${NC}"
else
    # Update existing settings.json with projectRoot using jq if available
    if command -v jq &> /dev/null; then
        echo -e "${BLUE}Updating projectRoot in existing settings.json${NC}"
        TMP_FILE=$(mktemp)
        jq ".general.projectRoot = \"$PROJECT_ROOT/\"" "$SETTINGS_FILE" > "$TMP_FILE" && mv "$TMP_FILE" "$SETTINGS_FILE"
        echo -e "${GREEN}✓ Updated projectRoot in settings.json${NC}"
    else
        echo -e "${YELLOW}Note: jq not found. Please manually add projectRoot to settings.json:${NC}"
        echo -e "${YELLOW}  \"general\": { \"projectRoot\": \"$PROJECT_ROOT/\" }${NC}"
    fi
fi

# ========================================
# 5. Create Quickshell Symlink
# ========================================
echo -e "\n${BLUE}[5/6]${NC} Creating Quickshell configuration..."

QS_CONFIG_DIR="$HOME/.config/quickshell"
mkdir -p "$QS_CONFIG_DIR"

if [ -L "$QS_CONFIG_DIR/niruv" ]; then
    rm "$QS_CONFIG_DIR/niruv"
fi

ln -sf "$NIRUV_DIR" "$QS_CONFIG_DIR/niruv"
echo -e "${GREEN}✓ Linked $NIRUV_DIR → $QS_CONFIG_DIR/niruv${NC}"

# ========================================
# 6. Optional: Install oNIgiRI Scripts
# ========================================
echo -e "\n${BLUE}[6/6]${NC} oNIgiRI Scripts (Optional)"
echo -e "${YELLOW}oNIgiRI provides system menu scripts, launchers, and TUI utilities for Niri.${NC}"
echo -e "${YELLOW}Repository: https://github.com/kkYrusobad/oNIgiRI${NC}"
echo

read -p "Install oNIgiRI scripts? [y/N] " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    ONIGIRI_DIR="$HOME/.local/share/oNIgiRI"
    
    # Check oNIgiRI dependencies
    onigiri_generic=("fuzzel" "gum" "fzf" "alacritty")
    missing_onigiri=()
    
    for generic in "${onigiri_generic[@]}"; do
        if ! command -v "$generic" &> /dev/null; then
            pkg=$(get_package_name "$generic")
            missing_onigiri+=("$pkg")
        fi
    done
    
    if [ ${#missing_onigiri[@]} -ne 0 ]; then
        echo -e "${YELLOW}oNIgiRI dependencies missing: ${missing_onigiri[*]}${NC}"
        read -p "Install oNIgiRI dependencies? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            install_packages "${missing_onigiri[@]}" || true
        fi
    fi
    
    # Clone or update oNIgiRI
    if [ -d "$ONIGIRI_DIR/.git" ]; then
        echo -e "${BLUE}Updating existing oNIgiRI installation...${NC}"
        cd "$ONIGIRI_DIR" && git pull
    else
        echo -e "${BLUE}Cloning oNIgiRI...${NC}"
        rm -rf "$ONIGIRI_DIR"
        git clone https://github.com/kkYrusobad/oNIgiRI.git "$ONIGIRI_DIR"
    fi
    
    # Add oNIgiRI bin to PATH
    ONIGIRI_BIN="$ONIGIRI_DIR/bin"
    
    if [[ ":$PATH:" != *":$ONIGIRI_BIN:"* ]]; then
        echo -e "${YELLOW}Adding oNIgiRI to your PATH...${NC}"
        
        if [ -f "$HOME/.bashrc" ]; then
            grep -q "oNIgiRI" "$HOME/.bashrc" || echo "export PATH=\"\$PATH:$ONIGIRI_BIN\"" >> "$HOME/.bashrc"
            echo -e "${GREEN}✓ Added to ~/.bashrc${NC}"
        fi
        if [ -f "$HOME/.zshrc" ]; then
            grep -q "oNIgiRI" "$HOME/.zshrc" || echo "export PATH=\"\$PATH:$ONIGIRI_BIN\"" >> "$HOME/.zshrc"
            echo -e "${GREEN}✓ Added to ~/.zshrc${NC}"
        fi
        if [ -d "$HOME/.config/fish" ]; then
            mkdir -p "$HOME/.config/fish/conf.d"
            echo "set -gx PATH \$PATH $ONIGIRI_BIN" > "$HOME/.config/fish/conf.d/onigiri.fish"
            echo -e "${GREEN}✓ Added to fish config${NC}"
        fi
        
        echo -e "${YELLOW}Note: Restart your shell or run 'source ~/.bashrc' to update PATH${NC}"
    fi
    
    echo -e "${GREEN}✓ oNIgiRI installed to $ONIGIRI_DIR${NC}"
fi

# ========================================
# Done!
# ========================================
echo
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}  Installation Complete! 󰄛${NC}"
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════${NC}"
echo
echo -e "To start Niruv, run:"
echo -e "  ${YELLOW}qs -c niruv${NC}"
echo
echo -e "To auto-start with Niri, add this to ~/.config/niri/config.kdl:"
echo -e "  ${YELLOW}spawn-at-startup \"qs\" \"-c\" \"niruv\"${NC}"
echo
echo -e "For debug mode:"
echo -e "  ${YELLOW}NIRUV_DEBUG=1 qs -c niruv${NC}"
echo
echo -e "Enjoy your quiet shell! 󰊠"
