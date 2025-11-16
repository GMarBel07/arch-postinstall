#!/usr/bin/env bash
# install_hyprland_full.sh
# Script automatizado para dejar Arch + Hyprland funcional con tema "Nord".
# Ejecutar como USUARIO normal (no root). El script pedirá sudo cuando haga falta.

set -euo pipefail

USER_HOME="$HOME"
WALLPAPER_DIR="$USER_HOME/Imágenes"
HYPR_CONF_DIR="$USER_HOME/.config/hypr"
WAYBAR_CONF_DIR="$USER_HOME/.config/waybar"
ALACRITTY_CONF_DIR="$USER_HOME/.config/alacritty"
WOFI_CONF_DIR="$USER_HOME/.config/wofi"
HYPRPAPER_CONF_DIR="$USER_HOME/.config/hyprpaper"

PAQUETES_BASE=(
  base-devel git vim wget
  xorg-server xorg-xinit mesa mesa-utils
  networkmanager network-manager-applet
  pipewire pipewire-pulse wireplumber pavucontrol
  bluez bluez-utils bluetooth
  xorg-xwayland xorg-xinput xorg-xrandr xorg-xkbcomp
  alsa-utils pulseaudio-alsa
  waybar wofi alacritty thunar pavucontrol brightnessctl
  polkit polkit-kde-agent
  xdg-desktop-portal xdg-desktop-portal-hyprland
  libx11 libxrandr libxinerama cairo pango
  wl-clipboard
)

AUR_PACKAGES=(
  wlroots-git
  hyprland-git
  hyprpaper-git
  hyprland-waybar-git
  hypridle-git
  hyprlock-git
)

confirm() {
  read -rp "$1 [y/N]: " resp
  case "$resp" in
    [yY][eE][sS]|[yY]) return 0 ;;
    *) return 1 ;;
  esac
}

echo "Este script instalará y configurará Hyprland y el entorno gráfico (tema Nord)."
echo "Ejecutar como usuario normal (no root)."
if ! confirm "¿Deseas continuar?"; then
  echo "Cancelado."
  exit 1
fi

# 1) Actualizar y paquetes de repos oficiales
echo "Actualizando base de datos de paquetes e instalando paquetes oficiales..."
sudo pacman -Syu --noconfirm
sudo pacman -S --noconfirm "${PAQUETES_BASE[@]}"

# 2) Habilitar servicios fundamentales
echo "Habilitando servicios: NetworkManager, bluetooth, wireplumber..."
sudo systemctl enable --now NetworkManager
sudo systemctl enable --now bluetooth
sudo systemctl enable --now wireplumber

# 3) Instalar yay si no existe
if ! command -v yay >/dev/null 2>&1; then
  echo "Instalando yay (AUR helper)..."
  cd "$USER_HOME"
  git clone https://aur.archlinux.org/yay.git /tmp/yay-src
  cd /tmp/yay-src
  makepkg -si --noconfirm
  rm -rf /tmp/yay-src
fi

# 4) Instalar paquetes AUR necesarios
echo "Instalando paquetes AUR (wlroots, hyprland, hyprpaper, hypridle, hyprlock, etc)..."
yay -S --noconfirm "${AUR_PACKAGES[@]}" || {
  echo "Fallo instalando paquetes AUR. Reintentando individualmente..."
  for pkg in "${AUR_PACKAGES[@]}"; do
    yay -S --noconfirm "$pkg" || echo "No se pudo instalar $pkg (saltar)."
  done
}

# 5) Crear directorios de configuración
echo "Creando directorios de configuración..."
mkdir -p "$HYPR_CONF_DIR" "$WAYBAR_CONF_DIR" "$ALACRITTY_CONF_DIR" "$WOFI_CONF_DIR" "$WALLPAPER_DIR" "$HYPRPAPER_CONF_DIR"

# 6) Descargar wallpaper (Unsplash) - puedes cambiarlo luego
WALLPAPER_URL="https://images.unsplash.com/photo-1503264116251-35a269479413?auto=format&fit=crop&w=1920&q=80"
WALLPAPER_PATH="$WALLPAPER_DIR/wallpaper_nord.jpg"
echo "Descargando wallpaper de ejemplo..."
wget -qO "$WALLPAPER_PATH" "$WALLPAPER_URL" || echo "No se pudo descargar el wallpaper. Puedes poner uno manualmente en $WALLPAPER_PATH"

# 7) Escribir hyprland.conf (config mínima i3-like, tema Nord)
cat > "$HYPR_CONF_DIR/hyprland.conf" <<'HYPRCONF'
# Hyprland minimal config (i3-like, Nord-inspired colors)
general {
    animation_duration = 0.15
    focus_follows_mouse = yes
    border_size = 2
    rounding = 6
    smart_window_placement = yes
}

# Basic monitor (auto)
monitor=,preferred,auto,auto,wallpaper=/home/USER_WALL/wallpaper_nord.jpg,wallpaper_mode=stretch

