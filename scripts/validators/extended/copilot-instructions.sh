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
    # Prüfe ob die dokumentierte Syntax im Code vorkommt
    local doc_guard=$(grep "Guard-Check" "$instructions_file" | grep -o '`[^`]*`' | head -1 | tr -d '`')
    
    if [[ -n "$doc_guard" ]]; then
        # Extrahiere das Pattern ohne tool-spezifischen Namen
        # Docs: "if ! command -v tool >/dev/null 2>&1; then return 0; fi"
        # Code: "if ! command -v bat >/dev/null 2>&1; then"
        if ! grep -q "if ! command -v .* >/dev/null 2>&1; then" "$DOTFILES_DIR/terminal/.config/alias/bat.alias"; then
            err "Guard-Check Syntax im Code weicht von Dokumentation ab"
            (( errors++ )) || true
        fi
        # Prüfe ob return 0 auch im Code ist
        if ! grep -q "return 0" "$DOTFILES_DIR/terminal/.config/alias/bat.alias"; then
            err "Guard-Check: 'return 0' fehlt im Code"
            (( errors++ )) || true
        fi
    fi
    
    # 2. Prüfe ob CONTRIBUTING.md Verweis existiert
    if ! grep -q "CONTRIBUTING.md" "$instructions_file"; then
        err "Kein Verweis auf CONTRIBUTING.md in copilot-instructions"
        (( errors++ )) || true
    fi
    
    # 3. Prüfe ob fzf-Shell-Verhalten korrekt dokumentiert ist
    # MUSS $SHELL erwähnen (nicht /bin/sh als Default)
    if ! grep -q '\$SHELL' "$instructions_file"; then
        err "fzf-Shell-Dokumentation unvollständig: \$SHELL muss erwähnt werden"
        (( errors++ )) || true
    fi
    # Wenn /bin/sh erwähnt wird, muss es im Kontext von Fallback sein, nicht als Default
    if grep -q 'fzf.*nutzt.*/bin/sh' "$instructions_file" || grep -q 'fzf.*defaults.*/bin/sh' "$instructions_file"; then
        err "fzf-Shell-Dokumentation falsch: fzf nutzt \$SHELL -c, nicht /bin/sh"
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
