#!/usr/bin/env bash
#
# Smart Mirror setup — automates the steps in README.md on Raspberry Pi OS.
#
# Safe to re-run: every step checks whether it has already been applied before
# changing anything, and files it edits are backed up first.

set -eu

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PY_DIR="$REPO_DIR/src/python"

# ---------- output helpers ----------
c_info='\033[1;34m'; c_ok='\033[1;32m'; c_warn='\033[1;33m'; c_err='\033[1;31m'; c_off='\033[0m'
info() { printf "${c_info}==>${c_off} %s\n" "$*"; }
ok()   { printf "${c_ok}  +${c_off} %s\n" "$*"; }
warn() { printf "${c_warn}  !${c_off} %s\n" "$*"; }
die()  { printf "${c_err}error:${c_off} %s\n" "$*" >&2; exit 1; }

confirm() { # confirm "Question?" [default Y|N]
    local prompt="$1" default="${2:-Y}" reply hint
    [ "$default" = Y ] && hint="Y/n" || hint="y/N"
    read -rp "$prompt [$hint] " reply || true
    reply="${reply:-$default}"
    [[ "$reply" =~ ^[Yy] ]]
}

ask() { # ask VARNAME "Prompt" "default"
    local __var="$1" prompt="$2" default="${3:-}" reply
    if [ -n "$default" ]; then
        read -rp "$prompt [$default]: " reply || true
        reply="${reply:-$default}"
    else
        read -rp "$prompt: " reply || true
    fi
    printf -v "$__var" '%s' "$reply"
}

backup() { [ -f "$1" ] && cp "$1" "$1.bak.$(date +%s)" && warn "backed up $1 -> $1.bak.*"; return 0; }

APT_UPDATED=0
apt_install() { # apt_install pkg...
    command -v apt-get >/dev/null 2>&1 || { warn "apt-get not found; install these manually: $*"; return 0; }
    if [ "$APT_UPDATED" -eq 0 ]; then info "apt-get update"; sudo apt-get update -qq; APT_UPDATED=1; fi
    info "installing: $*"; sudo apt-get install -y "$@"
}

# ---------- preflight ----------
[ "$(uname -s)" = "Linux" ] || die "This script targets Raspberry Pi OS (Linux); detected $(uname -s)."
[ -d "$REPO_DIR/src" ] || die "Run this script from inside the cloned repo (no src/ found)."

