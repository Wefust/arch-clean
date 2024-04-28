#!/bin/bash

# Check if running as root. If root, script will exit
if [[ $EUID -eq 0 ]]; then
	echo "This script should not be executed as root! Exiting......."
	exit 1
fi

clear

echo "$(tput setaf 6)Welcome to Max's Arch Linux Install Script!$(tput sgr0)"
printf "\n%.0s" {1..2}
echo "$(tput bold)$(tput setaf 7)Choose Y to launch the installation process $(tput sgr0)"
echo "$(tput bold)$(tput setaf 7)If you are not sure what to do, choose N$(tput sgr0)"
printf "\n%.0s" {1..1}
read -p "$(tput setaf 6)Would you like to take the red pill? (y/n): $(tput sgr0)" ignition

printf "\n%.0s" {1..3}

if [ "$ignition" != "y" ]; then
	echo "Installation aborted."
	exit 1
fi

ask_yes_no() {

	while true; do
		read -p "$(tput setaf 166)  $1 (y/n): ) :  $(tput sgr0)" choice
		case "$choice" in
		[Yy]*)
			eval "$2='Y'"
			return 0
			;;
		[Nn]*)
			eval "$2='N'"
			return 1
			;;
		*) echo "Please answer with y or n." ;;
		esac
	done
}

# Function for installing packages
install_package_pacman() {
	# Checking if package is already installed
	if pacman -Q "$1" &>/dev/null; then
		echo -e "${OK} $1 is already installed. Skipping..."
	else
		# Package not installed
		echo -e "${NOTE} Installing $1 ..."
		sudo pacman -S --noconfirm "$1" 2>&1
		# Making sure package is installed
		if pacman -Q "$1" &>/dev/null; then
			echo -e "${OK} $1 was installed."
		else
			# Something is missing, exiting to review log
			echo -e "${ERROR} $1 failed to install. You may need to install manually."
			exit 1
		fi
	fi
}

ISAUR=$(command -v yay)

# Function for installing packages
install_package_yay() {
	# Checking if package is already installed
	if $ISAUR -Q "$1" &>>/dev/null; then
		echo -e "${OK} $1 is already installed. Skipping..."
	else
		# Package not installed
		echo -e "${NOTE} Installing $1 ..."
		$ISAUR -S --noconfirm "$1" 2>&1
		# Making sure package is installed
		if $ISAUR -Q "$1" &>>/dev/null; then
			echo -e "\e[1A\e[K${OK} $1 was installed."
		else
			# Something is missing, exiting to review log
			echo -e "\e[1A\e[K${ERROR} $1 failed to install. You may need to install manually! "
			exit 1
		fi
	fi
}

ask_yes_no "-Do you want to install i3 window manager and all softwares ?" interface
printf "\n"
ask_yes_no "-Do you want to install max's config files for i3 ?" conf
printf "\n"
ask_yes_no "-Do you want to install softwares developpement tools ?" develop
printf "\n"
ask_yes_no "-Do you want to install virtualbox ?" virtualbox
printf "\n"
ask_yes_no "-Do you want to install exegol ?" exegol
printf "\n"
ask_yes_no "-Do you want to install bootloader rEFInd ?" refind
printf "\n"

