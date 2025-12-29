#!/usr/bin/env zsh
# ============================================================
# bootstrap.sh - macOS Bootstrap-Skript
# ============================================================
# Zweck   : Homebrew, CLI-Tools, Nerd Font & Terminal-Profil
# Aufruf  : ./bootstrap.sh
# Docs    : https://github.com/tshofmann/dotfiles#readme
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
# Trap-Handler für Abbruch/Fehler
# ------------------------------------------------------------
# Trackt den aktuellen Schritt für aussagekräftiges Feedback
CURRENT_STEP="Initialisierung"

cleanup() {
  local exit_code=$?
  if (( exit_code != 0 )); then
    print ""
    warn "Bootstrap abgebrochen bei: $CURRENT_STEP"
    warn "Exit-Code: $exit_code"
    print ""
    log "Das Skript ist idempotent – du kannst es erneut ausführen."
    log "Bereits installierte Komponenten werden übersprungen."
  fi
}
trap cleanup EXIT

# ------------------------------------------------------------
# Konfiguration (readonly verhindert versehentliche Überschreibung)
# ------------------------------------------------------------
readonly SCRIPT_DIR="${0:A:h}"
readonly DOTFILES_DIR="${SCRIPT_DIR:h}"
readonly PROFILE_FILE="$SCRIPT_DIR/catppuccin-mocha.terminal"
readonly PROFILE_NAME="catppuccin-mocha"
readonly FONT_GLOB="MesloLG*NerdFont*"
readonly BREWFILE="$SCRIPT_DIR/Brewfile"

# Starship-Konfiguration
# Merke, ob der Nutzer STARSHIP_PRESET explizit gesetzt hat
preset_from_env=false
[[ -n "${STARSHIP_PRESET+x}" ]] && preset_from_env=true

readonly STARSHIP_CONFIG="$HOME/.config/starship.toml"
readonly STARSHIP_PRESET_DEFAULT="catppuccin-powerline"
readonly STARSHIP_PRESET="${STARSHIP_PRESET:-$STARSHIP_PRESET_DEFAULT}"

# Terminal-Profil Import Timeout (Sekunden)
# Kann via PROFILE_IMPORT_TIMEOUT überschrieben werden (z.B. für langsame Systeme/VMs)
PROFILE_IMPORT_TIMEOUT_DEFAULT=20
PROFILE_IMPORT_TIMEOUT="${PROFILE_IMPORT_TIMEOUT:-$PROFILE_IMPORT_TIMEOUT_DEFAULT}"

# Validiere Timeout (muss positive Ganzzahl >= 1 sein)
if [[ ! "$PROFILE_IMPORT_TIMEOUT" =~ ^[1-9][0-9]*$ ]]; then
  warn "PROFILE_IMPORT_TIMEOUT='$PROFILE_IMPORT_TIMEOUT' ungültig, nutze Default: ${PROFILE_IMPORT_TIMEOUT_DEFAULT}s"
  PROFILE_IMPORT_TIMEOUT="$PROFILE_IMPORT_TIMEOUT_DEFAULT"
fi
readonly PROFILE_IMPORT_TIMEOUT_DEFAULT PROFILE_IMPORT_TIMEOUT

# Regex-Match für Terminal-Profil in defaults
readonly PROFILE_GREP_PATTERN="(^[[:space:]]+\"$PROFILE_NAME\"|^[[:space:]]+$PROFILE_NAME)[[:space:]]+="

# Nur Apple Silicon (arm64) wird unterstützt
if [[ $(uname -m) != "arm64" ]]; then
  err "Dieses Setup ist nur für Apple Silicon (arm64) vorgesehen"
  exit 1
fi

# macOS-Version prüfen (mindestens macOS 14 Sonoma erforderlich)
# Homebrew Tier 1 Support: macOS 14+, siehe https://docs.brew.sh/Support-Tiers
# Extrahiert Major-Version aus ProductVersion (z.B. "26.2" → "26")
readonly MACOS_VERSION=$(sw_vers -productVersion)
readonly MACOS_MAJOR=${MACOS_VERSION%%.*}
readonly MACOS_MIN_VERSION=14

if (( MACOS_MAJOR < MACOS_MIN_VERSION )); then
  err "macOS $MACOS_VERSION wird nicht unterstützt"
  err "Mindestversion: macOS $MACOS_MIN_VERSION (Sonoma)"
  err "Aktuelle Version: macOS $MACOS_VERSION"
  exit 1
fi

# Internetverbindung prüfen (erforderlich für Homebrew-Installation und Downloads)
# Verwendet curl HEAD-Request mit kurzem Timeout gegen Apple-Server (zuverlässig erreichbar)
CURRENT_STEP="Netzwerk-Prüfung"
if ! curl -sfL --head --connect-timeout 5 --max-time 10 "https://apple.com" >/dev/null 2>&1; then
  err "Keine Internetverbindung verfügbar"
  err "Das Bootstrap-Skript benötigt eine aktive Internetverbindung für:"
  err "  • Homebrew-Installation"
  err "  • Download von CLI-Tools und Fonts"
  err "  • Mac App Store Apps (optional)"
  err ""
  err "Bitte Netzwerkverbindung herstellen und erneut versuchen."
  exit 1
