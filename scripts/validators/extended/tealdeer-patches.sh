#!/usr/bin/env zsh
# ============================================================
# tealdeer-patches.sh - Tealdeer Patch-Validierung
# ============================================================
# Zweck   : Prüft Vollständigkeit der .patch.md Dateien
# Pfad    : scripts/validators/extended/tealdeer-patches.sh
# ============================================================
# Prüft:
#   1. 1:1 Mapping: Jede .alias Datei hat eine .patch.md
#   2. Aliase: Alle Aliase aus .alias sind im Patch
#   3. Funktionen: Alle Funktionen aus .alias sind im Patch
#   4. Format: Patches beginnen mit "# dotfiles:"
# ============================================================

# Source lib.sh wenn noch nicht geladen
if [[ -z "${VALIDATOR_LIB_LOADED:-}" ]]; then
    source "${0:A:h:h}/lib.sh"
fi

# ------------------------------------------------------------
# Konfiguration
# ------------------------------------------------------------
TEALDEER_DIR="$TERMINAL_DIR/.config/tealdeer/pages"

# Mapping: alias-Dateiname → patch-Dateiname
# (für Fälle wo die Namen abweichen)
typeset -gA PATCH_NAME_MAP=(
    [homebrew]="brew"
    [ripgrep]="rg"
)

# Ausgeschlossene .alias Dateien (keine Patches nötig)
typeset -ga EXCLUDED_ALIAS_FILES=(
    # Keine Ausnahmen – alle .alias Dateien brauchen Patches
)

# ------------------------------------------------------------
# Hilfsfunktionen
# ------------------------------------------------------------

# Extrahiere Befehle aus Patch-Datei (alles in Backticks nach "- dotfiles:")
extract_commands_from_patch() {
    local file="$1"
    # Suche Zeilen mit einzelnem Backtick-Block (Code-Zeile nach "- dotfiles:")
    grep -A1 "^- dotfiles:" "$file" 2>/dev/null | \
        grep "^\`[^\`]*\`$" | \
        sed 's/`//g' | \
        awk '{print $1}' | \
        sort -u
}

# Prüfe ob ein Befehl im Patch dokumentiert ist
is_command_in_patch() {
    local cmd="$1"
    local patch_file="$2"
    
    # Suche nach dem Befehl in Backticks
    grep -qE "^\`${cmd}( |\`)" "$patch_file" 2>/dev/null
}

# Hole den Patch-Dateinamen für eine Alias-Datei
get_patch_name() {
    local alias_base="$1"
    
    if [[ -n "${PATCH_NAME_MAP[$alias_base]:-}" ]]; then
        echo "${PATCH_NAME_MAP[$alias_base]}"
    else
        echo "$alias_base"
    fi
}

