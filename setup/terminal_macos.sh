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
# Konfiguration
# ------------------------------------------------------------
SCRIPT_DIR="${0:A:h}"
PROFILE_FILE="$SCRIPT_DIR/tshofmann.terminal"
PROFILE_NAME="tshofmann"
FONT_GLOB="MesloLG*NerdFont*"
BREWFILE="$SCRIPT_DIR/Brewfile"

# Homebrew-Prefix (Apple Silicon vs Intel)
if [[ $(uname -m) == "arm64" ]]; then
  BREW_PREFIX="/opt/homebrew"
else
  BREW_PREFIX="/usr/local"
fi

# ------------------------------------------------------------
# Hauptprogramm
# ------------------------------------------------------------
print "==> Terminal Setup (macOS)"

# Homebrew prüfen & bei Bedarf installieren
if ! command -v brew >/dev/null 2>&1; then
  print "→ Homebrew nicht gefunden, starte Installation..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  
  # Homebrew in aktueller Shell verfügbar machen
  if [[ -x "$BREW_PREFIX/bin/brew" ]]; then
    eval "$($BREW_PREFIX/bin/brew shellenv)"
    print "✔ Homebrew installiert und aktiviert"
  else
    print "✖ Homebrew-Installation fehlgeschlagen"
    exit 1
  fi
else
  print "✔ Homebrew vorhanden"
fi

# Brewfile prüfen
if [[ ! -f "$BREWFILE" ]]; then
  print "✖ Brewfile nicht gefunden: $BREWFILE"
  exit 1
fi

# CLI-Tools und Font über Brewfile installieren
print "→ Installiere Abhängigkeiten aus Brewfile"
brew bundle --file="$BREWFILE" --no-upgrade
print "✔ Abhängigkeiten installiert"

# Font-Installation verifizieren
font_installed() {
  # Prüfe User- und System-Font-Verzeichnisse (Homebrew installiert nach ~/Library/Fonts)
  [[ -n $(echo ~/Library/Fonts/${~FONT_GLOB}(N) /Library/Fonts/${~FONT_GLOB}(N)) ]]
}

if ! font_installed; then
  print "✖ Font nicht gefunden nach Installation, Terminal-Profil wird nicht importiert."
  print "  Prüfe: ls ~/Library/Fonts/$FONT_GLOB"
  exit 1
fi
print "✔ Font vorhanden"

# Profil-Datei prüfen
if [[ ! -f "$PROFILE_FILE" ]]; then
  print "✖ Profil-Datei nicht gefunden: $PROFILE_FILE"
  exit 1
fi

# Terminal-Profil importieren
# Regex prüft ob Profilname als Key existiert (mit oder ohne Quotes, je nach Leerzeichen im Namen)
if defaults read com.apple.Terminal "Window Settings" 2>/dev/null | grep -qE "(^[[:space:]]+\"$PROFILE_NAME\"|^[[:space:]]+$PROFILE_NAME)[[:space:]]+=" ; then
  print "✔ Profil '$PROFILE_NAME' bereits vorhanden"
else
  print "→ Importiere Profil '$PROFILE_NAME'"
  open "$PROFILE_FILE"
  sleep 2
  
  if defaults read com.apple.Terminal "Window Settings" 2>/dev/null | grep -qE "(^[[:space:]]+\"$PROFILE_NAME\"|^[[:space:]]+$PROFILE_NAME)[[:space:]]+=" ; then
    print "✔ Profil '$PROFILE_NAME' importiert"
  else
    print "⚠ Profil-Import konnte nicht verifiziert werden"
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
  print "✔ Profil '$PROFILE_NAME' bereits als Standard gesetzt"
else
  print "→ Setze '$PROFILE_NAME' als Standard- und Startprofil"
  
  set_profile_as_default "$PROFILE_NAME"
  
  # Verifiziere die Änderung
  sleep 1
  verify_default=$(defaults read com.apple.Terminal "Default Window Settings" 2>/dev/null || true)
  verify_startup=$(defaults read com.apple.Terminal "Startup Window Settings" 2>/dev/null || true)
  
  if [[ "$verify_default" == "$PROFILE_NAME" && "$verify_startup" == "$PROFILE_NAME" ]]; then
    print "✔ Profil '$PROFILE_NAME' als Standard gesetzt"
  else
    print "⚠ Konnte Standardprofil nicht verifizieren"
    print "  Default: $verify_default (erwartet: $PROFILE_NAME)"
    print "  Startup: $verify_startup (erwartet: $PROFILE_NAME)"
  fi
fi

print ""
print "✔ Setup abgeschlossen"
print "→ Terminal.app neu starten für vollständige Übernahme aller Einstellungen"