fi
ok "Internetverbindung verfügbar"

# Home-Verzeichnis Schreibrechte prüfen (für ~/.config, Starship-Config, etc.)
# Wichtig bei NFS/SMB-Mounts oder restriktiven Berechtigungen
CURRENT_STEP="Schreibrechte-Prüfung"
if ! touch "$HOME/.dotfiles_write_test" 2>/dev/null; then
  err "Keine Schreibrechte im Home-Verzeichnis: $HOME"
  err "Das Bootstrap-Skript muss Dateien in ~ erstellen können."
  exit 1
fi
rm -f "$HOME/.dotfiles_write_test"
ok "Schreibrechte vorhanden"

# Xcode Command Line Tools (git/clang & Header; Voraussetzung für Homebrew)
if ! xcode-select -p >/dev/null 2>&1; then
  log "Xcode Command Line Tools werden benötigt (für git/Homebrew). Starte Installation..."
  xcode-select --install || true
  err "Bitte Installation der Command Line Tools abschließen und Skript danach erneut ausführen."
  exit 1
fi

# Homebrew-Prefix für Apple Silicon
readonly BREW_PREFIX="/opt/homebrew"

# ------------------------------------------------------------
# Hauptprogramm
# ------------------------------------------------------------
print "==> macOS Bootstrap (Version $MACOS_VERSION)"

# Homebrew bei Bedarf installieren
CURRENT_STEP="Homebrew Installation"
if ! [[ -x "$BREW_PREFIX/bin/brew" ]]; then
  log "Homebrew nicht gefunden, starte Installation..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Homebrew-Umgebung initialisieren (idempotent, daher immer ausführen)
# Stellt sicher, dass PATH, HOMEBREW_PREFIX etc. korrekt gesetzt sind
# Unabhängig davon, ob Login-Shell oder Skript-Aufruf
if [[ -x "$BREW_PREFIX/bin/brew" ]]; then
  eval "$("$BREW_PREFIX/bin/brew" shellenv)"
  ok "Homebrew bereit"
else
  err "Homebrew-Binary nicht gefunden unter $BREW_PREFIX/bin/brew"
  exit 1
fi

# Brewfile prüfen
if [[ ! -f "$BREWFILE" ]]; then
  err "Brewfile nicht gefunden: $BREWFILE"
  exit 1
fi

# CLI-Tools und Font über Brewfile installieren
# HOMEBREW_NO_AUTO_UPDATE=1: Kein automatisches 'brew update' vor Installation
# --no-upgrade: Bestehende Formulae nicht upgraden (schneller, reproduzierbarer)
CURRENT_STEP="Brewfile Installation (brew bundle)"
log "Installiere Abhängigkeiten aus Brewfile"
if ! HOMEBREW_NO_AUTO_UPDATE=1 brew bundle --no-upgrade --file="$BREWFILE"; then
  err "Brew Bundle fehlgeschlagen – Setup wird abgebrochen"
  exit 1
fi
ok "Abhängigkeiten installiert"

# ------------------------------------------------------------
# bat Cache aktualisieren (für Catppuccin Mocha Theme)
# ------------------------------------------------------------
# Das Theme liegt im Repository unter terminal/.config/bat/themes/
# und wird via Stow nach ~/.config/bat/themes/ verlinkt.
# bat benötigt einen Cache-Rebuild um neue Themes zu erkennen.
CURRENT_STEP="bat-Cache aktualisieren"
if command -v bat >/dev/null 2>&1; then
  log "Baue bat-Cache neu (für Catppuccin Theme)"
  if bat cache --build >/dev/null 2>&1; then
    ok "bat-Cache aktualisiert"
  else
    warn "bat cache --build fehlgeschlagen"
  fi
else
  warn "bat nicht gefunden, überspringe Cache-Build"
fi

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

CURRENT_STEP="Font-Verifikation"
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
CURRENT_STEP="Terminal-Profil Import"
if profile_exists; then
  ok "Profil '$PROFILE_NAME' bereits vorhanden"
else
  log "Importiere Profil '$PROFILE_NAME'"
  open "$PROFILE_FILE"
  import_success=0
  for attempt in {1..$PROFILE_IMPORT_TIMEOUT}; do
    sleep 1
    if profile_exists; then
      ok "Profil '$PROFILE_NAME' importiert"
      import_success=1
      break
    fi
  done
  if (( import_success == 0 )); then
    warn "Profil-Import konnte nicht verifiziert werden (${PROFILE_IMPORT_TIMEOUT}s Timeout)"
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
CURRENT_STEP="Starship-Theme Konfiguration"
log "Konfiguriere Starship-Theme"

