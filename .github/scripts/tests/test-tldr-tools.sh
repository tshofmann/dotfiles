#!/usr/bin/env zsh
# ============================================================
# test-tldr-tools.sh - Tests für tldr/tools.sh
# ============================================================
# Zweck       : Unit Tests für alle Funktionen in tools.sh
#               (format_dothelp_item, generate_*_page,
#                generate_*_tldr)
# Pfad        : .github/scripts/tests/test-tldr-tools.sh
# Aufruf      : ./.github/scripts/tests/test-tldr-tools.sh
# Hinweis     : Fixtures als Inline-Heredocs (konsistent mit
#               allen bestehenden Tests, kein fixtures/-Verzeichnis)
# ============================================================

set -uo pipefail

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/lib/assertions.sh"

# Temp-Verzeichnis für Fixtures
_TEST_TMPDIR=$(mktemp -d)
trap 'rm -rf "$_TEST_TMPDIR"' EXIT

# tldr.sh → common.sh + alle tldr-Module (tools.sh etc.)
# Guard: Nur Funktionen laden, nicht den Generator ausführen
_SOURCED_BY_GENERATOR=1
source "$SCRIPT_DIR/../generators/tldr.sh"

# Pfade aus common.sh sind jetzt gesetzt (DOTFILES_DIR, ALIAS_DIR etc.)
# Originale Pfade sichern für spätere Wiederherstellung
_ORIG_DOTFILES_DIR="$DOTFILES_DIR"
_ORIG_ALIAS_DIR="$ALIAS_DIR"
_ORIG_TEALDEER_DIR="$TEALDEER_DIR"

# ============================================================
# format_dothelp_item() – Unit-Tests
# ============================================================
echo "=== format_dothelp_item ==="

# Einfacher Name + Beschreibung
result=$(format_dothelp_item "mycmd" "Dateien anzeigen")
assert_contains "Einfach: Beschreibung" "Dateien anzeigen" "$result"
assert_contains "Einfach: Backtick-Befehl" '`mycmd`' "$result"

# Name mit Parameter (param?) → {{param}}
result=$(format_dothelp_item "mycmd" "Verzeichnis wechseln(pfad?)")
assert_contains "Param: {{pfad}}" '{{pfad}}' "$result"
assert_contains "Param: Beschreibung ohne Klammer" "Verzeichnis wechseln" "$result"

# Name mit Parameter (param=default) → {{param}}
result=$(format_dothelp_item "mycmd" "Suche starten(query?=all)")
assert_contains "Param Default: {{query}}" '{{query}}' "$result"

# Beschreibung mit Keybindings nach " – "
result=$(format_dothelp_item "mycmd" "Vorschläge – Enter=Auswahl, Ctrl+Y=Kopieren")
assert_contains "Keys: Beschreibung" "Vorschläge" "$result"

# Leerer Name
result=$(format_dothelp_item "" "Beschreibung")
assert_contains "Leerer Name: Backticks" '``' "$result"

# ============================================================
# generate_catppuccin_page() – Integration (echtes theme-style)
# ============================================================
echo "=== generate_catppuccin_page (Integration) ==="

result=$(generate_catppuccin_page)

# tldr-Header
assert_contains "Header: catppuccin" "# catppuccin" "$result"
assert_contains "Header: Mocha" "Catppuccin Mocha" "$result"
assert_contains "Header: catppuccin.com" "catppuccin.com/palette" "$result"

# Upstream-Sektion
assert_contains "Upstream-Sektion vorhanden" "Themes aus offiziellen" "$result"
assert_contains "Upstream: bat" "bat: ~/.config/bat/themes/" "$result"

# Modified-Sektion
assert_contains "Modified-Sektion vorhanden" "Upstream mit lokalen Anpassungen" "$result"
assert_contains "Modified: fzf" "fzf:" "$result"

# Manual-Sektion
assert_contains "Manual-Sektion vorhanden" "Manuell konfiguriert" "$result"
assert_contains "Manual: kein offizielles Repo" "kein offizielles Repo" "$result"

# Farbvariablen-Sektion
assert_contains "Farbvariablen-Tipp" "source ~/.config/theme-style" "$result"

# Repo-Links-Sektion
assert_contains "Repo-Sektion vorhanden" "Upstream Theme-Repositories" "$result"
assert_contains "Repo: github.com/catppuccin/" "github.com/catppuccin/" "$result"

