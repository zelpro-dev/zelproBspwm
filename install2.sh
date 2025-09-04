#!/bin/bash

set -euo pipefail

# === Comprobamos que no se ejecute como root ===
if [ "$(id -u)" -eq 0 ]; then
  echo "⚠️  Este script no debe ejecutarse como root. Usa un usuario normal con sudo."
  exit 1
fi

ruta="$(pwd)"

echo "🧹 Limpiando posibles conflictos antes de la instalación..."

# 1️⃣ Directorios de compilación antiguos de Picom y Polybar
[ -d ~/github/picom/build ] && rm -rf ~/github/picom/build && echo "Eliminado build viejo de Picom"
[ -d ~/github/polybar/build ] && rm -rf ~/github/polybar/build && echo "Eliminado build viejo de Polybar"

# 2️⃣ Directorios de repositorios antiguos
[ -d ~/github/picom/.git ] && echo "Picom repo detectado, manteniéndolo"
[ -d ~/github/polybar/.git ] && echo "Polybar repo detectado, manteniéndolo"

# 3️⃣ Paquetes rotos de PyInstaller
sudo dpkg --remove --force-depends python3-pyinstaller-hooks-contrib || true
sudo apt --fix-broken install -y

# 4️⃣ Limpieza de paquetes huérfanos
sudo apt autoremove -y

echo "🔄 Actualizando el sistema..."
sudo apt update && sudo apt upgrade -y

echo "📦 Instalando dependencias de entorno..."
sudo apt install -y build-essential git vim \
  libxcb-util0-dev libxcb-ewmh-dev libxcb-randr0-dev libxcb-icccm4-dev \
  libxcb-keysyms1-dev libxcb-xinerama0-dev libasound2-dev libxcb-xtest0-dev libxcb-shape0-dev

echo "📦 Instalando dependencias para Polybar..."
sudo apt install -y polybar cmake cmake-data pkg-config python3-sphinx \
  libcairo2-dev libxcb1-dev libxcb-util0-dev libxcb-randr0-dev libxcb-composite0-dev \
  python3-xcbgen xcb-proto libxcb-image0-dev libxcb-ewmh-dev libxcb-icccm4-dev \
  libxcb-xkb-dev libxcb-xrm-dev libxcb-cursor-dev libasound2-dev libpulse-dev \
  libjsoncpp-dev libmpdclient-dev libuv1-dev libnl-genl-3-dev

echo "📦 Instalando dependencias de Picom..."
sudo apt install -y meson picom libxext-dev libxcb1-dev libxcb-damage0-dev \
  libxcb-xfixes0-dev libxcb-shape0-dev libxcb-render-util0-dev libxcb-render0-dev \
  libxcb-composite0-dev libxcb-image0-dev libxcb-present-dev libxcb-xinerama0-dev \
  libpixman-1-dev libdbus-1-dev libconfig-dev libgl1-mesa-dev libpcre2-dev \
  libevdev-dev uthash-dev libev-dev libx11-xcb-dev libxcb-glx0-dev libpcre3 libpcre3-dev

echo "📦 Instalando paquetes adicionales..."
sudo apt install -y kitty feh scrot brightnessctl flameshot scrub rofi xclip bat \
  locate ranger wmname acpi bspwm sxhkd imagemagick cmatrix

# === Carpeta de repositorios ===
mkdir -p ~/github
cd ~/github

echo "⬇️ Clonando repositorios..."
[ ! -d polybar ] && git clone --recursive https://github.com/polybar/polybar
[ ! -d picom ] && git clone https://github.com/ibhagwan/picom.git

# === Compilar Polybar ===
echo "⚙️ Instalando Polybar..."
cd ~/github/polybar
mkdir -p build && cd build
cmake ..
make -j"$(nproc)"
sudo make install

# === Compilar Picom ===
echo "⚙️ Instalando Picom..."
cd ~/github/picom
git submodule update --init --recursive
meson --buildtype=release . build
ninja -C build
sudo ninja -C build install

# === Powerlevel10k ===
echo "⬇️ Instalando Powerlevel10k..."
[ ! -d ~/.powerlevel10k ] && git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.powerlevel10k
grep -q "powerlevel10k.zsh-theme" ~/.zshrc || echo 'source ~/.powerlevel10k/powerlevel10k.zsh-theme' >> ~/.zshrc

sudo rm -rf /root/.powerlevel10k
sudo git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /root/.powerlevel10k

# === Instalar lsd si existe ===
if [ -f "$ruta/lsd.deb" ]; then
  echo "📦 Instalando lsd..."
  sudo dpkg -i "$ruta/lsd.deb" || sudo apt -f install -y
fi

# === Fuentes ===
echo "🔠 Instalando fuentes..."
sudo mkdir -p /usr/local/share/fonts /usr/share/fonts/truetype
[ -d "$ruta/fonts/HNF" ] && sudo cp -vn "$ruta/fonts/HNF/"* /usr/local/share/fonts/
[ -d "$ruta/config/polybar/fonts" ] && sudo cp -vn "$ruta/config/polybar/fonts/"* /usr/share/fonts/truetype/

# === Wallpapers ===
mkdir -p ~/Wallpaper
[ -d "$ruta/wallpaper" ] && cp -vn "$ruta/wallpaper/"* ~/Wallpaper/

# === Archivos de configuración ===
echo "🛠️ Copiando configuraciones..."
mkdir -p ~/.config
sudo chown -R $(whoami):$(whoami) ~/.config
sudo cp -rv "$ruta/config/"* ~/.config/
sudo cp -rv "$ruta/kitty" /opt/

# Dotfiles
[ -f "$ruta/.zshrc" ] && cp -v "$ruta/.zshrc" ~/.zshrc
[ -f "$ruta/.p10k.zsh" ] && cp -v "$ruta/.p10k.zsh" ~/.p10k.zsh
[ -f "$ruta/.p10k.zsh-root" ] && sudo cp -v "$ruta/.p10k.zsh-root" /root/.p10k.zsh

# === Script ===
echo "⚡ Instalando scripts..."
[ -f "$ruta/scripts/whichSystem.py" ] && sudo cp -v "$ruta/scripts/whichSystem.py" /usr/local/bin/ && sudo chmod +x /usr/local/bin/whichSystem.py

# Plugins ZSH
echo "🔌 Instalando plugins ZSH..."
sudo mkdir -p /usr/share/zsh-sudo
if [ ! -f /usr/share/zsh-sudo/sudo.plugin.zsh ]; then
  sudo wget -q -O /usr/share/zsh-sudo/sudo.plugin.zsh https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/plugins/sudo/sudo.plugin.zsh
fi

# Enlazar zshrc de root con el del usuario
sudo ln -sfv ~/.zshrc /root/.zshrc

# === Permisos de ejecución ===
echo "🔑 Ajustando permisos..."
# Archivos del usuario
chmod +x "$HOME/.config/bspwm/bspwmrc" \
        "$HOME/.config/bspwm/scripts/bspwm_resize" \
        "$HOME/.config/bin/ethernet_status.sh" \
        "$HOME/.config/bin/htb_status.sh" \
        "$HOME/.config/bin/htb_target.sh" \
        "$HOME/.config/polybar/launch.sh" \
        "$HOME/.config/bin/target"
chmod 755 "$HOME/.config/bin/target"

# Archivos del root
sudo chmod +x /root/.p10k.zsh-root
sudo chmod +x /usr/local/bin/whichSystem.py


# === Finalización ===
clear
echo "✅ Instalación completada correctamente."
