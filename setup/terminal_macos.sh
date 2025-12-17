#!/usr/bin/env zsh
# ============================================================
# terminal_macos.sh - Terminal.app Setup für macOS
# ============================================================
# Zweck   : Homebrew, CLI-Tools, Nerd Font & Terminal-Profil
# Pfad    : ~/dotfiles/setup/terminal_macos.sh
# Aufruf  : ./terminal_macos.sh
# ============================================================

set -euo pipefail

# ------------------------------------------------------------
# Logging-Helper
# ------------------------------------------------------------
log()  { print "→ $*"; }
ok()   { print "✔ $*"; }
err()  { print "✖ $*" >&2; }
warn() { print "⚠ $*"; }

# ------------------------------------------------------------
# Konfiguration
# ------------------------------------------------------------
SCRIPT_DIR="${0:A:h}"
PROFILE_FILE="$SCRIPT_DIR/tshofmann.terminal"
PROFILE_NAME="tshofmann"
FONT_GLOB="MesloLG*NerdFont*"
BREWFILE="$SCRIPT_DIR/Brewfile"

# Starship-Konfiguration
STARSHIP_CONFIG="$HOME/.config/starship.toml"
STARSHIP_PRESET="catppuccin-powerline"

# Regex-Match für Terminal-Profil in defaults
PROFILE_GREP_PATTERN="(^[[:space:]]+\"$PROFILE_NAME\"|^[[:space:]]+$PROFILE_NAME)[[:space:]]+="

# Nur Apple Silicon (arm64) wird unterstützt
if [[ $(uname -m) != "arm64" ]]; then
  err "Dieses Setup ist nur für Apple Silicon (arm64) vorgesehen"
  exit 1
fi

# Xcode Command Line Tools (git/clang & Header; Voraussetzung für Homebrew)
if ! xcode-select -p >/dev/null 2>&1; then
  log "Xcode Command Line Tools werden benötigt (für git/Homebrew). Starte Installation..."
  xcode-select --install || true
  err "Bitte Installation der Command Line Tools abschließen und Skript danach erneut ausführen."
  exit 1
fi

# Homebrew-Prefix für Apple Silicon
BREW_PREFIX="/opt/homebrew"

# ------------------------------------------------------------
# Hauptprogramm
# ------------------------------------------------------------
print "==> Terminal Setup (macOS)"

# Homebrew prüfen & bei Bedarf installieren
if ! command -v brew >/dev/null 2>&1; then
  log "Homebrew nicht gefunden, starte Installation..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  
  # Homebrew in aktueller Shell verfügbar machen
  if [[ -x "$BREW_PREFIX/bin/brew" ]]; then
    eval "$($BREW_PREFIX/bin/brew shellenv)"
    ok "Homebrew installiert und aktiviert"
  else
    err "Homebrew-Installation fehlgeschlagen"
    exit 1
  fi
else
  ok "Homebrew vorhanden"
fi

# Brewfile prüfen
if [[ ! -f "$BREWFILE" ]]; then
  err "Brewfile nicht gefunden: $BREWFILE"
  exit 1
fi

# CLI-Tools und Font über Brewfile installieren
log "Installiere Abhängigkeiten aus Brewfile"
if ! brew bundle --file="$BREWFILE" --no-upgrade; then
  err "Brew Bundle fehlgeschlagen – Setup wird abgebrochen"
  exit 1
fi
ok "Abhängigkeiten installiert"