# ============================================================
# generate_catppuccin_page() – Fixture-Tests
# ============================================================
echo ""
echo "=== generate_catppuccin_page (Fixture) ==="

# Fixture-Umgebung aufbauen
DOTFILES_DIR="$_TEST_TMPDIR/dotfiles"
mkdir -p "$DOTFILES_DIR/terminal/.config"

# --- Fixture: Minimale theme-style mit allen 3 Kategorien ---
cat > "$DOTFILES_DIR/terminal/.config/theme-style" << 'FIXTURE'
# ============================================================
# theme-style - Test Fixture
# ============================================================

# Format: tool | config-pfad | upstream-repo | status
#
#   testtool-a   | ~/.config/a/theme.toml  | github.com/catppuccin/a   | upstream
#   testtool-b   | ~/.config/b/config      | github.com/catppuccin/b   | upstream+header
#   testtool-c   | ~/.config/c/colors.yml  | manual                    | manual
#
# Status-Legende:
#   upstream      = unverändert
FIXTURE

result=$(generate_catppuccin_page)

assert_contains "Fixture: Upstream-Tool erkannt" "testtool-a:" "$result"
assert_contains "Fixture: Upstream-Pfad" "~/.config/a/theme.toml" "$result"
assert_contains "Fixture: Modified-Tool erkannt" "testtool-b:" "$result"
assert_contains "Fixture: Modified-Anpassung" "(header)" "$result"
assert_contains "Fixture: Manual-Tool erkannt" "testtool-c:" "$result"
assert_contains "Fixture: Manual-Label" "kein offizielles Repo" "$result"
assert_contains "Fixture: Repo-URL" "github.com/catppuccin/a" "$result"

# --- Fixture: Sortierung (alphabetisch) ---
local upstream_pos modified_pos manual_pos
upstream_pos=$(echo "$result" | grep -n '`testtool-a:' | head -1 | cut -d: -f1)
modified_pos=$(echo "$result" | grep -n '`testtool-b:' | head -1 | cut -d: -f1)
manual_pos=$(echo "$result" | grep -n '`testtool-c:' | head -1 | cut -d: -f1)
# Upstream kommt vor Modified, Modified vor Manual (Sektionsreihenfolge)
assert_equals "Sortierung: Upstream vor Modified" "1" "$(( upstream_pos < modified_pos ? 1 : 0 ))"
assert_equals "Sortierung: Modified vor Manual" "1" "$(( modified_pos < manual_pos ? 1 : 0 ))"

# --- Fixture: upstream- (mit Entfernung) ---
cat > "$DOTFILES_DIR/terminal/.config/theme-style" << 'FIXTURE'
# Format: tool | config-pfad | upstream-repo | status
#
#   removetool   | ~/.config/rm/cfg  | github.com/catppuccin/rm  | upstream-background
#
# Status-Legende:
#   upstream-X    = Entfernung
FIXTURE

result=$(generate_catppuccin_page)
assert_contains "Fixture: upstream- erkannt" "removetool:" "$result"
assert_contains "Fixture: Entfernung dokumentiert" "(background)" "$result"

# --- Fixture: generated Status ---
cat > "$DOTFILES_DIR/terminal/.config/theme-style" << 'FIXTURE'
# Format: tool | config-pfad | upstream-repo | status
#
#   gentool      | ~/.config/gen/cfg  | github.com/catppuccin/gen | generated
#
# Status-Legende:
#   generated     = automatisch
FIXTURE

result=$(generate_catppuccin_page)
assert_contains "Fixture: generated erkannt" "gentool:" "$result"
assert_contains "Fixture: generated Text" "generiert (bootstrap)" "$result"

# --- Fixture: Leere theme-style (keine Tools) ---
cat > "$DOTFILES_DIR/terminal/.config/theme-style" << 'FIXTURE'
# Format: tool | config-pfad | upstream-repo | status
#
# Status-Legende:
#   upstream      = unverändert
FIXTURE

result=$(generate_catppuccin_page)
# Sollte trotzdem den Header haben, aber keine Tool-Einträge
assert_contains "Fixture: Leere theme-style hat Header" "# catppuccin" "$result"

# --- Fixture: Fehlende theme-style ---
rm "$DOTFILES_DIR/terminal/.config/theme-style"
result=$(generate_catppuccin_page 2>/dev/null)
assert_empty "Fixture: Fehlende theme-style → leer" "$result"

