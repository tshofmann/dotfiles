# ============================================================
# _help_parser.zsh - Parser-Hilfsfunktionen für Help-System
# ============================================================
# Zweck   : Parst Alias-Dateien und extrahiert Informationen
# Pfad    : ~/.config/functions/_help_parser.zsh
# Laden   : Wird von help.zsh geladen
# ============================================================

# Parse alias file and extract aliases with descriptions
# Format: name|command|description
_help_parse_aliases() {
    setopt local_options extended_glob
    
    local file="$1"
    [[ -f "$file" ]] || return 1
    
    local prev_comment=""
    local in_function=0
    local in_guard_if=0
    
    while IFS= read -r line; do
        # Skip empty lines and section headers
        [[ -z "$line" || "$line" =~ ^#\ =+ || "$line" =~ ^#\ -+ ]] && continue
        
        # Special handling for guard clauses (if ! command -v ...)
        if [[ "$line" =~ ^if\ !\ command\ -v ]]; then
            in_guard_if=1
            continue
        fi
        
        # Handle return statements in guards
        if [[ "$line" =~ ^[[:space:]]*return\ 0 ]]; then
            continue
        fi
        
        # End of guard if
        if [[ $in_guard_if -eq 1 ]] && { [[ "$line" == "fi" ]] || [[ "$line" =~ ^[[:space:]]*fi[[:space:]]*$ ]]; }; then
            in_guard_if=0
            continue
        fi
        
        # Detect function definitions - skip until closing brace (but not alias lines)
        if [[ "$line" =~ ^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*\(\) ]] && [[ ! "$line" =~ alias ]]; then
            in_function=1
            prev_comment=""
            continue
        fi
        
        # End of function blocks (closing brace)
        if [[ $in_function -eq 1 ]]; then
            if [[ "$line" == "}" ]] || [[ "$line" =~ ^[[:space:]]*\}[[:space:]]*$ ]]; then
                in_function=0
            fi
            continue
        fi
        
        # Extract single-line comments (only outside blocks)
        if [[ "$line" =~ ^#\ ([^=].+)$ ]]; then
            local comment="${match[1]}"
            # Skip section comments and documentation links
            if [[ ! "$comment" =~ ^(Zweck|Pfad|Docs|Hinweis|Guard|------------) ]]; then
                prev_comment="$comment"
            fi
        # Extract alias definitions
        elif [[ "$line" =~ ^[[:space:]]*alias\ +([^=]+)=(.+)$ ]]; then
            local name="${match[1]}"
            local cmd="${match[2]}"
            # Remove quotes from command
            cmd="${cmd#[\'\"]}"
            cmd="${cmd%[\'\"]}"
            echo "$name|$cmd|${prev_comment:-}"
            prev_comment=""
        else
            # Reset comment if we encounter a non-comment, non-alias line
            [[ ! "$line" =~ ^# ]] && prev_comment=""
        fi
    done < "$file"
}

# Parse alias file and extract function definitions
# Format: name|description
_help_parse_functions() {
    setopt local_options extended_glob
    
    local file="$1"
    [[ -f "$file" ]] || return 1
    
    local prev_comment=""
    local in_guard_if=0
    local in_function=0
    
    while IFS= read -r line; do
        # Skip empty lines and section headers
        [[ -z "$line" || "$line" =~ ^#\ =+ || "$line" =~ ^#\ -+ ]] && continue
        
        # Special handling for guard clauses
        if [[ "$line" =~ ^if\ !\ command\ -v ]]; then
            in_guard_if=1
            continue
        fi
        
        # Handle return statements in guards
        if [[ "$line" =~ ^[[:space:]]*return\ 0 ]]; then
            continue
        fi
        
        # End of guard if
        if [[ $in_guard_if -eq 1 ]] && { [[ "$line" == "fi" ]] || [[ "$line" =~ ^[[:space:]]*fi[[:space:]]*$ ]]; }; then
            in_guard_if=0
            continue
        fi
        
        # Skip content inside functions
        if [[ $in_function -eq 1 ]]; then
            if [[ "$line" == "}" ]] || [[ "$line" =~ ^[[:space:]]*\}[[:space:]]*$ ]]; then
                in_function=0
            fi
            continue
        fi
        
        # Extract single-line comments (only outside blocks)
        if [[ "$line" =~ ^#\ ([^=].+)$ ]]; then
            local comment="${match[1]}"
            # Skip section comments and documentation links
            if [[ ! "$comment" =~ ^(Zweck|Pfad|Docs|Hinweis|Guard|------------) ]]; then
                prev_comment="$comment"
            fi
        # Detect function definitions
        elif [[ "$line" =~ ^[[:space:]]*([a-zA-Z_][a-zA-Z0-9_]*)\(\) ]] && [[ ! "$line" =~ alias ]]; then
            local name="${match[1]}"
            # Only include if we have a description
            if [[ -n "$prev_comment" ]]; then
                echo "$name|$prev_comment"
            fi
            prev_comment=""
            in_function=1
        else
            # Reset comment if we encounter a non-comment line
            [[ ! "$line" =~ ^# ]] && prev_comment=""
        fi
    done < "$file"
}

# Get category name from alias file
_help_get_category() {
    local file="$1"
    local basename="${file:t:r}"  # Remove path and extension
    echo "$basename"
}

# Get category description from alias file header
_help_get_category_description() {
    local file="$1"
    [[ -f "$file" ]] || return 1
    
    # Look for "Zweck" line in header
    local desc=$(grep -m1 "^# Zweck" "$file" | sed 's/^# Zweck[[:space:]]*:[[:space:]]*//')
    [[ -n "$desc" ]] && echo "$desc" || echo ""
}

# Get documentation URL from alias file header
_help_get_docs_url() {
    local file="$1"
    [[ -f "$file" ]] || return 1
    
    # Look for "Docs" line in header
    local url=$(grep -m1 "^# Docs" "$file" | sed 's/^# Docs[[:space:]]*:[[:space:]]*//')
    [[ -n "$url" ]] && echo "$url" || echo ""
}

# Get all alias files
_help_get_alias_files() {
    local alias_dir="${HOME}/.config/alias"
    [[ -d "$alias_dir" ]] || return 1
    
    # Return sorted list of alias files
    print -l "$alias_dir"/*.alias(N:t) | sort
}

# Check if a tool is installed and get its version
_help_get_tool_version() {
    local tool="$1"
    
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "not_installed"
        return 1
    fi
    
    # Try common version flags
    local version=""
    case "$tool" in
        bat|eza|fd|fzf|rg|ripgrep|starship|zoxide|gh|btop)
            version=$("$tool" --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
            ;;
        brew)
            version=$(brew --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
            ;;
        mas)
            version=$(mas version 2>/dev/null)
            ;;
        *)
            version=$("$tool" --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
            ;;
    esac
    
    [[ -n "$version" ]] && echo "$version" || echo "unknown"
}
