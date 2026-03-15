#!/usr/bin/env zsh
# ============================================================
# test-tldr-patch-generator.sh - Tests für tldr/patch-generator.sh
# ============================================================
# Zweck       : Unit Tests für Starship-, Lazygit-Generatoren
#               und Cross-Reference Reverse-Lookup
# Pfad        : .github/scripts/tests/test-tldr-patch-generator.sh
# Aufruf      : ./.github/scripts/tests/test-tldr-patch-generator.sh
# Hinweis     : Fixtures als Inline-Heredocs (konsistent mit
#               allen bestehenden Tests, kein fixtures/-Verzeichnis)
# ============================================================

set -uo pipefail

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/lib/assertions.sh"

# Temp-Verzeichnis für Fixtures
_TEST_TMPDIR=$(mktemp -d)
trap 'rm -rf "$_TEST_TMPDIR"' EXIT

# tldr.sh → common.sh + alle tldr-Module (patch-generator.sh etc.)
# Guard: Nur Funktionen laden, nicht den Generator ausführen
_SOURCED_BY_GENERATOR=1
source "$SCRIPT_DIR/../generators/tldr.sh"

# Pfade aus common.sh sind jetzt gesetzt (DOTFILES_DIR, ALIAS_DIR etc.)
# Originale Pfade sichern für spätere Wiederherstellung
_ORIG_ALIAS_DIR="$ALIAS_DIR"
_ORIG_DOTFILES_DIR="$DOTFILES_DIR"

# ============================================================
# generate_starship_specific_entries() – Fixture-Tests
# ============================================================
echo "=== generate_starship_specific_entries (Fixture) ==="

# --- Palette-Name und Powerline-Layout ---
cat > "$_TEST_TMPDIR/starship-full.toml" << 'FIXTURE'
# ============================================================
# starship.toml - Catppuccin Mocha Powerline Prompt
# ============================================================
# Zweck       : Starship Shell-Prompt Konfiguration
# Upstream    : github.com/catppuccin/starship (catppuccin-powerline Preset)
# ============================================================

palette = 'catppuccin_mocha'

[os]
disabled = false

[username]
show_always = true

[directory]
truncation_length = 3

[git_branch]
symbol = ""

[git_status]
style = "bg:yellow"

[nodejs]
symbol = ""

[rust]
symbol = ""

[python]
symbol = ""

[docker_context]
symbol = ""

[conda]
ignore_base = false

[time]
disabled = false

[line_break]
disabled = true

[character]
disabled = false

[cmd_duration]
show_milliseconds = true

[palettes.catppuccin_mocha]
red = "#f38ba8"
green = "#a6e3a1"
FIXTURE

result=$(generate_starship_specific_entries "$_TEST_TMPDIR/starship-full.toml")

assert_contains "Palette: Catppuccin Mocha" "Catppuccin Mocha" "$result"
assert_contains "Layout: Powerline" "Powerline-Layout" "$result"
assert_contains "Prompt-Module vorhanden" "Prompt-Module" "$result"
assert_contains "Modul os erkannt" "os" "$result"
assert_contains "Modul username erkannt" "username" "$result"
assert_contains "Modul git_branch erkannt" "git_branch" "$result"
assert_contains "Sprach-Module vorhanden" "Sprach-Module" "$result"
assert_contains "Modul nodejs erkannt" "nodejs" "$result"
assert_contains "Modul rust erkannt" "rust" "$result"
assert_contains "Modul python erkannt" "python" "$result"
assert_contains "Infra-Module vorhanden" "Infra-Module" "$result"
assert_contains "Modul docker_context erkannt" "docker_context" "$result"
assert_contains "Modul conda erkannt" "conda" "$result"
assert_contains "Performance-Hinweis" "starship timings" "$result"
assert_contains "Config-Debug" "starship config" "$result"

# palettes.catppuccin_mocha darf NICHT als Modul erscheinen (hat Dot → kein Top-Level)
local palette_as_module
palette_as_module=$(echo "$result" | grep -c "palettes" || true)
assert_equals "palettes nicht als Modul" "0" "$palette_as_module"

# --- Plain-Layout ---
echo ""
echo "=== generate_starship_specific_entries (Plain-Layout) ==="

