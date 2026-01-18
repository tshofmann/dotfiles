#!/usr/bin/env zsh
# ============================================================
# yazi.sh - Yazi Package-Manager Setup
# ============================================================
# Zweck       : Installiert Yazi Flavors und Plugins via ya pkg
# Pfad        : setup/modules/yazi.sh
# Benötigt    : _core.sh, homebrew (yazi muss installiert sein)
#
# STEP        : Yazi-Packages | ya pkg install | ⏭ Übersprungen wenn vorhanden
# Config      : ~/.config/yazi/package.toml
# Docs        : https://yazi-rs.github.io/docs/cli#package
#
# Was wird installiert?
#   - Catppuccin Mocha Flavor (Theme)
#   - Weitere Plugins nach Bedarf (package.toml erweitern)
#
# Manuelle Nutzung:
#   ya pkg install  # Installiert alle deps aus package.toml
#   ya pkg upgrade  # Aktualisiert alle Packages
#   ya pkg list     # Zeigt installierte Packages
# ============================================================

# Guard: Core muss geladen sein
[[ -z "${_BOOTSTRAP_CORE_LOADED:-}" ]] && {
    echo "FEHLER: _core.sh muss vor yazi.sh geladen werden" >&2
    return 1
}

# ------------------------------------------------------------
# Konfiguration
# ------------------------------------------------------------
readonly YAZI_CONFIG_DIR="$HOME/.config/yazi"
readonly YAZI_PACKAGE_FILE="$YAZI_CONFIG_DIR/package.toml"
readonly YAZI_FLAVORS_DIR="$YAZI_CONFIG_DIR/flavors"
readonly YAZI_FLAVOR_NAME="catppuccin-mocha"

# ------------------------------------------------------------
# Setup-Funktion
# ------------------------------------------------------------
setup_yazi() {
    CURRENT_STEP="Yazi-Packages"

    # Guard: ya CLI muss verfügbar sein
    if ! command -v ya >/dev/null 2>&1; then
        log "ya CLI nicht gefunden – überspringe (yazi noch nicht installiert?)"
        return 0
    fi

    # Guard: package.toml muss existieren (nach stow)
    if [[ ! -f "$YAZI_PACKAGE_FILE" ]]; then
        log "package.toml nicht gefunden – überspringe"
        log "Führe zuerst 'stow terminal' aus, dann bootstrap erneut."
        return 0
    fi

    # Prüfe ob Flavor bereits installiert ist
    if [[ -d "$YAZI_FLAVORS_DIR/${YAZI_FLAVOR_NAME}.yazi" ]]; then
        skip "Yazi Flavor '$YAZI_FLAVOR_NAME' bereits installiert"
        return 0
    fi

    # Installiere Packages aus package.toml
    section "Yazi-Packages"
    log "Installiere Flavors aus package.toml..."

    if ya pkg install 2>/dev/null; then
        success "Yazi Flavor '$YAZI_FLAVOR_NAME' installiert"
    else
        warn "ya pkg install fehlgeschlagen – manuell ausführen: ya pkg install"
        return 0  # Kein harter Fehler, Yazi funktioniert auch ohne Flavor
    fi

    return 0
}