# ---------- gather configuration ----------
info "Configuration"
ask WEATHER_API_KEY "Tomorrow.io API key" ""
[ -n "$WEATHER_API_KEY" ] || warn "No API key entered; edit src/js/secrets.js later."
ask GPS_LOCATION "Weather location 'lat,lon'" "47.6061,-122.3328"
LAT="$(printf '%s' "${GPS_LOCATION%%,*}" | tr -d ' ')"
LON="$(printf '%s' "${GPS_LOCATION##*,}" | tr -d ' ')"
DEFAULT_TZ="$(timedatectl show -p Timezone --value 2>/dev/null || echo America/Los_Angeles)"
ask TIMEZONE "Timezone (IANA name)" "$DEFAULT_TZ"

# ---------- 1. secrets.js ----------
info "Writing src/js/secrets.js"
SECRETS="$REPO_DIR/src/js/secrets.js"
if [ -f "$SECRETS" ] && ! confirm "secrets.js exists — overwrite?" N; then
    ok "keeping existing secrets.js"
else
    cat > "$SECRETS" <<EOF
let tomorrowIoApiKey = '$WEATHER_API_KEY';
let gpsLocation = '$GPS_LOCATION'; // Coordinates to show weather for
EOF
    ok "wrote $SECRETS"
fi

# ---------- 2. labwc: hide the cursor ----------
info "Configuring labwc cursor-hide keybind"
RC="$HOME/.config/labwc/rc.xml"
mkdir -p "$(dirname "$RC")"
if [ -f "$RC" ]; then
    if grep -q "HideCursor" "$RC"; then
        ok "HideCursor keybind already present"
    else
        warn "rc.xml exists without a HideCursor keybind; add this manually inside <keyboard>:"
        cat <<'EOF'
        <keybind key="A-W-h">
          <action name="HideCursor" />
          <action name="WarpCursor" x="-1" y="-1" />
        </keybind>
EOF
    fi
else
    cat > "$RC" <<'EOF'
<?xml version="1.0"?>
<labwc_config>
  <keyboard>
    <keybind key="A-W-h">
      <action name="HideCursor" />
      <action name="WarpCursor" x="-1" y="-1" />
    </keybind>
  </keyboard>
</labwc_config>
EOF
    ok "wrote $RC"
fi

# ---------- 3. labwc: autostart the mirror in kiosk mode ----------
info "Configuring labwc autostart"
apt_install wtype
CHROMIUM_BIN="$(command -v chromium || command -v chromium-browser || echo chromium)"
AUTOSTART="$HOME/.config/labwc/autostart"
mkdir -p "$(dirname "$AUTOSTART")"
if [ -f "$AUTOSTART" ] && grep -qF "$REPO_DIR/src/index.html" "$AUTOSTART"; then
    ok "autostart already launches the mirror"
else
    backup "$AUTOSTART"
    cat >> "$AUTOSTART" <<EOF

# Smart Mirror: hide cursor, pull latest, launch Chromium kiosk.
# '|| true' keeps a failed cursor-hide or offline 'git pull' from blocking launch.
wtype -M alt -M logo h -m alt -m logo || true
git -C "$REPO_DIR" pull || true
$CHROMIUM_BIN "$REPO_DIR/src/index.html" --incognito --noerrdialogs --kiosk &
EOF
    ok "added mirror launch to $AUTOSTART (using $CHROMIUM_BIN)"
fi

# ---------- 4. display overlay (config.txt) ----------
info "Configuring display overlay"
CONFIG_TXT=/boot/firmware/config.txt
[ -f "$CONFIG_TXT" ] || CONFIG_TXT=/boot/config.txt
if [ -f "$CONFIG_TXT" ]; then
    for entry in "dtoverlay=rpi-backlight" "disable_touchscreen=1"; do
        if sudo grep -qxF "$entry" "$CONFIG_TXT"; then
            ok "$entry already in $CONFIG_TXT"
        else
            echo "$entry" | sudo tee -a "$CONFIG_TXT" >/dev/null
            ok "added $entry to $CONFIG_TXT"
        fi
    done
else
    warn "No config.txt found; skipping display overlay step."
fi

# ---------- 5. brightness dimming (optional) ----------
if confirm "Set up automatic brightness dimming?" Y; then
    info "Setting up the brightness script"
    apt_install python3-venv
    python3 -m venv "$PY_DIR/.venv"
    "$PY_DIR/.venv/bin/pip" install -q -r "$PY_DIR/requirements.txt"
    ok "created venv and installed dependencies"

    # Location lives in the git-ignored config.py so it survives `git pull`.
    if [ -f "$PY_DIR/config.py" ] && ! confirm "config.py exists — overwrite?" N; then
        ok "keeping existing config.py"
    else
        cat > "$PY_DIR/config.py" <<EOF
LATITUDE = $LAT
LONGITUDE = $LON
TIMEZONE = "$TIMEZONE"
EOF
        ok "wrote $PY_DIR/config.py ($LAT, $LON, $TIMEZONE)"
    fi

    # Run every minute, but skip the 1am-4am overnight-off window (hours 0,4-23).
    CRON_LINE="* 0,4-23 * * * $PY_DIR/.venv/bin/python $PY_DIR/brightness.py"
    if sudo crontab -l 2>/dev/null | grep -qF "brightness.py"; then
        ok "brightness cron already installed"
    else
        { sudo crontab -l 2>/dev/null || true; echo "$CRON_LINE"; } | sudo crontab -
        ok "installed brightness cron (root)"
    fi
else
    ok "skipping brightness dimming"
fi

# ---------- 6. overnight display power-off (optional) ----------
if confirm "Power the display off overnight (1am-4am)?" Y; then
    info "Setting up overnight display power-off"
    apt_install wlr-randr
    ask OUTPUT_NAME "Display output name (run 'wlr-randr' in the session to check)" "DSI-1"
    UID_NUM="$(id -u)"
    WD="${WAYLAND_DISPLAY:-wayland-0}"
    OFF_LINE="0 1 * * * XDG_RUNTIME_DIR=/run/user/$UID_NUM WAYLAND_DISPLAY=$WD wlr-randr --output $OUTPUT_NAME --off"
    ON_LINE="0 4 * * * XDG_RUNTIME_DIR=/run/user/$UID_NUM WAYLAND_DISPLAY=$WD wlr-randr --output $OUTPUT_NAME --on"
    if crontab -l 2>/dev/null | grep -qF "wlr-randr --output $OUTPUT_NAME --off"; then
        ok "overnight power-off cron already installed"
    else
        { crontab -l 2>/dev/null || true; echo "$OFF_LINE"; echo "$ON_LINE"; } | crontab -
        ok "installed overnight on/off cron (user $USER)"
    fi
else
    ok "skipping overnight power-off"
fi

# ---------- done ----------
echo
info "Setup complete."
echo "  Remaining manual steps:"
echo "    - Rotate the display: Preferences > Control Centre > Screens"
echo "    - Reboot to apply config.txt and start the mirror: sudo reboot"
