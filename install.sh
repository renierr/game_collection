#!/usr/bin/env bash
# Installs a packaged Linux build into the user's home — no root, no package
# manager. Run from the extracted release folder (the one holding `dist/`).
set -euo pipefail

APP_LABEL="Game Collection"
BUILD_NAME="GameCollection-linux"
EXE_NAME="game_collection"
LAUNCH_NAME="gamecollection"

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
SRC="$SCRIPT_DIR/dist/$BUILD_NAME"
DEST="$HOME/.local/share/$BUILD_NAME"
BIN_DIR="$HOME/.local/bin"
BIN="$BIN_DIR/$LAUNCH_NAME"
DESKTOP="$HOME/.local/share/applications/$LAUNCH_NAME.desktop"
ICON_DIR="$HOME/.local/share/icons/hicolor/256x256/apps"

NC='\033[0m'
echo_info() { echo -e "\033[1;36mINFO:${NC} $1"; }
echo_ok() { echo -e "\033[1;32mOK:  ${NC} $1"; }
echo_warn() { echo -e "\033[1;33mWARN:${NC} $1"; }
echo_err() { echo -e "\033[1;31mERR: ${NC} $1"; }

VERSION=""
if [ -f "$SRC/version.txt" ]; then
  VERSION=$(tr -d '\r\n' < "$SRC/version.txt")
elif [ -f "$SCRIPT_DIR/pubspec.yaml" ]; then
  VERSION=$(grep '^version: ' "$SCRIPT_DIR/pubspec.yaml" | sed 's/version: //' | tr -d '\r')
fi

# MSYS2/Cygwin/Git Bash: this installer lays out a Linux tree under $HOME, which
# there is the MSYS home rather than the Windows profile. Hand over to the
# Windows installer instead of writing a useless directory.
case "$(uname -s)" in
  MINGW* | MSYS* | CYGWIN*)
    PS_SCRIPT="$SCRIPT_DIR/install.ps1"
    if [ ! -f "$PS_SCRIPT" ]; then
      echo_err "Windows detected, but install.ps1 is missing next to this script."
      exit 1
    fi
    PS_EXE=$(command -v pwsh.exe || command -v powershell.exe || true)
    if [ -z "$PS_EXE" ]; then
      echo_err "Windows detected. Run install.bat instead (PowerShell not on PATH)."
      exit 1
    fi
    command -v cygpath > /dev/null 2>&1 && PS_SCRIPT=$(cygpath -w "$PS_SCRIPT")
    declare -a PS_ARGS=()
    [ "${1:-}" = "--uninstall" ] || [ "${1:-}" = "-u" ] && PS_ARGS+=("-Uninstall")
    echo_warn "Windows detected — running install.ps1 instead."
    exec "$PS_EXE" -NoProfile -ExecutionPolicy Bypass -File "$PS_SCRIPT" "${PS_ARGS[@]}"
    ;;
esac

stop_app() {
  if pgrep -x "$EXE_NAME" > /dev/null 2>&1; then
    echo_info "Stopping running $APP_LABEL..."
    pkill -x "$EXE_NAME" 2> /dev/null || true
    sleep 1
  fi
}

install_all() {
  if [ ! -x "$SRC/$EXE_NAME" ]; then
    echo_err "Build not found at $SRC. Run './build.sh linux' first."
    exit 1
  fi

  stop_app
  echo_info "Copying files to $DEST..."
  rm -rf "$DEST"
  mkdir -p "$(dirname "$DEST")"
  cp -r "$SRC" "$DEST"
  echo_ok "Copied $(find "$DEST" -type f | wc -l) files"

  mkdir -p "$BIN_DIR"
  ln -sf "$DEST/$EXE_NAME" "$BIN"
  echo_ok "Launcher: $BIN"

  # Flutter's Linux runner ships no icon of its own, so the desktop entry points
  # at the logo bundled with the app's assets.
  local icon="$DEST/data/flutter_assets/assets/logo/logo.png"
  if [ -f "$icon" ]; then
    mkdir -p "$ICON_DIR"
    cp "$icon" "$ICON_DIR/$LAUNCH_NAME.png"
    icon="$ICON_DIR/$LAUNCH_NAME.png"
    echo_ok "Icon installed"
  else
    icon="applications-games"
    echo_warn "Bundled logo missing; falling back to a generic icon"
  fi

  mkdir -p "$(dirname "$DESKTOP")"
  cat > "$DESKTOP" << EOF
[Desktop Entry]
Name=$APP_LABEL
Comment=A collection of casual games
Exec=$DEST/$EXE_NAME
Icon=$icon
Terminal=false
Type=Application
Categories=Game;ArcadeGame;
StartupWMClass=$EXE_NAME
EOF
  echo_ok "Desktop entry: $DESKTOP"

  update-desktop-database "$HOME/.local/share/applications" 2> /dev/null || true

  echo_ok "$APP_LABEL installed to $DEST"
  echo_info "Launch with '$LAUNCH_NAME' or from your app menu"
  case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *) echo_warn "$BIN_DIR is not on your PATH — add it to use the '$LAUNCH_NAME' command" ;;
  esac
  echo_info "Run '$0 --uninstall' to remove"
}

uninstall_all() {
  echo_info "Uninstalling $APP_LABEL..."
  stop_app
  rm -f "$DESKTOP" "$BIN" "$ICON_DIR/$LAUNCH_NAME.png"
  rm -rf "$DEST"
  update-desktop-database "$HOME/.local/share/applications" 2> /dev/null || true
  echo_ok "Uninstall complete"
  echo_info "Saved games in ~/.local/share/$EXE_NAME were left untouched"
}

if [ -n "$VERSION" ]; then
  echo_info "Installer for $APP_LABEL (v$VERSION)"
else
  echo_info "Installer for $APP_LABEL"
fi

if [ "${1:-}" = "--uninstall" ] || [ "${1:-}" = "-u" ]; then
  uninstall_all
  exit 0
fi

if [ -d "$DEST" ]; then
  echo_info "$APP_LABEL is already installed at $DEST"
  read -r -p "Reinstall/update? [Y/n] " answer
  if [[ "$answer" =~ ^[Nn] ]]; then
    echo_info "Update cancelled"
    exit 0
  fi
fi

install_all
