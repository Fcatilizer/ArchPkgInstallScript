#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Function to install a package using pacman, yay, or paru
install_package() {
    local package=$1
    if echo "$root_password" | sudo -S pacman -S --noconfirm --needed "$package"; then
        echo "$package installed with pacman."
    elif yay -S --noconfirm --needed "$package"; then
        echo "$package installed with yay."
    elif paru -S --noconfirm --needed "$package"; then
        echo "$package installed with paru."
    else
        echo "$package could not be installed." >> failed_packages.log
    fi
}

# Ensure yay and paru are installed
if ! command_exists yay; then
    echo "Installing yay..."
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ..
    rm -rf yay
else
    echo "yay is already installed."
fi

if ! command_exists paru; then
    echo "Installing paru..."
    git clone https://aur.archlinux.org/paru.git
    cd paru
    makepkg -si --noconfirm
    cd ..
    rm -rf paru
else
    echo "paru is already installed."
fi

# List of packages
packages=(
    wine
    samba
    winetricks
    obs-studio
    discord
    libreoffice-fresh
    telegram-desktop
    fontconfig
    yakuake
    power-profiles-daemon
    firewalld
    audacity
    krita
    obsidian
    godot
    nano
    vim
    neovim
    python
    nodejs
    python-pip
    npm
    git
    tgpt
    python-seaborn
    python-numpy
    python-matplotlib
    docker
    kamoso
    haruna
    kdenlive
    okular
    htop
    btop
    p7zip
    unrar
    kcalc
    gnome-boxes
    kdialog
    flatpak
    vlc
    thunderbird
    packagekit
    packagekit-qt5
    packagekit-qt6
    google-chrome
    snapd
    visual-studio-code-bin
    p7zip-gui
    gwenview
    blender
    inkscape
    nvidia-settings
    onedrive-gui
    tokodon
    timeshift
    android-tools
    python-scikit-learn
    python-beautifulsoup4
    python-ipykernel
    winegui
    solaar
    noto-fonts-cjk
    openrgb
    jre
    cryfs
    encfs
    gocryptfs
    onlyoffice
    ttf-firacode
    rust
    vesktop
    spotify
    yazi
    ffmpeg
    ffmpegthumbs
    ffmpegthumbnailer
    ffmpegthumbnailer-mp3
    dart
    fwupd
    spectacle
)

# Create a Zenity checklist string
zenity_list=()
zenity_list+=("install_all" "Install All Packages" "FALSE")
for package in "${packages[@]}"; do
    zenity_list+=("$package" "$package")
done

# Prompt user to select packages
selected_packages=$(zenity --list --checklist \
    --title="Select Packages to Install" \
    --text="Select the packages you want to install (or choose Install All Packages):" \
    --column="Select" --column="Package" \
    "${zenity_list[@]}" \
    --width=500 --height=600 \
    --separator="|")

if [ $? -ne 0 ]; then
    echo "No packages selected. Exiting."
    exit 1
fi

# Ask for root password
root_password=$(zenity --password --title="Root Password")

if [ -z "$root_password" ]; then
    echo "Root password is required. Exiting."
    exit 1
fi

# Update system and install base-devel if not already installed
echo "$root_password" | sudo -S pacman -Syu --needed --noconfirm base-devel

# Check if "Install All Packages" was selected
if [[ "$selected_packages" == *"install_all"* ]]; then
    selected_array=("${packages[@]}")
else
    # Install selected packages
    IFS='|' read -r -a selected_array <<< "$selected_packages"
fi

for package in "${selected_array[@]}"; do
    echo "Installing $package..."
    install_package "$package"
done

# Enable snapd and classic support if snapd is installed
if command_exists snapd; then
    echo "$root_password" | sudo -S systemctl enable --now snapd.socket
    echo "$root_password" | sudo -S systemctl enable --now snapd.apparmor.service
    echo "$root_password" | sudo -S ln -s /var/lib/snapd/snap /snap
fi

# Enable and start firewalld if installed
if command_exists firewalld; then
    echo "$root_password" | sudo -S systemctl enable firewalld
    echo "$root_password" | sudo -S systemctl start firewalld
fi

# Echo packages that could not be installed
if [ -f failed_packages.log ]; then
    zenity --text-info --filename=failed_packages.log --title="Installation Report" --width=500 --height=300
    rm failed_packages.log
else
    zenity --info --text="All packages installed successfully."
fi
