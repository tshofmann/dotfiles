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
    local alias_dir="$TERMINAL_DIR/.config/alias"
    local errors=0
    
    [[ -f "$tools_md" ]] || { err "tools.md nicht gefunden"; return 1; }
    
    log "Prüfe Alias-Definitionen gegen Dokumentation..."
    
    # Lade alle Definitionen
    load_all_definitions
    
    # Erstelle kombinierte Liste aller gültigen Befehle
    local -a all_valid_commands=("${ALL_ALIASES[@]}" "${ALL_FUNCTIONS[@]}")
    
    # Standard-Shell-Befehle und System-Tools hinzufügen
    local -a shell_builtins=(
        # Shell-Builtins
        cd ls cat grep sed awk find xargs head tail sort uniq wc
        echo print printf mkdir rm cp mv ln chmod chown touch
        source eval exec export set unset local typeset
        compinit autoload zstyle bindkey  # zsh-spezifisch
        # Entwickler-Tools
        git docker kubectl npm node python pip brew mas
        man which type whereis file stat du df ps kill
        # Navigation
        z zi zoxide  # zoxide Basis-Befehle
        # CLI-Tools (aus Brewfile)
        rg fd bat eza btop fzf gh stow fastfetch lazygit tldr starship
        # Editoren
        nvim vim vi code nano
        # macOS-spezifisch
        open pbcopy pbpaste defaults osascript
    )
    all_valid_commands+=("${shell_builtins[@]}")
    
    # Deduplizieren
    all_valid_commands=(${(u)all_valid_commands})
    
    debug "Gültige Befehle gesamt: ${#all_valid_commands[@]}"
    
    # DYNAMISCH: Extrahiere dokumentierte Aliase aus allen *.alias Dateien
    local -a doc_aliases=()
    local base_name section_name
    
    for alias_file in "$alias_dir"/*.alias(N); do
        [[ -f "$alias_file" ]] || continue
        base_name=$(basename "$alias_file" .alias)
        
        # Versuche den passenden Abschnitt in tools.md zu finden
        # Format: ### <name>.alias
        if grep -q "### ${base_name}.alias" "$tools_md" 2>/dev/null; then
            local -a tool_doc=($(extract_aliases_from_docs "$tools_md" "$base_name"))
            doc_aliases+=("${tool_doc[@]}")
            debug "Geladen aus $base_name.alias: ${#tool_doc[@]} Einträge"
        else
            debug "Kein Doku-Abschnitt für $base_name.alias gefunden"
        fi
    done
    
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
            (( errors++ )) || true
        done
    else
        ok "Alle dokumentierten Aliase existieren im Code"
    fi
    
    # Prüfe auch umgekehrt: Undokumentierte Aliase UND Funktionen
    local -a undocumented=()
    
    # Prüfe Aliase
    for alias_name in "${ALL_ALIASES[@]}"; do
        # Ignoriere interne/private Aliase (mit Underscore)
        [[ "$alias_name" == _* ]] && continue
        
        if [[ ! " ${doc_aliases[*]} " =~ " ${alias_name} " ]]; then
            undocumented+=("$alias_name")
        fi
    done
    
    # Prüfe auch Funktionen (außer die in fzf.alias, die werden separat geprüft)
    local fzf_funcs=($(extract_functions_from_file "$ALIAS_DIR/fzf.alias" 2>/dev/null))
    for func_name in "${ALL_FUNCTIONS[@]}"; do
        # Ignoriere interne/private Funktionen (mit Underscore)
        [[ "$func_name" == _* ]] && continue
        # Ignoriere fzf.alias Funktionen (werden separat geprüft)
        [[ " ${fzf_funcs[*]} " =~ " ${func_name} " ]] && continue
        
        if [[ ! " ${doc_aliases[*]} " =~ " ${func_name} " ]]; then
            undocumented+=("$func_name (Funktion)")
        fi
    done
    
    if (( ${#undocumented[@]} > 0 )); then
        err "Undokumentierte Aliase/Funktionen gefunden (${#undocumented[@]}):"
        for item in "${undocumented[@]}"; do
            print "   ${RED}→${NC} $item"
        done
        ((errors += ${#undocumented[@]}))
    else
        ok "Alle Aliase und Funktionen sind dokumentiert"
    fi
    
    return $errors
}

# ------------------------------------------------------------
# Validierung: FZF-Funktionen (nur generische in fzf.alias)
# Tool-spezifische fzf-Funktionen werden über validate_alias_names geprüft
# ------------------------------------------------------------
validate_fzf_functions() {
    local tools_md="$DOCS_DIR/tools.md"
    local fzf_alias="$ALIAS_DIR/fzf.alias"
    local errors=0
    
    [[ -f "$tools_md" ]] || { err "tools.md nicht gefunden"; return 1; }
    [[ -f "$fzf_alias" ]] || { err "fzf.alias nicht gefunden"; return 1; }
    
    log "Prüfe FZF-Funktionen..."
    
    # Extrahiere Funktionen aus fzf.alias Code
    local -a code_functions=($(extract_functions_from_file "$fzf_alias"))
    
    # Extrahiere nur die generischen FZF-Funktionen aus der Dokumentation
    # (Tabellen unter "Zoxide + fzf" und "System-Utilities")
    local -a doc_functions=()
    
    # Suche nur in fzf.alias-Sektion nach Tabellen
    local in_fzf_section=false
    local in_reference_section=false
    while IFS= read -r line; do
        # Prüfe ob wir in der fzf.alias-Sektion sind
        if [[ "$line" == "### fzf.alias"* ]]; then
            in_fzf_section=true
            continue
        fi
        # Beende bei nächster ###-Sektion
        if [[ "$line" == "### "* ]] && [[ "$line" != "### fzf"* ]] && $in_fzf_section; then
            break
        fi
        # Überspringe Referenz-Sektion (zeigt wo andere Funktionen sind)
        if [[ "$line" == *"Tool-spezifische"* ]]; then
            in_reference_section=true
            continue
        fi
        # Extrahiere Funktionsnamen aus Tabellenzeilen (aber nicht aus Referenz)
        if $in_fzf_section && ! $in_reference_section && [[ "$line" == "| \`"* ]]; then
            local func_name=$(echo "$line" | sed 's/^| `//' | sed 's/`.*//')
            func_name=$(echo "$func_name" | awk '{print $1}')
            # Ignoriere zi (zoxide builtin, nicht in fzf.alias)
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
            (( errors++ )) || true
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
