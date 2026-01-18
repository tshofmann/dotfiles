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

# ------------------------------------------------------------
# API-Kompatibilität
# ------------------------------------------------------------
# Alle Funktionen aus den Modulen sind jetzt verfügbar:
#
# Aus tldr/parsers.sh:
#   - has_official_tldr_page()
#   - format_keybindings_for_tldr()
#   - format_param_for_tldr()
#   - parse_fzf_config_keybindings()
#   - parse_yazi_keymap()
#   - parse_shell_keybindings()
#   - parse_cross_references()
#
# Aus tldr/alias-helpers.sh:
#   - extract_alias_names()
#   - extract_alias_desc()
#   - extract_function_desc()
#   - extract_section_items()
#   - extract_alias_header_info()
#   - find_config_path()
#
# Aus tldr/patch-generator.sh:
#   - generate_patch_for_alias()
#   - generate_cross_references()
#   - generate_fzf_helper_descriptions()
#   - generate_complete_patch()
#
# Aus tldr/tools.sh:
#   - generate_dotfiles_page()
#   - generate_dotfiles_tldr()
#   - generate_catppuccin_page()
#   - generate_catppuccin_tldr()
#   - generate_zsh_page()
#   - generate_zsh_tldr()
#
# Aus tldr/core.sh:
#   - generate_tldr_patches()

# Nur ausführen wenn direkt aufgerufen (nicht gesourct)
[[ -z "${_SOURCED_BY_GENERATOR:-}" ]] && generate_tldr_patches "$@" || true