cat > "$_TEST_TMPDIR/starship-plain.toml" << 'FIXTURE'
# Upstream    : github.com/catppuccin/starship (catppuccin-plain Preset)

palette = 'catppuccin_latte'

[os]
disabled = false

[character]
disabled = false
FIXTURE

result=$(generate_starship_specific_entries "$_TEST_TMPDIR/starship-plain.toml")

assert_contains "Palette: Catppuccin Latte" "Catppuccin Latte" "$result"
assert_contains "Layout: Plain" "Plain-Layout" "$result"

# --- Ohne Upstream-Feld (kein Layout-Stil) ---
echo ""
echo "=== generate_starship_specific_entries (ohne Upstream) ==="

cat > "$_TEST_TMPDIR/starship-no-upstream.toml" << 'FIXTURE'
# Zweck       : Minimaler Prompt

palette = 'custom_theme'

[character]
disabled = false
FIXTURE

result=$(generate_starship_specific_entries "$_TEST_TMPDIR/starship-no-upstream.toml")

assert_contains "Palette: Custom Theme" "Custom Theme" "$result"
# Kein Layout-Suffix wenn kein Upstream
local layout_count
layout_count=$(echo "$result" | grep -c "Layout" || true)
assert_equals "Kein Layout ohne Upstream" "0" "$layout_count"

# --- Nur Prompt-Module (keine Sprach-/Infra-Module) ---
echo ""
echo "=== generate_starship_specific_entries (nur Prompt-Module) ==="

cat > "$_TEST_TMPDIR/starship-prompt-only.toml" << 'FIXTURE'
palette = 'test'

[os]
disabled = false

[character]
disabled = false

[time]
disabled = false
FIXTURE

result=$(generate_starship_specific_entries "$_TEST_TMPDIR/starship-prompt-only.toml")

assert_contains "Prompt-Module vorhanden" "Prompt-Module" "$result"
# Keine Sprach-/Infra-Module
local lang_count infra_count
lang_count=$(echo "$result" | grep -c "Sprach-Module" || true)
infra_count=$(echo "$result" | grep -c "Infra-Module" || true)
assert_equals "Keine Sprach-Module" "0" "$lang_count"
assert_equals "Keine Infra-Module" "0" "$infra_count"

# --- Keine Palette (Fallback) ---
echo ""
echo "=== generate_starship_specific_entries (keine Palette) ==="

cat > "$_TEST_TMPDIR/starship-no-palette.toml" << 'FIXTURE'
[character]
disabled = false

[os]
disabled = false
FIXTURE

result=$(generate_starship_specific_entries "$_TEST_TMPDIR/starship-no-palette.toml")

# Keine Palette → kein Farbpalette-Eintrag
local palette_count
palette_count=$(echo "$result" | grep -c "Farbpalette" || true)
assert_equals "Keine Palette → kein Palette-Eintrag" "0" "$palette_count"
# Aber Module sollten trotzdem erkannt werden
assert_contains "Module auch ohne Palette" "Prompt-Module" "$result"

# ============================================================
# generate_starship_specific_entries() – Integration
# ============================================================
echo ""
echo "=== generate_starship_specific_entries (Integration) ==="

local real_starship="$_ORIG_DOTFILES_DIR/terminal/.config/starship/starship.toml"
if [[ -f "$real_starship" ]]; then
    result=$(generate_starship_specific_entries "$real_starship")

    assert_contains "Echte Config: Catppuccin Mocha" "Catppuccin Mocha" "$result"
    assert_contains "Echte Config: Powerline-Layout" "Powerline-Layout" "$result"
    assert_contains "Echte Config: Prompt-Module" "Prompt-Module" "$result"
    assert_contains "Echte Config: Sprach-Module" "Sprach-Module" "$result"
    assert_contains "Echte Config: Infra-Module" "Infra-Module" "$result"
    assert_contains "Echte Config: starship timings" "starship timings" "$result"
else
    echo "  ⃠ Übersprungen (starship.toml nicht vorhanden)"
fi

# ============================================================
# generate_lazygit_specific_entries() – Fixture-Tests
# ============================================================
echo ""
echo "=== generate_lazygit_specific_entries (Fixture) ==="

# Eigenes ALIAS_DIR für git.alias-Verweis
ALIAS_DIR="$_TEST_TMPDIR/alias"
mkdir -p "$ALIAS_DIR"

