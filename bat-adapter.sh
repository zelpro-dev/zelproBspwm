#!/bin/sh

# === Detectar adaptador de corriente (AC) ===
ac_adapter=$(ls /sys/class/power_supply/ | grep -E '^ADP' | head -n1)
[ -z "$ac_adapter" ] && ac_adapter="ADP0"

# === Detectar batería ===
battery_adapter=$(ls /sys/class/power_supply/ | grep -E '^BAT' | head -n1)
[ -z "$battery_adapter" ] && battery_adapter="BAT0"

# === Actualizar current.ini en el directorio actual ===
current_ini="config/polybar/current.ini"

if [ -f "$current_ini" ]; then
    # Reemplazar battery =
    sed -i "s/^battery = .*/battery = $battery_adapter/" "$current_ini"
    # Reemplazar adapter =
    sed -i "s/^adapter = .*/adapter = $ac_adapter/" "$current_ini"
    echo "current.ini actualizado con battery = $battery_adapter y adapter = $ac_adapter"
else
    echo "current.ini no encontrado en $(pwd), no se pudo actualizar"
fi
