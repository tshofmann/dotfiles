#!/usr/bin/env zsh
# ============================================================
# tldr.sh - Generator für tldr-Patches und Pages
# ============================================================
# Zweck       : Generiert tldr-Patches aus .alias-Dateien
#           Falls keine offizielle tldr-Seite existiert,
#           wird stattdessen eine .page.md generiert
# Pfad        : .github/scripts/generators/tldr.sh
# Hinweis     : Modularisierte Version – einzelne Module in tldr/
# ============================================================

# Bibliothek laden (Pfade, Parser, UI)
source "${0:A:h}/common.sh"

# ------------------------------------------------------------
# tldr-Module laden (Reihenfolge wichtig!)
# ------------------------------------------------------------
TLDR_DIR="${0:A:h}/tldr"

# 1. Parser (Keybindings, fzf-Config, Yazi)
source "$TLDR_DIR/parsers.sh"

# 2. Alias-Helper (Extraktion, Sektionen)
source "$TLDR_DIR/alias-helpers.sh"

# 3. Patch-Generator (einzelne Tool-Patches)
source "$TLDR_DIR/patch-generator.sh"

# 4. Tool-Generatoren (dotfiles, catppuccin, zsh)
source "$TLDR_DIR/tools.sh"

# 5. Core-Logik (Hauptfunktion)
source "$TLDR_DIR/core.sh"

# Nur ausführen wenn direkt aufgerufen (nicht gesourct)
[[ -z "${_SOURCED_BY_GENERATOR:-}" ]] && generate_tldr_patches "$@" || true
