#!/bin/bash
# ============================================================
# test-generator-logic.sh - Test Generator Logic (Bash simulation)
# ============================================================
# Testet ob Parser-Logik korrekt funktioniert
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧪 Generator Logic Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test 1: Marker detection
echo "Test 1: Marker-Erkennung in docs/tools.md"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

MARKERS_FOUND=$(grep -c "BEGIN:GENERATED:ALIASES_" "$DOTFILES_DIR/docs/tools.md" || echo 0)
EXPECTED_MARKERS=10

if [ "$MARKERS_FOUND" -eq "$EXPECTED_MARKERS" ]; then
    echo "✔ $MARKERS_FOUND/$EXPECTED_MARKERS Marker gefunden"
else
    echo "✖ $MARKERS_FOUND/$EXPECTED_MARKERS Marker gefunden (erwartet: $EXPECTED_MARKERS)"
    exit 1
fi

# Test 2: Alias file count
echo ""
echo "Test 2: Alias-Dateien vorhanden"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ALIAS_COUNT=$(find "$DOTFILES_DIR/terminal/.config/alias" -name "*.alias" | wc -l)
EXPECTED_ALIAS=10

if [ "$ALIAS_COUNT" -eq "$EXPECTED_ALIAS" ]; then
    echo "✔ $ALIAS_COUNT Alias-Dateien gefunden"
else
    echo "✖ $ALIAS_COUNT Alias-Dateien gefunden (erwartet: $EXPECTED_ALIAS)"
    exit 1
fi

# Test 3: Generator scripts exist
echo ""
echo "Test 3: Generator-Scripts vorhanden"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

REQUIRED_FILES=(
    "scripts/generate-docs.sh"
    "scripts/generators/lib.sh"
    "scripts/generators/aliases.sh"
    "scripts/generators/README.md"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$DOTFILES_DIR/$file" ]; then
        echo "✔ $file"
    else
        echo "✖ $file fehlt"
        exit 1
    fi
done

# Test 4: Marker pairs matched
echo ""
echo "Test 4: Marker-Paare konsistent"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

BEGIN_COUNT=$(grep -c "BEGIN:GENERATED:ALIASES_" "$DOTFILES_DIR/docs/tools.md" || echo 0)
END_COUNT=$(grep -c "END:GENERATED:ALIASES_" "$DOTFILES_DIR/docs/tools.md" || echo 0)

if [ "$BEGIN_COUNT" -eq "$END_COUNT" ]; then
    echo "✔ $BEGIN_COUNT BEGIN-Marker = $END_COUNT END-Marker"
else
    echo "✖ $BEGIN_COUNT BEGIN-Marker ≠ $END_COUNT END-Marker"
    exit 1
fi

# Test 5: Verify each alias file has corresponding marker
echo ""
echo "Test 5: Jede Alias-Datei hat Marker"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ALIAS_FILES=("bat" "brew" "btop" "eza" "fastfetch" "fd" "fzf" "gh" "git" "rg")
MISSING_MARKERS=()

for alias_name in "${ALIAS_FILES[@]}"; do
    marker="ALIASES_${alias_name^^}"  # Uppercase
    if grep -q "BEGIN:GENERATED:$marker" "$DOTFILES_DIR/docs/tools.md"; then
        echo "✔ $alias_name.alias → $marker"
    else
        echo "✖ $alias_name.alias → $marker fehlt"
        MISSING_MARKERS+=("$marker")
    fi
done

if [ ${#MISSING_MARKERS[@]} -gt 0 ]; then
    echo ""
    echo "Fehlende Marker: ${MISSING_MARKERS[*]}"
    exit 1
fi

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Alle Tests bestanden!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Hinweis: Vollständige Funktionstests benötigen ZSH auf macOS."
echo "Führe auf macOS aus: ./scripts/generate-docs.sh --dry-run"
