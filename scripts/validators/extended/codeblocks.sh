#!/usr/bin/env zsh
# ============================================================
# codeblocks.sh - Code-Beispiele Validierung
# ============================================================
# Prüft: Befehle in Markdown-Codeblöcken auf Gültigkeit
# ============================================================

# Source lib.sh wenn noch nicht geladen
if [[ -z "${VALIDATOR_LIB_LOADED:-}" ]]; then
    source "${0:A:h:h}/lib.sh"
fi

# ------------------------------------------------------------
# Validierung: Befehle in Code-Blöcken
# ------------------------------------------------------------
validate_codeblock_commands() {
    local file="$1"
    local errors=0
    
    [[ -f "$file" ]] || { err "Datei nicht gefunden: $file"; return 1; }
    
    log "Prüfe Code-Blöcke in ${file:t}..."
    
    # Lade alle gültigen Definitionen
    load_all_definitions
    
    # Kombinierte Liste aller gültigen Befehle
    local -a all_valid=("${ALL_ALIASES[@]}" "${ALL_FUNCTIONS[@]}")
    
    # Standard-Befehle
    local -a standard_cmds=(
        # Shell built-ins
        cd ls cat grep sed awk find xargs head tail sort uniq wc
        echo print printf mkdir rm cp mv ln chmod chown touch
        source export alias type which whereis file stat du df
        read test true false exit return set
        
        # macOS/Unix tools
        open pbcopy pbpaste say osascript defaults sw_vers
        curl wget ssh scp rsync tar zip unzip gzip
        ps kill pkill top htop man less more
        
        # Version control
        git gh
        
        # Package managers
        brew npm yarn pip pip3 cargo gem
        
        # Runtimes/Languages
        node python python3 ruby perl php java
        
        # CLI tools (installed via Brewfile)
        rg fd bat eza btop fzf delta tldr jq yq
        z zi zoxide
        nvim vim code
        starship
        docker kubectl
        mas stow
    )
    all_valid+=("${standard_cmds[@]}")
    all_valid=(${(u)all_valid})
    
    # Extrahiere Befehle aus Shell-Code-Blöcken
    local in_shell_block=false
    local line_num=0
    local -a unknown_commands=()
    
    while IFS= read -r line; do
        ((line_num++)) || true
        
        # Block-Start erkennen
        case "$line" in
            '```zsh'|'```bash'|'```sh'|'```shell')
                in_shell_block=true
                continue
                ;;
            '```'*)
                # Anderer Block-Typ (ruby, json, etc.)
                in_shell_block=false
                continue
                ;;
            '```')
                # Block-Ende
                in_shell_block=false
                continue
                ;;
        esac
        
        # Nur Shell-Blöcke verarbeiten
        $in_shell_block || continue
        
        # Kommentare und leere Zeilen überspringen
        [[ "$line" == "#"* ]] && continue
        [[ "$line" == "  #"* ]] && continue
        [[ -z "${line// /}" ]] && continue
        
        # Ersten Befehl extrahieren
        local cmd="${line%%[|;&<>]*}"
        cmd="${cmd##[[:space:]]}"
        cmd="${cmd%%[[:space:]]*}"
        
        # Leere Befehle überspringen
        [[ -z "$cmd" ]] && continue
        
        # Variablen-Zuweisungen überspringen
        [[ "$cmd" == *"="* ]] && continue
        
        # Optionen überspringen
        [[ "$cmd" == "-"* ]] && continue
        
        # Shell-Variablen überspringen
        [[ "$cmd" == '$'* ]] && continue
        
        # Pfade überspringen
        [[ "$cmd" == "."* ]] && continue
        [[ "$cmd" == "/"* ]] && continue
        [[ "$cmd" == "~"* ]] && continue
        
        # Prüfe ob Befehl bekannt ist
        local is_known=false
        for valid_cmd in "${all_valid[@]}"; do
            if [[ "$cmd" == "$valid_cmd" ]]; then
                is_known=true
                break
            fi
        done
        
        if ! $is_known; then
            unknown_commands+=("$line_num:$cmd")
        fi
    done < "$file"
    
    if (( ${#unknown_commands[@]} > 0 )); then
        warn "Möglicherweise unbekannte Befehle in Shell-Blöcken:"
        for entry in "${unknown_commands[@]}"; do
            local num="${entry%%:*}"
            local cmd="${entry#*:}"
            print "   ${YELLOW}Zeile $num:${NC} $cmd"
        done
        info "Hinweis: Diese könnten externe Tools sein, bitte manuell prüfen"
    else
        ok "Alle Befehle in Code-Blöcken sind bekannt"
    fi
    
    return 0
}

# ------------------------------------------------------------
# Hauptfunktion für diesen Validator
# ------------------------------------------------------------
check_codeblocks() {
    local tools_md="$DOCS_DIR/tools.md"
    validate_codeblock_commands "$tools_md"
}

# Registrierung
register_validator "codeblocks" "check_codeblocks" "Code-Block Validierung" "extended"