# git.alias mit fzf im Nutzt-Feld für Cross-Verweis
cat > "$ALIAS_DIR/git.alias" << 'FIXTURE'
# ============================================================
# git.alias - Git Aliase
# ============================================================
# Zweck       : Aliase für häufige Git-Operationen
# Nutzt       : fzf (Interactive), bat (Diff-Highlighting)
# Aliase      : git-log, git-branch
# ============================================================
FIXTURE

# --- Vollständige lazygit-Config ---
cat > "$_TEST_TMPDIR/lazygit-full.yml" << 'FIXTURE'
# ============================================================
# config.yml - lazygit Terminal-UI für Git
# ============================================================
# Zweck       : lazygit Konfiguration mit Catppuccin Mocha Theme
# ============================================================

gui:
  theme:
    activeBorderColor:
      - '#cba6f7' # Mauve
      - bold
    inactiveBorderColor:
      - '#a6adc8' # Subtext0
  showIcons: true
  nerdFontsVersion: "3"
  showFileTree: true
  showRandomTip: false
  border: rounded

git:
  log:
    showGraph: always
FIXTURE

result=$(generate_lazygit_specific_entries "$_TEST_TMPDIR/lazygit-full.yml")

assert_contains "Theme: Catppuccin Mocha Theme" "Catppuccin Mocha Theme" "$result"
assert_contains "Akzent: Mauve" "Mauve-Akzent" "$result"
assert_contains "Nerd Font v3" "Nerd Font v3" "$result"
assert_contains "UI: File Tree" "File Tree" "$result"
assert_contains "UI: Rounded Border" "Rounded Border" "$result"
assert_contains "UI: Git Graph" "Git Graph" "$result"
assert_contains "Git-Verweis vorhanden" "tldr git" "$result"

# --- Akzentfarbe mit Trailing Whitespace ---
echo ""
echo "=== generate_lazygit_specific_entries (Trailing Whitespace) ==="

cat > "$_TEST_TMPDIR/lazygit-ws.yml" << FIXTURE
# Zweck       : Catppuccin Latte Theme

gui:
  theme:
    activeBorderColor:
      - '#cba6f7' # Mauve   
      - bold
FIXTURE

result=$(generate_lazygit_specific_entries "$_TEST_TMPDIR/lazygit-ws.yml")

# sed 's/[[:space:]]*$//' im Generator entfernt Trailing Whitespace
assert_contains "Trailing WS: Mauve erkannt" "Mauve" "$result"

# --- Farbname mit Ziffer (z.B. Surface1) ---
echo ""
echo "=== generate_lazygit_specific_entries (Farbname mit Ziffer) ==="

cat > "$_TEST_TMPDIR/lazygit-digit.yml" << 'FIXTURE'
# Zweck       : Test Theme

gui:
  theme:
    activeBorderColor:
      - '#45475a' # Surface1
      - bold
FIXTURE

result=$(generate_lazygit_specific_entries "$_TEST_TMPDIR/lazygit-digit.yml")

assert_contains "Surface1 als Farbname" "Surface1" "$result"

# --- Kein Theme-Label (kein "Theme" im Zweck) → generischer Fallback ---
echo ""
echo "=== generate_lazygit_specific_entries (kein Theme-Label) ==="

cat > "$_TEST_TMPDIR/lazygit-no-theme.yml" << 'FIXTURE'
# Zweck       : lazygit Konfiguration

gui:
  theme:
    activeBorderColor:
      - '#cba6f7' # Lavender
      - bold
FIXTURE

result=$(generate_lazygit_specific_entries "$_TEST_TMPDIR/lazygit-no-theme.yml")

# Kein "Catppuccin ... Theme" im Zweck → generischer Fallback "Theme (Farbe-Akzent)"
local catppuccin_count
catppuccin_count=$(echo "$result" | grep -c "Catppuccin" || true)
assert_equals "Kein Catppuccin-Label ohne Theme im Zweck" "0" "$catppuccin_count"
assert_contains "Fallback: generisches Theme mit Farbname" "Theme (Lavender-Akzent)" "$result"

# --- UI-Features teilweise aktiv ---
echo ""
echo "=== generate_lazygit_specific_entries (Teil-Features) ==="

