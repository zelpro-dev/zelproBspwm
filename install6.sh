#!/bin/bash

set -euo pipefail

# === Colores ===
GREEN="\033[1;32m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
RESET="\033[0m"

# === Función para manejar errores ===
error_handler() {
    printf " ${RED}[ERROR]${RESET} El script se detuvo debido a un error\n"
    exit 1
}

trap error_handler ERR

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

# === Función para limpiar directorios ===
cleanup_directories() {
    echo "Limpiando directorios de instalación..."
    
    # Directorios a limpiar
    local dirs_to_clean=(
        "$HOME/github/picom"
        "$HOME/github/polybar"
        "$HOME/.config/bspwm"
        "$HOME/.config/sxhkd"
        "$HOME/.config/polybar"
        "$HOME/.config/kitty"
        "$HOME/.config/rofi"
        "$HOME/.config/bin"
        "/opt/kitty"
    )
    
    for dir in "${dirs_to_clean[@]}"; do
        if [ -d "$dir" ]; then
            echo "Eliminando: $dir"
            sudo rm -rf "$dir" || true
        fi
    done
    
    # Limpiar archivos de configuración específicos
    local files_to_clean=(
        "$HOME/.zshrc"
        "$HOME/.p10k.zsh"
        "/root/.p10k.zsh"
        "/root/.zshrc"
        "/usr/local/bin/whichSystem.py"
    )
    
    for file in "${files_to_clean[@]}"; do
        if [ -f "$file" ]; then
            echo "Eliminando: $file"
            sudo rm -f "$file" || true
        fi
    done
    
    printf " ${GREEN}[OK]${RESET}\n"
}

# === Comprobamos que no se ejecute como root ===
if [ "$(id -u)" -eq 0 ]; then
    echo "Este script no debe ejecutarse como root. Usa un usuario normal con sudo."
    exit 1
fi

ruta="$(pwd)"
mkdir -p ~/github

# === Limpieza inicial completa ===
cleanup_directories

# Comandos que requieren sudo y pueden pedir input
echo "Limpiando paquetes conflictivos..."
sudo dpkg --remove --force-depends python3-pyinstaller-hooks-contrib 2>/dev/null || true
sudo apt --fix-broken install -y || true
sudo apt autoremove -y || true

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

# === Config Adapters (con manejo de errores) ===
echo "Ejecutando adaptadores (requiere input del usuario)..."
if [ -f "$ruta/net-adapter.sh" ]; then
    bash "$ruta/net-adapter.sh" || echo "Advertencia: net-adapter.sh falló, continuando..."
else
    echo "Advertencia: net-adapter.sh no encontrado"
fi

if [ -f "$ruta/bat-adapter.sh" ]; then
    bash "$ruta/bat-adapter.sh" || echo "Advertencia: bat-adapter.sh falló, continuando..."
else
    echo "Advertencia: bat-adapter.sh no encontrado"
fi

printf " ${GREEN}[OK]${RESET}\n"

# === Clonando repositorios ===
cd ~/github
run "Clonando repositorio Polybar..." git clone --recursive https://github.com/polybar/polybar || true
run "Clonando repositorio Picom..." git clone https://github.com/ibhagwan/picom.git || true

# === Compilación (con manejo de errores) ===
if [ -d ~/github/polybar ]; then
    run "Compilando Polybar..." bash -c "
        cd ~/github/polybar && 
        mkdir -p build && 
        cd build && 
        cmake .. && 
        make -j\$(nproc) && 
        sudo make install
    " || echo "Advertencia: Compilación de Polybar falló, continuando..."
fi

if [ -d ~/github/picom ]; then
    run "Compilando Picom..." bash -c "
        cd ~/github/picom && 
        git submodule update --init --recursive && 
        meson --buildtype=release . build && 
        ninja -C build && 
        sudo ninja -C build install
    " || echo "Advertencia: Compilación de Picom falló, continuando..."
fi

