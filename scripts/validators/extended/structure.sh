#!/usr/bin/env zsh
# ============================================================
# structure.sh - Verzeichnisstruktur Validierung
# ============================================================
# Prüft: terminal/ Dateien in CONTRIBUTING.md Struktur-Baum
# ============================================================

[[ -z "${VALIDATOR_LIB_LOADED:-}" ]] && source "${0:A:h:h}/lib.sh"

check_structure() {
    log "Prüfe Verzeichnisstruktur in CONTRIBUTING.md..."
    
    local contrib="$DOTFILES_DIR/CONTRIBUTING.md"
    local terminal_dir="$TERMINAL_DIR"
    local errors=0
    
    # Extrahiere terminal/ Einträge aus dem Struktur-Baum in CONTRIBUTING.md
    # Format: │   ├── .zshenv  oder │   ├── .gitconfig          # Kommentar
    # Entferne alles nach # (Kommentare) und extrahiere nur Dateinamen
    local -a doc_files
    doc_files=($(sed -n '/├── terminal\//,/└── docs\//p' "$contrib" | \
        grep -E '^\│[[:space:]]+[├└]── \.' | \
        sed 's/#.*//' | \
        sed 's/.*[├└]── //' | \
        sed 's/[[:space:]]*$//' | \
        grep -v '\.config'))
    
    # Prüfe ob jede tatsächliche Datei in terminal/ dokumentiert ist
    local -a actual_files
    actual_files=(.zshenv .zshrc .zprofile)
    
    for file in "${actual_files[@]}"; do
        if [[ -f "$terminal_dir/$file" ]]; then
            if ! grep -q "$file" <<< "${doc_files[*]}"; then
                err "terminal/$file existiert aber fehlt in CONTRIBUTING.md Struktur"
                ((errors++))
            fi
        fi
    done
    
    # Prüfe ob dokumentierte Dateien existieren
    for file in "${doc_files[@]}"; do
        [[ -z "$file" ]] && continue
        if [[ ! -f "$terminal_dir/$file" && ! -d "$terminal_dir/$file" ]]; then
            err "CONTRIBUTING.md listet terminal/$file aber existiert nicht"
            ((errors++))
        fi
    done
    
    if ((errors == 0)); then
        ok "terminal/ Struktur in CONTRIBUTING.md korrekt"
    fi
}

register_validator "structure" "check_structure" "Verzeichnisstruktur CONTRIBUTING.md" "extended"
