#!/usr/bin/env zsh
# ============================================================
# xcode-theme.sh - Xcode Theme Installation
# ============================================================
# Zweck       : Installiert Xcode Syntax-Highlighting Theme
# Pfad        : setup/modules/xcode-theme.sh
# Benötigt    : _core.sh
# CURRENT_STEP: Xcode Theme Installation
# Theme       : Catppuccin Mocha (.xccolortheme-Datei in setup/)
# Zielort     : ~/Library/Developer/Xcode/UserData/FontAndColorThemes/
# Aktivierung : Xcode → Settings (⌘,) → Themes → Theme-Name
# ============================================================

# Guard: Core muss geladen sein
[[ -z "${_BOOTSTRAP_CORE_LOADED:-}" ]] && {
    echo "FEHLER: _core.sh muss vor xcode-theme.sh geladen werden" >&2
    return 1
}

# ------------------------------------------------------------
# Konfiguration
# ------------------------------------------------------------
readonly XCODE_THEMES_DIR="$HOME/Library/Developer/Xcode/UserData/FontAndColorThemes"

# ------------------------------------------------------------
# Theme-Datei ermitteln
# ------------------------------------------------------------
detect_xcode_theme() {
    local theme_file
    theme_file=$(find "$SCRIPT_DIR" -maxdepth 1 -name "*.xccolortheme" -type f 2>/dev/null | sort | head -1)

    # Warnung wenn mehrere .xccolortheme-Dateien existieren
    local theme_count
    theme_count=$(find "$SCRIPT_DIR" -maxdepth 1 -name "*.xccolortheme" -type f 2>/dev/null | wc -l | tr -d ' ')
    if (( theme_count > 1 )); then
        warn "Mehrere .xccolortheme-Dateien gefunden, verwende: ${theme_file:t}"
    fi

    echo "$theme_file"
}

# ------------------------------------------------------------
# Haupt-Setup-Funktion
# ------------------------------------------------------------
setup_xcode_theme() {
    CURRENT_STEP="Xcode Theme Installation"

    # Prüfe ob Xcode.app installiert ist (nicht nur Command Line Tools)
    if [[ ! -d "/Applications/Xcode.app" ]]; then
        log "Xcode.app nicht installiert, überspringe Theme-Installation"
        return 2  # Skip, kein Fehler
    fi

    log "Prüfe Xcode Theme-Installation"

    local theme_file theme_name
    theme_file=$(detect_xcode_theme)

    if [[ -z "$theme_file" || ! -f "$theme_file" ]]; then
        warn "Keine .xccolortheme-Datei in setup/ gefunden"
        return 2
    fi

    # Theme-Name aus Dateiname extrahieren (für Log-Meldungen)
    theme_name="${${theme_file:t}%.xccolortheme}"

    # Defensiv: Prüfe ob Zielverzeichnis erstellt/beschrieben werden kann
    if ! ensure_dir_writable "$XCODE_THEMES_DIR" "Xcode Themes-Verzeichnis"; then
        warn "Kann Xcode Theme nicht installieren, Verzeichnis nicht schreibbar"
        return 2
    fi

    # Prüfe ob Theme-Datei geschrieben werden kann
    local theme_dest="$XCODE_THEMES_DIR/${theme_file:t}"
    if ! ensure_file_writable "$theme_dest" "Xcode Theme"; then
        warn "Kann Xcode Theme nicht installieren, Zieldatei nicht schreibbar"
        return 2
    fi

    # Theme kopieren (überschreibt existierende Version)
    if cp "$theme_file" "$XCODE_THEMES_DIR/"; then
        ok "Xcode Theme '$theme_name' installiert"
        log "Aktivierung: Xcode → Settings (⌘,) → Themes → '$theme_name'"
    else
        warn "Konnte Xcode Theme nicht kopieren (unbekannter Fehler)"
        return 1
    fi

    return 0
}
