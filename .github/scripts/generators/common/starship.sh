#!/usr/bin/env zsh
# ============================================================
# starship.sh - Starship-Konfiguration Helper
# ============================================================
# Zweck   : Extrahiert Starship-Preset aus Bootstrap-Modul
# Pfad    : .github/scripts/generators/common/starship.sh
# Hinweis : Plattformunabhängig (Starship läuft auf allen OS)
# ============================================================

# Abhängigkeit: config.sh muss vorher geladen sein (für BOOTSTRAP_MODULES)

# ------------------------------------------------------------
# Starship-Preset Extraktion
# ------------------------------------------------------------
# Extrahiert STARSHIP_PRESET_DEFAULT aus starship.sh Modul
extract_starship_default_preset() {
    local starship_module="$BOOTSTRAP_MODULES/starship.sh"
    [[ -f "$starship_module" ]] || { echo "catppuccin-powerline"; return; }
    local preset=$(grep "readonly STARSHIP_PRESET_DEFAULT=" "$starship_module" | sed 's/.*="\([^"]*\)".*/\1/')
    echo "${preset:-catppuccin-powerline}"
}
