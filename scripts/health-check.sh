#!/usr/bin/env zsh
# ============================================================
# health-check.sh - Systemprüfung der dotfiles-Installation
# ============================================================
# Zweck   : Prüft ob alle Komponenten korrekt INSTALLIERT sind
#           (Symlinks, Tools, Konfigurationen, Abhängigkeiten)
#
# HINWEIS : Dieser Check prüft die INSTALLATION auf dem System.
#           Für Konsistenz Doku↔Code: ./scripts/validate-docs.sh
#
# Design  : SOLL-IST-VERGLEICH – vollständig dynamisch!
#
#           SOLL (was sein sollte):
#           - Alle Dateien in terminal/ → Symlinks in ~/
#           - Alle brew-Formulae in Brewfile → installierte Tools
#           - Alle zsh-* in Brewfile → ZSH-Plugins
#           - Alle font-* in Brewfile → Fonts
#
#           IST (was tatsächlich existiert):
#           - Symlinks im Home-Verzeichnis
#           - Installierte Binaries (command -v)
#           - Plugin-Verzeichnisse in $(brew --prefix)/share/
#           - Font-Dateien in ~/Library/Fonts/
#
#           → Neue Dateien werden AUTOMATISCH erkannt!
#           → Keine manuellen Updates bei neuen Configs nötig!
#
# Aufruf  : ./scripts/health-check.sh
# Docs    : https://github.com/tshofmann/dotfiles#readme
# ============================================================

set -uo pipefail

# ------------------------------------------------------------
# Farben (Catppuccin Mocha)
# ------------------------------------------------------------
C_RESET='\033[0m'
C_MAUVE='\033[38;2;203;166;247m'
C_GREEN='\033[38;2;166;227;161m'
C_RED='\033[38;2;243;139;168m'
C_YELLOW='\033[38;2;249;226;175m'
C_BLUE='\033[38;2;137;180;250m'
C_TEXT='\033[38;2;205;214;244m'
C_DIM='\033[38;2;108;112;134m'

# ------------------------------------------------------------
# Konfiguration
# ------------------------------------------------------------
readonly SCRIPT_DIR="${0:A:h}"
readonly DOTFILES_DIR="${SCRIPT_DIR:h}"
readonly TERMINAL_DIR="$DOTFILES_DIR/terminal"
readonly BREWFILE="$DOTFILES_DIR/setup/Brewfile"

# Zähler für Ergebnisse
typeset -i passed=0
typeset -i failed=0
typeset -i warnings=0

# ------------------------------------------------------------
# Ausgabe-Helper
# ------------------------------------------------------------
pass()    { echo -e "  ${C_GREEN}✔${C_RESET} $*"; (( passed++ )); }
fail()    { echo -e "  ${C_RED}✖${C_RESET} $*"; (( failed++ )); }
warn()    { echo -e "  ${C_YELLOW}⚠${C_RESET} $*"; (( warnings++ )); }
section() { echo -e "\n${C_BLUE}━━━${C_RESET} $* ${C_BLUE}━━━${C_RESET}"; }

# ------------------------------------------------------------
# Symlink-Prüfung
# ------------------------------------------------------------
check_symlink() {
  local link="$1"
  local expected_target="$2"
  local display_name="${3:-$link}"
  
  if [[ -L "$link" ]]; then
    local actual_target
    actual_target=$(readlink "$link")
    if [[ "$actual_target" == *"$expected_target"* ]]; then
      pass "$display_name → korrekt verlinkt"
    else
      fail "$display_name → falsches Ziel: $actual_target"
    fi
  elif [[ -e "$link" ]]; then
    fail "$display_name → existiert, ist aber kein Symlink"
  else
    fail "$display_name → fehlt"
  fi
}

# ------------------------------------------------------------
# Tool-Prüfung
# ------------------------------------------------------------
check_tool() {
  local tool="$1"
  local description="${2:-$tool}"
  
  if command -v "$tool" >/dev/null 2>&1; then
    pass "$description"
  else
    fail "$description → nicht installiert"
  fi
}

# ------------------------------------------------------------
# Brewfile-Parser: Extrahiert Tool-Namen
# ------------------------------------------------------------
# Liest brew-Formulae aus Brewfile und gibt Tool-Namen zurück
# Filtert ZSH-Plugins (haben kein Binary) und mappt abweichende Namen
get_tools_from_brewfile() {
  local brewfile="$1"
  [[ -f "$brewfile" ]] || return 1
  
  # Mapping: Formula-Name → Binary-Name (falls unterschiedlich)
  typeset -A tool_mapping=(
    [ripgrep]=rg
    [tealdeer]=tldr
  )
  
  # Formulae die kein eigenständiges Binary haben (werden separat geprüft)
  typeset -a skip_formulae=(
    zsh-syntax-highlighting
    zsh-autosuggestions
  )
  
  # Extrahiere brew-Formulae (keine casks, keine mas)
  grep -E '^brew "[^"]+"' "$brewfile" | \
    sed 's/brew "\([^"]*\)".*/\1/' | \
    while read -r formula; do
      # Überspringe Formulae ohne Binary
      if (( ${skip_formulae[(Ie)$formula]} )); then
        continue
      fi
      # Verwende Mapping falls vorhanden, sonst Formula-Name
      print "${tool_mapping[$formula]:-$formula}"
    done
}

