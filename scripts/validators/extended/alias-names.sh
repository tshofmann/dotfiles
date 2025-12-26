#!/usr/bin/env zsh
# ============================================================
# alias-names.sh - Alias-Namen Validierung
# ============================================================
# Prüft: Dokumentierte Aliase vs tatsächlich definierte
# ============================================================

# Source lib.sh wenn noch nicht geladen
if [[ -z "${VALIDATOR_LIB_LOADED:-}" ]]; then
    source "${0:A:h:h}/lib.sh"
fi

# ------------------------------------------------------------
# Alias-Tool Mapping: Welcher Code definiert welche Aliase
# ------------------------------------------------------------
# Format: tool_name:docs_section:code_file
typeset -gA ALIAS_MAPPINGS=(
    [ripgrep]="ripgrep:ripgrep.alias"
    [fd]="fd:fd.alias"
    [eza]="eza:eza.alias"
    [bat]="bat:bat.alias"
    [fzf]="fzf:fzf.alias"
    [btop]="btop:btop.alias"
    [homebrew]="homebrew:homebrew.alias"
    [zoxide]="zoxide:eza.alias"
)

# ------------------------------------------------------------
# Validierung: Dokumentierte Aliase existieren im Code
# ------------------------------------------------------------
validate_alias_names() {
    local tools_md="$DOCS_DIR/tools.md"
    local errors=0
    
    [[ -f "$tools_md" ]] || { err "tools.md nicht gefunden"; return 1; }
    
    log "Prüfe Alias-Definitionen gegen Dokumentation..."
    
    # Lade alle Definitionen
    load_all_definitions
    
    # Erstelle kombinierte Liste aller gültigen Befehle
    local -a all_valid_commands=("${ALL_ALIASES[@]}" "${ALL_FUNCTIONS[@]}")
    
    # Standard-Shell-Befehle hinzufügen (die nicht als Alias definiert sind)
    local -a shell_builtins=(
        cd ls cat grep sed awk find xargs head tail sort uniq
        echo print printf mkdir rm cp mv ln chmod chown
        git docker kubectl npm node python pip brew
        man which type whereis file stat du df
        z zi  # zoxide Basis-Befehle
        rg fd bat eza btop fzf  # CLI-Tools selbst
        nvim vim code  # Editoren
    )
    all_valid_commands+=("${shell_builtins[@]}")
    
    # Deduplizieren
    all_valid_commands=(${(u)all_valid_commands})
    
    debug "Gültige Befehle gesamt: ${#all_valid_commands[@]}"
    
    # Extrahiere dokumentierte Aliase aus tools.md Tabellen
    local -a doc_aliases=()
    
    # Ripgrep Aliase
    local -a rg_doc=($(extract_aliases_from_docs "$tools_md" "ripgrep"))
    doc_aliases+=("${rg_doc[@]}")
    
    # fd Aliase
    local -a fd_doc=($(extract_aliases_from_docs "$tools_md" "fd"))
    doc_aliases+=("${fd_doc[@]}")
    
    # eza Aliase
    local -a eza_doc=($(extract_aliases_from_docs "$tools_md" "eza"))
    doc_aliases+=("${eza_doc[@]}")
    
    # bat Aliase
    local -a bat_doc=($(extract_aliases_from_docs "$tools_md" "bat"))
    doc_aliases+=("${bat_doc[@]}")
    
    # btop Aliase
    local -a btop_doc=($(extract_aliases_from_docs "$tools_md" "btop"))
    doc_aliases+=("${btop_doc[@]}")
    
    # homebrew Aliase
    local -a brew_doc=($(extract_aliases_from_docs "$tools_md" "homebrew"))
    doc_aliases+=("${brew_doc[@]}")
    
    # Deduplizieren
    doc_aliases=(${(u)doc_aliases})
    
    info "Gefundene dokumentierte Aliase: ${#doc_aliases[@]}"
    debug "Aliase: ${doc_aliases[*]}"
    
    # Prüfe jeden dokumentierten Alias
    local -a missing_aliases=()
    for alias_name in "${doc_aliases[@]}"; do
        if [[ ! " ${all_valid_commands[*]} " =~ " ${alias_name} " ]]; then
            missing_aliases+=("$alias_name")
        fi
    done
    
    if (( ${#missing_aliases[@]} > 0 )); then
        err "Dokumentierte Aliase ohne Code-Definition:"
        for alias_name in "${missing_aliases[@]}"; do
            print "   ${RED}→${NC} $alias_name"
            ((errors++))
        done
    else
        ok "Alle dokumentierten Aliase existieren im Code"
    fi
    
    # Prüfe auch umgekehrt: Undokumentierte Aliase
    local -a undocumented=()
    for alias_name in "${ALL_ALIASES[@]}"; do
        # Ignoriere interne/private Aliase (mit Underscore)
        [[ "$alias_name" == _* ]] && continue
        
        if [[ ! " ${doc_aliases[*]} " =~ " ${alias_name} " ]]; then
            undocumented+=("$alias_name")
        fi
    done
    
    if (( ${#undocumented[@]} > 0 )); then
        warn "Undokumentierte Aliase gefunden (${#undocumented[@]}):"
        for alias_name in "${undocumented[@]}"; do
            print "   ${YELLOW}→${NC} $alias_name"
        done
    else
        ok "Keine undokumentierten Aliase"
    fi
    
    return $errors
}

# ------------------------------------------------------------
# Validierung: FZF-Funktionen
# ------------------------------------------------------------
validate_fzf_functions() {
    local tools_md="$DOCS_DIR/tools.md"
    local fzf_alias="$ALIAS_DIR/fzf.alias"
    local errors=0
    
    [[ -f "$tools_md" ]] || { err "tools.md nicht gefunden"; return 1; }
    [[ -f "$fzf_alias" ]] || { err "fzf.alias nicht gefunden"; return 1; }
    
    log "Prüfe FZF-Funktionen..."
    
    # Extrahiere Funktionen aus Code
    local -a code_functions=($(extract_functions_from_file "$fzf_alias"))
    
    # Extrahiere dokumentierte Funktionen aus dem gesamten fzf-Bereich
    # Die FZF-Funktionen sind unter "### fzf.alias" dokumentiert
    local -a doc_functions=()
    
    # Alle FZF-Funktions-Tabellen durchsuchen
    local in_fzf_section=false
    while IFS= read -r line; do
        # Prüfe ob wir in der fzf.alias-Sektion sind
        if [[ "$line" == "### fzf.alias"* ]]; then
            in_fzf_section=true
            continue
        fi
        # Beende bei nächster ###-Sektion (aber nicht bei ####)
        if [[ "$line" == "### "* ]] && [[ "$line" != "### fzf"* ]] && $in_fzf_section; then
            break
        fi
        # Extrahiere Funktionsnamen aus Tabellenzeilen
        if $in_fzf_section && [[ "$line" == "| \`"* ]]; then
            # Extrahiere Text zwischen erstem ` und zweitem `
            local func_name=$(echo "$line" | sed 's/^| `//' | sed 's/`.*//')
            # Entferne Parameter wie [query] oder [path]
            func_name=$(echo "$func_name" | awk '{print $1}')
            # Ignoriere leere oder zu kurze Namen und zi (zoxide builtin)
            if [[ -n "$func_name" ]] && [[ ${#func_name} -gt 1 ]] && [[ "$func_name" != "zi" ]]; then
                doc_functions+=("$func_name")
            fi
        fi
    done < "$tools_md"
    
    doc_functions=(${(u)doc_functions})
    
    info "FZF Code-Funktionen: ${#code_functions[@]}"
    info "FZF Dokumentierte Funktionen: ${#doc_functions[@]}"
    
    debug "Code: ${code_functions[*]}"
    debug "Docs: ${doc_functions[*]}"
    
    # Prüfe fehlende Dokumentation
    local -a undoc_funcs=()
    for func in "${code_functions[@]}"; do
        if [[ ! " ${doc_functions[*]} " =~ " ${func} " ]]; then
            undoc_funcs+=("$func")
        fi
    done
    
    if (( ${#undoc_funcs[@]} > 0 )); then
        warn "Undokumentierte FZF-Funktionen:"
        for func in "${undoc_funcs[@]}"; do
            print "   ${YELLOW}→${NC} $func"
        done
    else
        ok "Alle FZF-Funktionen sind dokumentiert"
    fi
    
    # Prüfe fehlende Implementation
    local -a missing_funcs=()
    for func in "${doc_functions[@]}"; do
        if [[ ! " ${code_functions[*]} " =~ " ${func} " ]]; then
            missing_funcs+=("$func")
        fi
    done
    
    if (( ${#missing_funcs[@]} > 0 )); then
        err "Dokumentierte FZF-Funktionen ohne Implementation:"
        for func in "${missing_funcs[@]}"; do
            print "   ${RED}→${NC} $func"
            ((errors++))
        done
    else
        ok "Alle dokumentierten FZF-Funktionen existieren"
    fi
    
    return $errors
}

# ------------------------------------------------------------
# Hauptfunktion für diesen Validator
# ------------------------------------------------------------
check_alias_names() {
    local total_errors=0
    local rc=0
    
    validate_alias_names
    rc=$?
    ((total_errors += rc)) || true
    
    print ""
    
    validate_fzf_functions
    rc=$?
    ((total_errors += rc)) || true
    
    return $total_errors
}

# Registrierung
register_validator "alias-names" "check_alias_names" "Alias-Namen Validierung" "extended"