# DOTFILES_DIR zurücksetzen
DOTFILES_DIR="$_ORIG_DOTFILES_DIR"

# ============================================================
# generate_dotfiles_page() – Integration (echte Dateien)
# ============================================================
echo ""
echo "=== generate_dotfiles_page (Integration) ==="

result=$(generate_dotfiles_page)

# Header
assert_contains "dotfiles: Header" "# dotfiles" "$result"
assert_contains "dotfiles: Tagline" "$PROJECT_TAGLINE" "$result"
assert_contains "dotfiles: Repo-URL" "$PROJECT_REPO" "$result"

# Einstiegspunkte
assert_contains "dotfiles: dothelp" "dothelp" "$result"
assert_contains "dotfiles: cmds" "cmds" "$result"
assert_contains "dotfiles: tldr" "tldr" "$result"

# Keybinding-Sektion
assert_contains "dotfiles: Keybinding-Sektion" "$DOTHELP_CAT_KEYBINDINGS" "$result"

# fzf-Shortcuts-Sektion
assert_contains "dotfiles: fzf-Sektion" "$DOTHELP_CAT_FZF" "$result"

# Replacements-Sektion
assert_contains "dotfiles: Replacements-Sektion" "$DOTHELP_CAT_REPLACEMENTS" "$result"

# Homebrew-Sektion
assert_contains "dotfiles: Homebrew-Sektion" "Homebrew" "$result"

# Dotfiles-Wartung-Sektion
assert_contains "dotfiles: Wartung-Sektion" "Dotfiles-Wartung" "$result"

# Dokumentation-Sektion
assert_contains "dotfiles: Doku-Sektion" "Vollständige Dokumentation" "$result"

# ============================================================
# generate_dotfiles_page() – Fixture-Tests
# ============================================================
echo ""
echo "=== generate_dotfiles_page (Fixture) ==="

# Fixture-Umgebung aufbauen
DOTFILES_DIR="$_TEST_TMPDIR/dotfiles-dothelp"
ALIAS_DIR="$_TEST_TMPDIR/dotfiles-dothelp/alias"
TEALDEER_DIR="$_TEST_TMPDIR/dotfiles-dothelp/tealdeer"
mkdir -p "$DOTFILES_DIR/terminal/.config/fzf" "$ALIAS_DIR" "$TEALDEER_DIR"

# --- Fixture: .zshrc mit Keybindings ---
cat > "$DOTFILES_DIR/terminal/.zshrc" << 'FIXTURE'
# Autosuggestions: Vorschläge aus der History
#   →        Vorschlag komplett übernehmen
#   Alt+→    Wort für Wort übernehmen
source "$HOME/.config/zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"
FIXTURE

# --- Fixture: fzf/init.zsh mit globalem Keybinding ---
cat > "$DOTFILES_DIR/terminal/.config/fzf/init.zsh" << 'FIXTURE'
bindkey '^X1' fzf-history-widget  # Ctrl+X 1 = Befehlsverlauf durchsuchen
FIXTURE

# --- Fixture: Alias mit Ersetzt-Feld ---
cat > "$ALIAS_DIR/bat.alias" << 'FIXTURE'
# ============================================================
# bat.alias - Syntax-Highlighting für cat
# ============================================================
# Zweck       : cat mit Farben
# Ersetzt     : cat (Syntax-Highlighting)
# Aliase      : cat, bat
# ============================================================
FIXTURE

# --- Fixture: brew.alias mit Sektion ---
cat > "$ALIAS_DIR/brew.alias" << 'FIXTURE'
# ============================================================
# brew.alias - Homebrew
# ============================================================
# Zweck       : Paketmanager
# ============================================================

# ---
# Updates
# ---

# Homebrew aktualisieren
alias bup='brew update && brew upgrade'
FIXTURE

# --- Fixture: dotfiles.alias mit Wartung ---
cat > "$ALIAS_DIR/dotfiles.alias" << 'FIXTURE'
# ============================================================
# dotfiles.alias - Verwaltung
# ============================================================
# Zweck       : Dotfiles-Wartung
# ============================================================

# ---
# Dotfiles Wartung
# ---

# Dotfiles aktualisieren
alias dotupdate='cd ~/.dotfiles && git pull'
FIXTURE

# --- Fixture: tldr-Dateien ---
echo "" > "$TEALDEER_DIR/bat.patch.md"
echo "" > "$TEALDEER_DIR/zsh.patch.md"
echo "" > "$TEALDEER_DIR/catppuccin.page.md"

