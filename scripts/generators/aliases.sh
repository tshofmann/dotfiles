#!/usr/bin/env zsh
# ============================================================
# aliases.sh - Generator für Alias-Tabellen
# ============================================================
# Zweck   : Generiert Alias-Tabellen aus *.alias-Dateien
# Aufruf  : source generators/aliases.sh && generate_alias_sections
# ============================================================

[[ -z "${GENERATOR_LIB_LOADED:-}" ]] && source "${0:A:h}/lib.sh"

# Generiert Alias-Tabellen für alle *.alias Dateien
generate_alias_sections() {
    local target_file="${1:-$DOCS_DIR/tools.md}"
    
    [[ ! -f "$target_file" ]] && { warn "Datei nicht gefunden: $target_file"; return 1; }
    
    log "Generiere Alias-Tabellen aus $ALIAS_DIR..."
    
    local alias_file base_name section_name
    local -i generated=0
    
    for alias_file in "$ALIAS_DIR"/*.alias(N); do
        [[ -f "$alias_file" ]] || continue
        
        base_name=$(basename "$alias_file" .alias)
        section_name="ALIASES_${base_name:u}"
        
        debug "Verarbeite: $base_name.alias → $section_name"
        
        # Extrahiere Aliase
        local -a alias_lines=($(extract_alias_table "$alias_file"))
        
        # Extrahiere Funktionen (für Dateien mit interaktiven Funktionen)
        local -a func_lines=($(extract_function_table "$alias_file"))
        
        # Baue vollständige Tabelle
        local content=""
        
        if (( ${#alias_lines[@]} > 0 )); then
            content+="| Alias | Befehl | Beschreibung |\n"
            content+="|-------|--------|--------------|\n"
            for line in "${alias_lines[@]}"; do
                content+="$line\n"
            done
        fi
        
        # Füge Funktions-Tabelle hinzu wenn vorhanden
        if (( ${#func_lines[@]} > 0 )); then
            [[ -n "$content" ]] && content+="\n**Interaktive Funktionen (mit fzf):**\n\n"
            content+="| Funktion | Beschreibung |\n"
            content+="|----------|--------------|\n"
            for line in "${func_lines[@]}"; do
                content+="$line\n"
            done
        fi
        
        # Ersetze Marker wenn vorhanden
        if grep -q "<!-- BEGIN:GENERATED:${section_name} -->" "$target_file" 2>/dev/null; then
            replace_marked_section "$target_file" "$section_name" "$content"
            (( generated++ )) || true
        else
            debug "Keine Marker für $section_name in $target_file"
        fi
    done
    
    if (( generated > 0 )); then
        ok "Generiert: $generated Alias-Sektionen"
    else
        warn "Keine Marker gefunden – Dokumentation muss manuell vorbereitet werden"
    fi
}
