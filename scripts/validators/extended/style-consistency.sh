#!/usr/bin/env zsh
# ============================================================
# style-consistency.sh - Code-Stil Konsistenz Validierung
# ============================================================
# Prüft: Metadaten-Padding, Guard-Format, fzf-Header-Stil,
#        Sektions-Trenner
# ============================================================

[[ -z "${VALIDATOR_LIB_LOADED:-}" ]] && source "${0:A:h:h}/lib.sh"

# ------------------------------------------------------------
# Stil-Regeln (Konstanten)
# ------------------------------------------------------------
# Metadaten-Felder: 8 Zeichen breit (mit Leerzeichen aufgefüllt)
# Beispiel: "# Docs    :" "# Guard   :" "# Hinweis :"
typeset -ga METADATA_FIELDS=(
    "Docs"
    "Guard"
    "Hinweis"
    "Nutzt"
    "Benötigt"
    "Alias"
    "Beispiel"
)
: ${METADATA_WIDTH:=8}

# Guard-Format: Kurze Version ohne "Aliase nur aktivieren wenn"
# Richtig:  "# Guard   : Nur wenn X installiert ist"
# Falsch:   "# Guard   : Aliase nur aktivieren wenn X installiert ist"
: ${GUARD_WRONG_PATTERN:="Aliase nur aktivieren wenn"}

# fzf Header-Format: Enter zuerst, ASCII-Pipe als Trenner
# Richtig:  --header="Enter: Aktion | Key: Aktion"
# Falsch:   --header="Key: Aktion | Enter: Aktion"
# Falsch:   --header="Enter: Aktion │ Key: Aktion" (Unicode)

# Sektions-Trenner: Nur ---- für Sektionen, ==== nur für Datei-Header
# Richtig:  # ------------------------------------------------------------
# Falsch:   # ============================================================ (nach Header-Block)

# Header-Block: Erste 3 Zeilen mit ==== sind erlaubt (Datei-Header)
: ${HEADER_BLOCK_END:=20}  # Nach Zeile 20 nur noch ---- erlaubt