# === Powerlevel10k ===
run "Instalando Powerlevel10k..." bash -c "
    [ ! -d ~/.powerlevel10k ] && git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.powerlevel10k || true
    grep -q 'powerlevel10k.zsh-theme' ~/.zshrc || echo 'source ~/.powerlevel10k/powerlevel10k.zsh-theme' >> ~/.zshrc
    sudo rm -rf /root/.powerlevel10k 2>/dev/null || true
    sudo git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /root/.powerlevel10k 2>/dev/null || true
"

# === Instalación opcional lsd ===
if [ -f "$ruta/lsd.deb" ]; then
    run "Instalando lsd..." sudo dpkg -i "$ruta/lsd.deb" || sudo apt -f install -y
fi

# === Fuentes y wallpapers ===
run "Instalando fuentes y wallpapers..." bash -c "
    sudo mkdir -p /usr/local/share/fonts /usr/share/fonts/truetype 2>/dev/null || true
    [ -d '$ruta/fonts/HNF' ] && sudo cp -vn '$ruta/fonts/HNF/'* /usr/local/share/fonts/ 2>/dev/null || true
    [ -d '$ruta/config/polybar/fonts' ] && sudo cp -vn '$ruta/config/polybar/fonts/'* /usr/share/fonts/truetype/ 2>/dev/null || true
    mkdir -p ~/Wallpaper
    [ -d '$ruta/wallpapers' ] && cp -vn '$ruta/wallpapers/'* ~/Wallpaper/ 2>/dev/null || true
"

# === Configuraciones y scripts ===
run "Copiando configuraciones y scripts..." bash -c "
    mkdir -p ~/.config
    sudo chown -R \$(whoami):\$(whoami) ~/.config 2>/dev/null || true
    [ -d '$ruta/config' ] && cp -rv '$ruta/config/'* ~/.config/ 2>/dev/null || true
    [ -d '$ruta/kitty' ] && sudo cp -rv '$ruta/kitty' /opt/ 2>/dev/null || true
    [ -f '$ruta/.zshrc' ] && cp -v '$ruta/.zshrc' ~/.zshrc 2>/dev/null || true
    [ -f '$ruta/.p10k.zsh' ] && cp -v '$ruta/.p10k.zsh' ~/.p10k.zsh 2>/dev/null || true
    [ -f '$ruta/.p10k.zsh-root' ] && sudo cp -v '$ruta/.p10k.zsh-root' /root/.p10k.zsh 2>/dev/null || true
    [ -f '$ruta/scripts/whichSystem.py' ] && sudo cp -v '$ruta/scripts/whichSystem.py' /usr/local/bin/ 2>/dev/null || true
"

# === Plugins ZSH y permisos ===
run "Instalando plugins ZSH y ajustando permisos..." bash -c "
    sudo mkdir -p /usr/share/zsh-sudo 2>/dev/null || true
    [ ! -f /usr/share/zsh-sudo/sudo.plugin.zsh ] && sudo wget -q -O /usr/share/zsh-sudo/sudo.plugin.zsh https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/plugins/sudo/sudo.plugin.zsh 2>/dev/null || true
    sudo ln -sfv ~/.zshrc /root/.zshrc 2>/dev/null || true
    chmod +x \$HOME/.config/bspwm/bspwmrc \$HOME/.config/bspwm/scripts/bspwm_resize \$HOME/.config/bin/htb_status.sh \
        \$HOME/.config/bin/htb_target.sh \$HOME/.config/polybar/launch.sh \$HOME/.config/bin/target 2>/dev/null || true
    chmod 755 \$HOME/.config/bin/target 2>/dev/null || true
    sudo chmod +x /root/.p10k.zsh-root /usr/local/bin/whichSystem.py 2>/dev/null || true
"

clear
printf "${GREEN}[INSTALACIÓN COMPLETADA]${RESET}\n"
echo "Puedes reiniciar o ejecutar: bspwm"
