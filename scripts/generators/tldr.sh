#!/usr/bin/env zsh
# ============================================================
# tldr.sh - Generator für tldr-Patches
# ============================================================
# Zweck   : Generiert tldr-Patches aus .alias-Dateien
# Pfad    : scripts/generators/tldr.sh
# Hinweis : Ersetzt scripts/generate-tldr-patches.sh
# ============================================================

source "${0:A:h}/lib.sh"

# ------------------------------------------------------------
# Parser: Keybindings zu tldr-Format
# ------------------------------------------------------------
# Eingabe: Enter=Öffnen, Ctrl+S=man↔tldr
# Ausgabe: (`<Enter>` Öffnen, `<Ctrl s>` man↔tldr)
format_keybindings_for_tldr() {
    local keybindings="$1"
    [[ -z "$keybindings" ]] && return
    
    # Prüfe ob überhaupt Keybindings vorhanden sind
    case "$keybindings" in
        *Enter* | *Tab* | *Ctrl* | *Shift* | *Alt* | *Esc*) ;;
        *) return ;;
    esac
    
    local result=""
    local IFS=','
    
    for binding in ${=keybindings}; do
        binding="${binding## }"
        binding="${binding%% }"
        
        [[ "$binding" != *"="* ]] && continue
        
        local key="${binding%%=*}"
        local action="${binding#*=}"
        
        case "$key" in
            Enter | Tab | Esc | Ctrl+* | Shift+* | Alt+*) ;;
            *) continue ;;
        esac
        
        key="${key//+/ }"
        if [[ "$key" == *" "* ]]; then
            local modifier="${key%% *}"
            local letter="${key##* }"
            [[ "$letter" == [A-Za-z] ]] && key="${modifier} ${(L)letter}"
        fi
        
        [[ -n "$result" ]] && result+=", "
        result+="\`<${key}>\` ${action}"
    done
    
    [[ -n "$result" ]] && echo "($result)"
}

# ------------------------------------------------------------
# Parser: Parameter zu tldr-Format
# ------------------------------------------------------------
format_param_for_tldr() {
    local param="$1"
    [[ -z "$param" ]] && return
    
    param="${param%%\?}"
    param="${param%%=*}"
    
    echo "{{${param}}}"
}

# ------------------------------------------------------------
# Parser: fzf/config globale Keybindings
# ------------------------------------------------------------
parse_fzf_config_keybindings() {
    local config="$1"
    local output=""
    local prev_comment=""
    
    while IFS= read -r line; do
        if [[ "$line" == "# Ctrl"*":"* || "$line" == "# Alt"*":"* ]]; then
            prev_comment="${line#\# }"
        elif [[ "$line" == "--bind="* && -n "$prev_comment" ]]; then
            local key="${prev_comment%% :*}"
            local action="${prev_comment#*: }"
            
            key="${key//+/ }"
            if [[ "$key" == *" "* ]]; then
                local modifier="${key%% *}"
                local letter="${key##* }"
                [[ "$letter" =~ ^[A-Za-z]+$ ]] && letter="${(L)letter}"
                key="${modifier} ${letter}"
            fi
            
            output+="- dotfiles: ${action}:\n\n\`<${key}>\`\n\n"
            prev_comment=""
        else
            prev_comment=""
        fi
    done < "$config"
    
    output+="- dotfiles: Einzelnen Eintrag zur Auswahl hinzufügen:\n\n\`<Tab>\`\n\n"
    
    echo -e "$output"
}