if [ "$interface" == "Y" ]; then

	### 1 - needed packet for install
	install_package_pacman "base-devel" 2>&1

	###############################
	##### 2 -add pacman spice #####
	###############################
	echo -e "${NOTE} Adding Extra Spice in pacman.conf ... ${RESET}" 2>&1
	pacman_conf="/etc/pacman.conf"

	# Remove comments '#' from specific lines
	lines_to_edit=(
		"Color"
		"CheckSpace"
		"VerbosePkgLists"
		"ParallelDownloads"
	)

	# Uncomment specified lines if they are commented out
	for line in "${lines_to_edit[@]}"; do
		if grep -q "^#$line" "$pacman_conf"; then
			sudo sed -i "s/^#$line/$line/" "$pacman_conf"
		fi
	done

	# Add "ILoveCandy" below ParallelDownloads if it doesn't exist
	if grep -q "^ParallelDownloads" "$pacman_conf" && ! grep -q "^ILoveCandy" "$pacman_conf"; then
		sudo sed -i "/^ParallelDownloads/a ILoveCandy" "$pacman_conf"
	fi

	echo -e "${CAT} Pacman.conf spicing up completed ${RESET}" 2>&1

	# updating pacman.conf
	sudo pacman -Syu --noconfirm

	###############################
	##### 3 - yay install #####
	###############################
	if [ -n "$ISAUR" ]; then
		printf "\n%s - AUR helper already installed, moving on.\n" "${OK}"
	else
		git clone https://aur.archlinux.org/yay-git.git && cd yay-git && makepkg -si --noconfirm && cd ..
		### suppression du dépot téléchargé
		rm -rf yay-git
	fi

	### 5 - some extra paquet
	extra=(
		man-db
		wget
		gnome-keyring
	)
	for package in "${extra[@]}"; do
		install_package_pacman "$package" 2>&1
	done

	###############################
	##### 4 - X11 #####
	###############################
	x11=(
		xorg-server
		xorg-server-xephyr
		xorg-setxkbmap
		xorg-xrandr
	)
	for package in "${x11[@]}"; do
		install_package_pacman "$package" 2>&1
	done

	###############################
	##### 5 - i3 #####
	###############################
	i3=(
		i3-wm
		i3blocks
		i3status
	)
	for package in "${i3[@]}"; do
		install_package_pacman "$package" 2>&1
	done

	## install tt-font-awesome for i3 "icons"
	sudo pacman -S ttf-font-awesome --noconfirm
	fc-cache -fv

	###############################
	##### 6 - i3 softwares #####
	###############################
	i3_tools=(
		rofi
		feh
		alacritty
		firefox
		flameshot
		gimp
		thunar
		ranger
		xautolock
	)
	for package in "${i3_tools[@]}"; do
		install_package_pacman "$package" 2>&1
	done
	sudo systemctl enable docker.service
	sudo systemctl start docker.service
	sleep 0.5

	i3_yay=(
		i3lock-color
		picom
	)
	for package in "${i3_yay[@]}"; do
		install_package_yay "$package" 2>&1
	done

	#####################################
	##### 7 - sddm install #####
	#####################################
	sddm=(
		qt6-5compat
		qt6-declarative
		qt6-svg
		qt5-graphicaleffects
		qt5-quickcontrols2
		sddm
	)
	for package in "${sddm[@]}"; do
		install_package_pacman "$package" 2>&1
	done

	## sddm conf files
	sudo cp sddm/sddm.conf /etc/
	sudo cp -r sddm/sddm.conf.d /etc/
	sudo cp -r sddm/archcraft /usr/share/sddm/themes/
	sudo systemctl enable sddm.service

	#####################################
	##### 8 - add tools #####
	#####################################
	tools=(
		zip
		keepassxc
		syncthing
		openvpn
		neofetch
	)
	for package in "${tools[@]}"; do
		install_package_pacman "$package" 2>&1
	done

	#####################################
	##### 9 - install ttheme #####
	#####################################
	gtk=(
		gtk3
		gnome-settings-daemon
		gsettings-desktop-schemas
		gsettings-qt
		lxappearance-gtk3
		arc-gtk-theme
	)
	for package in "${gtk[@]}"; do
		install_package_yay "$package" 2>&1
	done

	clear

fi


