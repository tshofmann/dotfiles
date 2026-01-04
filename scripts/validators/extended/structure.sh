#!/usr/bin/env zsh
# ============================================================
# structure.sh - Verzeichnisstruktur Validierung
# ============================================================
# Prüft: Alle Dateien in terminal/ gegen architecture.md
# ============================================================
# Dynamisch: Scannt tatsächliche Dateien und vergleicht mit Doku
# ============================================================

[[ -z "${VALIDATOR_LIB_LOADED:-}" ]] && source "${0:A:h:h}/lib.sh"

check_structure() {
    log "Prüfe Verzeichnisstruktur in architecture.md..."
    
    local arch_doc="$DOTFILES_DIR/docs/architecture.md"
    local terminal_dir="$TERMINAL_DIR"
    local errors=0
    
    # ----------------------------------------------------
    # Extrahiere alle Dateinamen aus dem terminal/ Baum in architecture.md
    # Strategie: Suche alle Zeilen mit ├── oder └── die Dateien enthalten
    # ----------------------------------------------------
    local -a doc_files=()
    
    # Extrahiere den terminal/ Block
    local terminal_block=$(sed -n '/└── terminal\//,/^```$/p' "$arch_doc")
    
    # Parse jede Zeile und extrahiere Dateinamen
    echo "$terminal_block" | while IFS= read -r line; do
        # Nur Zeilen mit ├── oder └── 
        [[ "$line" != *[├└]──* ]] && continue
        
        # Extrahiere den Eintrag (entferne Kommentare und Baum-Zeichen)
        local entry=$(echo "$line" | sed 's/#.*//' | sed 's/.*[├└]── //' | sed 's/[[:space:]]*$//')
        
        # Überspringe leere und Verzeichnis-Einträge
        [[ -z "$entry" ]] && continue
        [[ "$entry" == */ ]] && continue
        
        # Speichere nur den Dateinamen (nicht den vollen Pfad)
        doc_files+=("$entry")
    done
    
    # Array aus Subshell zurückholen
    doc_files=($(echo "$terminal_block" | grep -E '[├└]──' | \
        sed 's/#.*//' | sed 's/.*[├└]── //' | sed 's/[[:space:]]*$//' | \
        grep -v '/$' | grep -v '^$'))
    
    # ----------------------------------------------------
    # Prüfung 1: Dokumentierte Dateien müssen irgendwo in terminal/ existieren
    # ----------------------------------------------------
    for doc_file in "${doc_files[@]}"; do
        # Überspringe Platzhalter-Kommentare wie "(10 Dateien)"
        [[ "$doc_file" == *"("* ]] && continue
        
        # Suche die Datei rekursiv in terminal/
        local found=$(find "$terminal_dir" -name "$doc_file" -type f 2>/dev/null | head -1)
        
        if [[ -z "$found" ]]; then
            err "architecture.md listet '$doc_file' aber existiert nicht in terminal/"
            (( errors++ )) || true
        fi
    done
    
    # ----------------------------------------------------
    # Prüfung 2: Wichtige Config-Dateien müssen dokumentiert sein
    # Scanne .config/fzf/ und .config/alias/ dynamisch
    # ----------------------------------------------------
    local -a critical_dirs=(".config/fzf" ".config/alias")
    
    for check_dir in "${critical_dirs[@]}"; do
        local dir_path="$terminal_dir/$check_dir"
        [[ ! -d "$dir_path" ]] && continue
        
        # Alle Dateien in diesem Verzeichnis (nicht rekursiv)
        for f in "$dir_path"/*(.N); do
            local filename=$(basename "$f")
            
            # Prüfe ob Dateiname in der Doku erwähnt wird
            if ! grep -q "$filename" "$arch_doc" 2>/dev/null; then
                err "Datei '$check_dir/$filename' existiert aber fehlt in architecture.md"
                (( errors++ )) || true
            fi
        done
    done
    
    if ((errors == 0)); then
        ok "terminal/ Struktur in architecture.md korrekt"
    fi
    
    return $errors
}

register_validator "structure" "check_structure" "Verzeichnisstruktur architecture.md" "extended"
