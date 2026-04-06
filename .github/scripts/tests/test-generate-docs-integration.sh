#!/usr/bin/env zsh
# ============================================================
# test-generate-docs-integration.sh - Integrationstest für generate-docs.sh
# ============================================================
# Zweck       : End-to-End-Test der Dokumentations-Pipeline
#               (--check, --generate Roundtrip, Diff-Erkennung)
# Pfad        : .github/scripts/tests/test-generate-docs-integration.sh
# Aufruf      : ./.github/scripts/tests/test-generate-docs-integration.sh
# ============================================================

set -uo pipefail

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/lib/assertions.sh"

GENERATE_DOCS="$SCRIPT_DIR/../generate-docs.sh"
DOTFILES_DIR="${SCRIPT_DIR:h:h:h}"

# Pfade die der Test mutiert (alles generierte Dateien)
_MUTATED_PATHS=(README.md docs/ terminal/.config/tealdeer/pages/)

# Temp-Verzeichnis für Backups
_TEST_TMPDIR=$(mktemp -d)

# Cleanup: Mutierte Dateien wiederherstellen (Ctrl+C, Fehler, normales Ende)
cleanup() {
    git -C "$DOTFILES_DIR" checkout -- "${_MUTATED_PATHS[@]}" 2>/dev/null
    rm -rf "$_TEST_TMPDIR"
}
trap cleanup EXIT INT TERM

# Guard: Keine lokalen Änderungen in Test-Pfaden überschreiben
if ! git -C "$DOTFILES_DIR" diff --quiet -- "${_MUTATED_PATHS[@]}" \
  || ! git -C "$DOTFILES_DIR" diff --cached --quiet -- "${_MUTATED_PATHS[@]}"; then
    echo "Abbruch: Lokale Änderungen in generierten Dateien. Bitte erst committen oder verwerfen." >&2
    exit 1
fi

# ============================================================
# --check im sauberen Zustand
# ============================================================
echo "=== --check (sauberer Zustand) ==="

output=$(zsh "$GENERATE_DOCS" --check 2>&1)
check_exit=$?
assert_equals "--check erfolgreich (Exit 0)" "0" "$check_exit"
assert_contains "--check: README.md geprüft" "README.md" "$output"
assert_contains "--check: setup.md geprüft" "setup.md" "$output"
assert_contains "--check: customization.md geprüft" "customization.md" "$output"
assert_contains "--check: tldr-Patches geprüft" "tldr" "$output"

# ============================================================
# --generate Idempotenz (keine Änderungen im sauberen Zustand)
# ============================================================
echo ""
echo "=== --generate (Idempotenz) ==="

output=$(zsh "$GENERATE_DOCS" --generate 2>&1)
gen_exit=$?
assert_equals "--generate erfolgreich (Exit 0)" "0" "$gen_exit"
assert_contains "--generate: Unverändert-Meldungen" "Unverändert" "$output"

# Nach --generate: Working Tree darf nicht dirty sein (alle generierten Pfade)
dirty=$(git -C "$DOTFILES_DIR" diff --name-only -- "${_MUTATED_PATHS[@]}")
assert_empty "--generate ändert nichts im sauberen Zustand" "$dirty"

# ============================================================
# Diff-Erkennung: Mutation → --check schlägt fehl
# ============================================================
echo ""
echo "=== Diff-Erkennung (Mutation → --check) ==="

# README.md manipulieren und Original sichern
cp "$DOTFILES_DIR/README.md" "$_TEST_TMPDIR/README.md.bak"
echo "<!-- test-mutation -->" >> "$DOTFILES_DIR/README.md"

output=$(zsh "$GENERATE_DOCS" --check 2>&1)
check_exit=$?
assert_equals "--check erkennt veraltete README.md (Exit 1)" "1" "$check_exit"
assert_contains "--check meldet README.md veraltet" "README.md" "$output"
assert_contains "--check meldet veraltet" "veraltet" "$output"

# Original wiederherstellen
cp "$_TEST_TMPDIR/README.md.bak" "$DOTFILES_DIR/README.md"

# ============================================================
# Roundtrip: --generate → --check = sauber
# ============================================================
echo ""
echo "=== Roundtrip (generate → check) ==="

# docs/setup.md manipulieren
cp "$DOTFILES_DIR/docs/setup.md" "$_TEST_TMPDIR/setup.md.bak"
echo "<!-- test-mutation -->" >> "$DOTFILES_DIR/docs/setup.md"

# --check: sollte Diff erkennen
output=$(zsh "$GENERATE_DOCS" --check 2>&1)
assert_equals "Roundtrip: Mutation erkannt (Exit 1)" "1" "$?"

# --generate: sollte reparieren
output=$(zsh "$GENERATE_DOCS" --generate 2>&1)
assert_equals "Roundtrip: --generate erfolgreich" "0" "$?"

# --check: sollte jetzt sauber sein
output=$(zsh "$GENERATE_DOCS" --check 2>&1)
assert_equals "Roundtrip: --check nach --generate sauber (Exit 0)" "0" "$?"

# Original wiederherstellen (falls --generate andere Whitespace-Konvention hat)
cp "$_TEST_TMPDIR/setup.md.bak" "$DOTFILES_DIR/docs/setup.md"

# ============================================================
# Generierte Inhalte: Nicht-Leer-Validierung
# ============================================================
echo ""
echo "=== Generierte Inhalte (Nicht-Leer) ==="

# Generierte Dateien müssen substantiellen Inhalt haben
for doc_file in README.md docs/setup.md docs/customization.md; do
    local size=$(wc -c < "$DOTFILES_DIR/$doc_file")
    [[ "$size" -gt 100 ]]
    assert_equals "$doc_file > 100 Bytes" "0" "$?"
done

# tldr-Dateien: Mindestens eine muss existieren und substantiell sein
local tldr_dir="$DOTFILES_DIR/terminal/.config/tealdeer/pages"
local tldr_count=$(find "$tldr_dir" -name '*.md' 2>/dev/null | wc -l)
[[ "$tldr_count" -gt 0 ]]
assert_equals "tldr-Pages existieren (>0)" "0" "$?"
local sample_size=$(wc -c < "$tldr_dir/fzf.patch.md" 2>/dev/null || echo 0)
[[ "$sample_size" -gt 50 ]]
assert_equals "tldr-Stichprobe: fzf.patch.md > 50 Bytes" "0" "$?"

# ============================================================
# Fehlerbehandlung: Ungültige Option
# ============================================================
echo ""
echo "=== Fehlerbehandlung ==="

output=$(zsh "$GENERATE_DOCS" --invalid 2>&1)
assert_equals "--invalid: Exit ≠ 0" "1" "$?"
assert_contains "--invalid: Fehlermeldung" "Unbekannte" "$output"

output=$(zsh "$GENERATE_DOCS" --help 2>&1)
assert_equals "--help: Exit 0" "0" "$?"
assert_contains "--help: Verwendung" "check" "$output"

# ============================================================
# Zusammenfassung
# ============================================================
test_summary
