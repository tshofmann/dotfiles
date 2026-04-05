#!/usr/bin/env zsh
# ============================================================
# test-common-bootstrap.sh - Tests für common/bootstrap.sh
# ============================================================
# Zweck       : Unit Tests für extract_module_step_metadata(),
#               extract_module_steps(), extract_module_header_field(),
#               get_bootstrap_module_order(),
#               generate_bootstrap_steps_table(),
#               generate_bootstrap_steps_from_modules(),
#               extract_terminal_profile_name()
# Pfad        : .github/scripts/tests/test-common-bootstrap.sh
# Aufruf      : ./.github/scripts/tests/test-common-bootstrap.sh
# ============================================================

set -uo pipefail

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/lib/assertions.sh"

# Pfade für Dependencies
DOTFILES_DIR="${SCRIPT_DIR:h:h:h}"
BOOTSTRAP="$DOTFILES_DIR/setup/bootstrap.sh"
BOOTSTRAP_MODULES="$DOTFILES_DIR/setup/modules"

# bootstrap.sh braucht macos.sh (für Platzhalter-Ersetzung)
source "$SCRIPT_DIR/../generators/common/macos.sh"
source "$SCRIPT_DIR/../lib/log.sh"
source "$SCRIPT_DIR/../generators/common/bootstrap.sh"

# Temp-Verzeichnis für Fixtures
_TEST_TMPDIR=$(mktemp -d)
trap 'rm -rf "$_TEST_TMPDIR"' EXIT

# Originale Pfade sichern
_ORIG_BOOTSTRAP="$BOOTSTRAP"
_ORIG_BOOTSTRAP_MODULES="$BOOTSTRAP_MODULES"
_ORIG_DOTFILES_DIR="$DOTFILES_DIR"

# ============================================================
# extract_module_header_field()
# ============================================================
echo "=== extract_module_header_field ==="

cat > "$_TEST_TMPDIR/test-module.sh" << 'FIXTURE'
#!/usr/bin/env zsh
# ============================================================
# test-module.sh - Testmodul
# ============================================================
# Zweck       : Testzweck für Unit Tests
# Benötigt    : git, stow
# ============================================================
echo "module body"
FIXTURE

result=$(extract_module_header_field "$_TEST_TMPDIR/test-module.sh" "Zweck")
assert_equals "Zweck extrahiert" "Testzweck für Unit Tests" "$result"

result=$(extract_module_header_field "$_TEST_TMPDIR/test-module.sh" "Benötigt")
assert_equals "Benötigt extrahiert" "git, stow" "$result"

result=$(extract_module_header_field "$_TEST_TMPDIR/test-module.sh" "NichtVorhanden")
assert_empty "Nichtexistentes Feld" "$result"

# Nichtexistente Datei
result=$(extract_module_header_field "$_TEST_TMPDIR/nonexistent.sh" "Zweck")
assert_empty "Nichtexistente Datei" "$result"

# ============================================================
# extract_module_steps() (Legacy)
# ============================================================
echo ""
echo "=== extract_module_steps ==="

cat > "$_TEST_TMPDIR/legacy-module.sh" << 'FIXTURE'
#!/usr/bin/env zsh
CURRENT_STEP="Initialisierung"
echo "init"
CURRENT_STEP="Symlinks erstellen"
echo "stow"
CURRENT_STEP="Git konfigurieren"
echo "git"
FIXTURE

result=$(extract_module_steps "$_TEST_TMPDIR/legacy-module.sh")
# "Initialisierung" wird gefiltert
assert_contains "Symlinks-Schritt erkannt" "Symlinks erstellen" "$result"
assert_contains "Git-Schritt erkannt" "Git konfigurieren" "$result"

local init_count
init_count=$(echo "$result" | grep -c "Initialisierung" || true)
assert_equals "Initialisierung gefiltert" "0" "$init_count"

# Nichtexistente Datei
result=$(extract_module_steps "$_TEST_TMPDIR/nonexistent.sh")
assert_empty "Nichtexistente Datei → leer" "$result"

