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
    
    # 6. Prüfe ob Alias-Datei-Anzahl stimmt
    local actual_alias_count=$(ls "$DOTFILES_DIR/terminal/.config/alias/"*.alias 2>/dev/null | wc -l | tr -d ' ')
    if grep -q "alias.*([0-9]* Dateien)" "$instructions_file"; then
        local doc_alias_count=$(grep -o "alias.*([0-9]* Dateien)" "$instructions_file" | grep -o "[0-9]*")
        if [[ "$actual_alias_count" != "$doc_alias_count" ]]; then
            err "Alias-Datei-Anzahl veraltet: Docs=$doc_alias_count, Actual=$actual_alias_count"
            (( errors++ )) || true
        fi
    fi
    
    # 7. Prüfe ob alle Brewfile-Tools erwähnt sind (Kern-CLI-Tools)
    local brewfile="$DOTFILES_DIR/setup/Brewfile"
    if [[ -f "$brewfile" ]]; then
        local missing_tools=()
        for tool in bat btop eza fd fzf gh ripgrep starship stow zoxide; do
            if grep -q "^brew \"$tool\"" "$brewfile" && ! grep -q "$tool" "$instructions_file"; then
                missing_tools+=("$tool")
            fi
        done
        if (( ${#missing_tools[@]} > 0 )); then
            err "Brewfile-Tools nicht in Instructions: ${missing_tools[*]}"
            (( errors++ )) || true
        fi
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