# 1. Prüfe ob Starship installiert ist
if ! command -v starship >/dev/null 2>&1; then
  # 2. Falls nicht installiert, Theme-Setup überspringen
  warn "starship nicht gefunden, überspringe Theme-Setup"
else
  # 3. Falls installiert, prüfe ob starship.toml vorhanden ist
  if [[ -f "$STARSHIP_CONFIG" ]]; then
    # Config existiert bereits
    if [[ "$preset_from_env" == "true" ]]; then
      # Nutzer hat explizit ein Preset gesetzt → überschreiben (mit Fallback)
      log "Überschreibe $STARSHIP_CONFIG mit Preset '$STARSHIP_PRESET'"
      if starship preset "$STARSHIP_PRESET" -o "$STARSHIP_CONFIG" 2>/dev/null; then
        ok "Starship-Theme '$STARSHIP_PRESET' gesetzt → $STARSHIP_CONFIG"
      else
        warn "Starship-Preset '$STARSHIP_PRESET' ungültig, nutze Fallback '$STARSHIP_PRESET_DEFAULT'"
        if starship preset "$STARSHIP_PRESET_DEFAULT" -o "$STARSHIP_CONFIG" 2>/dev/null; then
          ok "Fallback-Theme '$STARSHIP_PRESET_DEFAULT' gesetzt → $STARSHIP_CONFIG"
        else
          warn "Auch Fallback-Preset konnte nicht gesetzt werden"
        fi
      fi
    else
      # Kein explizites Preset → bestehende Config bleibt unverändert
      ok "$STARSHIP_CONFIG existiert bereits"
    fi
  else
    # Keine Config vorhanden → erstellen
    if [[ -e "$HOME/.config" && ! -d "$HOME/.config" ]]; then
      err "$HOME/.config existiert, ist aber kein Verzeichnis"
      exit 1
    fi

    if [[ ! -d "$HOME/.config" ]]; then
      log "Erstelle Verzeichnis ~/.config"
      mkdir -p "$HOME/.config"
    fi

    if starship preset "$STARSHIP_PRESET" -o "$STARSHIP_CONFIG" 2>/dev/null; then
      ok "Starship-Theme '$STARSHIP_PRESET' gesetzt → $STARSHIP_CONFIG"
    else
      warn "Starship-Preset '$STARSHIP_PRESET' ungültig, nutze Fallback '$STARSHIP_PRESET_DEFAULT'"
      if starship preset "$STARSHIP_PRESET_DEFAULT" -o "$STARSHIP_CONFIG" 2>/dev/null; then
        ok "Fallback-Theme '$STARSHIP_PRESET_DEFAULT' gesetzt → $STARSHIP_CONFIG"
      else
        warn "Auch Fallback-Preset konnte nicht gesetzt werden"
      fi
    fi
  fi
fi

# ------------------------------------------------------------
# macOS zsh Session-Wiederherstellung deaktivieren
# ------------------------------------------------------------
# macOS Terminal.app speichert standardmäßig separate History pro Tab/Fenster
# in ~/.zsh_sessions/. Die Umgebungsvariable SHELL_SESSIONS_DISABLE=1 in
# ~/.zshenv deaktiviert das Feature zugunsten einer zentralen ~/.zsh_history.
#
# WICHTIG: Die Variable muss in .zshenv gesetzt werden, da /etc/zshrc_Apple_Terminal
# VOR .zprofile und .zshrc geladen wird. Eine leere Datei .zsh_sessions_disable
# hat KEINE Wirkung (verbreiteter Irrtum).
# Ref: /etc/zshrc_Apple_Terminal
print ""
CURRENT_STEP="ZSH-Sessions Konfiguration"
log "Prüfe ZSH-Sessions Konfiguration"

# Prüfe ob .zshenv existiert und SHELL_SESSIONS_DISABLE enthält
if [[ -f "$HOME/.zshenv" ]] && grep -q "SHELL_SESSIONS_DISABLE=1" "$HOME/.zshenv" 2>/dev/null; then
  ok "zsh_sessions deaktiviert via ~/.zshenv"
else
  warn "~/.zshenv fehlt oder SHELL_SESSIONS_DISABLE nicht gesetzt"
  warn "Nach 'stow -R terminal' wird dies automatisch verlinkt"
fi

# Erfolgreicher Abschluss – CURRENT_STEP zurücksetzen für sauberen Exit
CURRENT_STEP=""

print ""
ok "Setup abgeschlossen"
print ""
log "Nächste Schritte:"
log "  1. Terminal.app neu starten für vollständige Übernahme aller Einstellungen"
log "  2. Konfigurationsdateien verlinken: cd $DOTFILES_DIR && stow --adopt -R terminal && git reset --hard HEAD"