cat > "$_TEST_TMPDIR/lazygit-partial.yml" << 'FIXTURE'
# Zweck       : Catppuccin Mocha Theme

gui:
  showFileTree: false
  border: rounded

git:
  log:
    showGraph: never
FIXTURE

result=$(generate_lazygit_specific_entries "$_TEST_TMPDIR/lazygit-partial.yml")

# Nur Rounded Border, NICHT File Tree oder Git Graph
assert_contains "Partial: Rounded Border" "Rounded Border" "$result"
local filetree_count graph_count
filetree_count=$(echo "$result" | grep -c "File Tree" || true)
graph_count=$(echo "$result" | grep -c "Git Graph" || true)
assert_equals "Partial: kein File Tree" "0" "$filetree_count"
assert_equals "Partial: kein Git Graph" "0" "$graph_count"

# --- Ohne git.alias mit fzf → kein Git-Verweis ---
echo ""
echo "=== generate_lazygit_specific_entries (ohne fzf in git.alias) ==="

# git.alias OHNE fzf im Nutzt-Feld
cat > "$ALIAS_DIR/git.alias" << 'FIXTURE'
# ============================================================
# git.alias - Git Aliase
# ============================================================
# Zweck       : Aliase für häufige Git-Operationen
# Nutzt       : bat (Diff-Highlighting)
# ============================================================
FIXTURE

cat > "$_TEST_TMPDIR/lazygit-no-fzf.yml" << 'FIXTURE'
# Zweck       : Catppuccin Mocha Theme

gui:
  border: rounded
FIXTURE

result=$(generate_lazygit_specific_entries "$_TEST_TMPDIR/lazygit-no-fzf.yml")

local git_ref_count
git_ref_count=$(echo "$result" | grep -c "tldr git" || true)
assert_equals "Kein Git-Verweis ohne fzf" "0" "$git_ref_count"

# --- Fehlende Config-Datei ---
echo ""
echo "=== generate_lazygit_specific_entries (fehlende Config) ==="

result=$(generate_lazygit_specific_entries "$_TEST_TMPDIR/nicht-vorhanden.yml")
assert_empty "Fehlende Config → leere Ausgabe" "$result"

# ============================================================
# generate_lazygit_specific_entries() – Integration
# ============================================================
echo ""
echo "=== generate_lazygit_specific_entries (Integration) ==="

# ALIAS_DIR auf echtes zurücksetzen für Integration
ALIAS_DIR="$_ORIG_ALIAS_DIR"

local real_lazygit="$_ORIG_DOTFILES_DIR/terminal/.config/lazygit/config.yml"
if [[ -f "$real_lazygit" ]]; then
    result=$(generate_lazygit_specific_entries "$real_lazygit")

    assert_contains "Echte Config: Catppuccin Mocha Theme" "Catppuccin Mocha Theme" "$result"
    assert_contains "Echte Config: Mauve-Akzent" "Mauve" "$result"
    assert_contains "Echte Config: Nerd Font" "Nerd Font" "$result"
    assert_contains "Echte Config: UI-Features" "File Tree" "$result"
    assert_contains "Echte Config: Git-Verweis" "tldr git" "$result"
else
    echo "  ⃠ Übersprungen (lazygit/config.yml nicht vorhanden)"
fi

# ============================================================
# generate_cross_references() – Fixture-Tests
# ============================================================
echo ""
echo "=== generate_cross_references (Fixture) ==="

# Kontrollierbares ALIAS_DIR
ALIAS_DIR="$_TEST_TMPDIR/cross-alias"
mkdir -p "$ALIAS_DIR"

# Tool mit fzf im Nutzt-Feld + Aliase
cat > "$ALIAS_DIR/git.alias" << 'FIXTURE'
# ============================================================
# git.alias - Git Aliase
# ============================================================
# Zweck       : Aliase für häufige Git-Operationen
# Nutzt       : fzf (Interactive), bat (Diff-Highlighting)
# Aliase      : git-log, git-branch, git-diff
# ============================================================

# Guard
if ! command -v git >/dev/null 2>&1; then return 0; fi
FIXTURE

# Tool mit fzf + Kommandos-Feld (statt Aliase)
cat > "$ALIAS_DIR/brew.alias" << 'FIXTURE'
# ============================================================
# brew.alias - Homebrew Aliase
# ============================================================
# Zweck       : Homebrew-Verwaltung
# Nutzt       : fzf (Interactive), jq
# Kommandos   : brew-add, brew-rm
# Aliase      : bup, bout
# ============================================================

