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
# Design  : DYNAMISCH – erkennt automatisch neue Dateien in:
#           - terminal/.zsh* (Shell-Konfiguration)
#           - terminal/.config/alias/*.alias (Alias-Dateien)
#           - terminal/.config/*/{config,ignore} (Tool-Configs)
#           - terminal/.config/*/*.zsh (ZSH-Module wie fzf/init.zsh)
#           - terminal/.config/* (Direkte Dateien wie shell-colors)
#           - setup/Brewfile (CLI-Tools via brew)
#
# Aufruf  : ./scripts/health-check.sh
# Docs    : https://github.com/tshofmann/dotfiles#readme
# ============================================================

set -uo pipefail

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
pass()    { print "  ✔ $*"; (( passed++ )); }
fail()    { print "  ✖ $*"; (( failed++ )); }
warn()    { print "  ⚠ $*"; (( warnings++ )); }
section() { print "\n━━━ $* ━━━"; }

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
print "   ℹ Dynamische Erkennung aus terminal/ und Brewfile"

# --- Symlinks: ZSH-Dotfiles ---
section "Symlinks (ZSH-Konfiguration)"

# DYNAMISCH: Alle ZSH-Konfigurationsdateien im terminal/ Verzeichnis
# Matcht: .zshenv, .zshrc, .zprofile, .zlogin (alle Standard-ZSH-Dateien)
for dotfile in "$TERMINAL_DIR"/.z(shenv|shrc|profile|login)(N); do
  [[ -f "$dotfile" ]] || continue
  local filename="${dotfile:t}"
  check_symlink "$HOME/$filename" "dotfiles/terminal/$filename" "~/$filename"
done

# --- Symlinks: Alias-Dateien ---
section "Symlinks (Alias-Dateien)"

# DYNAMISCH: Alle .alias Dateien
for alias_file in "$TERMINAL_DIR/.config/alias"/*.alias(N); do
  [[ -f "$alias_file" ]] || continue
  local filename="${alias_file:t}"
  check_symlink "$HOME/.config/alias/$filename" \
                "dotfiles/terminal/.config/alias/$filename" \
                "~/.config/alias/$filename"
done

# --- Symlinks: Tool-Konfigurationen ---
section "Symlinks (Tool-Konfigurationen)"

# DYNAMISCH: Alle config/ignore Dateien in .config/*/
for config_file in "$TERMINAL_DIR/.config"/*/(config|ignore)(N); do
  [[ -f "$config_file" ]] || continue
  # Extrahiere relativen Pfad ab .config/
  local rel_path="${config_file#$TERMINAL_DIR/}"
  local display_path="~/${rel_path}"
  check_symlink "$HOME/$rel_path" "dotfiles/terminal/$rel_path" "$display_path"
done

# DYNAMISCH: Alle .zsh Dateien in .config/*/ (z.B. fzf/init.zsh)
for zsh_file in "$TERMINAL_DIR/.config"/*/*.zsh(N); do
  [[ -f "$zsh_file" ]] || continue
  local rel_path="${zsh_file#$TERMINAL_DIR/}"
  local display_path="~/${rel_path}"
  check_symlink "$HOME/$rel_path" "dotfiles/terminal/$rel_path" "$display_path"
done

# DYNAMISCH: Direkte Dateien in .config/ (z.B. shell-colors)
for direct_file in "$TERMINAL_DIR/.config"/*(N-.); do
  [[ -f "$direct_file" ]] || continue
  local filename="${direct_file:t}"
  # Überspringe versteckte Dateien
  [[ "$filename" == .* ]] && continue
  local rel_path=".config/$filename"
  local display_path="~/$rel_path"
  check_symlink "$HOME/$rel_path" "dotfiles/terminal/$rel_path" "$display_path"
done

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

# ZSH-Plugins (aus Brewfile, aber spezielle Prüfung da kein Binary)
section "ZSH-Plugins"

for plugin in zsh-syntax-highlighting zsh-autosuggestions; do
  if [[ -d "$(brew --prefix)/share/$plugin" ]]; then
    pass "$plugin"
  else
    warn "$plugin nicht installiert"
  fi
done

# --- Font ---
section "Nerd Font"

font_files=(~/Library/Fonts/MesloLG*NerdFont*(N) /Library/Fonts/MesloLG*NerdFont*(N))
if (( ${#font_files} > 0 )); then
  pass "MesloLG Nerd Font installiert (${#font_files} Dateien)"
else
  fail "MesloLG Nerd Font nicht gefunden"
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