# ------------------------------------------------------------
# Prüfung: Metadaten-Padding (8 Zeichen)
# ------------------------------------------------------------
check_metadata_padding() {
    local file="$1"
    local errors=0
    local line_num=0
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        ((line_num++))
        
        for field in "${METADATA_FIELDS[@]}"; do
            # Prüfe ob die Zeile das Feld enthält
            if [[ "$line" =~ "^# ${field}" ]]; then
                # Berechne erwartetes Format
                local padded_field="$field"
                local padding=$((METADATA_WIDTH - ${#field}))
                for ((i=0; i<padding; i++)); do
                    padded_field+=" "
                done
                
                # Prüfe korrektes Format: "# Feld   :"
                if [[ ! "$line" =~ "^# ${padded_field}:" ]]; then
                    err "$(basename "$file"):$line_num: Falsches Metadaten-Format"
                    debug "  Erwartet: '# ${padded_field}:'"
                    debug "  Gefunden: '$line'"
                    ((errors++))
                fi
                break
            fi
        done
    done < "$file"
    
    return $errors
}

# ------------------------------------------------------------
# Prüfung: Guard-Kommentar Format
# ------------------------------------------------------------
check_guard_format() {
    local file="$1"
    local errors=0
    local line_num=0
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        ((line_num++))
        
        # Prüfe auf altes Guard-Format
        if [[ "$line" =~ "$GUARD_WRONG_PATTERN" ]]; then
            err "$(basename "$file"):$line_num: Altes Guard-Format gefunden"
            debug "  Falsch: 'Aliase nur aktivieren wenn...'"
            debug "  Richtig: 'Nur wenn ... installiert ist'"
            ((errors++))
        fi
    done < "$file"
    
    return $errors
}

# ------------------------------------------------------------
# Prüfung: Sektions-Trenner (---- vs ====)
# ------------------------------------------------------------
check_section_separators() {
    local file="$1"
    local errors=0
    local line_num=0
    local in_header_block=true
    local header_end_found=false
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        ((line_num++))
        
        # Header-Block endet nach der ersten leeren Zeile nach ====
        if $in_header_block; then
            if [[ "$line" =~ "^# ====" ]]; then
                header_end_found=true
            elif $header_end_found && [[ -z "$line" || ! "$line" =~ "^#" ]]; then
                in_header_block=false
            fi
        fi
        
        # Nach dem Header-Block: ==== ist nicht erlaubt
        if ! $in_header_block; then
            if [[ "$line" =~ "^# ============" ]]; then
                err "$(basename "$file"):$line_num: Falscher Sektions-Trenner"
                debug "  Verwende '# ------------' statt '# ============'"
                ((errors++))
            fi
        fi
    done < "$file"
    
    return $errors
}

# ------------------------------------------------------------
# Prüfung: fzf Header-Stil
# ------------------------------------------------------------
check_fzf_headers() {
    local file="$1"
    local errors=0
    local line_num=0
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        ((line_num++))
        
        # Nur Zeilen mit --header= prüfen
        if [[ "$line" =~ "--header=" ]]; then
            # 1. Prüfe auf Unicode-Pipe (│ statt |)
            if [[ "$line" =~ "│" ]]; then
                err "$(basename "$file"):$line_num: Unicode-Pipe in fzf-Header"
                debug "  Verwende ASCII '|' statt Unicode '│'"
                ((errors++))
            fi
            
            # 2. Prüfe ob Enter am Anfang steht (nach Anführungszeichen)
            # Erlaubte Formate: --header="Enter:" oder --header='Enter:'
            if [[ "$line" =~ "--header=" ]] && [[ ! "$line" =~ '--header=["'"'"']Enter:' ]]; then
                # Spezialfall: Header ohne Enter ist ok (z.B. nur Info-Text)
                if [[ "$line" =~ "--header=" ]] && [[ "$line" =~ ":" ]]; then
                    # Hat Doppelpunkt = wahrscheinlich Keybinding-Format
                    # Prüfe ob NICHT mit Enter beginnt
                    local header_content
                    header_content=$(echo "$line" | sed -E "s/.*--header=['\"]?([^'\"]*)['\"]?.*/\1/")
                    
                    # Wenn Header ein Keybinding-Format hat (X: Aktion)
                    if [[ "$header_content" =~ ^[A-Za-z]+: ]]; then
                        if [[ ! "$header_content" =~ ^Enter: ]]; then
                            err "$(basename "$file"):$line_num: fzf-Header muss mit 'Enter:' beginnen"
                            debug "  Gefunden: '$header_content'"
                            ((errors++))
                        fi
                    fi
                fi
            fi
            
            # 3. Prüfe Trenner-Format (Leerzeichen um Pipe)
            if [[ "$line" =~ "\|" ]] && [[ ! "$line" =~ " \| " ]]; then
                err "$(basename "$file"):$line_num: Pipe ohne Leerzeichen in fzf-Header"
                debug "  Verwende ' | ' mit Leerzeichen"
                ((errors++))
            fi
        fi
    done < "$file"
    
    return $errors
}

# ------------------------------------------------------------
# Hauptvalidierung
# ------------------------------------------------------------
validate_style_consistency() {
    log "Prüfe Code-Stil Konsistenz..."
    
    local alias_dir="$TERMINAL_DIR/.config/alias"
    local config_dir="$TERMINAL_DIR/.config"
    local total_errors=0
    local file_errors=0
    
    # Prüfe alle .alias Dateien
    for alias_file in "$alias_dir"/*.alias(N); do
        [[ -f "$alias_file" ]] || continue
        file_errors=0
        
        check_metadata_padding "$alias_file"
        ((file_errors += $?))
        
        check_guard_format "$alias_file"
        ((file_errors += $?))
        
        check_fzf_headers "$alias_file"
        ((file_errors += $?))
        
        check_section_separators "$alias_file"
        ((file_errors += $?))
        
        if ((file_errors == 0)); then
            debug "  ✓ $(basename "$alias_file")"
        fi
        
        ((total_errors += file_errors))
    done
    
    # Prüfe fzf/config
    local fzf_config="$config_dir/fzf/config"
    if [[ -f "$fzf_config" ]]; then
        file_errors=0
        
        check_metadata_padding "$fzf_config"
        ((file_errors += $?))
        
        check_fzf_headers "$fzf_config"
        ((file_errors += $?))
        
        if ((file_errors == 0)); then
            debug "  ✓ fzf/config"
        fi
        
        ((total_errors += file_errors))
    fi
    
    # Zusammenfassung
    if ((total_errors == 0)); then
        ok "Alle Dateien folgen dem Stil-Standard"
    else
        err "$total_errors Stil-Verletzungen gefunden"
    fi
    
    return $((total_errors > 0 ? 1 : 0))
}

register_validator "style-consistency" "validate_style_consistency" "Code-Stil Konsistenz" "extended"
