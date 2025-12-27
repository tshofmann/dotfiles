# ============================================================
# help.zsh - Interaktives Help-System für dotfiles
# ============================================================
# Zweck   : Zeigt Aliase, Funktionen und Tool-Informationen
# Pfad    : ~/.config/functions/help.zsh
# Nutzung : help [command] [args]
# ============================================================

# Load parser functions
source "${HOME}/.config/functions/_help_parser.zsh"

# Color codes (using Catppuccin-inspired colors)
typeset -g _HELP_COLOR_RESET=$'\e[0m'
typeset -g _HELP_COLOR_HEADER=$'\e[1;35m'    # Magenta
typeset -g _HELP_COLOR_CATEGORY=$'\e[1;36m'  # Cyan
typeset -g _HELP_COLOR_ALIAS=$'\e[33m'       # Yellow
typeset -g _HELP_COLOR_COMMAND=$'\e[32m'     # Green
typeset -g _HELP_COLOR_DESC=$'\e[90m'        # Gray
typeset -g _HELP_COLOR_SUCCESS=$'\e[32m'     # Green
typeset -g _HELP_COLOR_ERROR=$'\e[31m'       # Red
typeset -g _HELP_COLOR_ICON=$'\e[34m'        # Blue

# Print colored header box
_help_print_header() {
    local title="$1"
    local width=65
    
    echo "${_HELP_COLOR_HEADER}╭$(printf '─%.0s' {1..$width})╮${_HELP_COLOR_RESET}"
    printf "${_HELP_COLOR_HEADER}│${_HELP_COLOR_RESET} %-${width}s ${_HELP_COLOR_HEADER}│${_HELP_COLOR_RESET}\n" "$title"
    echo "${_HELP_COLOR_HEADER}╰$(printf '─%.0s' {1..$width})╯${_HELP_COLOR_RESET}"
}

