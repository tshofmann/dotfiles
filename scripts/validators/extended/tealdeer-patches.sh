#!/usr/bin/env zsh
# ============================================================
# tealdeer-patches.sh - Tealdeer Patch-Validierung
# ============================================================
# Zweck   : Prüft ob .patch.md Dateien aktuell sind
# Pfad    : scripts/validators/extended/tealdeer-patches.sh
# ============================================================
# Delegiert an: scripts/generate-tldr-patches.sh --check
#
# Single Source of Truth: Die Logik zum Generieren und Prüfen
# der Patches liegt im Generator. Dieser Validator ruft ihn
# nur im Check-Modus auf.
# ============================================================

# Source lib.sh wenn noch nicht geladen
if [[ -z "${VALIDATOR_LIB_LOADED:-}" ]]; then
    source "${0:A:h:h}/lib.sh"
fi

# ------------------------------------------------------------
# Hauptfunktion
# ------------------------------------------------------------
validate_tealdeer_patches() {
    local generator="$SCRIPTS_DIR/generate-tldr-patches.sh"
    
    # Prüfe ob Generator existiert
    if [[ ! -f "$generator" ]]; then
        err "Generator nicht gefunden: $generator"
        return 1
    fi
    
    # Prüfe ob Generator ausführbar ist
    if [[ ! -x "$generator" ]]; then
        err "Generator nicht ausführbar: $generator"
        return 1
    fi
    
    # Generator im Check-Modus aufrufen
    "$generator" --check
}

# ------------------------------------------------------------
# Registrierung
# ------------------------------------------------------------
register_validator "tealdeer-patches" \
    "validate_tealdeer_patches" \
    "Tealdeer Patch-Dateien" \
    "extended"