# ------------------------------------------------------------
# Hauptprüfungen
# ------------------------------------------------------------
print "🔍 dotfiles Health Check (Systemprüfung)"
print "   Prüft ob alle Komponenten korrekt installiert sind"
print "   ℹ SOLL-IST-Vergleich: Alle Dateien in terminal/ werden geprüft"

# --- Symlinks: SOLL-IST-Vergleich ---
section "Symlinks (SOLL-IST-Vergleich)"

# VOLLSTÄNDIG DYNAMISCH: Scannt ALLE Dateien in terminal/
# und prüft ob entsprechende Symlinks im Home-Verzeichnis existieren
#
# SOLL = Alle Dateien in terminal/ (außer .DS_Store, *.patch.md)
# IST  = Entsprechende Symlinks in ~/ bzw. ~/.config/
#
# Bei neuen Dateien in terminal/ wird der Check automatisch erweitert!

typeset -i symlink_count=0
typeset -a missing_symlinks=()

while IFS= read -r source_file; do
  [[ -z "$source_file" ]] && continue
  
  # Relativen Pfad berechnen (ab terminal/)
  local rel_path="${source_file#$TERMINAL_DIR/}"
  
  # Ziel-Pfad im Home-Verzeichnis
  local target_path="$HOME/$rel_path"
  local display_path="~/$rel_path"
  
  (( symlink_count++ )) || true
  
  if [[ -L "$target_path" ]]; then
    # readlink direkt in Vergleich verwenden (vermeidet typeset output)
    if [[ "$(readlink "$target_path")" == *"dotfiles/terminal/$rel_path"* ]]; then
      pass "$display_path"
    else
      fail "$display_path → falsches Ziel: $(readlink "$target_path")"
    fi
  elif [[ -e "$target_path" ]]; then
    fail "$display_path → existiert, ist aber kein Symlink"
  else
    fail "$display_path → fehlt"
    missing_symlinks+=("$rel_path")
  fi
done < <(find "$TERMINAL_DIR" -type f ! -name '.DS_Store' ! -name '*.patch.md' 2>/dev/null | sort)

