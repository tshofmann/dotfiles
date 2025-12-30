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
        # Prüfe alle Alias-Dateien die einen Guard-Check AM ANFANG haben
        # Pattern: "if ! command -v <tool> >/dev/null 2>&1; then ... return 0"
        local alias_dir="$DOTFILES_DIR/terminal/.config/alias"
        for alias_file in "$alias_dir"/*.alias; do
            [[ -f "$alias_file" ]] || continue
            local filename=$(basename "$alias_file")
            # Prüfe nur Dateien mit Guard-Check in den ersten 20 Zeilen (Header-Bereich)
            local header=$(head -20 "$alias_file")
            if echo "$header" | grep -q "^if ! command -v"; then
                if ! echo "$header" | grep -Eq 'if ! command -v [a-zA-Z0-9_-]+ >/dev/null 2>&1; then'; then
                    err "Guard-Check Syntax in $filename weicht von Dokumentation ab"
                    (( errors++ )) || true
                fi
                if ! echo "$header" | grep -q "return 0"; then
                    err "Guard-Check: 'return 0' fehlt in $filename"
                    (( errors++ )) || true
                fi
            fi
        done
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
    
    # 6. Prüfe ob Alias-Datei-Anzahl stimmt
    local actual_alias_count=$(ls "$DOTFILES_DIR/terminal/.config/alias/"*.alias 2>/dev/null | wc -l | tr -d ' ')
    if grep -Eq "alias.*\([0-9]+ Dateien\)" "$instructions_file"; then
        local doc_alias_count=$(grep -Eo "alias.*\([0-9]+ Dateien\)" "$instructions_file" | grep -Eo "[0-9]+")
        if [[ "$actual_alias_count" != "$doc_alias_count" ]]; then
            err "Alias-Datei-Anzahl veraltet: Docs=$doc_alias_count, Actual=$actual_alias_count"
            (( errors++ )) || true
        fi
    fi
    
    # 7. Prüfe ob Verweis auf Brewfile existiert (statt alle Tools zu listen)
    if ! grep -q "Brewfile" "$instructions_file"; then
        err "Kein Verweis auf Brewfile in Instructions"
        (( errors++ )) || true
    fi
    
    # 8. Prüfe ob Verweis auf architecture.md existiert
    if ! grep -q "architecture.md" "$instructions_file"; then
        err "Kein Verweis auf architecture.md in Instructions"
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
