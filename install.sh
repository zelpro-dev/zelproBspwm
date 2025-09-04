#!/bin/bash

# Comprobar que root
if [ "$(whoami)" == "root" ]; then
  exit 1
fi

ruta=$(pwd)

# Actualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalando dependencias de Entorno
sudo apt install -y build-essential git vim libxcb-util0-dev libxcb-ewmh-dev libxcb-randr0-dev libxcb-icccm4-dev libxcb-keysyms1-dev libxcb-xinerama0-dev libasound2-dev libxcb-xtest0-dev libxcb-shape0-dev

# Instalando Requerimientos para la polybar
sudo apt install -y polybar cmake cmake-data pkg-config python3-sphinx libcairo2-dev libxcb1-dev libxcb-util0-dev libxcb-randr0-dev libxcb-composite0-dev python3-xcbgen xcb-proto libxcb-image0-dev libxcb-ewmh-dev libxcb-icccm4-dev libxcb-xkb-dev libxcb-xrm-dev libxcb-cursor-dev libasound2-dev libpulse-dev libjsoncpp-dev libmpdclient-dev libuv1-dev libnl-genl-3-dev

# Dependencias de Picom
sudo apt install -y meson picom libxext-dev libxcb1-dev libxcb-damage0-dev libxcb-xfixes0-dev libxcb-shape0-dev libxcb-render-util0-dev libxcb-render0-dev libxcb-composite0-dev libxcb-image0-dev libxcb-present-dev libxcb-xinerama0-dev libpixman-1-dev libdbus-1-dev libconfig-dev libgl1-mesa-dev libpcre2-dev libevdev-dev uthash-dev libev-dev libx11-xcb-dev libxcb-glx0-dev libpcre3 libpcre3-dev

# Instalamos paquetes adionales
sudo apt install -y kitty feh scrot brightnessctl flameshot scrub rofi xclip bat locate ranger wmname acpi bspwm sxhkd imagemagick cmatrix

# Creando carpeta de Reposistorios
mkdir ~/github

# Descargar Repositorios Necesarios
cd ~/github
git clone --recursive https://github.com/polybar/polybar
git clone https://github.com/ibhagwan/picom.git

# Instalando Polybar
cd ~/github/polybar
mkdir build
cd build
cmake ..
make -j$(nproc)
sudo make install

# Instalando Picom
cd ~/github/picom
git submodule update --init --recursive
meson --buildtype=release . build
ninja -C build
sudo ninja -C build install

# Instalando p10k
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.powerlevel10k
echo 'source ~/.powerlevel10k/powerlevel10k.zsh-theme' >>~/.zshrc

# Instalando p10k root
sudo git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /root/.powerlevel10k

# Configuramos el tema Nord de Rofi:
# mkdir -p ~/.config/rofi/themes
# cp $ruta/rofi/nord.rasi ~/.config/rofi/themes/

# Instando lsd
sudo dpkg -i $ruta/lsd.deb

# Instalamos las HackNerdFonts
sudo cp -v $ruta/fonts/HNF/* /usr/local/share/fonts/

# Instalando Fuentes de Polybar
sudo cp -v $ruta/config/polybar/fonts/* /usr/share/fonts/truetype/

# Instalando Wallpapers
mkdir ~/Wallpaper
cp -v $ruta/wallpaper/* ~/Wallpaper

# Copiando Archivos de Configuración
rm -r ~/.config/polybar
sudo cp -rv $ruta/kitty /opt/

# Copia de configuracion de .p10k.zsh y .zshrc
rm -rf ~/.zshrc
cp -v $ruta/.zshrc ~/.zshrc

cp -v $ruta/.p10k.zsh ~/.p10k.zsh
sudo cp -v $ruta/.p10k.zsh-root /root/.p10k.zsh

# Script
sudo cp -v $ruta/scripts/whichSystem.py /usr/local/bin/

# Plugins ZSH
sudo apt install -y zsh-syntax-highlighting zsh-autosuggestions
sudo mkdir /usr/share/zsh-sudo
cd /usr/share/zsh-sudo
sudo wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/plugins/sudo/sudo.plugin.zsh

# Cambiando de SHELL a zsh
sudo ln -s -fv ~/.zshrc /root/.zshrc

#Damos permisos de ejecución 
sudo chmod +x $ruta/.p10k.zsh
sudo chmod +x $ruta/.p10k.zsh-root
sudo chmod +x $ruta/config/bspwm/bspwmrc 
sudo chmod +x $ruta/config/bspwm/scripts/bspwm_resize 
sudo chmod +x $ruta/config/bin/ethernet_status.sh
sudo chmod +x $ruta/config/bin/htb_status.sh 
sudo chmod +x $ruta/config/bin/htb_target.sh 
sudo chmod 777 $ruta/config/bin/target 
sudo chmod +x $ruta/config/polybar/launch.sh
sudo chmod +x /usr/local/bin/whichSystem.py

#Movemos los dot files
sudo cp -v $ruta/.p10k.zsh ~/.p10k.zsh
sudo cp -v $ruta/.p10k.zsh-root /root/.p10k.zsh

# Movemos la configuración
sudo cp -rv $ruta/config/* ~/.config/  

# Mensaje de Instalado
clear
