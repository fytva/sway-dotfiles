#!/bin/bash

# Swaybar status script
# Outputs one line per second to swaybar

get_cpu() {
    read -r cpu a b c idle _ < /proc/stat
    sleep 0.2
    read -r cpu a2 b2 c2 idle2 _ < /proc/stat
    used=$(( (a2+b2+c2) - (a+b+c) ))
    total=$(( (a2+b2+c2+idle2) - (a+b+c+idle) ))
    echo $(( used * 100 / total ))%
}

get_mem() {
    awk '/MemTotal/ { total=$2 }
         /MemAvailable/ { avail=$2 }
         END { printf "%dM", (total-avail)/1024 }' /proc/meminfo
}

get_disk() {
    df -h / | awk 'NR==2 { print $3 "/" $2 }'
}

get_vol() {
    vol=$(pamixer --get-volume 2>/dev/null)
    mute=$(pamixer --get-mute 2>/dev/null)

    if [ "$mute" = "true" ]; then
        echo "[󰝟 mute]"
    else
        echo "[󰕾 ${vol}%]"
    fi
}

get_net() {
    # активный интерфейс
    iface=$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if ($i=="dev") print $(i+1)}')

    [ -z "$iface" ] && echo "no net" && return

    # проверяем Wi-Fi интерфейс через iw dev
    if iw dev "$iface" info &>/dev/null; then
        ssid=$(iw dev "$iface" link | awk -F': ' '/SSID/ {print $2}')
        
        if [ -n "$ssid" ]; then
            echo "[󰖩 $ssid]"
        else
            echo "[󰖩 disconnected]"
        fi
        return
    fi

    # иначе это ethernet
    echo "[󰈀 $iface]"
}

get_bat() {
    bat_path=$(ls /sys/class/power_supply/ | grep BAT | head -n 1)
    [ -z "$bat_path" ] && return

    cap=$(cat "/sys/class/power_supply/$bat_path/capacity" 2>/dev/null)
    status=$(cat "/sys/class/power_supply/$bat_path/status" 2>/dev/null)

    if [ "$status" = "Charging" ]; then
        echo "[󰂄 ${cap}]%"
    elif [ "$cap" -le 20 ]; then
        echo "[󰂎 ${cap}%]"
    else
        echo "[󰁹 ${cap}%]"
    fi
}

get_date() {
    date "+%a %d %b  %H:%M"
}

while true; do
    BAT=$(get_bat)
    VOL=$(get_vol)
    NET=$(get_net)

    STATUS=""
    STATUS+="[󰍛 CPU $(get_cpu)] "
    STATUS+="[󰘚 RAM $(get_mem)] "
    STATUS+="[HDD $(get_disk)] "
    [ -n "$NET" ] && STATUS+="  $NET"
    [ -n "$VOL" ] && STATUS+="  $VOL"
    [ -n "$BAT" ] && STATUS+="  $BAT"
    STATUS+=" [$(get_date)] "

    echo "$STATUS"
    sleep 1
done