# Show overview of all categories
_help_overview() {
    _help_print_header "🚀 Dotfiles Help"
    
    echo ""
    echo "${_HELP_COLOR_CATEGORY}📁 Alias-Kategorien:${_HELP_COLOR_RESET}"
    
    local alias_dir="${HOME}/.config/alias"
    if [[ -d "$alias_dir" ]]; then
        for file in "$alias_dir"/*.alias(N); do
            local category=$(_help_get_category "$file")
            local desc=$(_help_get_category_description "$file")
            printf "  ${_HELP_COLOR_ALIAS}%-12s${_HELP_COLOR_RESET} ${_HELP_COLOR_DESC}%s${_HELP_COLOR_RESET}\n" "$category" "$desc"
        done | sort
    fi
    
    echo ""
    echo "${_HELP_COLOR_CATEGORY}⚡ Funktionen:${_HELP_COLOR_RESET}"
    printf "  ${_HELP_COLOR_ALIAS}%-12s${_HELP_COLOR_RESET} ${_HELP_COLOR_DESC}%s${_HELP_COLOR_RESET}\n" "help" "Diese Hilfe anzeigen"
    
    echo ""
    echo "${_HELP_COLOR_CATEGORY}💡 Nutzung:${_HELP_COLOR_RESET}"
    echo "  ${_HELP_COLOR_COMMAND}help <name>${_HELP_COLOR_RESET}        Details zu Kategorie/Funktion"
    echo "  ${_HELP_COLOR_COMMAND}help search <text>${_HELP_COLOR_RESET} Suche in allen Aliasen"
    echo "  ${_HELP_COLOR_COMMAND}help tools${_HELP_COLOR_RESET}         Installierte Tools anzeigen"
    echo "  ${_HELP_COLOR_COMMAND}help --fzf${_HELP_COLOR_RESET}         Interaktive Auswahl"
    echo ""
}

# Show aliases for a specific category
_help_category() {
    local category="$1"
    local alias_file="${HOME}/.config/alias/${category}.alias"
    
    if [[ ! -f "$alias_file" ]]; then
        echo "${_HELP_COLOR_ERROR}✖ Kategorie nicht gefunden: $category${_HELP_COLOR_RESET}"
        echo ""
        echo "Verfügbare Kategorien:"
        local alias_dir="${HOME}/.config/alias"
        for file in "$alias_dir"/*.alias(N); do
            echo "  - $(_help_get_category "$file")"
        done | sort
        return 1
    fi
    
    _help_print_header "📁 $category"
    echo ""
    
    # Parse and display aliases
    local has_aliases=0
    while IFS='|' read -r name cmd desc; do
        has_aliases=1
        printf "  ${_HELP_COLOR_ALIAS}%-8s${_HELP_COLOR_RESET} ${_HELP_COLOR_COMMAND}%-25s${_HELP_COLOR_RESET} ${_HELP_COLOR_DESC}%s${_HELP_COLOR_RESET}\n" \
            "$name" "$cmd" "$desc"
    done < <(_help_parse_aliases "$alias_file")
    
    # Parse and display functions
    local has_functions=0
    while IFS='|' read -r name desc; do
        [[ $has_functions -eq 0 && $has_aliases -eq 1 ]] && echo ""
        has_functions=1
        printf "  ${_HELP_COLOR_ALIAS}%-8s${_HELP_COLOR_RESET} ${_HELP_COLOR_COMMAND}%-25s${_HELP_COLOR_RESET} ${_HELP_COLOR_DESC}%s${_HELP_COLOR_RESET}\n" \
            "$name" "(Funktion)" "$desc"
    done < <(_help_parse_functions "$alias_file")
    
    if [[ $has_aliases -eq 0 && $has_functions -eq 0 ]]; then
        echo "  ${_HELP_COLOR_DESC}Keine Aliase oder Funktionen gefunden${_HELP_COLOR_RESET}"
    fi
    
    # Show documentation link if available
    local docs_url=$(_help_get_docs_url "$alias_file")
    if [[ -n "$docs_url" ]]; then
        echo ""
        echo "${_HELP_COLOR_ICON}📖 Docs:${_HELP_COLOR_RESET} $docs_url"
    fi
    
    echo ""
}

# Search through all aliases and functions
_help_search() {
    local query="$1"
    
    if [[ -z "$query" ]]; then
        echo "${_HELP_COLOR_ERROR}✖ Bitte Suchbegriff angeben${_HELP_COLOR_RESET}"
        echo "Nutzung: help search <text>"
        return 1
    fi
    
    _help_print_header "🔍 Suche: $query"
    echo ""
    
    local found=0
    local alias_dir="${HOME}/.config/alias"
    
    for file in "$alias_dir"/*.alias(N); do
        local category=$(_help_get_category "$file")
        local category_printed=0
        
        # Search in aliases
        while IFS='|' read -r name cmd desc; do
            # Case-insensitive search
            if [[ "${name:l}" =~ "${query:l}" || "${cmd:l}" =~ "${query:l}" || "${desc:l}" =~ "${query:l}" ]]; then
                if [[ $category_printed -eq 0 ]]; then
                    echo "${_HELP_COLOR_CATEGORY}[$category]${_HELP_COLOR_RESET}"
                    category_printed=1
                fi
                printf "  ${_HELP_COLOR_ALIAS}%-8s${_HELP_COLOR_RESET} ${_HELP_COLOR_COMMAND}%-25s${_HELP_COLOR_RESET} ${_HELP_COLOR_DESC}%s${_HELP_COLOR_RESET}\n" \
                    "$name" "$cmd" "$desc"
                found=1
            fi
        done < <(_help_parse_aliases "$file")
        
        # Search in functions
        while IFS='|' read -r name desc; do
            # Case-insensitive search
            if [[ "${name:l}" =~ "${query:l}" || "${desc:l}" =~ "${query:l}" ]]; then
                if [[ $category_printed -eq 0 ]]; then
                    echo "${_HELP_COLOR_CATEGORY}[$category]${_HELP_COLOR_RESET}"
                    category_printed=1
                fi
                printf "  ${_HELP_COLOR_ALIAS}%-8s${_HELP_COLOR_RESET} ${_HELP_COLOR_COMMAND}%-25s${_HELP_COLOR_RESET} ${_HELP_COLOR_DESC}%s${_HELP_COLOR_RESET}\n" \
                    "$name" "(Funktion)" "$desc"
                found=1
            fi
        done < <(_help_parse_functions "$file")
        
        [[ $category_printed -eq 1 ]] && echo ""
    done
    
    if [[ $found -eq 0 ]]; then
        echo "  ${_HELP_COLOR_DESC}Keine Treffer gefunden${_HELP_COLOR_RESET}"
        echo ""
    fi
}

# Show installed tools with versions
_help_tools() {
    _help_print_header "🔧 Installierte Tools"
    echo ""
    
    # Define tools to check (from Brewfile)
    local -a tools=(
        "bat:Syntax-Highlighting"
        "eza:Modernes ls"
        "fd:Schnelle Dateisuche"
        "fzf:Fuzzy Finder"
        "rg:Schnelles grep"
        "starship:Shell-Prompt"
        "zoxide:Smartes cd"
        "btop:Ressourcen-Monitor"
        "gh:GitHub CLI"
        "mas:Mac App Store CLI"
    )
    
    for tool_info in "${tools[@]}"; do
        local tool="${tool_info%%:*}"
        local desc="${tool_info##*:}"
        local version=$(_help_get_tool_version "$tool")
        
        if [[ "$version" == "not_installed" ]]; then
            printf "  ${_HELP_COLOR_ERROR}✖${_HELP_COLOR_RESET} ${_HELP_COLOR_ALIAS}%-12s${_HELP_COLOR_RESET} ${_HELP_COLOR_DESC}%-10s  %s${_HELP_COLOR_RESET}\n" \
                "$tool" "—" "$desc"
        else
            printf "  ${_HELP_COLOR_SUCCESS}✔${_HELP_COLOR_RESET} ${_HELP_COLOR_ALIAS}%-12s${_HELP_COLOR_RESET} ${_HELP_COLOR_COMMAND}%-10s${_HELP_COLOR_RESET}  ${_HELP_COLOR_DESC}%s${_HELP_COLOR_RESET}\n" \
                "$tool" "$version" "$desc"
        fi
    done
    
    echo ""
}

# Interactive fzf mode
_help_interactive() {
    if ! command -v fzf >/dev/null 2>&1; then
        echo "${_HELP_COLOR_ERROR}✖ fzf nicht installiert${_HELP_COLOR_RESET}"
        return 1
    fi
    
    local alias_dir="${HOME}/.config/alias"
    local -a items=()
    
    # Collect all aliases and functions
    for file in "$alias_dir"/*.alias(N); do
        local category=$(_help_get_category "$file")
        
        # Add aliases
        while IFS='|' read -r name cmd desc; do
            items+=("[$category] $name|$cmd|$desc")
        done < <(_help_parse_aliases "$file")
        
        # Add functions
        while IFS='|' read -r name desc; do
            items+=("[$category] $name|(Funktion)|$desc")
        done < <(_help_parse_functions "$file")
    done
    
    # Show in fzf
    local selection=$(printf '%s\n' "${items[@]}" | \
        fzf --ansi \
            --delimiter='|' \
            --preview 'echo {2} | fold -w 60' \
            --preview-window='down:3:wrap' \
            --header='Enter: Details kopieren | Esc: Beenden' \
            --prompt='Aliase> ')
    
    if [[ -n "$selection" ]]; then
        # Extract and display selection
        local name=$(echo "$selection" | sed 's/^\[[^]]*\] \([^|]*\).*/\1/')
        local cmd=$(echo "$selection" | cut -d'|' -f2)
        echo ""
        echo "${_HELP_COLOR_SUCCESS}✔${_HELP_COLOR_RESET} ${_HELP_COLOR_ALIAS}$name${_HELP_COLOR_RESET} → ${_HELP_COLOR_COMMAND}$cmd${_HELP_COLOR_RESET}"
        echo ""
    fi
}

# Main help function
help() {
    local cmd="${1:-}"
    local arg="${2:-}"
    
    case "$cmd" in
        "")
            _help_overview
            ;;
        "search")
            _help_search "$arg"
            ;;
        "tools")
            _help_tools
            ;;
        "--fzf")
            _help_interactive
            ;;
        *)
            _help_category "$cmd"
            ;;
    esac
}