# Font-Installation verifizieren
font_installed() {
  # Prüfe User- und System-Font-Verzeichnisse (Homebrew installiert nach ~/Library/Fonts)
  # Array sammelt alle gematchten Dateien; (N) = NULL_GLOB, ${~VAR} = Glob-Expansion
  local -a fonts=(
    ~/Library/Fonts/${~FONT_GLOB}(N)
    /Library/Fonts/${~FONT_GLOB}(N)
  )
  (( ${#fonts} > 0 ))
}

profile_exists() {
  local settings
  settings=$(defaults read com.apple.Terminal "Window Settings" 2>/dev/null || true)
  [[ -z "$settings" ]] && return 1
  print -r -- "$settings" | grep -qE "$PROFILE_GREP_PATTERN"
}

if ! font_installed; then
  err "Font nicht gefunden nach Installation, Terminal-Profil wird nicht importiert."
  err "  Prüfe: ls ~/Library/Fonts/$FONT_GLOB"
  exit 1
fi
ok "Font vorhanden"

# Profil-Datei prüfen
if [[ ! -f "$PROFILE_FILE" ]]; then
  err "Profil-Datei nicht gefunden: $PROFILE_FILE"
  exit 1
fi

# Terminal-Profil importieren (mit Retry, falls defaults noch nicht aktualisiert sind)
if profile_exists; then
  ok "Profil '$PROFILE_NAME' bereits vorhanden"
else
  log "Importiere Profil '$PROFILE_NAME'"
  open "$PROFILE_FILE"
  import_success=0
  for attempt in {1..20}; do
    sleep 1
    if profile_exists; then
      ok "Profil '$PROFILE_NAME' importiert"
      import_success=1
      break
    fi
  done
  if (( import_success == 0 )); then
    warn "Profil-Import konnte nicht verifiziert werden (20s Timeout)"
  fi
fi

# Profil als Standard setzen (AppleScript, da defaults write bei laufendem Terminal nicht persistiert)
set_profile_as_default() {
  local profile_name="$1"
  
  osascript <<EOF
tell application "Terminal"
    set targetProfile to null
    repeat with s in settings sets
        if name of s is "$profile_name" then
            set targetProfile to s
            exit repeat
        end if
    end repeat
    
    if targetProfile is not null then
        set default settings to targetProfile
        set startup settings to targetProfile
        return "success"
    else
        return "profile not found"
    end if
end tell
EOF
}

# Aktuelle Einstellungen prüfen
current_default=$(defaults read com.apple.Terminal "Default Window Settings" 2>/dev/null || true)
current_startup=$(defaults read com.apple.Terminal "Startup Window Settings" 2>/dev/null || true)

if [[ "$current_default" == "$PROFILE_NAME" && "$current_startup" == "$PROFILE_NAME" ]]; then
  ok "Profil '$PROFILE_NAME' bereits als Standard gesetzt"
else
  log "Setze '$PROFILE_NAME' als Standard- und Startprofil"
  
  applescript_result=$(set_profile_as_default "$PROFILE_NAME")
  if [[ "$applescript_result" != "success" ]]; then
    warn "AppleScript konnte Profil nicht direkt setzen: $applescript_result"
  fi
  
  # Verifiziere die Änderung
  sleep 1
  verify_default=$(defaults read com.apple.Terminal "Default Window Settings" 2>/dev/null || true)
  verify_startup=$(defaults read com.apple.Terminal "Startup Window Settings" 2>/dev/null || true)
  
  if [[ "$verify_default" == "$PROFILE_NAME" && "$verify_startup" == "$PROFILE_NAME" ]]; then
    ok "Profil '$PROFILE_NAME' als Standard gesetzt"
  else
    warn "Konnte Standardprofil nicht verifizieren"
    warn "  Default: $verify_default (erwartet: $PROFILE_NAME)"
    warn "  Startup: $verify_startup (erwartet: $PROFILE_NAME)"
  fi
fi

print ""
log "Konfiguriere Starship-Theme"

# 1. Prüfe ob Starship installiert ist
if ! command -v starship >/dev/null 2>&1; then
  # 2. Falls nicht installiert, Theme-Setup überspringen
  warn "starship nicht gefunden, überspringe Theme-Setup"
else
  # 3. Falls installiert, prüfe ob starship.toml vorhanden ist
  if [[ -f "$STARSHIP_CONFIG" ]]; then
    # 4. Falls vorhanden, informieren
    ok "$STARSHIP_CONFIG existiert bereits"
  else
    # 5. Prüfe ob ~/.config existiert und ein Verzeichnis ist
    if [[ -e "$HOME/.config" && ! -d "$HOME/.config" ]]; then
      err "$HOME/.config existiert, ist aber kein Verzeichnis"
      exit 1
    fi

    # 6. Erstelle ~/.config falls nicht vorhanden, dann Theme setzen
    if [[ ! -d "$HOME/.config" ]]; then
      log "Erstelle Verzeichnis ~/.config"
      mkdir -p "$HOME/.config"
    fi

    if starship preset "$STARSHIP_PRESET" -o "$STARSHIP_CONFIG" 2>/dev/null; then
      ok "Starship-Theme '$STARSHIP_PRESET' gesetzt → $STARSHIP_CONFIG"
    else
      warn "Starship-Preset '$STARSHIP_PRESET' konnte nicht gesetzt werden"
    fi
  fi
fi

print ""
ok "Setup abgeschlossen"
log "Terminal.app neu starten für vollständige Übernahme aller Einstellungen"
