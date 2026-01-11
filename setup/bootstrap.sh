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
# Farben (Catppuccin Mocha)
# ------------------------------------------------------------
# WICHTIG: Synchron halten mit terminal/.config/theme-colors!
#          Nur Subset hier, da bootstrap.sh vor stow läuft.
C_RESET='\033[0m'
C_MAUVE='\033[38;2;203;166;247m'
C_GREEN='\033[38;2;166;227;161m'
C_RED='\033[38;2;243;139;168m'
C_YELLOW='\033[38;2;249;226;175m'
C_BLUE='\033[38;2;137;180;250m'
C_TEXT='\033[38;2;205;214;244m'
C_OVERLAY0='\033[38;2;108;112;134m'
# Text Styles
C_BOLD='\033[1m'
C_DIM='\033[2m'

# ------------------------------------------------------------
# Logging-Helper
# ------------------------------------------------------------
log()  { echo -e "${C_BLUE}→${C_RESET} $*"; }
ok()   { echo -e "${C_GREEN}✔${C_RESET} $*"; }
err()  { echo -e "${C_RED}✖${C_RESET} $*" >&2; }
warn() { echo -e "${C_YELLOW}⚠${C_RESET} $*"; }

# ------------------------------------------------------------
# Defensive Helper für Dateioperationen
# ------------------------------------------------------------
# Prüft ob ein Verzeichnis erstellt werden kann (oder bereits existiert und schreibbar ist)
# Rückgabe: 0 = OK, 1 = Fehler
ensure_dir_writable() {
  local dir="$1"
  local description="${2:-Verzeichnis}"

  # Falls Verzeichnis existiert, prüfe ob schreibbar
  if [[ -d "$dir" ]]; then
    if [[ -w "$dir" ]]; then
      return 0
    else
      err "$description nicht schreibbar: $dir"
      return 1
    fi
  fi

  # Verzeichnis existiert nicht, prüfe ob Elternverzeichnis schreibbar ist
  local parent="${dir:h}"
  if [[ ! -w "$parent" ]]; then
    err "Kann $description nicht erstellen, Elternverzeichnis nicht schreibbar: $parent"
    return 1
  fi

  # Versuche Verzeichnis zu erstellen
  if ! mkdir -p "$dir" 2>/dev/null; then
    err "Konnte $description nicht erstellen: $dir"
    return 1
  fi

  return 0
}

# Prüft ob eine Datei geschrieben werden kann (Verzeichnis existiert und ist schreibbar)
# Rückgabe: 0 = OK, 1 = Fehler
ensure_file_writable() {
  local file="$1"
  local description="${2:-Datei}"
  local dir="${file:h}"

  # Prüfe ob Zielverzeichnis schreibbar ist
  if ! ensure_dir_writable "$dir" "Zielverzeichnis für $description"; then
    return 1
  fi

  # Falls Datei existiert, prüfe ob überschreibbar
  if [[ -e "$file" && ! -w "$file" ]]; then
    err "$description existiert aber ist nicht schreibbar: $file"
    return 1
  fi

  return 0
}

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

# Terminal-Profil dynamisch ermitteln (alphabetisch erste .terminal-Datei in setup/)
PROFILE_FILE=$(find "$SCRIPT_DIR" -maxdepth 1 -name "*.terminal" -type f 2>/dev/null | sort | head -1)
if [[ -z "$PROFILE_FILE" ]]; then
  echo "FEHLER: Keine .terminal-Datei in setup/ gefunden" >&2
  exit 1
fi
readonly PROFILE_FILE

# Warnung wenn mehrere .terminal-Dateien existieren
TERMINAL_COUNT=$(find "$SCRIPT_DIR" -maxdepth 1 -name "*.terminal" -type f 2>/dev/null | wc -l | tr -d ' ')
if (( TERMINAL_COUNT > 1 )); then
  warn "Mehrere .terminal-Dateien gefunden, verwende: ${PROFILE_FILE:t}"
fi
# Profil-Name aus Dateiname extrahieren (ohne .terminal-Endung)
readonly PROFILE_NAME="${${PROFILE_FILE:t}%.terminal}"

readonly FONT_GLOB="MesloLG*NerdFont*"
readonly BREWFILE="$SCRIPT_DIR/Brewfile"

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Starship Shell-Prompt Konfiguration
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Config:  ~/.config/starship.toml (NICHT versioniert)
# Docs:    https://starship.rs/
# Theme:   Catppuccin Mocha via catppuccin-powerline Preset
#
# Warum nicht versioniert?
#   - Config wird via `starship preset` generiert
#   - Nutzer können STARSHIP_PRESET überschreiben
#   - Verhindert Konflikte bei Preset-Updates
#
# Anpassung:
#   export STARSHIP_PRESET="gruvbox-rainbow"  # vor bootstrap.sh
#   Oder: ~/.config/starship.toml direkt editieren (wird dann
#         nicht mehr überschrieben, außer STARSHIP_PRESET gesetzt)
#
# Verfügbare Presets: starship preset --list
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
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