input {
    kb_layout = es
}

# Nord colors (used for borders in config)
nord0 = 0xff2e3440
nord1 = 0xff3b4252
nord2 = 0xff434c5e
nord3 = 0xff4c566a
nord4 = 0xffd8dee9
nord5 = 0xffe5e9f0
nord6 = 0xff8fbcbb
nord7 = 0xff88c0d0
nord8 = 0xff81a1c1
nord9 = 0xff5e81ac

# Keybindings (i3-like)
bind = SUPER+Return, exec, alacritty
bind = SUPER+d, exec, wofi --show drun
bind = SUPER+q, killactive
bind = SUPER+Shift+R, reload
bind = SUPER+Shift+Q, exit
# Move focus (vim keys)
bind = SUPER+h, movefocus, left
bind = SUPER+j, movefocus, down
bind = SUPER+k, movefocus, up
bind = SUPER+l, movefocus, right

# Workspaces (1..9)
bind = SUPER+1, workspace, 1
bind = SUPER+2, workspace, 2
bind = SUPER+3, workspace, 3
bind = SUPER+4, workspace, 4

# Autostart programs
exec-once = waybar
exec-once = nm-applet
exec-once = hyprpaper --daemon
exec-once = dunst
HYPRCONF

# Replace path placeholder in hyprland.conf with the real HOME
sed -i "s|USER_WALL|$USER_HOME/Imágenes|g" "$HYPR_CONF_DIR/hyprland.conf"

# 8) Waybar config + style (Nord)
cat > "$WAYBAR_CONF_DIR/config.json" <<'WAYBARCFG'
{
  "layer": "top",
  "position": "top",
  "modules-left": ["sway/workspaces"],
  "modules-center": ["sway/mode"],
  "modules-right": ["network", "pulseaudio", "battery", "clock"]
}
WAYBARCFG

cat > "$WAYBAR_CONF_DIR/style.css" <<'WAYBARCSS'
* {
  font-family: "JetBrains Mono", monospace;
  font-size: 12px;
  color: #D8DEE9;
  background: #2E3440;
}

#network { background: #3B4252; padding: 4px; border-radius: 4px; }
#pulseaudio { background: #3B4252; padding: 4px; border-radius: 4px; }
#battery { background: #3B4252; padding: 4px; border-radius: 4px; }
#clock { padding: 4px; }
WAYBARCSS

# 9) Wofi config (minimal)
cat > "$WOFI_CONF_DIR/config" <<'WOFICFG'
[settings]
show-icons=true
show-descriptions=false
theme=dracula
WOFICFG

# 10) Alacritty config (simple)
cat > "$ALACRITTY_CONF_DIR/alacritty.yml" <<'ALACFG'
window:
  padding:
    x: 6
    y: 6

font:
  normal:
    family: "JetBrains Mono"
    size: 12.0

colors:
  primary:
    background: '#2E3440'
    foreground: '#D8DEE9'
ALACFG

# 11) Hyprpaper config (simple)
cat > "$HYPRPAPER_CONF_DIR/hyprpaper.conf" <<'HPAPER'
# Simple hyprpaper config
wallpaper = "$HOME/Imágenes/wallpaper_nord.jpg"
HPAPER

# 12) Dunst minimal config (notifications)
mkdir -p "$USER_HOME/.config/dunst"
cat > "$USER_HOME/.config/dunst/dunstrc" <<'DUNSTRC'
[global]
font = JetBrains Mono 10
DUNSTRC

# 13) Ensure correct ownership
chown -R "$USER:$USER" "$HYPR_CONF_DIR" "$WAYBAR_CONF_DIR" "$ALACRITTY_CONF_DIR" "$WOFI_CONF_DIR" "$WALLPAPER_DIR" "$HYPRPAPER_CONF_DIR" "$USER_HOME/.config/dunst" || true

# 14) Install fonts (Nerd fonts JetBrains)
sudo pacman -S --noconfirm nerd-fonts-jetbrains-mono ttf-jetbrains-mono

# 15) Enable polkit agent (kde polkit) so GUI prompts work
sudo systemctl enable --now polkit

echo
echo "------------------------------------------------------------"
echo "INSTALACIÓN COMPLETADA (pasos finales):"
echo "1) Asegúrate de reiniciar sesión para cargar servicios gráficos."
echo "2) Si deseas que tu usuario inicie Hyprland al login, instala y habilita un display manager (sddm):"
echo "     sudo pacman -S sddm"
echo "     sudo systemctl enable --now sddm"
echo "3) Para cambiar el wallpaper sólo sustituye el archivo:"
echo "     $WALLPAPER_PATH"
echo "4) Para cambiar colores o personalizar la apariencia edita:"
echo "     $HYPR_CONF_DIR/hyprland.conf"
echo "     $WAYBAR_CONF_DIR/style.css"
echo
echo "Reinicia ahora para asegurarte de que todo arranca correctamente."
echo "------------------------------------------------------------"
