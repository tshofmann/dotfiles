#!/usr/bin/env zsh
# ============================================================
# common.sh - Gemeinsame Bibliothek für Dokumentations-Generatoren
# ============================================================
# Zweck       : Lädt alle Module und stellt API bereit
# Pfad        : .github/scripts/generators/common.sh
# Hinweis     : Modularisierte Version – einzelne Module in common/
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

# 4. Bootstrap-Parser (Modul-Metadaten)
source "$COMMON_DIR/bootstrap.sh"

# 5. Text-Parser (Header, Aliase)
source "$COMMON_DIR/parsers.sh"

# 6. Brewfile-Parser
source "$COMMON_DIR/brewfile.sh"

# 7. dothelp-Kategorien
source "$COMMON_DIR/dothelp.sh"

# 8. Inhaltsverzeichnis (ToC)
source "$COMMON_DIR/toc.sh"
