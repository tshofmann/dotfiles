#!/usr/bin/env zsh
# ============================================================
# starship.sh - Starship Shell-Prompt Konfiguration
# ============================================================
# Zweck       : Konfiguriert Starship-Theme via Presets
# Pfad        : setup/modules/starship.sh
# Benötigt    : _core.sh
# CURRENT_STEP: Starship-Theme Konfiguration
# Config      : ~/.config/starship.toml (NICHT versioniert)
# Docs        : https://starship.rs/
# Theme       : Catppuccin Mocha via catppuccin-powerline Preset
#
# Warum nicht versioniert?
#   - Config wird via `starship preset` generiert
#   - Nutzer können STARSHIP_PRESET überschreiben
#   - Verhindert Konflikte bei Preset-Updates
#
# Anpassung:
#   export STARSHIP_PRESET="gruvbox-rainbow"  # vor bootstrap.sh
#   Oder: ~/.config/starship.toml direkt editieren (wird dann
#         nicht mehr überschrieben, außer STARSHIP_PRESET gesetzt)
#
# Verfügbare Presets: starship preset --list
# ============================================================

# Guard: Core muss geladen sein
[[ -z "${_BOOTSTRAP_CORE_LOADED:-}" ]] && {
    echo "FEHLER: _core.sh muss vor starship.sh geladen werden" >&2
    return 1
}

# ------------------------------------------------------------
# Konfiguration
# ------------------------------------------------------------
readonly STARSHIP_CONFIG="$HOME/.config/starship.toml"
readonly STARSHIP_PRESET_DEFAULT="catppuccin-powerline"

# Merke, ob der Nutzer STARSHIP_PRESET explizit gesetzt hat
_preset_from_env=false
[[ -n "${STARSHIP_PRESET+x}" ]] && _preset_from_env=true

readonly STARSHIP_PRESET_ACTIVE="${STARSHIP_PRESET:-$STARSHIP_PRESET_DEFAULT}"

# ------------------------------------------------------------
# Preset anwenden
# ------------------------------------------------------------
apply_starship_preset() {
    local preset="$1"
    local fallback="${2:-}"

    if starship preset "$preset" -o "$STARSHIP_CONFIG" 2>/dev/null; then
        ok "Starship-Theme '$preset' gesetzt → $STARSHIP_CONFIG"
        return 0
    fi

    # Fallback wenn Preset ungültig
    if [[ -n "$fallback" ]]; then
        warn "Starship-Preset '$preset' ungültig, nutze Fallback '$fallback'"
        if starship preset "$fallback" -o "$STARSHIP_CONFIG" 2>/dev/null; then
            ok "Fallback-Theme '$fallback' gesetzt → $STARSHIP_CONFIG"
            return 0
        fi
    fi

    warn "Starship-Preset konnte nicht gesetzt werden"
    return 1
}

# ------------------------------------------------------------
# Haupt-Setup-Funktion
# ------------------------------------------------------------
setup_starship() {
    CURRENT_STEP="Starship-Theme Konfiguration"

    # Prüfe ob Starship installiert ist
    if ! command -v starship >/dev/null 2>&1; then
        warn "starship nicht gefunden, überspringe Theme-Setup"
        return 2  # Skip, kein Fehler
    fi

    # Config existiert bereits?
    if [[ -f "$STARSHIP_CONFIG" ]]; then
        if [[ "$_preset_from_env" == "true" ]]; then
            # Nutzer hat explizit ein Preset gesetzt → überschreiben
            if ! ensure_file_writable "$STARSHIP_CONFIG" "Starship-Config"; then
                warn "Kann Starship-Config nicht überschreiben, überspringe"
                return 2
            fi
            log "Überschreibe $STARSHIP_CONFIG mit Preset '$STARSHIP_PRESET_ACTIVE'"
            apply_starship_preset "$STARSHIP_PRESET_ACTIVE" "$STARSHIP_PRESET_DEFAULT"
        else
            # Kein explizites Preset → bestehende Config bleibt unverändert
            ok "$STARSHIP_CONFIG existiert bereits"
        fi
        return 0
    fi

    # Keine Config vorhanden → erstellen
    if [[ -e "$HOME/.config" && ! -d "$HOME/.config" ]]; then
        err "$HOME/.config existiert, ist aber kein Verzeichnis"
        return 1
    fi

    # Defensiv: Prüfe ob wir Config-Datei erstellen können
    if ! ensure_file_writable "$STARSHIP_CONFIG" "Starship-Config"; then
        warn "Kann Starship-Config nicht erstellen, überspringe"
        return 2
    fi

    apply_starship_preset "$STARSHIP_PRESET_ACTIVE" "$STARSHIP_PRESET_DEFAULT"
    return 0
}
