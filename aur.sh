#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Function to install yay if not already installed
install_yay() {
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
}

# Function to install paru if not already installed
install_paru() {
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
}

# Function to choose between yay and paru
choose_aur_helper() {
    aur_helper=$(zenity --list --title="Select AUR Helper" --text="Choose an AUR helper:" \
                        --column="Helper" yay paru --width=300 --height=200)
    if [ -z "$aur_helper" ]; then
        zenity --error --text="No AUR helper selected. Exiting."
        exit 1
    fi
}

# Ensure yay or paru is installed
choose_aur_helper
if [ "$aur_helper" == "yay" ]; then
    install_yay
elif [ "$aur_helper" == "paru" ]; then
    install_paru
fi

# Function to fetch and display recently updated AUR packages
fetch_recently_updated_packages() {
    recent_updates=$(curl -s "https://aur.archlinux.org/rpc/?v=5&type=search&arg=updated" | jq -r '.results[] | "\(.Name) - \(.Version)"')
    if [ -z "$recent_updates" ]; then
        zenity --error --text="Failed to fetch recently updated packages."
        return
    fi
    echo "$recent_updates"
}

# Function to search and display AUR packages
search_packages() {
    search_query=$(zenity --entry --title="Search AUR Packages" --text="Enter the package name to search:" --width=400)
    if [ -z "$search_query" ]; then
        zenity --error --text="No search query entered. Exiting."
        exit 1
    fi

    search_results=$($aur_helper -Ss "$search_query" | awk -F " " '{print $1 " - " $2}')
    if [ -z "$search_results" ]; then
        zenity --error --text="No packages found for the search query: $search_query"
        return
    fi

    selected_package=$(echo "$search_results" | zenity --list --title="Search Results" --text="Select a package to install/uninstall:" \
                                             --column="Package" --width=600 --height=400)
    if [ -z "$selected_package" ]; then
        zenity --error --text="No package selected. Exiting."
        exit 1
    fi
}

# Function to install selected package
install_package() {
    # Fetch the required dependencies
    dependencies=$(echo "$root_password" | sudo -S $aur_helper -S --noconfirm --print-format "%d" "$selected_package" 2>&1)
    
    # Display dependencies in a scrollable window
    zenity --text-info --title="Dependencies Required for $selected_package" --width=600 --height=400 --scroll \
           --text="The following dependencies are required:\n\n$dependencies"

    # Install the package
    echo "$root_password" | sudo -S $aur_helper -S --noconfirm "$selected_package" 2>&1 | tee >(zenity --text-info --title="Installation Output" --width=600 --height=400)
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        zenity --info --text="Package $selected_package installed successfully."
    else
        zenity --error --text="Failed to install package $selected_package."
    fi
}

# Function to uninstall selected package
uninstall_package() {
    # Uninstall the package
    echo "$root_password" | sudo -S $aur_helper -R --noconfirm "$selected_package" 2>&1 | tee >(zenity --text-info --title="Uninstallation Output" --width=600 --height=400)
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        zenity --info --text="Package $selected_package uninstalled successfully."
    else
        zenity --error --text="Failed to uninstall package $selected_package."
    fi
}

# Prompt user to search and select packages
recent_updates=$(fetch_recently_updated_packages)
search_packages

# Display recently updated packages below search bar
if [ -n "$recent_updates" ]; then
    zenity --info --title="Recently Updated AUR Packages" --text="These packages were recently updated in the AUR repository:\n$recent_updates" --width=600 --height=400
fi

# Ask for root password
root_password=$(zenity --password --title="Root Password")

if [ -z "$root_password" ]; then
    echo "Root password is required. Exiting."
    exit 1
fi

# Prompt user to install or uninstall the selected package
action=$(zenity --list --title="Select Action" --text="Select an action for the package $selected_package:" \
                --column="Action" "Install" "Uninstall" --width=300 --height=200)

if [ "$action" == "Install" ]; then
    install_package
elif [ "$action" == "Uninstall" ]; then
    uninstall_package
else
    zenity --error --text="No action selected. Exiting."
    exit 1
fi