# macOS-Version prüfen
# Homebrew Tier 1 Support: macOS 14+, siehe https://docs.brew.sh/Support-Tiers
readonly MACOS_VERSION=$(sw_vers -productVersion)
readonly MACOS_MAJOR=${MACOS_VERSION%%.*}
readonly MACOS_MIN_VERSION=26     # Unterstützt ab (ändert sich selten)
readonly MACOS_TESTED_VERSION=26  # Zuletzt getestet auf (ändert sich bei Upgrade)

if (( MACOS_MAJOR < MACOS_MIN_VERSION )); then
  err "macOS $MACOS_VERSION wird nicht unterstützt"
  err "Unterstützt ab: macOS $MACOS_MIN_VERSION"
  err "Getestet auf: macOS $MACOS_TESTED_VERSION"
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
      if ! ensure_file_writable "$STARSHIP_CONFIG" "Starship-Config"; then
        warn "Kann Starship-Config nicht überschreiben, überspringe"
      else
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

    # Defensiv: Prüfe ob wir Config-Datei erstellen können
    if ! ensure_file_writable "$STARSHIP_CONFIG" "Starship-Config"; then
      warn "Kann Starship-Config nicht erstellen, überspringe"
    else
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
fi

# ------------------------------------------------------------
# Xcode Theme installieren (dynamisch ermittelt)
# ------------------------------------------------------------
# Xcode verwendet .xccolortheme Dateien für Syntax-Highlighting.
# Das Theme wird nach ~/Library/Developer/Xcode/UserData/FontAndColorThemes/ kopiert.
# Nach Installation muss das Theme manuell in Xcode aktiviert werden.
print ""
CURRENT_STEP="Xcode Theme Installation"

# Xcode-Theme dynamisch ermitteln (alphabetisch erste .xccolortheme-Datei in setup/)
XCODE_THEME_FILE=$(find "$SCRIPT_DIR" -maxdepth 1 -name "*.xccolortheme" -type f 2>/dev/null | sort | head -1)
XCODE_THEMES_DIR="$HOME/Library/Developer/Xcode/UserData/FontAndColorThemes"

# Warnung wenn mehrere .xccolortheme-Dateien existieren
XCODE_THEME_COUNT=$(find "$SCRIPT_DIR" -maxdepth 1 -name "*.xccolortheme" -type f 2>/dev/null | wc -l | tr -d ' ')
if (( XCODE_THEME_COUNT > 1 )); then
  warn "Mehrere .xccolortheme-Dateien gefunden, verwende: ${XCODE_THEME_FILE:t}"
fi

# Theme-Name aus Dateiname extrahieren (für Log-Meldungen)
XCODE_THEME_NAME="${${XCODE_THEME_FILE:t}%.xccolortheme}"

# Prüfe ob Xcode.app installiert ist (nicht nur Command Line Tools)
if [[ -d "/Applications/Xcode.app" ]]; then
  log "Prüfe Xcode Theme-Installation"

  if [[ -n "$XCODE_THEME_FILE" && -f "$XCODE_THEME_FILE" ]]; then
    # Defensiv: Prüfe ob Zielverzeichnis erstellt/beschrieben werden kann
    if ! ensure_dir_writable "$XCODE_THEMES_DIR" "Xcode Themes-Verzeichnis"; then
      warn "Kann Xcode Theme nicht installieren, Verzeichnis nicht schreibbar"
    else
      # Prüfe ob Theme-Datei geschrieben werden kann
      local theme_dest="$XCODE_THEMES_DIR/${XCODE_THEME_FILE:t}"
      if ! ensure_file_writable "$theme_dest" "Xcode Theme"; then
        warn "Kann Xcode Theme nicht installieren, Zieldatei nicht schreibbar"
      else
        # Theme kopieren (überschreibt existierende Version)
        if cp "$XCODE_THEME_FILE" "$XCODE_THEMES_DIR/"; then
          ok "Xcode Theme '$XCODE_THEME_NAME' installiert"
          log "Aktivierung: Xcode → Settings (⌘,) → Themes → '$XCODE_THEME_NAME'"
        else
          warn "Konnte Xcode Theme nicht kopieren (unbekannter Fehler)"
        fi
      fi
    fi
  else
    warn "Keine .xccolortheme-Datei in setup/ gefunden"
  fi
else
  log "Xcode.app nicht installiert, überspringe Theme-Installation"
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
  warn "Nach 'stow -R terminal editor' wird dies automatisch verlinkt"
fi

# Erfolgreicher Abschluss – CURRENT_STEP zurücksetzen für sauberen Exit
CURRENT_STEP=""

print ""
ok "Setup abgeschlossen"
print ""
log "Nächste Schritte:"
log "  1. Terminal.app neu starten für vollständige Übernahme aller Einstellungen"
log "  2. Konfigurationsdateien verlinken: cd $DOTFILES_DIR && stow --adopt -R terminal editor && git reset --hard HEAD"
log "  3. Git-Hooks aktivieren: git config core.hooksPath .github/hooks"
log "  4. bat Theme-Cache bauen: bat cache --build"
log "  5. tldr-Pages herunterladen: tldr --update"
print ""
print "  ${C_GREEN}💡 Gib im Terminal '${C_BOLD}dothelp${C_RESET}${C_GREEN}' ein für Hilfe/Dokumentation${C_RESET}"
print ""
