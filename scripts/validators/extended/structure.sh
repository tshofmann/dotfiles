#!/usr/bin/env zsh
# ============================================================
# structure.sh - Verzeichnisstruktur Validierung
# ============================================================
# Zweck   : Prüft ob Dateisystem und architecture.md synchron sind
# Pfad    : scripts/validators/extended/structure.sh
# ============================================================
# Prüft bidirektional:
#   1. Dokumentierte Dateien → müssen im Filesystem existieren
#   2. Existierende Dateien → müssen in architecture.md sein
# ============================================================

[[ -z "${VALIDATOR_LIB_LOADED:-}" ]] && source "${0:A:h:h}/lib.sh"

# Deaktiviere errexit lokal (grep gibt Exit 1 bei no-match)
setopt localoptions noerrexit

# ------------------------------------------------------------
# Hauptvalidierung
# ------------------------------------------------------------
check_structure() {
    log "Prüfe Verzeichnisstruktur gegen architecture.md..."
    
    local arch_doc="$DOTFILES_DIR/docs/architecture.md"
    local errors=0
    
    # Konfiguration: Ignorierte Patterns und Aggregate-Verzeichnisse
    local -a ignored_patterns=(
        "*.theme"           # Theme-Dateien (btop, bat)
        "*.tmTheme"         # TextMate Themes
        "*.patch.md"        # Tealdeer Patches (eigener Validator)
    )
    local -a aggregate_dirs=(
        "terminal/.config/tealdeer/pages"
        "terminal/.config/btop/themes"
        "terminal/.config/bat/themes"
    )
    
    # Hilfsfunktion: Prüft ob ein Pfad ignoriert werden soll
    _should_ignore() {
        local path="$1"
        local filename="${path##*/}"
        
        for pattern in "${ignored_patterns[@]}"; do
            [[ "$filename" == ${~pattern} ]] && return 0
        done
        
        for agg_dir in "${aggregate_dirs[@]}"; do
            [[ "$path" == "$DOTFILES_DIR/$agg_dir/"* ]] && return 0
        done
        
        return 1
    }
    
    # ========================================================
    # PRÜFUNG 1: Dokumentierte Dateien müssen existieren
    # ========================================================
    # Extrahiere nur den Haupt-Baumblock (der mit "dotfiles/" beginnt)
    # bis zum Ende des Codeblocks (```)
    local tree_block=$(sed -n '/^dotfiles\/$/,/^```$/p' "$arch_doc")
    
    # Extrahiere Dateien aus der Baumstruktur
    # Format: "├── dateiname" oder "└── dateiname" (mit alphanumerischen Zeichen)
    local -a doc_files=()
    doc_files=($(echo "$tree_block" | grep -E '[├└]── [a-zA-Z0-9]' | \
        sed 's/#.*//' | \
        sed 's/.*[├└]── //' | \
        sed 's/[[:space:]]*$//' | \
        grep -v '/$' | \
        grep -v '^$' | \
        grep -v '(' ))
    
    for doc_file in "${doc_files[@]}"; do
        # Suche die Datei im gesamten Repository
        local found=$(find "$DOTFILES_DIR" -name "$doc_file" -type f 2>/dev/null | head -1)
        
        if [[ -z "$found" ]]; then
            err "architecture.md listet '$doc_file' aber existiert nicht"
            (( errors++ )) || true
        fi
    done
    
    # ========================================================
    # PRÜFUNG 2: Existierende Dateien müssen dokumentiert sein
    # ========================================================
    # Scanne alle relevanten Verzeichnisse vom Root aus
    local -a scan_dirs=(
        "$DOTFILES_DIR/setup"
        "$DOTFILES_DIR/scripts"
        "$DOTFILES_DIR/terminal"
        "$DOTFILES_DIR/docs"
    )
    
    for scan_dir in "${scan_dirs[@]}"; do
        [[ ! -d "$scan_dir" ]] && continue
        
        # Finde alle Dateien rekursiv
        while IFS= read -r filepath; do
            [[ -z "$filepath" ]] && continue
            
            # Prüfe ob ignoriert
            _should_ignore "$filepath" && continue
            
            local filename="${filepath##*/}"  # basename via Parameter Expansion
            local rel_path="${filepath#$DOTFILES_DIR/}"
            
            # Prüfe ob Dateiname in architecture.md erwähnt wird
            if ! grep -qF "$filename" "$arch_doc" 2>/dev/null; then
                err "Datei '$rel_path' existiert aber fehlt in architecture.md"
                (( errors++ )) || true
            fi
        done < <(find "$scan_dir" -type f 2>/dev/null)
    done
    
    # ========================================================
    # PRÜFUNG 3: Root-Dateien (README, LICENSE, etc.)
    # ========================================================
    for root_file in "$DOTFILES_DIR"/*(.N); do
        local filename="${root_file##*/}"  # basename via Parameter Expansion
        
        # Ignoriere versteckte Dateien
        [[ "$filename" == .* ]] && continue
        
        if ! grep -qF "$filename" "$arch_doc" 2>/dev/null; then
            err "Root-Datei '$filename' fehlt in architecture.md"
            (( errors++ )) || true
        fi
    done
    
    if ((errors == 0)); then
        ok "Verzeichnisstruktur und architecture.md synchron"
    fi
    
    return $errors
}

register_validator "structure" "check_structure" "Verzeichnisstruktur architecture.md" "extended"
