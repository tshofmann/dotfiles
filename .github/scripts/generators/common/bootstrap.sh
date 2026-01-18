#!/usr/bin/env zsh
# ============================================================
# bootstrap.sh - Bootstrap-Modul Parser
# ============================================================
# Zweck       : Extrahiert Metadaten aus Bootstrap-Modulen
# Pfad        : .github/scripts/generators/common/bootstrap.sh
# ============================================================

# Abhängigkeit: config.sh und macos.sh müssen vorher geladen sein

# ------------------------------------------------------------
# Modul-Metadaten Extraktion
# ------------------------------------------------------------
# Extrahiert STEP-Metadaten aus einem Modul
# Format: # STEP        : Name | Beschreibung | Fehlerverhalten
# Rückgabe: Zeilenweise "Name|Beschreibung|Fehlerverhalten"
# Ersetzt Platzhalter: ${MACOS_MIN_VERSION} → tatsächlicher Wert
extract_module_step_metadata() {
    local module_file="$1"
    [[ -f "$module_file" ]] || return 1

    # macOS-Version für Platzhalter-Ersetzung holen
    local macos_min macos_min_name
    macos_min=$(extract_macos_min_version_smart)
    macos_min_name=$(get_macos_codename "$macos_min")

    grep "^# STEP[[:space:]]*:" "$module_file" 2>/dev/null | while read -r line; do
        # Entferne "# STEP        : " Prefix (flexibel mit beliebig vielen Spaces)
        local data="${line#\# STEP}"
        data="${data#"${data%%[^[:space:]]*}"}"  # Trim leading spaces
        data="${data#:}"                          # Remove colon
        data="${data#"${data%%[^[:space:]]*}"}"  # Trim spaces after colon
        # Ersetze Platzhalter
        data="${data//\$\{MACOS_MIN_VERSION\}/${macos_min}+ (${macos_min_name})}"
        # Gib Name|Beschreibung|Fehlerverhalten aus
        echo "$data"
    done
}

# Legacy: Extrahiert CURRENT_STEP Zuweisungen (für Abwärtskompatibilität)
extract_module_steps() {
    local module_file="$1"
    [[ -f "$module_file" ]] || return 1

    grep "CURRENT_STEP=" "$module_file" 2>/dev/null | while read -r line; do
        local step="${line#*CURRENT_STEP=}"
        step="${step#\"}"
        step="${step%\"}"
        [[ -n "$step" && "$step" != "Initialisierung" ]] && echo "$step"
    done
}

# Extrahiert Header-Feld aus Modul (z.B. "Zweck", "Benötigt", "CURRENT_STEP")
# Format im Modul: # Feldname   : Wert
extract_module_header_field() {
    local module_file="$1"
    local field="$2"
    [[ -f "$module_file" ]] || return 1

    # Suche nach "# Feldname" gefolgt von ":" und extrahiere Wert
    local value
    value=$(grep -E "^# ${field}[[:space:]]*:" "$module_file" 2>/dev/null | head -1 | sed "s/^# ${field}[[:space:]]*:[[:space:]]*//")
    echo "$value"
}

# ------------------------------------------------------------
# Bootstrap-Modul Reihenfolge
# ------------------------------------------------------------
# Liste aller Bootstrap-Module in der definierten Reihenfolge
# Liest MODULES Array aus bootstrap.sh
get_bootstrap_module_order() {
    local bootstrap="$BOOTSTRAP"

    [[ -f "$bootstrap" ]] || return 1

    # Extrahiere MODULES Array
    local in_modules=false
    while IFS= read -r line; do
        # Whitespace trimmen
        local trimmed="${line#"${line%%[![:space:]]*}"}"
        trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"

        # Array-Start erkennen
        if [[ "$trimmed" == "readonly -a MODULES="* || "$trimmed" == "MODULES=("* ]]; then
            in_modules=true
            continue
        fi

        # Array-Ende erkennen
        if $in_modules && [[ "$trimmed" == ")" ]]; then
            break
        fi

        # Modul-Namen extrahieren (Format: "modulname  # Kommentar" oder "prefix:modulname")
        if $in_modules; then
            # Kommentar entfernen und trimmen
            local module="${trimmed%%#*}"
            module="${module#"${module%%[![:space:]]*}"}"
            module="${module%"${module##*[![:space:]]}"}"

            # Plattform-Prefix entfernen falls vorhanden (macos:, linux:, etc.)
            if [[ "$module" == *":"* ]]; then
                module="${module#*:}"
            fi

            # Nur gültige Modul-Namen (alphanumerisch + Bindestrich)
            [[ "$module" =~ ^[a-z][a-z0-9-]*$ ]] && echo "$module"
        fi
    done < "$bootstrap"
}

# ------------------------------------------------------------
# Bootstrap-Schritte-Tabelle (Markdown)
# ------------------------------------------------------------
# Generiert Bootstrap-Schritte-Tabelle aus Modulen (Markdown-Format)
# Nutzt STEP-Metadaten: # STEP        : Name | Beschreibung | Fehlerverhalten
# Rückgabe: Markdown-Tabellenzeilen
generate_bootstrap_steps_table() {
    local -a modules
    modules=($(get_bootstrap_module_order))

    for module in "${modules[@]}"; do
        local module_file="$BOOTSTRAP_MODULES/${module}.sh"
        [[ -f "$module_file" ]] || continue

        # STEP-Metadaten aus Modul extrahieren
        while IFS= read -r step_data; do
            [[ -z "$step_data" ]] && continue
            # Format: "Name | Beschreibung | Fehlerverhalten"
            # Umwandeln in Markdown-Tabellenzeile
            echo "| $step_data |"
        done < <(extract_module_step_metadata "$module_file")
    done
}

# Legacy: Generiert nur Schritt-Namen (für Abwärtskompatibilität)
generate_bootstrap_steps_from_modules() {
    local -a modules
    modules=($(get_bootstrap_module_order))

    for module in "${modules[@]}"; do
        local module_file="$BOOTSTRAP_MODULES/${module}.sh"
        [[ -f "$module_file" ]] || continue

        # CURRENT_STEP Werte aus Modul extrahieren
        extract_module_steps "$module_file"
    done
}