# Guard
if ! command -v brew >/dev/null 2>&1; then return 0; fi
FIXTURE

# Tool OHNE fzf → darf NICHT erscheinen
cat > "$ALIAS_DIR/bat.alias" << 'FIXTURE'
# ============================================================
# bat.alias - Besseres cat
# ============================================================
# Zweck       : cat-Ersatz mit Syntax-Highlighting
# Nutzt       : theme-style
# ============================================================

# Guard
if ! command -v bat >/dev/null 2>&1; then return 0; fi
FIXTURE

# fzf selbst → darf NICHT auf sich selbst verweisen
cat > "$ALIAS_DIR/fzf.alias" << 'FIXTURE'
# ============================================================
# fzf.alias - Fuzzy Finder
# ============================================================
# Zweck       : Interaktiver Fuzzy Finder
# Nutzt       : bat (Preview), fd (Suche)
# Aliase      : procs, cmds
# ============================================================

# Guard
if ! command -v fzf >/dev/null 2>&1; then return 0; fi
FIXTURE

# Tool mit fzf aber OHNE Aliase/Kommandos → nur `tldr tool`
cat > "$ALIAS_DIR/zoxide.alias" << 'FIXTURE'
# ============================================================
# zoxide.alias - Smarter cd
# ============================================================
# Zweck       : cd-Ersatz mit Frecency
# Nutzt       : fzf (Interactive), eza (Preview)
# ============================================================

# Guard
if ! command -v zoxide >/dev/null 2>&1; then return 0; fi
FIXTURE

result=$(generate_cross_references)

# git → wird mit Aliase-Feld referenziert
assert_contains "Cross-Ref: git erkannt" "tldr git" "$result"
assert_contains "Cross-Ref: git-log als Funktion" "git-log" "$result"
assert_contains "Cross-Ref: git-branch als Funktion" "git-branch" "$result"

# brew → Kommandos-Feld hat Vorrang, Aliase werden angehängt
assert_contains "Cross-Ref: brew erkannt" "tldr brew" "$result"
assert_contains "Cross-Ref: brew-add als Kommando" "brew-add" "$result"
assert_contains "Cross-Ref: bup als Alias" "bup" "$result"

# bat → kein fzf → nicht in Cross-Refs
local bat_count
bat_count=$(echo "$result" | grep -c "tldr bat" || true)
assert_equals "Cross-Ref: bat ausgeschlossen (kein fzf)" "0" "$bat_count"

# fzf → nicht auf sich selbst verweisen
local fzf_self_count
fzf_self_count=$(echo "$result" | grep -c "tldr fzf" || true)
assert_equals "Cross-Ref: fzf nicht selbstreferenziert" "0" "$fzf_self_count"

# zoxide → fzf gefunden, aber kein Aliase/Kommandos-Feld → nur `tldr zoxide`
assert_contains "Cross-Ref: zoxide erkannt" "tldr zoxide" "$result"

# ============================================================
# generate_cross_references() – Integration
# ============================================================
echo ""
echo "=== generate_cross_references (Integration) ==="

# Echtes ALIAS_DIR
ALIAS_DIR="$_ORIG_ALIAS_DIR"

if [[ -d "$ALIAS_DIR" ]]; then
    result=$(generate_cross_references)

    # Mindestens git und brew sollten fzf nutzen (aus echten .alias-Dateien)
    assert_contains "Echte Refs: git referenziert" "tldr git" "$result"
    assert_contains "Echte Refs: brew referenziert" "tldr brew" "$result"

    # fzf darf nicht selbst referenziert werden
    local fzf_real_count
    fzf_real_count=$(echo "$result" | grep -c "tldr fzf" || true)
    assert_equals "Echte Refs: fzf nicht selbstreferenziert" "0" "$fzf_real_count"
else
    echo "  ⃠ Übersprungen (ALIAS_DIR nicht vorhanden)"
fi

# ALIAS_DIR zurücksetzen
ALIAS_DIR="$_ORIG_ALIAS_DIR"

# ============================================================
# Zusammenfassung
# ============================================================
test_summary