if [ "$conf" == "Y" ]; then
	### 0 - set FR keyboard
	sudo localectl set-x11-keymap fr pc86

	### 1 - create conf dir
	mkdir /home/$USER/.config

	###############################
	##### 2 - zsh / oh my zsh #####
	###############################

	zsh=(
		zsh
		zsh-completions
	)
	for package in "${zsh[@]}"; do
		install_package_pacman "$package" 2>&1
	done

	### install oh my zsh
	if command -v zsh >/dev/null; then
		printf "${NOTE} Installing Oh My Zsh and plugins...\n"
		if [ ! -d "$HOME/.oh-my-zsh" ]; then
			sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || true
		else
			echo "Directory .oh-my-zsh already exists. Skipping re-installation." 2>&1
		fi
		### change zsh theme
		#sed -i 's/^ZSH_THEME=.*/ZSH_THEME="dst"/' /home/$USER/.zshrc
		cp .zshrc /home/$USER/

		### set zsh by default
		while ! chsh -s $(which zsh); do
			echo "${ERROR} Authentication failed. Please enter the correct password." 2>&1
			sleep 1
		done
		printf "${NOTE} Shell changed successfully to zsh.\n"
	fi
	clear

	#####################################
	##### 3 - copy i3 config files #####
	#####################################

	## COPY i3 conf
	cp -r .config/* ~/.config/
	chmod +x $HOME/.config/scripts/lock

	## wallpapers
	cp -r .wallpapers /home/$USER/

	## Install fonts
	install_package_pacman "ttf-jetbrains-mono" 2>&1
	install_package_pacman "papirus-icon-theme" 2>&1
	fc-cache -fv

	## icons
	install_package_yay "kora-icon-theme" 2>&1

fi

if [ "$develop" == "Y" ]; then

	### 1 - Install code
	install_package_yay "visual-studio-code-bin" 2>&1

	### 2 - install python
	python=(
		python3
		python-pip
		python-pipx
		python-pywal
	)
	for package in "${python[@]}"; do
		install_package_pacman "$package" 2>&1
	done

	### 3 - install golang
	install_page_pacman "go" 2>&1
	clear
fi

if [ "$virtualbox" == "Y" ]; then

	virt=(
		linux-hardened-headers
		virtualbox-host-dkms
		virtualbox
	)

	for package in "${virt[@]}"; do
		install_package_pacman "$package" 2>&1
	done

	sudo modprobe vboxdrv

	## check version
	ver=$(vboxmanage -v | cut -dr -f1)

	nom="Oracle_VM_VirtualBox_Extension_Pack-$ver.vbox-extpack"

	## download extension pack
	wget "https://download.virtualbox.org/virtualbox/$ver/$nom"
	## install ext pack
	sudo vboxmanage extpack install $nom
	## del ext pack install
	sudo rm $nom
	## add user to vboxusers group
	sudo usermod -aG vboxusers $USER
	clear
fi

if [ "$docker" == "Y" ] || [ "$exegol" == "Y" ]; then

	doc=(
		docker
		docker-compose
	)
	for package in "${doc[@]}"; do
		install_package_pacman "$package" 2>&1
	done
	sudo systemctl enable docker.service
	sudo systemctl start docker.service

	clear
fi


if [ "$exegol" == "Y" ]; then

	## add user to docker group
	sudo usermod -aG docker $(id -u -n)
	## reload docker group
	# newgrp docker

	echo $exegol
	## install exegol
	pipx install git+https://github.com/ThePorgs/Exegol

	## add python auto completion to zsh
	echo 'eval "$(register-python-argcomplete --no-defaults exegol)"' >>~/.zshrc

	pipx ensurepath

	## install exegol nightly image
	/$HOME/.local/bin/exegol install nightly
fi


if [ "$refind" == "Y" ]; then
	install_package_pacman "refind" 2>&1

	sudo mkdir /boot/EFI/refind/themes
	sudo cd /boot/EFI/refind/themes
	sudo git clone https://github.com/evanpurkhiser/rEFInd-minimal
	sudo cd ..
	sudo echo "# Load rEFInd minimal theme" >>refind.conf
	sudo echo "include themes/rEFInd-minimal/theme.conf" >>refind.conf
	cd ~/arch-clean

fi

if [ "$interface" == "Y" ]; then
	sudo systemctl reboot
fi
