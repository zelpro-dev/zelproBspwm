#!/bin/bash

set -euo pipefail

# === Colores ===
GREEN="\033[1;32m"
RESET="\033[0m"

# === Spinner function ===
spinner() {
    local pid=$!
    local delay=0.1
    local spinstr='|/-\'
    while kill -0 "$pid" 2>/dev/null; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# === Run command with spinner ===
run() {
    local msg=$1
    shift
    printf "%s" "$msg"
    "$@" >/dev/null 2>&1 &
    spinner
    printf " ${GREEN}[OK]${RESET}\n"
}

# === Comprobamos que no se ejecute como root ===
if [ "$(id -u)" -eq 0 ]; then
  echo "Este script no debe ejecutarse como root. Usa un usuario normal con sudo."
  exit 1
fi

ruta="$(pwd)"
mkdir -p ~/github

# === Limpieza inicial ===
echo "Limpiando posibles conflictos..."
[ -d ~/github/picom/build ] && rm -rf ~/github/picom/build
[ -d ~/github/polybar/build ] && rm -rf ~/github/polybar/build

# Comandos que requieren sudo y pueden pedir input
sudo dpkg --remove --force-depends python3-pyinstaller-hooks-contrib || true
sudo apt --fix-broken install -y
sudo apt autoremove -y

printf "${GREEN}[OK]${RESET}\n"

# === Actualización del sistema ===
run "Actualizando sistema..." sudo apt update && sudo apt upgrade -y

# === Instalación de dependencias ===
run "Instalando dependencias básicas..." sudo apt install -y build-essential git vim \
  libxcb-util0-dev libxcb-ewmh-dev libxcb-randr0-dev libxcb-icccm4-dev \
  libxcb-keysyms1-dev libxcb-xinerama0-dev libasound2-dev libxcb-xtest0-dev libxcb-shape0-dev

run "Instalando dependencias Polybar..." sudo apt install -y polybar cmake cmake-data pkg-config python3-sphinx \
  libcairo2-dev libxcb1-dev libxcb-util0-dev libxcb-randr0-dev libxcb-composite0-dev \
  python3-xcbgen xcb-proto libxcb-image0-dev libxcb-ewmh-dev libxcb-icccm4-dev \
  libxcb-xkb-dev libxcb-xrm-dev libxcb-cursor-dev libasound2-dev libpulse-dev \
  libjsoncpp-dev libmpdclient-dev libuv1-dev libnl-genl-3-dev

run "Instalando dependencias Picom..." sudo apt install -y meson picom libxext-dev libxcb1-dev libxcb-damage0-dev \
  libxcb-xfixes0-dev libxcb-shape0-dev libxcb-render-util0-dev libxcb-render0-dev \
  libxcb-composite0-dev libxcb-image0-dev libxcb-present-dev libxcb-xinerama0-dev \
  libpixman-1-dev libdbus-1-dev libconfig-dev libgl1-mesa-dev libpcre2-dev \
  libevdev-dev uthash-dev libev-dev libx11-xcb-dev libxcb-glx0-dev libpcre3 libpcre3-dev

run "Instalando paquetes adicionales..." sudo apt install -y kitty feh scrot brightnessctl flameshot scrub rofi xclip bat \
  locate ranger wmname acpi bspwm sxhkd imagemagick cmatrix

# === Config Adapters (requieren input) ===
echo "Ejecutando adaptadores (requiere input del usuario)..."
bash "$ruta/net-adapter.sh"
printf " ${GREEN}[OK]${RESET}\n"
bash "$ruta/bat-adapter.sh"
printf " ${GREEN}[OK]${RESET}\n"

# === Clonando repositorios ===
cd ~/github
run "Clonando repositorio Polybar..." git clone --recursive https://github.com/polybar/polybar || true
run "Clonando repositorio Picom..." git clone https://github.com/ibhagwan/picom.git || true

# === Compilación ===
run "Compilando Polybar..." bash -c "cd ~/github/polybar && mkdir -p build && cd build && cmake .. && make -j\$(nproc) && sudo make install"
run "Compilando Picom..." bash -c "cd ~/github/picom && git submodule update --init --recursive && meson --buildtype=release . build && ninja -C build && sudo ninja -C build install"

# === Powerlevel10k ===
run "Instalando Powerlevel10k..." bash -c "
[ ! -d ~/.powerlevel10k ] && git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.powerlevel10k
grep -q 'powerlevel10k.zsh-theme' ~/.zshrc || echo 'source ~/.powerlevel10k/powerlevel10k.zsh-theme' >> ~/.zshrc
sudo rm -rf /root/.powerlevel10k
sudo git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /root/.powerlevel10k
"

# === Instalación opcional lsd ===
if [ -f "$ruta/lsd.deb" ]; then
  run "Instalando lsd..." sudo dpkg -i "$ruta/lsd.deb" || sudo apt -f install -y
fi

# === Fuentes y wallpapers ===
run "Instalando fuentes y wallpapers..." bash -c "
sudo mkdir -p /usr/local/share/fonts /usr/share/fonts/truetype
[ -d '$ruta/fonts/HNF' ] && sudo cp -vn '$ruta/fonts/HNF/'* /usr/local/share/fonts/
[ -d '$ruta/config/polybar/fonts' ] && sudo cp -vn '$ruta/config/polybar/fonts/'* /usr/share/fonts/truetype/
mkdir -p ~/Wallpaper
[ -d '$ruta/wallpapers' ] && cp -vn '$ruta/wallpapers/'* ~/Wallpaper/
"

# === Configuraciones y scripts ===
run "Copiando configuraciones y scripts..." bash -c "
mkdir -p ~/.config
sudo chown -R \$(whoami):\$(whoami) ~/.config
sudo cp -rv '$ruta/config/'* ~/.config/
sudo cp -rv '$ruta/kitty' /opt/
[ -f '$ruta/.zshrc' ] && cp -v '$ruta/.zshrc' ~/.zshrc
[ -f '$ruta/.p10k.zsh' ] && cp -v '$ruta/.p10k.zsh' ~/.p10k.zsh
[ -f '$ruta/.p10k.zsh-root' ] && sudo cp -v '$ruta/.p10k.zsh-root' /root/.p10k.zsh
[ -f '$ruta/scripts/whichSystem.py' ] && sudo cp -v '$ruta/scripts/whichSystem.py' /usr/local/bin/ && sudo chmod +x /usr/local/bin/whichSystem.py
"

# === Plugins ZSH y permisos ===
run "Instalando plugins ZSH y ajustando permisos..." bash -c "
sudo mkdir -p /usr/share/zsh-sudo
[ ! -f /usr/share/zsh-sudo/sudo.plugin.zsh ] && sudo wget -q -O /usr/share/zsh-sudo/sudo.plugin.zsh https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/plugins/sudo/sudo.plugin.zsh
sudo ln -sfv ~/.zshrc /root/.zshrc
chmod +x \$HOME/.config/bspwm/bspwmrc \$HOME/.config/bspwm/scripts/bspwm_resize \$HOME/.config/bin/htb_status.sh \
    \$HOME/.config/bin/htb_target.sh \$HOME/.config/polybar/launch.sh \$HOME/.config/bin/target
chmod 755 \$HOME/.config/bin/target
sudo chmod +x /root/.p10k.zsh-root /usr/local/bin/whichSystem.py
"

clear
printf "${GREEN}[INSTALACIÓN COMPLETADA]${RESET}\n"
