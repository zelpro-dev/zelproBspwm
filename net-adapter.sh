#!/bin/sh

# === Detectar adaptadores de red disponibles (excluyendo loopback) ===
adapters=$(ip -o link show | awk -F': ' '{print $2}' | grep -v lo)

# Si no hay adaptadores
if [ -z "$adapters" ]; then
    echo "No se detectaron adaptadores"
    exit 1
fi

# Si hay varios adaptadores, permitir seleccionar
count=$(echo "$adapters" | wc -l)

if [ "$count" -eq 1 ]; then
    adapter="$adapters"
else
    echo "Adaptadores de red detectados:"
    i=1
    for a in $adapters; do
        echo "  $i) $a"
        i=$((i+1))
    done

    # Pedir selección
    while true; do
        printf "Selecciona un adaptador (1-%d): " "$count"
        read choice
        if [ "$choice" -ge 1 ] 2>/dev/null && [ "$choice" -le "$count" ] 2>/dev/null; then
            adapter=$(echo "$adapters" | sed -n "${choice}p")
            break
        else
            echo "Selección inválida, intenta de nuevo."
        fi
    done
fi

# === Sobrescribir el archivo ethernet_status.sh con el adaptador seleccionado ===
cat > config/bin/ethernet_status.sh <<EOF
#!/bin/sh
echo "%{F#FFFFFF} \$(/usr/sbin/ifconfig $adapter | grep 'inet ' | awk '{print \$2}')"
EOF

# === Hacerlo ejecutable ===
chmod +x config/bin/ethernet_status.sh

echo "ethernet_status.sh actualizado con el adaptador $adapter"