result=$(generate_dotfiles_page)

# Keybindings aus .zshrc
assert_contains "Fixture: Keybinding →" "Vorschlag komplett" "$result"
assert_contains "Fixture: Keybinding Alt+→" "Wort für Wort" "$result"

# fzf-Shortcuts aus init.zsh
assert_contains "Fixture: fzf Ctrl+X 1" "Befehlsverlauf durchsuchen" "$result"

# Ersetzungen aus bat.alias
assert_contains "Fixture: bat Ersetzung" "cat" "$result"
assert_contains "Fixture: bat → bat" "bat" "$result"

# Homebrew-Sektionen
assert_contains "Fixture: Homebrew Updates" "bup" "$result"

# Dotfiles-Wartung
assert_contains "Fixture: dotupdate" "dotupdate" "$result"

# Patches/Pages
assert_contains "Fixture: Patch-Liste" "bat" "$result"
assert_contains "Fixture: Page-Liste" "catppuccin" "$result"

# --- Fixture: Leere Dateien ---
rm -f "$DOTFILES_DIR/terminal/.zshrc"
rm -f "$DOTFILES_DIR/terminal/.config/fzf/init.zsh"
rm -f "$ALIAS_DIR"/*.alias
rm -f "$TEALDEER_DIR"/*

result=$(generate_dotfiles_page)
# Header und Sektionen vorhanden, aber keine dynamischen Inhalte
assert_contains "Leer: Header vorhanden" "# dotfiles" "$result"
assert_contains "Leer: Homebrew-Sektion" "Homebrew" "$result"

# Pfade zurücksetzen
DOTFILES_DIR="$_ORIG_DOTFILES_DIR"
ALIAS_DIR="$_ORIG_ALIAS_DIR"
TEALDEER_DIR="$_ORIG_TEALDEER_DIR"

# ============================================================
# generate_zsh_page() – Integration (echte .zshrc/.zshenv)
# ============================================================
echo ""
echo "=== generate_zsh_page (Integration) ==="

result=$(generate_zsh_page)

# Header-Sektionen
assert_contains "Sektion: Konfigurationsdateien" "# dotfiles: Konfigurationsdateien" "$result"
assert_contains "Sektion: XDG Base Directory" "# dotfiles: XDG Base Directory" "$result"
assert_contains "Sektion: History-Konfiguration" "# dotfiles: History-Konfiguration" "$result"
assert_contains "Sektion: Alias-System" "# dotfiles: Alias-System" "$result"
assert_contains "Sektion: Tool-Integrationen" "# dotfiles: Tool-Integrationen" "$result"
assert_contains "Sektion: ZSH-Plugins" "# dotfiles: ZSH-Plugins" "$result"
assert_contains "Sektion: Completion-System" "# dotfiles: Completion-System" "$result"

# Header-Felder aus echten Dateien
assert_contains "zshenv: Zweck" "Umgebungsvariablen" "$result"
assert_contains "zshrc: Zweck" "Hauptkonfiguration" "$result"
assert_contains "Lade-Reihenfolge" ".zshenv" "$result"

# XDG-Variablen
assert_contains "XDG_CONFIG_HOME" "XDG_CONFIG_HOME" "$result"
assert_contains "XDG: ~/.config" "~/.config" "$result"

# History
assert_contains "History: 25.000 Einträge" "25.000 Einträge" "$result"
assert_contains "History: SHELL_SESSIONS_DISABLE" "SHELL_SESSIONS_DISABLE" "$result"
assert_contains "History: HIST_IGNORE_SPACE" "HIST_IGNORE_SPACE" "$result"

# Alias-System
assert_contains "Alias: .alias-Dateien" ".alias" "$result"
assert_contains "Alias: theme-style" "theme-style" "$result"

# Tool-Integrationen
assert_contains "Tool: fzf" "fzf" "$result"
assert_contains "Tool: zoxide" "zoxide" "$result"
assert_contains "Tool: bat" "bat" "$result"
assert_contains "Tool: starship" "starship" "$result"
assert_contains "Tool: gh" "gh" "$result"

# ZSH-Plugins
assert_contains "Plugin: autosuggestions" "zsh-autosuggestions" "$result"
assert_contains "Plugin: syntax-highlighting" "zsh-syntax-highlighting" "$result"

# Completion
assert_contains "Completion: compinit" "compinit" "$result"

# ============================================================
# generate_zsh_page() – Fixture-Tests
# ============================================================
echo ""
echo "=== generate_zsh_page (Fixture) ==="

# Fixture-Umgebung aufbauen
DOTFILES_DIR="$_TEST_TMPDIR/dotfiles-zsh"
mkdir -p "$DOTFILES_DIR/terminal"

# --- Fixture: Minimale .zshenv ---
cat > "$DOTFILES_DIR/terminal/.zshenv" << 'FIXTURE'
# ============================================================
# .zshenv - ZSH Environment
# ============================================================
# Zweck       : Test-Umgebungsvariablen
# Pfad        : ~/.zshenv
# Laden       : [.zshenv] → .zprofile → .zshrc → .zlogin
# ============================================================

export XDG_CONFIG_HOME="$HOME/.config"

export EZA_CONFIG_DIR="$XDG_CONFIG_HOME/eza"

SHELL_SESSIONS_DISABLE=1
FIXTURE

# --- Fixture: Minimale .zshrc ---
cat > "$DOTFILES_DIR/terminal/.zshrc" << 'FIXTURE'
# ============================================================
# .zshrc - ZSH Konfiguration
# ============================================================
# Zweck       : Test-Konfiguration
# Pfad        : ~/.zshrc
# Laden       : .zshenv → .zprofile → [.zshrc] → .zlogin
# ============================================================

SAVEHIST=10000

setopt HIST_IGNORE_SPACE

# Alias-Dateien laden
for alias_file in "$HOME/.config/alias"/*.alias(N-.on); do
    source "$alias_file"
done

# theme-style laden
[[ -f "$HOME/.config/theme-style" ]] && source "$HOME/.config/theme-style"

# Tool-Integrationen
if command -v fzf >/dev/null 2>&1; then
    source "$HOME/.config/fzf/init.zsh"
    export FZF_DEFAULT_OPTS_FILE="$HOME/.config/fzf/config"
fi

# Man-Pages mit Syntax-Highlighting
if command -v bat >/dev/null 2>&1; then
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"
fi

if command -v zoxide >/dev/null 2>&1; then
    # z <query> = schnell wechseln, zi = interaktive Auswahl
    eval "$(zoxide init zsh)"
fi

if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)" # Powerline-Prompt
fi

if command -v gh >/dev/null 2>&1; then
    eval "$(gh completion -s zsh)" # Tab-Completion
fi

# Autosuggestions: Zeigt Vorschläge aus History
#   →     Vorschlag komplett
#   Alt+→ Wort für Wort
source "$HOME/.config/zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"

# Syntax-Highlighting: Farben zeigen Befehlsgültigkeit
#   Grün         gültiger Befehl
#   Rot          ungültiger Befehl
# WICHTIG: Muss zuletzt geladen werden
source "$HOME/.config/zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# Completion
# Tab-Vervollständigung mit täglicher Cache-Erneuerung
autoload -Uz compinit
compinit -i
FIXTURE

result=$(generate_zsh_page)

# Header-Felder aus Fixture
assert_contains "Fixture: zshenv Zweck" "Test-Umgebungsvariablen" "$result"
assert_contains "Fixture: zshrc Zweck" "Test-Konfiguration" "$result"

# XDG
assert_contains "Fixture: XDG_CONFIG_HOME" "XDG_CONFIG_HOME" "$result"
assert_contains "Fixture: EZA_CONFIG_DIR Override" "EZA_CONFIG_DIR" "$result"

# History: 10000 → 10.000
assert_contains "Fixture: History formatiert" "10.000 Einträge" "$result"
assert_contains "Fixture: SHELL_SESSIONS_DISABLE" "SHELL_SESSIONS_DISABLE" "$result"
assert_contains "Fixture: HIST_IGNORE_SPACE" "HIST_IGNORE_SPACE" "$result"

# Alias-System
assert_contains "Fixture: Alias-Pfad" "~/.config/alias/" "$result"
assert_contains "Fixture: theme-style" "theme-style" "$result"

# Tool-Integrationen
assert_contains "Fixture: fzf erkannt" "fzf" "$result"
assert_contains "Fixture: zoxide erkannt" "zoxide" "$result"
assert_contains "Fixture: bat erkannt" "bat" "$result"
assert_contains "Fixture: starship erkannt" "starship" "$result"
assert_contains "Fixture: gh erkannt" "gh" "$result"

# Plugins
assert_contains "Fixture: autosuggestions" "zsh-autosuggestions" "$result"
assert_contains "Fixture: syntax-highlighting" "zsh-syntax-highlighting" "$result"

# Completion
assert_contains "Fixture: compinit" "compinit" "$result"

# --- Fixture: .zshrc ohne Tools (Minimal) ---
echo ""
echo "=== generate_zsh_page (Minimal-Fixture) ==="

cat > "$DOTFILES_DIR/terminal/.zshrc" << 'FIXTURE'
# ============================================================
# .zshrc - ZSH Konfiguration
# ============================================================
# Zweck       : Minimale Shell
# Pfad        : ~/.zshrc
# Laden       : .zshenv → .zprofile → [.zshrc] → .zlogin
# ============================================================

SAVEHIST=500
FIXTURE

cat > "$DOTFILES_DIR/terminal/.zshenv" << 'FIXTURE'
# ============================================================
# .zshenv - ZSH Environment
# ============================================================
# Zweck       : Leere Umgebung
# Pfad        : ~/.zshenv
# Laden       : [.zshenv] → .zprofile → .zshrc → .zlogin
# ============================================================
FIXTURE

result=$(generate_zsh_page)

assert_contains "Minimal: Header vorhanden" "# dotfiles: Konfigurationsdateien" "$result"
assert_contains "Minimal: Zweck erkannt" "Minimale Shell" "$result"
assert_contains "Minimal: History 500" "500 Einträge" "$result"

# Keine Tools → keine Tool-Ausgabe
local tool_fzf_count
tool_fzf_count=$(echo "$result" | grep -c "dotfiles: fzf" || true)
assert_equals "Minimal: Kein fzf" "0" "$tool_fzf_count"

local plugin_count
plugin_count=$(echo "$result" | grep -c "zsh-autosuggestions" || true)
assert_equals "Minimal: Keine Plugins" "0" "$plugin_count"

# --- Fixture: Fehlende .zshrc/.zshenv ---
echo ""
echo "=== generate_zsh_page (Fehlende Dateien) ==="

rm -f "$DOTFILES_DIR/terminal/.zshrc" "$DOTFILES_DIR/terminal/.zshenv"

# stderr unterdrücken: parse_header_field warnt bei fehlenden Dateien
result=$(generate_zsh_page 2>/dev/null)

# Sollte trotzdem Header generieren (mit Defaults)
assert_contains "Fehlend: Header vorhanden" "# dotfiles: Konfigurationsdateien" "$result"

# --- Fixture: SAVEHIST < 1000 (kein Tausender-Punkt) ---
echo ""
echo "=== generate_zsh_page (SAVEHIST Edge Cases) ==="

cat > "$DOTFILES_DIR/terminal/.zshrc" << 'FIXTURE'
# ============================================================
# .zshrc - ZSH Konfiguration
# ============================================================
# Zweck       : Test
# Pfad        : ~/.zshrc
# Laden       : .zshenv → .zprofile → [.zshrc] → .zlogin
# ============================================================

SAVEHIST=999
FIXTURE

cat > "$DOTFILES_DIR/terminal/.zshenv" << 'FIXTURE'
# ============================================================
# .zshenv - ZSH Environment
# ============================================================
# Zweck       : Test
# Pfad        : ~/.zshenv
# Laden       : [.zshenv] → .zprofile → .zshrc → .zlogin
# ============================================================
FIXTURE

result=$(generate_zsh_page)
assert_contains "SAVEHIST < 1000: keine Formatierung" "999 Einträge" "$result"

# --- Fixture: SAVEHIST = 100000 (6-stellig) ---
cat > "$DOTFILES_DIR/terminal/.zshrc" << 'FIXTURE'
# ============================================================
# .zshrc - ZSH Konfiguration
# ============================================================
# Zweck       : Test
# Pfad        : ~/.zshrc
# Laden       : .zshenv → .zprofile → [.zshrc] → .zlogin
# ============================================================

SAVEHIST=100000
FIXTURE

result=$(generate_zsh_page)
assert_contains "SAVEHIST 6-stellig: formatiert" "100.000 Einträge" "$result"

# DOTFILES_DIR zurücksetzen
DOTFILES_DIR="$_ORIG_DOTFILES_DIR"

# ============================================================
# generate_*_tldr() – Wrapper-Tests (--check und --generate)
# ============================================================
echo ""
echo "=== generate_*_tldr (Wrapper) ==="

# Fixture-Umgebung für Wrapper-Tests
DOTFILES_DIR="$_TEST_TMPDIR/dotfiles-wrapper"
ALIAS_DIR="$_TEST_TMPDIR/dotfiles-wrapper/alias"
TEALDEER_DIR="$_TEST_TMPDIR/dotfiles-wrapper/tealdeer"
mkdir -p "$DOTFILES_DIR/terminal/.config" "$ALIAS_DIR" "$TEALDEER_DIR"

# --- generate_catppuccin_tldr ---

# Fixture: theme-style für catppuccin
cat > "$DOTFILES_DIR/terminal/.config/theme-style" << 'FIXTURE'
# Format: tool | config-pfad | upstream-repo | status
#
#   wraptool  | ~/.config/wrap/cfg  | github.com/catppuccin/wrap  | upstream
#
# Status-Legende:
#   upstream      = unverändert
FIXTURE

# --check mit veralteter/fehlender Datei → return 1
generate_catppuccin_tldr --check 2>/dev/null
assert_equals "catppuccin_tldr: --check veraltet" "1" "$?"

# --generate → Datei erstellen
generate_catppuccin_tldr --generate 2>/dev/null
assert_equals "catppuccin_tldr: --generate erstellt" "0" "$( [[ -f "$TEALDEER_DIR/catppuccin.page.md" ]] && echo 0 || echo 1 )"

# --check nach --generate → return 0
generate_catppuccin_tldr --check 2>/dev/null
assert_equals "catppuccin_tldr: --check aktuell" "0" "$?"

# --- generate_zsh_tldr ---

# Fixture: .zshrc/.zshenv für zsh
cat > "$DOTFILES_DIR/terminal/.zshrc" << 'FIXTURE'
# ============================================================
# .zshrc - ZSH Konfiguration
# ============================================================
# Zweck       : Wrapper-Test
# Pfad        : ~/.zshrc
# Laden       : .zshenv → .zprofile → [.zshrc] → .zlogin
# ============================================================

SAVEHIST=5000
FIXTURE
cat > "$DOTFILES_DIR/terminal/.zshenv" << 'FIXTURE'
# ============================================================
# .zshenv - ZSH Environment
# ============================================================
# Zweck       : Wrapper-Test
# Pfad        : ~/.zshenv
# Laden       : [.zshenv] → .zprofile → .zshrc → .zlogin
# ============================================================
FIXTURE

# --check mit fehlender Datei → return 1
generate_zsh_tldr --check 2>/dev/null
assert_equals "zsh_tldr: --check veraltet" "1" "$?"

# --generate → Datei erstellen
generate_zsh_tldr --generate 2>/dev/null
assert_equals "zsh_tldr: --generate erstellt" "0" "$( [[ -f "$TEALDEER_DIR/zsh.patch.md" ]] && echo 0 || echo 1 )"

# --check nach --generate → return 0
generate_zsh_tldr --check 2>/dev/null
assert_equals "zsh_tldr: --check aktuell" "0" "$?"

# --- generate_dotfiles_tldr ---

# Fixtures für dotfiles (leere alias-Dateien + fzf)
mkdir -p "$DOTFILES_DIR/terminal/.config/fzf"
touch "$DOTFILES_DIR/terminal/.config/fzf/init.zsh"

# --check mit fehlender Datei → return 1
generate_dotfiles_tldr --check 2>/dev/null
assert_equals "dotfiles_tldr: --check veraltet" "1" "$?"

# --generate → Datei erstellen
generate_dotfiles_tldr --generate 2>/dev/null
assert_equals "dotfiles_tldr: --generate erstellt" "0" "$( [[ -f "$TEALDEER_DIR/dotfiles.page.md" ]] && echo 0 || echo 1 )"

# --check nach --generate → return 0
generate_dotfiles_tldr --check 2>/dev/null
assert_equals "dotfiles_tldr: --check aktuell" "0" "$?"

# Pfade zurücksetzen
DOTFILES_DIR="$_ORIG_DOTFILES_DIR"
ALIAS_DIR="$_ORIG_ALIAS_DIR"
TEALDEER_DIR="$_ORIG_TEALDEER_DIR"

# ============================================================
# Zusammenfassung
# ============================================================
test_summary
