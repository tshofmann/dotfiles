#!/usr/bin/env zsh
set -euo pipefail

PROFILE_FILE="tshofmann.terminal"
PROFILE_NAME="tshofmann"
FONT_NAME="MesloLGS NF"
BREW_FONT_CASK="font-meslo-lg-nerd-font"

print "==> Terminal Setup (macOS, idempotent)"

# 1️⃣ Homebrew prüfen
if ! command -v brew >/dev/null 2>&1; then
  print "✖ Homebrew nicht installiert"
  print "  → https://brew.sh"
  exit 1
fi

# 2️⃣ Nerd Font prüfen & bei Bedarf installieren
if system_profiler SPFontsDataType 2>/dev/null | grep -q "$FONT_NAME"; then
  print "✔ Nerd Font '$FONT_NAME' bereits installiert"
else
  print "→ Installiere Nerd Font '$FONT_NAME'"
  brew install --cask "$BREW_FONT_CASK"
fi

# 3️⃣ Prüfen, ob Terminal-Profil existiert
if defaults read com.apple.Terminal "Window Settings" 2>/dev/null | grep -q "\"$PROFILE_NAME\""; then
  print "✔ Profil '$PROFILE_NAME' existiert bereits"
else
  print "→ Importiere Terminal-Profil"
  [[ -f "$PROFILE_FILE" ]] || { print "✖ $PROFILE_FILE fehlt"; exit 1; }
  open "$PROFILE_FILE"
fi

# 4️⃣ Profil als Default & Startup setzen (nur wenn nötig)
for KEY in "Default Window Settings" "Startup Window Settings"; do
  CURRENT=$(defaults read com.apple.Terminal "$KEY" 2>/dev/null || true)
  if [[ "$CURRENT" != "$PROFILE_NAME" ]]; then
    print "→ Setze $KEY auf '$PROFILE_NAME'"
    defaults write com.apple.Terminal "$KEY" -string "$PROFILE_NAME"
  else
    print "✔ $KEY bereits korrekt"
  fi
done

print "✔ Terminal Setup abgeschlossen"
print "ℹ Terminal.app ggf. neu starten"
