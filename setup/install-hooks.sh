#!/usr/bin/env zsh
# ============================================================
# install-hooks.sh - Git Hooks installieren
# ============================================================
# Zweck   : Installiert pre-commit Hook für Docs-Validierung
# Aufruf  : ./setup/install-hooks.sh
# ============================================================

set -euo pipefail

SCRIPT_DIR="${0:A:h}"
DOTFILES_DIR="${SCRIPT_DIR:h}"
HOOKS_SRC="$SCRIPT_DIR/hooks"
HOOKS_DST="$DOTFILES_DIR/.git/hooks"

echo "📎 Installiere Git Hooks..."

# Pre-commit Hook
if [[ -f "$HOOKS_SRC/pre-commit" ]]; then
    cp "$HOOKS_SRC/pre-commit" "$HOOKS_DST/pre-commit"
    chmod +x "$HOOKS_DST/pre-commit"
    echo "✔ pre-commit Hook installiert"
else
    echo "✖ pre-commit nicht gefunden: $HOOKS_SRC/pre-commit"
    exit 1
fi

echo ""
echo "✅ Git Hooks installiert!"
echo ""
echo "Der pre-commit Hook prüft automatisch:"
echo "  • Brewfile ↔ architecture.md"
echo "  • Alias-Dateien ↔ tools.md"
echo "  • Config-Dateien ↔ architecture.md"
echo "  • Symlinks ↔ installation.md"
echo ""
echo "Hook überspringen: git commit --no-verify"