# Hinweis bei fehlenden Symlinks
if (( ${#missing_symlinks[@]} > 0 )); then
  print "\n  💡 Fehlende Symlinks erstellen mit:"
  print "     cd $DOTFILES_DIR && stow -R terminal"
fi

print "\n  📊 Geprüft: $symlink_count Dateien aus terminal/"

# --- Homebrew & Tools ---
section "Homebrew & CLI-Tools"

if command -v brew >/dev/null 2>&1; then
  pass "Homebrew installiert ($(brew --version | head -1))"
  
  # DYNAMISCH: Tools aus Brewfile extrahieren
  if [[ -f "$BREWFILE" ]]; then
    local -a tools=($(get_tools_from_brewfile "$BREWFILE"))
    for tool in "${tools[@]}"; do
      check_tool "$tool" "$tool"
    done
  else
    warn "Brewfile nicht gefunden: $BREWFILE"
  fi
else
  fail "Homebrew nicht installiert"
fi

# ZSH-Plugins (DYNAMISCH aus Brewfile extrahiert)
section "ZSH-Plugins"

# DYNAMISCH: Extrahiere zsh-* Formulae aus Brewfile
typeset -a zsh_plugins=($(grep -E '^brew "zsh-' "$BREWFILE" 2>/dev/null | sed 's/brew "\([^"]*\)".*/\1/'))

if (( ${#zsh_plugins[@]} > 0 )); then
  for plugin in "${zsh_plugins[@]}"; do
    if [[ -d "$(brew --prefix)/share/$plugin" ]]; then
      pass "$plugin"
    else
      warn "$plugin nicht installiert (brew install $plugin)"
    fi
  done
else
  warn "Keine ZSH-Plugins in Brewfile gefunden"
fi

# --- Font (DYNAMISCH aus Brewfile) ---
section "Nerd Font"

# DYNAMISCH: Extrahiere Font-Casks aus Brewfile
typeset -a font_casks=($(grep -E '^cask "font-' "$BREWFILE" 2>/dev/null | sed 's/cask "\([^"]*\)".*/\1/'))

if (( ${#font_casks[@]} > 0 )); then
  for font_cask in "${font_casks[@]}"; do
    # Konvertiere cask-name zu Font-Dateiname-Pattern
    # z.B. font-meslo-lg-nerd-font → MesloLG*NerdFont*
    local font_pattern
    case "$font_cask" in
      font-meslo-lg-nerd-font)
        font_pattern="MesloLG*NerdFont*"
        ;;
      font-*)
        # Generischer Fallback: Entferne font- Prefix, CamelCase
        font_pattern="${font_cask#font-}"
        font_pattern="${font_pattern//-/}*"
        ;;
    esac
    
    local -a font_files=(~/Library/Fonts/${~font_pattern}(N) /Library/Fonts/${~font_pattern}(N))
    if (( ${#font_files} > 0 )); then
      pass "$font_cask installiert (${#font_files} Dateien)"
    else
      fail "$font_cask nicht gefunden"
    fi
  done
else
  warn "Keine Font-Casks in Brewfile gefunden"
fi

# --- Terminal-Profil ---
section "Terminal.app Profil"

profile_name="catppuccin-mocha"
default_profile=$(defaults read com.apple.Terminal "Default Window Settings" 2>/dev/null || echo "")
startup_profile=$(defaults read com.apple.Terminal "Startup Window Settings" 2>/dev/null || echo "")

if [[ "$default_profile" == "$profile_name" ]]; then
  pass "Standard-Profil: $profile_name"
else
  warn "Standard-Profil ist '$default_profile' (erwartet: $profile_name)"
fi

if [[ "$startup_profile" == "$profile_name" ]]; then
  pass "Startup-Profil: $profile_name"
else
  warn "Startup-Profil ist '$startup_profile' (erwartet: $profile_name)"
fi

# --- Starship ---
section "Starship Konfiguration"

if [[ -f "$HOME/.config/starship.toml" ]]; then
  pass "~/.config/starship.toml vorhanden"
else
  warn "~/.config/starship.toml fehlt (wird bei Bootstrap erstellt)"
fi

# --- ZSH-Sessions ---
section "ZSH-Sessions"

if [[ -f "$HOME/.zshenv" ]] && grep -q "SHELL_SESSIONS_DISABLE=1" "$HOME/.zshenv" 2>/dev/null; then
  pass "macOS zsh_sessions deaktiviert (SHELL_SESSIONS_DISABLE=1 in ~/.zshenv)"
else
  warn "SHELL_SESSIONS_DISABLE=1 nicht in ~/.zshenv (macOS Session-History aktiv)"
  warn "  → stow -R terminal ausführen oder ~/.zshenv manuell erstellen"
fi

# --- Brewfile Status ---
section "Brewfile Status"

if [[ -n "${HOMEBREW_BUNDLE_FILE:-}" ]] && [[ -f "$HOMEBREW_BUNDLE_FILE" ]]; then
  local check_output
  check_output=$(brew bundle check --file="$HOMEBREW_BUNDLE_FILE" --verbose 2>&1)
  local check_exit=$?
  
  if (( check_exit == 0 )); then
    pass "Alle Brewfile-Abhängigkeiten erfüllt"
  elif echo "$check_output" | grep -qE "needs to be installed or updated"; then
    # Pakete fehlen oder sind veraltet (Formulas und Casks)
    local outdated
    outdated=$(echo "$check_output" | grep -oE "(Formula|Cask) [^ ]+ needs" | sed -E 's/(Formula|Cask) ([^ ]+) needs/\2/' | tr '\n' ' ')
    warn "Brewfile-Pakete fehlen oder sind veraltet:${outdated:+ $outdated}"
    warn "  → brew bundle --file=$HOMEBREW_BUNDLE_FILE"
  else
    # Echte fehlende Pakete
    warn "Nicht alle Brewfile-Abhängigkeiten installiert"
    warn "  → brew bundle --file=$HOMEBREW_BUNDLE_FILE"
  fi
else
  warn "HOMEBREW_BUNDLE_FILE nicht gesetzt (neu einloggen nach stow)"
fi

# ------------------------------------------------------------
# Zusammenfassung
# ------------------------------------------------------------
print "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print "📊 Zusammenfassung"
print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print "   ✔ Bestanden: $passed"
print "   ⚠ Warnungen: $warnings"
print "   ✖ Fehler:    $failed"

if (( failed > 0 )); then
  print "\n❌ Health Check fehlgeschlagen"
  print "   Behebe die Fehler und führe den Check erneut aus."
  exit 1
elif (( warnings > 0 )); then
  print "\n⚠️  Health Check mit Warnungen abgeschlossen"
  print "   Das Setup funktioniert, aber einige optionale Komponenten fehlen."
  exit 0
else
  print "\n✅ Health Check erfolgreich"
  print "   Alle Komponenten korrekt installiert."
  exit 0
fi
