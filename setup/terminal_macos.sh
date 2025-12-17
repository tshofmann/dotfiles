#!/usr/bin/env zsh
# ============================================================
# terminal_macos.sh - Terminal.app Setup für macOS
# ============================================================
# Zweck   : Installiert Nerd Font und importiert Terminal-Profil
# Aufruf  : ./terminal_macos.sh
# Voraus. : macOS mit Terminal.app
# ============================================================

set -euo pipefail

# ------------------------------------------------------------
# Konfiguration
# ------------------------------------------------------------
SCRIPT_DIR="${0:A:h}"
PROFILE_FILE="$SCRIPT_DIR/tshofmann.terminal"
PROFILE_NAME="tshofmann"
FONT_GLOB="MesloLG*NerdFont*"              # Glob für Nerd Font-Dateien
BREW_FONT_CASK="font-meslo-lg-nerd-font"

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

# CLI-Tools installieren (alphabetisch sortiert)
TOOLS=(fzf gh stow starship zoxide)
print "→ Installiere Tools: ${TOOLS[*]}"
brew install "${TOOLS[@]}"
print "✔ Tools installiert"

# Nerd Font prüfen & bei Bedarf installieren
font_installed() {
  # Prüfe User- und System-Font-Verzeichnisse (Homebrew installiert nach ~/Library/Fonts)
  [[ -n $(echo ~/Library/Fonts/${~FONT_GLOB}(N) /Library/Fonts/${~FONT_GLOB}(N)) ]]
}

if font_installed; then
  print "✔ Font '$BREW_FONT_CASK' vorhanden"
else
  print "→ Installiere Font '$BREW_FONT_CASK'"
  if ! brew install --cask "$BREW_FONT_CASK"; then
    print "✖ Font-Installation fehlgeschlagen"
    exit 1
  fi
  
  # Verifiziere Installation (kurz warten für Systemcache)
  sleep 1
  if font_installed; then
    print "✔ Font '$BREW_FONT_CASK' installiert"
  else
    print "✖ Font nicht gefunden nach Installation, Terminal-Profil wird nicht importiert."
    print "  Prüfe: ls ~/Library/Fonts/$FONT_GLOB"
    exit 1
  fi
fi

# Profil-Datei prüfen
if [[ ! -f "$PROFILE_FILE" ]]; then
  print "✖ Profil-Datei nicht gefunden: $PROFILE_FILE"
  exit 1
fi

# Terminal-Profil importieren (via offiziellem Apple-Mechanismus)
if defaults read com.apple.Terminal "Window Settings" 2>/dev/null | grep -q "\"$PROFILE_NAME\""; then
  print "✔ Profil '$PROFILE_NAME' bereits vorhanden"
else
  print "→ Importiere Profil '$PROFILE_NAME'"
  open "$PROFILE_FILE"
  # Kurz warten bis Terminal das Profil registriert hat
  sleep 2
  
  if defaults read com.apple.Terminal "Window Settings" 2>/dev/null | grep -q "\"$PROFILE_NAME\""; then
    print "✔ Profil '$PROFILE_NAME' importiert"
  else
    print "⚠ Profil-Import konnte nicht verifiziert werden"
  fi
fi

# Profil als Standard setzen
for key in "Default Window Settings" "Startup Window Settings"; do
  current=$(defaults read com.apple.Terminal "$key" 2>/dev/null || true)
  if [[ "$current" != "$PROFILE_NAME" ]]; then
    print "→ Setze $key"
    defaults write com.apple.Terminal "$key" -string "$PROFILE_NAME"
  else
    print "✔ $key korrekt"
  fi
done

print ""
print "✔ Setup abgeschlossen"

# Hinweis bei laufendem Terminal
if pgrep -x "Terminal" >/dev/null 2>&1; then
  print "⚠ Terminal.app neu starten für Änderungen"
fi
