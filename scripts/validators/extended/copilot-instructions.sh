# ============================================================
# copilot-instructions.sh - Validator für Copilot Instructions
# ============================================================
# Prüft Konsistenz zwischen .github/copilot-instructions.md
# und dem tatsächlichen Code/Dokumentation
# ============================================================

validate_copilot_instructions() {
    local errors=0
    local instructions_file="$DOTFILES_DIR/.github/copilot-instructions.md"
    
    [[ -f "$instructions_file" ]] || {
        warn "copilot-instructions.md nicht gefunden"
        return 1
    }
    
    info "Prüfe Copilot Instructions Konsistenz..."
    
    # 1. Guard-Check Syntax muss mit Code übereinstimmen
    local code_guard=$(head -20 "$DOTFILES_DIR/terminal/.config/alias/bat.alias" | grep -A2 "^# Guard" | grep "command -v" | head -1)
    local doc_guard=$(grep "Guard-Check" "$instructions_file" | grep -o '`[^`]*`' | head -1 | tr -d '`')
    
    if [[ -n "$code_guard" && -n "$doc_guard" ]]; then
        # Normalisiere für Vergleich (entferne führende Whitespaces)
        code_guard="${code_guard#"${code_guard%%[![:space:]]*}"}"
        if [[ "$code_guard" != *"$doc_guard"* && "$doc_guard" != *"command -v"* ]]; then
            err "Guard-Check in Instructions stimmt nicht mit Code überein"
            err "  Code: $code_guard"
            err "  Docs: $doc_guard"
            (( errors++ )) || true
        fi
    fi
    
    # 2. Prüfe ob CONTRIBUTING.md Verweis existiert
    if ! grep -q "CONTRIBUTING.md" "$instructions_file"; then
        err "Kein Verweis auf CONTRIBUTING.md in copilot-instructions"
        (( errors++ )) || true
    fi
    
    # 3. Prüfe ob fzf-Shell-Verhalten korrekt dokumentiert ist
    if grep -q '/bin/sh' "$instructions_file" && ! grep -q '\$SHELL' "$instructions_file"; then
        err "fzf-Shell-Dokumentation falsch: fzf nutzt \$SHELL, nicht /bin/sh"
        (( errors++ )) || true
    fi
    
    # 4. Prüfe ob Arithmetik-Pattern dokumentiert ist (wichtig für set -e)
    if ! grep -q '|| true' "$instructions_file"; then
        warn "Arithmetik-Pattern (|| true) nicht dokumentiert"
    fi
    
    # 5. Prüfe Konsistenz-Prinzip ist dokumentiert
    if ! grep -qi 'konsistenz' "$instructions_file"; then
        err "Konsistenz-Prinzip nicht dokumentiert"
        (( errors++ )) || true
    fi
    
    if (( errors > 0 )); then
        err "Copilot Instructions haben $errors Inkonsistenz(en)"
        return 1
    fi
    
    ok "Copilot Instructions sind konsistent"
    return 0
}

# Registrierung
register_validator "copilot-instructions" "validate_copilot_instructions" "Copilot Instructions Konsistenz"