# ============================================================
# extract_module_step_metadata()
# ============================================================
echo ""
echo "=== extract_module_step_metadata ==="

cat > "$_TEST_TMPDIR/step-module.sh" << 'FIXTURE'
#!/usr/bin/env zsh
# ============================================================
# step-module.sh - Testmodul mit STEP-Metadaten
# ============================================================
# STEP        : Pakete installieren | Homebrew-Pakete | Abbruch bei Fehler
# STEP        : Konfiguration | Shell-Setup | Warnung und weiter
# ============================================================
FIXTURE

result=$(extract_module_step_metadata "$_TEST_TMPDIR/step-module.sh" 2>/dev/null)
assert_contains "Erster STEP erkannt" "Pakete installieren" "$result"
assert_contains "Zweiter STEP erkannt" "Konfiguration" "$result"
assert_contains "Fehlerverhalten" "Abbruch bei Fehler" "$result"

# Nichtexistente Datei
result=$(extract_module_step_metadata "$_TEST_TMPDIR/nonexistent.sh" 2>/dev/null)
assert_empty "Nichtexistente Datei → leer" "$result"

# ============================================================
# get_bootstrap_module_order()
# ============================================================
echo ""
echo "=== get_bootstrap_module_order ==="

BOOTSTRAP="$_TEST_TMPDIR/bootstrap.sh"
cat > "$BOOTSTRAP" << 'FIXTURE'
#!/usr/bin/env zsh
# Bootstrap

readonly -a MODULES=(
    validation
    backup     # Backup erstellen
    homebrew
    stow
    bat
    git-hooks
)

for module in "${MODULES[@]}"; do
    source "$module.sh"
done
FIXTURE

result=$(get_bootstrap_module_order)
assert_contains "validation erkannt" "validation" "$result"
assert_contains "backup erkannt" "backup" "$result"
assert_contains "homebrew erkannt" "homebrew" "$result"
assert_contains "stow erkannt" "stow" "$result"
assert_contains "bat erkannt" "bat" "$result"
assert_contains "git-hooks erkannt" "git-hooks" "$result"

# Reihenfolge prüfen
local first_module
first_module=$(echo "$result" | head -1)
assert_equals "Erstes Modul: validation" "validation" "$first_module"

# Kommentare nicht als Module
local comment_count
comment_count=$(echo "$result" | grep -c "#" || true)
assert_equals "Keine Kommentare in Modulnamen" "0" "$comment_count"

# Integration mit echtem bootstrap.sh
BOOTSTRAP="$_ORIG_BOOTSTRAP"
result=$(get_bootstrap_module_order)
local module_count
module_count=$(echo "$result" | wc -l | tr -d ' ')
if (( module_count >= 5 )); then
    echo "  ${C_GREEN:-}✔${C_RESET:-} Echte Module: >= 5 ($module_count)"
    (( _TEST_PASSED++ )) || true
else
    echo "  ${C_RED:-}✖${C_RESET:-} Echte Module: < 5 ($module_count)"
    (( _TEST_FAILED++ )) || true
fi

# ============================================================
# generate_bootstrap_steps_table()
# ============================================================
echo ""
echo "=== generate_bootstrap_steps_table ==="

BOOTSTRAP="$_TEST_TMPDIR/bootstrap-table.sh"
BOOTSTRAP_MODULES="$_TEST_TMPDIR/table-modules"
mkdir -p "$BOOTSTRAP_MODULES"

cat > "$BOOTSTRAP" << 'FIXTURE'
readonly -a MODULES=(
    alpha
    beta
)
FIXTURE

cat > "$BOOTSTRAP_MODULES/alpha.sh" << 'FIXTURE'
# STEP        : Alpha-Schritt | Erste Aktion | Abbruch
FIXTURE

cat > "$BOOTSTRAP_MODULES/beta.sh" << 'FIXTURE'
# STEP        : Beta-Schritt | Zweite Aktion | Warnung
FIXTURE

