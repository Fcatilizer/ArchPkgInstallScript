#### Post Install Arch Quick Install Script.
## A graphical tool for AUR that usage zenity.

## How it works
- It prompts users for yay or paru.
- It check if the following aur helper is installed in the system or not. If not it will install it.
- Prompts User a search box to search any packages.
- Throws a list of packages it found.
- After selecting the package it will ask for Install or Uninstall and prompts for sudo user password.

## How to set up
1. Clone the project.
2. Run the following command to give execute permissions to the script:
```bash
chmod +x aur.sh
```
3. Now Run it
```bash
./aur.sh
```
