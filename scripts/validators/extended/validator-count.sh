#!/usr/bin/env zsh
# ============================================================
# validator-count.sh - Validator-Anzahl Validierung
# ============================================================
# Prüft: Anzahl der Validator-Module in architecture.md stimmt
#        mit tatsächlichen Dateien in validators/ überein
# ============================================================

[[ -z "${VALIDATOR_LIB_LOADED:-}" ]] && source "${0:A:h:h}/lib.sh"

check_validator_count() {
    log "Prüfe Validator-Anzahlen in architecture.md..."
    
    local arch_doc="$DOCS_DIR/architecture.md"
    local validators_dir="$DOTFILES_DIR/scripts/validators"
    local errors=0
    
    # Zähle tatsächliche Validator-Dateien
    local core_actual=$(find "$validators_dir/core" -name "*.sh" -type f | wc -l | tr -d ' ')
    local extended_actual=$(find "$validators_dir/extended" -name "*.sh" -type f | wc -l | tr -d ' ')
    
    # Extrahiere dokumentierte Anzahlen aus architecture.md
    # Format: "# Kern-Validierungen (8 Module)" oder "# Erweiterte Validierungen (7 Module)"
    local core_documented=$(grep -o "Kern-Validierungen ([0-9]* Module)" "$arch_doc" | grep -o "[0-9]*")
    local extended_documented=$(grep -o "Erweiterte Validierungen ([0-9]* Module)" "$arch_doc" | grep -o "[0-9]*")
    
    # Validiere Kern-Validierungen
    if [[ "$core_actual" != "$core_documented" ]]; then
        err "Kern-Validierungen: $core_actual Dateien, aber architecture.md sagt $core_documented"
        err "  → architecture.md → Verzeichnisstruktur → validators/core/ aktualisieren"
        (( errors++ )) || true
    else
        ok "Kern-Validierungen: $core_actual Module"
    fi
    
    # Validiere Extended-Validierungen
    if [[ "$extended_actual" != "$extended_documented" ]]; then
        err "Extended-Validierungen: $extended_actual Dateien, aber architecture.md sagt $extended_documented"
        err "  → architecture.md → Verzeichnisstruktur → validators/extended/ aktualisieren"
        (( errors++ )) || true
    else
        ok "Extended-Validierungen: $extended_actual Module"
    fi
    
    # Prüfe ob alle Dateien im Struktur-Baum gelistet sind
    local -a core_files=($(ls "$validators_dir/core/"*.sh 2>/dev/null | xargs -n1 basename))
    local -a extended_files=($(ls "$validators_dir/extended/"*.sh 2>/dev/null | xargs -n1 basename))
    
    for file in "${core_files[@]}"; do
        if ! grep -q "$file" "$arch_doc"; then
            err "validators/core/$file fehlt in architecture.md Struktur-Baum"
            (( errors++ )) || true
        fi
    done
    
    for file in "${extended_files[@]}"; do
        if ! grep -q "$file" "$arch_doc"; then
            err "validators/extended/$file fehlt in architecture.md Struktur-Baum"
            (( errors++ )) || true
        fi
    done
    
    if ((errors == 0)); then
        ok "Validator-Struktur in architecture.md korrekt"
    fi
    
    return $errors
}

# Registriere den Validator
register_validator "validator-count" "check_validator_count" "extended"