# ------------------------------------------------------------
# Parser: Shell-Keybindings aus fzf.alias Header
# ------------------------------------------------------------
parse_shell_keybindings() {
    local file="$1"
    local output=""
    local in_section=false
    
    while IFS= read -r line; do
        [[ "$line" == *"Shell-Keybindings"* ]] && { in_section=true; continue; }
        [[ "$in_section" == true && "$line" == "# ----"* ]] && continue
        [[ "$in_section" == true && "$line" == *"ZOXIDE"* ]] && break
        
        if [[ "$in_section" == true && "$line" == "# Ctrl+X "* ]]; then
            local rest="${line#\# Ctrl+X }"
            local num="${rest%%:*}"
            local desc="${rest#*: }"
            output+="- dotfiles: ${desc}:\n\n\`<Ctrl x> ${num}\`\n\n"
        fi
    done < "$file"
    
    echo -e "$output"
}

# ------------------------------------------------------------
# Parser: Cross-Referenzen aus Header-Block
# ------------------------------------------------------------
parse_cross_references() {
    local file="$1"
    local output=""
    
    while IFS= read -r line; do
        [[ "$line" == "# Guard"* ]] && break
        
        if [[ "$line" == *".alias"*"→"* ]]; then
            local temp="${line#*- }"
            local tool="${temp%%.alias*}"
            tool="${tool// /}"
            
            local after_arrow="${line#*→ }"
            local funcs="$after_arrow"
            while [[ "$funcs" == *'('*')'* ]]; do
                funcs="${funcs%%\(*}${funcs#*\)}"
            done
            funcs="${funcs// /}"
            
            [[ -n "$tool" && -n "$funcs" ]] && output+="${tool}|${funcs}\n"
        fi
    done < "$file"
    
    echo -e "$output"
}

