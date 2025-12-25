#!/usr/bin/env zsh
# ============================================================
# health-check.sh - Validierung der dotfiles-Installation
# ============================================================
# Zweck   : Prüft alle Komponenten auf korrekte Installation
# Aufruf  : ./scripts/health-check.sh
# Docs    : https://github.com/tshofmann/dotfiles#readme
# ============================================================

set -uo pipefail

# ------------------------------------------------------------
# Konfiguration
# ------------------------------------------------------------
readonly SCRIPT_DIR="${0:A:h}"
readonly DOTFILES_DIR="${SCRIPT_DIR:h}"

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
# Hauptprüfungen
# ------------------------------------------------------------
print "🔍 dotfiles Health Check"
print "   Prüft die Installation auf Vollständigkeit und Korrektheit"

# --- Symlinks ---
section "Symlinks"

check_symlink "$HOME/.zshenv" "dotfiles/terminal/.zshenv" "~/.zshenv"
check_symlink "$HOME/.zshrc" "dotfiles/terminal/.zshrc" "~/.zshrc"
check_symlink "$HOME/.zprofile" "dotfiles/terminal/.zprofile" "~/.zprofile"

# Alias-Dateien
for alias_file in homebrew eza bat ripgrep fd fzf btop; do
  check_symlink "$HOME/.config/alias/${alias_file}.alias" \
                "dotfiles/terminal/.config/alias/${alias_file}.alias" \
                "~/.config/alias/${alias_file}.alias"
done

# Tool-Konfigurationen
check_symlink "$HOME/.config/fzf/config" "dotfiles/terminal/.config/fzf/config" "~/.config/fzf/config"
check_symlink "$HOME/.config/bat/config" "dotfiles/terminal/.config/bat/config" "~/.config/bat/config"
check_symlink "$HOME/.config/ripgrep/config" "dotfiles/terminal/.config/ripgrep/config" "~/.config/ripgrep/config"

# --- Homebrew & Tools ---
section "Homebrew & CLI-Tools"

if command -v brew >/dev/null 2>&1; then
  pass "Homebrew installiert ($(brew --version | head -1))"
else
  fail "Homebrew nicht installiert"
fi

# Pflicht-Tools aus Brewfile
check_tool "fzf" "fzf (Fuzzy Finder)"
check_tool "stow" "GNU Stow"
check_tool "starship" "Starship Prompt"
check_tool "zoxide" "zoxide (smarter cd)"
check_tool "eza" "eza (ls-Ersatz)"
check_tool "bat" "bat (cat-Ersatz)"
check_tool "rg" "ripgrep (grep-Ersatz)"
check_tool "fd" "fd (find-Ersatz)"
check_tool "btop" "btop (top-Ersatz)"
check_tool "gh" "GitHub CLI"

# Optionale Tools
if command -v mas >/dev/null 2>&1; then
  pass "mas (Mac App Store CLI)"
else
  warn "mas nicht installiert (optional, für App Store Updates)"
fi

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

profile_name="tshofmann"
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
  if brew bundle check --file="$HOMEBREW_BUNDLE_FILE" >/dev/null 2>&1; then
    pass "Alle Brewfile-Abhängigkeiten erfüllt"
  else
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