# ------------------------------------------------------------
# Hauptvalidierung
# ------------------------------------------------------------
validate_tealdeer_patches() {
    local errors=0
    local warnings=0
    
    log "Prüfe Tealdeer-Patches gegen .alias Dateien..."
    
    # Prüfe ob Tealdeer-Verzeichnis existiert
    if [[ ! -d "$TEALDEER_DIR" ]]; then
        warn "Tealdeer-Verzeichnis nicht gefunden: $TEALDEER_DIR"
        return 0
    fi
    
    # ----------------------------------------------------
    # 1. Prüfung: 1:1 Mapping (.alias → .patch.md)
    # ----------------------------------------------------
    log "Prüfe 1:1 Mapping..."
    
    local -a missing_patches=()
    local -a orphan_patches=()
    
    # Sammle alle erwarteten Patch-Namen
    local -a expected_patches=()
    for alias_file in "$ALIAS_DIR"/*.alias(N); do
        local base=$(basename "$alias_file" .alias)
        
        # Überspringe ausgeschlossene Dateien
        [[ " ${EXCLUDED_ALIAS_FILES[*]} " =~ " ${base} " ]] && continue
        
        local patch_name=$(get_patch_name "$base")
        expected_patches+=("$patch_name")
        
        local patch_file="$TEALDEER_DIR/${patch_name}.patch.md"
        if [[ ! -f "$patch_file" ]]; then
            missing_patches+=("$base → ${patch_name}.patch.md")
        fi
    done
    
    # Prüfe auf verwaiste Patches (ohne zugehörige .alias)
    for patch_file in "$TEALDEER_DIR"/*.patch.md(N); do
        local patch_base=$(basename "$patch_file" .patch.md)
        
        # Überspringe Template
        [[ "$patch_base" == "_template" ]] && continue
        
        if [[ ! " ${expected_patches[*]} " =~ " ${patch_base} " ]]; then
            orphan_patches+=("$patch_base.patch.md")
        fi
    done
    
    if (( ${#missing_patches[@]} > 0 )); then
        err "Fehlende Patch-Dateien:"
        for item in "${missing_patches[@]}"; do
            print "   ${RED}→${NC} $item"
        done
        (( errors += ${#missing_patches[@]} )) || true
    else
        ok "Alle .alias Dateien haben Patches"
    fi
    
    if (( ${#orphan_patches[@]} > 0 )); then
        warn "Verwaiste Patches (keine .alias Datei):"
        for item in "${orphan_patches[@]}"; do
            print "   ${YELLOW}→${NC} $item"
        done
        (( warnings += ${#orphan_patches[@]} )) || true
    fi
    
    # ----------------------------------------------------
    # 2. Prüfung: Vollständigkeit (Aliase + Funktionen)
    # ----------------------------------------------------
    log "Prüfe Vollständigkeit der Patches..."
    
    local -a undocumented_aliases=()
    local -a undocumented_functions=()
    
    for alias_file in "$ALIAS_DIR"/*.alias(N); do
        local base=$(basename "$alias_file" .alias)
        
        # Überspringe ausgeschlossene Dateien
        [[ " ${EXCLUDED_ALIAS_FILES[*]} " =~ " ${base} " ]] && continue
        
        local patch_name=$(get_patch_name "$base")
        local patch_file="$TEALDEER_DIR/${patch_name}.patch.md"
        
        # Überspringe wenn Patch nicht existiert (bereits gemeldet)
        [[ ! -f "$patch_file" ]] && continue
        
        # Extrahiere Aliase aus .alias
        local -a file_aliases=($(extract_aliases_from_file "$alias_file"))
        
        # Extrahiere Funktionen aus .alias (ohne private _func)
        local -a file_functions=($(extract_functions_from_file "$alias_file" | grep -v "^_"))
        
        # Prüfe jeden Alias
        for alias_name in "${file_aliases[@]}"; do
            if ! is_command_in_patch "$alias_name" "$patch_file"; then
                undocumented_aliases+=("$alias_name (${base}.alias → ${patch_name}.patch.md)")
            fi
        done
        
        # Prüfe jede Funktion
        for func_name in "${file_functions[@]}"; do
            if ! is_command_in_patch "$func_name" "$patch_file"; then
                undocumented_functions+=("$func_name (${base}.alias → ${patch_name}.patch.md)")
            fi
        done
    done
    
    if (( ${#undocumented_aliases[@]} > 0 )); then
        err "Undokumentierte Aliase in Patches:"
        for item in "${undocumented_aliases[@]}"; do
            print "   ${RED}→${NC} $item"
        done
        (( errors += ${#undocumented_aliases[@]} )) || true
    else
        ok "Alle Aliase sind in Patches dokumentiert"
    fi
    
    if (( ${#undocumented_functions[@]} > 0 )); then
        err "Undokumentierte Funktionen in Patches:"
        for item in "${undocumented_functions[@]}"; do
            print "   ${RED}→${NC} $item"
        done
        (( errors += ${#undocumented_functions[@]} )) || true
    else
        ok "Alle Funktionen sind in Patches dokumentiert"
    fi
    
    # ----------------------------------------------------
    # 3. Prüfung: Verwaiste Befehle (im Patch, aber nicht im Code)
    # ----------------------------------------------------
    log "Prüfe auf verwaiste Befehle in Patches..."
    
    local -a orphan_commands=()
    
    for alias_file in "$ALIAS_DIR"/*.alias(N); do
        local base=$(basename "$alias_file" .alias)
        
        # Überspringe ausgeschlossene Dateien
        [[ " ${EXCLUDED_ALIAS_FILES[*]} " =~ " ${base} " ]] && continue
        
        local patch_name=$(get_patch_name "$base")
        local patch_file="$TEALDEER_DIR/${patch_name}.patch.md"
        
        # Überspringe wenn Patch nicht existiert
        [[ ! -f "$patch_file" ]] && continue
        
        # Extrahiere alle Befehle aus dem Patch
        local -a patch_commands=($(extract_commands_from_patch "$patch_file"))
        
        # Extrahiere Aliase und Funktionen aus Code
        local -a code_aliases=($(extract_aliases_from_file "$alias_file"))
        local -a code_functions=($(extract_functions_from_file "$alias_file"))
        local -a all_code_commands=("${code_aliases[@]}" "${code_functions[@]}")
        
        # Prüfe jeden Patch-Befehl gegen Code
        for cmd in "${patch_commands[@]}"; do
            if [[ ! " ${all_code_commands[*]} " =~ " ${cmd} " ]]; then
                orphan_commands+=("$cmd (${patch_name}.patch.md → nicht in ${base}.alias)")
            fi
        done
    done
    
    if (( ${#orphan_commands[@]} > 0 )); then
        err "Verwaiste Befehle in Patches (nicht mehr im Code):"
        for item in "${orphan_commands[@]}"; do
            print "   ${RED}→${NC} $item"
        done
        (( errors += ${#orphan_commands[@]} )) || true
    else
        ok "Keine verwaisten Befehle in Patches"
    fi
    
    # ----------------------------------------------------
    # 4. Prüfung: Format (# dotfiles: Header)
    # ----------------------------------------------------
    # ----------------------------------------------------
    log "Prüfe Patch-Format..."
    
    local -a invalid_format=()
    
    for patch_file in "$TEALDEER_DIR"/*.patch.md(N); do
        local patch_base=$(basename "$patch_file" .patch.md)
        
        # Überspringe Template
        [[ "$patch_base" == "_template" ]] && continue
        
        # Erste nicht-leere Zeile muss mit "# dotfiles:" beginnen
        local first_line=$(grep -v "^$" "$patch_file" | head -1)
        if [[ ! "$first_line" =~ ^#[[:space:]]+dotfiles: ]]; then
            invalid_format+=("$patch_base.patch.md (erste Zeile: '$first_line')")
        fi
    done
    
    if (( ${#invalid_format[@]} > 0 )); then
        err "Patches mit ungültigem Format (muss mit '# dotfiles:' beginnen):"
        for item in "${invalid_format[@]}"; do
            print "   ${RED}→${NC} $item"
        done
        (( errors += ${#invalid_format[@]} )) || true
    else
        ok "Alle Patches haben korrektes Format"
    fi
    
    # ----------------------------------------------------
    # Zusammenfassung
    # ----------------------------------------------------
    if (( errors > 0 )); then
        return 1
    fi
    return 0
}

# ------------------------------------------------------------
# Registrierung
# ------------------------------------------------------------
register_validator "tealdeer-patches" \
    "validate_tealdeer_patches" \
    "Tealdeer Patch-Dateien" \
    "extended"