# ------------------------------------------------------------
# Generator: Patch für eine .alias Datei
# ------------------------------------------------------------
generate_patch_for_alias() {
    local alias_file="$1"
    local output=""
    local prev_comment=""
    
    while IFS= read -r line; do
        local trimmed="${line#"${line%%[![:space:]]*}"}"
        
        if [[ "$trimmed" == \#* && "$trimmed" != \#\ ----* && "$trimmed" != \#\ ====* ]]; then
            local content="${trimmed#\# }"
            local first_word="${content%% *}"
            
            if [[ "$content" == *" – "* || "$content" == *" - "* ]]; then
                case "$first_word" in
                    Zweck|Hinweis|Pfad|Docs|Guard|Voraussetzung|Nutzt) prev_comment="" ;;
                    *) prev_comment="$content" ;;
                esac
            else
                # Einfacher Kommentar ohne Trennzeichen
                prev_comment="$content"
            fi
            continue
        fi
        
        # Funktionen: func() {
        if [[ "$trimmed" =~ ^[a-zA-Z][a-zA-Z0-9_-]*\(\)\ \{ ]]; then
            local func_name="${trimmed%%\(*}"
            
            [[ "$func_name" == _* ]] && { prev_comment=""; continue; }
            
            if [[ -n "$prev_comment" ]]; then
                local parsed=$(parse_description_comment "$prev_comment")
                local name="${parsed%%|*}"
                local rest="${parsed#*|}"
                local param="${rest%%|*}"
                local keybindings="${rest#*|}"
                keybindings="${keybindings%%|*}"
                
                local tldr_param=$(format_param_for_tldr "$param")
                local tldr_keys=$(format_keybindings_for_tldr "$keybindings")
                
                output+="- dotfiles: ${name}"
                [[ -n "$tldr_keys" ]] && output+=" ${tldr_keys}"
                output+=":\n\n"
                output+="\`${func_name}"
                [[ -n "$tldr_param" ]] && output+=" ${tldr_param}"
                output+="\`\n\n"
            fi
            
            prev_comment=""
        fi
        
        # Aliase: alias name='command'
        if [[ "$trimmed" =~ ^alias[[:space:]]+[a-zA-Z][a-zA-Z0-9_-]*= ]]; then
            local alias_def="${trimmed#alias }"
            local alias_name="${alias_def%%=*}"
            
            if [[ -n "$prev_comment" ]]; then
                output+="- dotfiles: ${prev_comment}:\n\n"
                output+="\`${alias_name}\`\n\n"
            fi
            
            prev_comment=""
        fi
    done < "$alias_file"
    
    echo -e "$output"
}

# ------------------------------------------------------------
# Generator: Cross-Referenzen für fzf.patch.md
# ------------------------------------------------------------
generate_cross_references() {
    local fzf_alias="$ALIAS_DIR/fzf.alias"
    local output=""
    
    local refs=$(parse_cross_references "$fzf_alias")
    
    while IFS='|' read -r tool funcs; do
        [[ -z "$tool" ]] && continue
        output+="- dotfiles: Siehe \`tldr ${tool}\` für \`${funcs//,/\`, \`}\`\n"
    done <<< "$refs"
    
    echo -e "$output"
}

# ------------------------------------------------------------
# Generator: Kompletter Patch für ein Tool
# ------------------------------------------------------------
generate_complete_patch() {
    local tool_name="$1"
    local alias_file="$ALIAS_DIR/${tool_name}.alias"
    local output=""
    
    [[ ! -f "$alias_file" ]] && { err "Alias-Datei nicht gefunden: $alias_file"; return 1; }
    
    if [[ "$tool_name" == "fzf" ]]; then
        output+="# dotfiles: Globale Tastenkürzel (in allen fzf-Dialogen)\n\n"
        output+=$(parse_fzf_config_keybindings "$FZF_CONFIG")
        output+="\n# dotfiles: Funktionen (aus fzf.alias)\n\n"
    fi
    
    output+=$(generate_patch_for_alias "$alias_file")
    
    if [[ "$tool_name" == "fzf" ]]; then
        output+="\n# dotfiles: Shell-Keybindings (Ctrl+X Prefix)\n\n"
        output+=$(parse_shell_keybindings "$alias_file")
        output+="\n# dotfiles: Tool-spezifische fzf-Funktionen\n\n"
        output+=$(generate_cross_references)
    fi
    
    echo -e "$output"
}

# ------------------------------------------------------------
# Öffentliche Funktion: Alle tldr-Patches generieren/prüfen
# ------------------------------------------------------------
generate_tldr_patches() {
    local mode="${1:---check}"
    local errors=0
    
    case "$mode" in
        --check)
            for alias_file in "$ALIAS_DIR"/*.alias(N); do
                local tool_name=$(basename "$alias_file" .alias)
                local patch_file="$TEALDEER_DIR/${tool_name}.patch.md"
                local page_file="$TEALDEER_DIR/${tool_name}.page.md"
                
                # Überspringe wenn eine .page.md existiert (vollständig eigene Seite)
                [[ -f "$page_file" ]] && continue
                
                [[ ! -f "$patch_file" ]] && continue
                
                local generated=$(generate_complete_patch "$tool_name")
                local current=$(cat "$patch_file")
                
                if [[ "$generated" != "$current" ]]; then
                    err "${tool_name}.patch.md ist veraltet"
                    (( errors++ )) || true
                fi
            done
            
            return $errors
            ;;
            
        --generate)
            for alias_file in "$ALIAS_DIR"/*.alias(N); do
                local tool_name=$(basename "$alias_file" .alias)
                local patch_file="$TEALDEER_DIR/${tool_name}.patch.md"
                local page_file="$TEALDEER_DIR/${tool_name}.page.md"
                
                # Überspringe wenn eine .page.md existiert (vollständig eigene Seite)
                [[ -f "$page_file" ]] && continue
                
                local generated=$(generate_complete_patch "$tool_name")
                
                local trimmed="${generated//[[:space:]]/}"
                if [[ -z "$trimmed" ]]; then
                    [[ -f "$patch_file" ]] && rm "$patch_file"
                    continue
                fi
                
                write_if_changed "$patch_file" "$generated"
            done
            ;;
    esac
}

# Nur ausführen wenn direkt aufgerufen (nicht gesourct)
[[ -z "${_SOURCED_BY_GENERATOR:-}" ]] && generate_tldr_patches "$@" || true
