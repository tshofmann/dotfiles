#!/usr/bin/env zsh
# ============================================================
# common.sh - Gemeinsame Bibliothek für Dokumentations-Generatoren
# ============================================================
# Zweck   : Lädt alle Module und stellt API bereit
# Pfad    : .github/scripts/generators/common.sh
# Hinweis : Modularisierte Version – einzelne Module in common/
# ============================================================

# ------------------------------------------------------------
# Basis-Konfiguration (vor allen anderen Modulen)
# ------------------------------------------------------------
# DOTFILES_DIR setzen bevor Module geladen werden
SCRIPT_DIR="${0:A:h}"
GENERATORS_DIR="${SCRIPT_DIR}"
DOTFILES_DIR="${GENERATORS_DIR:h:h:h}"  # .github/scripts/generators → dotfiles

COMMON_DIR="$GENERATORS_DIR/common"

# ------------------------------------------------------------
# Module laden (Reihenfolge wichtig!)
# ------------------------------------------------------------
# 1. Konfiguration (Pfade, Konstanten)
source "$COMMON_DIR/config.sh"

# 2. UI-Komponenten (Logging, Ausgabe)
source "$COMMON_DIR/ui.sh"

# 3. macOS-Helper (Versionen, Codenamen)
source "$COMMON_DIR/macos.sh"

# 4. Starship-Helper (Presets – plattformunabhängig)
source "$COMMON_DIR/starship.sh"

# 5. Bootstrap-Parser (Modul-Metadaten)
source "$COMMON_DIR/bootstrap.sh"

# 6. Text-Parser (Header, Aliase)
source "$COMMON_DIR/parsers.sh"

# 7. Brewfile-Parser
source "$COMMON_DIR/brewfile.sh"

# 8. dothelp-Kategorien
source "$COMMON_DIR/dothelp.sh"

# ------------------------------------------------------------
# API-Kompatibilität
# ------------------------------------------------------------
# Alle Funktionen aus den Modulen sind jetzt verfügbar:
#
# Aus config.sh:
#   - Pfad-Variablen (ALIAS_DIR, FZF_DIR, etc.)
#   - Projekt-Metadaten (PROJECT_TAGLINE, etc.)
#
# Aus ui.sh:
#   - log(), ok(), warn(), err(), dim(), bold()
#   - ui_banner(), ui_section(), ui_footer()
#   - compare_content(), write_if_changed()
#
# Aus macos.sh:
#   - get_macos_codename()
#   - extract_macos_min_version_smart()
#   - extract_macos_tested_version_smart()
#   - has_bootstrap_modules()
#
# Aus starship.sh:
#   - extract_starship_default_preset()
#
# Aus bootstrap.sh:
#   - extract_module_step_metadata()
#   - extract_module_steps()
#   - extract_module_header_field()
#   - get_bootstrap_module_order()
#   - generate_bootstrap_steps_table()
#   - generate_bootstrap_steps_from_modules()
#
# Aus parsers.sh:
#   - parse_header_field()
#   - parse_description_comment()
#   - parse_alias_command()
#   - extract_usage_codeblock()
#
# Aus brewfile.sh:
#   - parse_brewfile_entry()
#   - generate_brewfile_section()
#
# Aus dothelp.sh:
#   - get_dothelp_categories()
