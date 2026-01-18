#!/usr/bin/env zsh
# ============================================================
# kitty.sh - Kitty Terminal Konfiguration
# ============================================================
# Zweck       : Initialisiert Kitty mit Catppuccin Mocha Theme
# Pfad        : setup/modules/kitty.sh
# Benötigt    : _core.sh
#
# STEP        : Kitty Terminal | Setzt Catppuccin Mocha als Theme | ⚠️ Optional
# Theme       : Eingebaut seit Kitty v0.26 (kein Download nötig)
# Config      : ~/.config/kitty/kitty.conf (via stow)
# ============================================================

# Guard: Core muss geladen sein
[[ -z "${_BOOTSTRAP_CORE_LOADED:-}" ]] && {
    echo "FEHLER: _core.sh muss vor kitty.sh geladen werden" >&2
    return 1
}

# Guard: Nur auf macOS relevant (Linux hat eigene Paketmanager)
if ! is_macos; then
    log "Kitty-Modul übersprungen (nur macOS)"
    return 0
fi

# ------------------------------------------------------------
# Theme-Konfiguration
# ------------------------------------------------------------
readonly KITTY_THEME_NAME="Catppuccin-Mocha"
readonly KITTY_CONFIG_DIR="$HOME/.config/kitty"
readonly KITTY_CURRENT_THEME="$KITTY_CONFIG_DIR/current-theme.conf"

# ------------------------------------------------------------
# Prüfen ob Kitty installiert ist
# ------------------------------------------------------------
kitty_installed() {
    [[ -d "/Applications/kitty.app" ]] || command -v kitty >/dev/null 2>&1
}

# ------------------------------------------------------------
# Prüfen ob Theme bereits gesetzt ist
# ------------------------------------------------------------
theme_already_set() {
    if [[ ! -f "$KITTY_CURRENT_THEME" ]]; then
        return 1
    fi

    # Prüfe ob es das Catppuccin Mocha Theme ist
    grep -qi "catppuccin" "$KITTY_CURRENT_THEME" 2>/dev/null
}

# ------------------------------------------------------------
# Theme setzen (nutzt Kitty's eingebauten Theme-Manager)
# ------------------------------------------------------------
set_kitty_theme() {
    CURRENT_STEP="Kitty Theme"

    if ! kitty_installed; then
        log "Kitty nicht installiert – übersprungen"
        return 0
    fi

    if theme_already_set; then
        ok "Kitty Theme bereits konfiguriert"
        return 0
    fi

    log "Setze Kitty Theme: $KITTY_THEME_NAME"

    # Config-Verzeichnis sicherstellen
    [[ -d "$KITTY_CONFIG_DIR" ]] || mkdir -p "$KITTY_CONFIG_DIR"

    # Theme setzen via kitten (non-interaktiv)
    # --reload-in=none: Nicht versuchen laufende Instanzen zu reloaden
    # (Kitty läuft noch nicht beim Bootstrap)
    if command -v kitten >/dev/null 2>&1; then
        kitten themes --reload-in=none "$KITTY_THEME_NAME" 2>/dev/null && {
            ok "Kitty Theme gesetzt: $KITTY_THEME_NAME"
            return 0
        }
    elif [[ -d "/Applications/kitty.app" ]]; then
        # Fallback: Kitty CLI im App-Bundle
        /Applications/kitty.app/Contents/MacOS/kitten themes --reload-in=none "$KITTY_THEME_NAME" 2>/dev/null && {
            ok "Kitty Theme gesetzt: $KITTY_THEME_NAME"
            return 0
        }
    fi

    # Fallback: Manuelles Theme-File erstellen
    # Das Theme ist in Kitty eingebaut, wir zeigen nur drauf
    warn "kitten nicht gefunden – erstelle manuelles Theme-Include"

    # Kitty's eingebaute Themes liegen im App-Bundle
    local builtin_theme="/Applications/kitty.app/Contents/Resources/kitty/themes/Catppuccin-Mocha.conf"

    if [[ -f "$builtin_theme" ]]; then
        echo "# Catppuccin Mocha (eingebaut)" > "$KITTY_CURRENT_THEME"
        echo "include $builtin_theme" >> "$KITTY_CURRENT_THEME"
        ok "Kitty Theme verlinkt: $KITTY_THEME_NAME"
    else
        warn "Eingebautes Theme nicht gefunden – Kitty wird beim ersten Start Theme-Auswahl anbieten"
    fi

    return 0
}

# ------------------------------------------------------------
# Hauptfunktion
# ------------------------------------------------------------
setup_kitty() {
    CURRENT_STEP="Kitty Setup"

    log "Konfiguriere Kitty Terminal..."
    set_kitty_theme

    return 0
}

# Modul ausführen wenn direkt aufgerufen
if [[ "${(%):-%N}" == "$0" ]]; then
    # Standalone-Modus: Core laden
    source "${0:A:h}/_core.sh"
    setup_kitty
fi