result=$(generate_bootstrap_steps_table 2>/dev/null)
assert_contains "Alpha-Zeile" "Alpha-Schritt" "$result"
assert_contains "Beta-Zeile" "Beta-Schritt" "$result"
assert_contains "Markdown-Pipe" "|" "$result"

# Integration mit echten Modulen
BOOTSTRAP="$_ORIG_BOOTSTRAP"
BOOTSTRAP_MODULES="$_ORIG_BOOTSTRAP_MODULES"
result=$(generate_bootstrap_steps_table 2>/dev/null)
local step_count
step_count=$(echo "$result" | grep -c "^|" || true)
if (( step_count >= 5 )); then
    echo "  ${C_GREEN:-}✔${C_RESET:-} Echte Schritte-Tabelle: >= 5 Zeilen ($step_count)"
    (( _TEST_PASSED++ )) || true
else
    echo "  ${C_RED:-}✖${C_RESET:-} Echte Schritte-Tabelle: < 5 Zeilen ($step_count)"
    (( _TEST_FAILED++ )) || true
fi

# ============================================================
# generate_bootstrap_steps_from_modules() (Legacy)
# ============================================================
echo ""
echo "=== generate_bootstrap_steps_from_modules ==="

BOOTSTRAP="$_TEST_TMPDIR/bootstrap-legacy.sh"
BOOTSTRAP_MODULES="$_TEST_TMPDIR/legacy-modules"
mkdir -p "$BOOTSTRAP_MODULES"

cat > "$BOOTSTRAP" << 'FIXTURE'
readonly -a MODULES=(
    one
    two
)
FIXTURE

cat > "$BOOTSTRAP_MODULES/one.sh" << 'FIXTURE'
CURRENT_STEP="Initialisierung"
CURRENT_STEP="Erster Schritt"
FIXTURE

cat > "$BOOTSTRAP_MODULES/two.sh" << 'FIXTURE'
CURRENT_STEP="Zweiter Schritt"
FIXTURE

result=$(generate_bootstrap_steps_from_modules)
assert_contains "Erster Schritt erkannt" "Erster Schritt" "$result"
assert_contains "Zweiter Schritt erkannt" "Zweiter Schritt" "$result"

local init_count
init_count=$(echo "$result" | grep -c "Initialisierung" || true)
assert_equals "Initialisierung gefiltert" "0" "$init_count"

# ============================================================
# extract_terminal_profile_name()
# ============================================================
echo ""
echo "=== extract_terminal_profile_name ==="

BOOTSTRAP="$_ORIG_BOOTSTRAP"
BOOTSTRAP_MODULES="$_ORIG_BOOTSTRAP_MODULES"

# Fixture: Setup-Verzeichnis mit .terminal-Datei
DOTFILES_DIR="$_TEST_TMPDIR/dotfiles-term"
mkdir -p "$DOTFILES_DIR/setup"
touch "$DOTFILES_DIR/setup/catppuccin-mocha.terminal"

result=$(extract_terminal_profile_name)
assert_equals "Profilname aus .terminal" "catppuccin-mocha" "$result"

# Mehrere .terminal-Dateien → alphabetisch erste
touch "$DOTFILES_DIR/setup/another-theme.terminal"
result=$(extract_terminal_profile_name)
assert_equals "Alphabetisch erste .terminal" "another-theme" "$result"

# Keine .terminal-Datei
DOTFILES_DIR="$_TEST_TMPDIR/no-terminal"
mkdir -p "$DOTFILES_DIR/setup"
result=$(extract_terminal_profile_name)
assert_empty "Keine .terminal → leer" "$result"

# Integration: Echtes Setup
DOTFILES_DIR="$_ORIG_DOTFILES_DIR"
result=$(extract_terminal_profile_name)
assert_contains "Echtes Profil enthält 'catppuccin'" "catppuccin" "$result"

# Zurücksetzen
BOOTSTRAP="$_ORIG_BOOTSTRAP"
BOOTSTRAP_MODULES="$_ORIG_BOOTSTRAP_MODULES"
DOTFILES_DIR="$_ORIG_DOTFILES_DIR"

# ============================================================
# Zusammenfassung
# ============================================================
test_summary
