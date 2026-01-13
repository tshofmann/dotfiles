#!/usr/bin/env zsh
# ============================================================
# config.sh - Zentrale Konfiguration für Dokumentations-Generatoren
# ============================================================
# Zweck   : Pfade, Konstanten, Projekt-Metadaten
# Pfad    : .github/scripts/generators/common/config.sh
# ============================================================

# ------------------------------------------------------------
# Pfad-Konfiguration
# ------------------------------------------------------------
# Diese Datei kann aus verschiedenen Kontexten geladen werden,
# daher DOTFILES_DIR als Referenzpunkt nutzen
if [[ -z "${DOTFILES_DIR:-}" ]]; then
    # Fallback: Aus Skriptpfad ableiten
    DOTFILES_DIR="${0:A:h:h:h:h:h}"  # lib/config.sh → generators → scripts → .github → dotfiles
fi

ALIAS_DIR="$DOTFILES_DIR/terminal/.config/alias"
FZF_DIR="$DOTFILES_DIR/terminal/.config/fzf"
DOCS_DIR="$DOTFILES_DIR/docs"
FZF_CONFIG="$DOTFILES_DIR/terminal/.config/fzf/config"
TEALDEER_DIR="$DOTFILES_DIR/terminal/.config/tealdeer/pages"
BOOTSTRAP="$DOTFILES_DIR/setup/bootstrap.sh"
BOOTSTRAP_MODULES="$DOTFILES_DIR/setup/modules"
SHELL_COLORS="$DOTFILES_DIR/terminal/.config/theme-style"

# BREWFILE nur setzen wenn nicht bereits definiert (Konflikt mit homebrew.sh vermeiden)
[[ -z "${BREWFILE:-}" ]] && BREWFILE="$DOTFILES_DIR/setup/Brewfile"

# Farben (Catppuccin Mocha) – zentral definiert
[[ -f "$SHELL_COLORS" ]] && source "$SHELL_COLORS"

# ------------------------------------------------------------
# Projekt-Metadaten (Single Source of Truth)
# ------------------------------------------------------------
# Kurzbeschreibung für README, tldr, GitHub Repo Description
readonly PROJECT_TAGLINE="Dotfiles mit Catppuccin-Theme und modernen CLI-Tools."
# Erweiterte Beschreibung für README
readonly PROJECT_DESCRIPTION="Automatisiertes Dotfile-Setup mit modernen CLI-Ersetzungen."

# dothelp-Kategorien (Single Source of Truth für readme.sh + tldr.sh)
readonly DOTHELP_CAT_ALIASES="Aliase"
readonly DOTHELP_CAT_KEYBINDINGS="Keybindings"
readonly DOTHELP_CAT_FZF="fzf-Shortcuts"
readonly DOTHELP_CAT_REPLACEMENTS="Tool-Ersetzungen"

# ------------------------------------------------------------
# UI-Konstanten
# ------------------------------------------------------------
readonly UI_LINE_WIDTH=46
readonly UI_LINE=$(printf '━%.0s' {1..46})
