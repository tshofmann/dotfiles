#!/usr/bin/env zsh
# ============================================================
# lib.sh - Gemeinsame Bibliothek für Validatoren
# ============================================================
# Zweck   : Shared Functions und Konfiguration
# Aufruf  : source validators/lib.sh
# ============================================================

# Verhindere doppeltes Laden
[[ -n "${VALIDATOR_LIB_LOADED:-}" ]] && return 0

# Farben (nur wenn Terminal vorhanden)
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' CYAN='' BOLD='' NC=''
fi

# Globale Zähler
typeset -gi VALIDATOR_ERRORS=0
typeset -gi VALIDATOR_WARNINGS=0
typeset -gi VALIDATOR_PASSED=0

# ------------------------------------------------------------
# Logging-Funktionen
# ------------------------------------------------------------
log()     { print "→ $*"; }
ok()      { print "${GREEN}✔${NC} $*"; ((VALIDATOR_PASSED++)); }
warn()    { print "${YELLOW}⚠${NC} $*"; ((VALIDATOR_WARNINGS++)); }
err()     { print "${RED}✖${NC} $*"; ((VALIDATOR_ERRORS++)); }
info()    { print "${BLUE}ℹ${NC} $*"; }
debug()   { [[ -n "${VALIDATE_DEBUG:-}" ]] && print "${CYAN}⚙${NC} $*" || true; }
section() { print "\n${BOLD}━━━ $* ━━━${NC}"; }

# ------------------------------------------------------------
# Pfad-Konfiguration (wird vom Hauptskript gesetzt)
# ------------------------------------------------------------
: ${DOTFILES_DIR:="${0:A:h:h:h}"}
: ${DOCS_DIR:="$DOTFILES_DIR/docs"}
: ${SETUP_DIR:="$DOTFILES_DIR/setup"}
: ${SCRIPTS_DIR:="$DOTFILES_DIR/scripts"}
: ${TERMINAL_DIR:="$DOTFILES_DIR/terminal"}
: ${ALIAS_DIR:="$TERMINAL_DIR/.config/alias"}
: ${CONFIG_DIR:="$TERMINAL_DIR/.config"}

# ------------------------------------------------------------
# Hilfsfunktionen
# ------------------------------------------------------------

# Extrahiere alle Alias-Namen aus einer Alias-Datei
# Usage: extract_aliases_from_file <file>
extract_aliases_from_file() {
    local file="$1"
    grep -oE "^[[:space:]]*alias [a-z][a-z0-9_-]*=" "$file" 2>/dev/null | \
        sed 's/.*alias //' | sed 's/=.*//' | sort -u
}

# Extrahiere alle Funktionsnamen aus einer Alias-Datei
# Usage: extract_functions_from_file <file>
extract_functions_from_file() {
    local file="$1"
    grep -oE "^[[:space:]]*[a-z][a-z0-9_]*\(\)[[:space:]]*\{" "$file" 2>/dev/null | \
        sed 's/().*//' | sed 's/^[[:space:]]*//' | sort -u
}

# Extrahiere dokumentierte Aliase aus einer Markdown-Tabelle
# Usage: extract_aliases_from_docs <file> <section_name>
extract_aliases_from_docs() {
    local file="$1"
    local section="$2"
    
    sed -n "/### ${section}/,/^### /p" "$file" 2>/dev/null | \
        grep -oE "^\| \`[a-z][a-z0-9_-]*\`" | \
        sed 's/| `//' | sed 's/`.*//' | sort -u
}

# Extrahiere dokumentierte Funktionen aus einer Markdown-Tabelle
# Usage: extract_functions_from_docs <file> <section_pattern>
extract_functions_from_docs() {
    local file="$1"
    local section="$2"
    
    sed -n "/${section}/,/^### [^#]/p" "$file" 2>/dev/null | \
        grep -oE "^\| \`[a-z][a-z0-9_]*(\s|\[|\`)" | \
        sed 's/| `//' | sed 's/[` \[].*//' | sort -u
}

# Extrahiere Befehle aus Code-Blöcken in Markdown
# Usage: extract_commands_from_codeblocks <file>
extract_commands_from_codeblocks() {
    local file="$1"
    
    # Extrahiere Inhalte von ```zsh ... ``` Blöcken
    sed -n '/^```zsh/,/^```/p' "$file" 2>/dev/null | \
        grep -v '^```' | \
        grep -v '^#' | \
        grep -v '^$' | \
        sed 's/[[:space:]]*#.*//' | \
        awk '{print $1}' | \
        grep -E '^[a-z]' | \
        sort -u
}

# Vergleiche zwei Listen und finde Unterschiede
# Usage: compare_lists <list1_name> <list2_name>
# Erwartet Arrays mit diesen Namen im Scope
compare_lists() {
    local -a list1=("${(@P)1}")
    local -a list2=("${(@P)2}")
    local name1="$1"
    local name2="$2"
    
    local -a only_in_1=()
    local -a only_in_2=()
    
    # Finde Elemente nur in Liste 1
    for item in "${list1[@]}"; do
        if [[ ! " ${list2[*]} " =~ " ${item} " ]]; then
            only_in_1+=("$item")
        fi
    done
    
    # Finde Elemente nur in Liste 2
    for item in "${list2[@]}"; do
        if [[ ! " ${list1[*]} " =~ " ${item} " ]]; then
            only_in_2+=("$item")
        fi
    done
    
    # Ausgabe
    if (( ${#only_in_1[@]} > 0 )); then
        debug "Nur in $name1: ${only_in_1[*]}"
    fi
    if (( ${#only_in_2[@]} > 0 )); then
        debug "Nur in $name2: ${only_in_2[*]}"
    fi
    
    # Return: 0 wenn identisch, 1 wenn unterschiedlich
    (( ${#only_in_1[@]} == 0 && ${#only_in_2[@]} == 0 ))
}

# Prüfe ob ein Befehl in den definierten Aliasen/Funktionen existiert
# Usage: command_exists_in_definitions <command> <definitions_array_name>
command_exists_in_definitions() {
    local cmd="$1"
    local -a defs=("${(@P)2}")
    
    [[ " ${defs[*]} " =~ " ${cmd} " ]]
}

# Lade alle definierten Aliase und Funktionen
# Usage: load_all_definitions
# Setzt: ALL_ALIASES, ALL_FUNCTIONS
load_all_definitions() {
    typeset -ga ALL_ALIASES=()
    typeset -ga ALL_FUNCTIONS=()
    
    for alias_file in "$ALIAS_DIR"/*.alias(N); do
        [[ -f "$alias_file" ]] || continue
        
        local -a file_aliases=($(extract_aliases_from_file "$alias_file"))
        local -a file_functions=($(extract_functions_from_file "$alias_file"))
        
        ALL_ALIASES+=("${file_aliases[@]}")
        ALL_FUNCTIONS+=("${file_functions[@]}")
    done
    
    # Deduplizieren
    ALL_ALIASES=(${(u)ALL_ALIASES})
    ALL_FUNCTIONS=(${(u)ALL_FUNCTIONS})
    
    debug "Geladen: ${#ALL_ALIASES[@]} Aliase, ${#ALL_FUNCTIONS[@]} Funktionen"
}

# ------------------------------------------------------------
# Validator-Registry
# ------------------------------------------------------------
typeset -ga REGISTERED_VALIDATORS=()

# Registriere einen Validator
# Usage: register_validator <name> <function> <description>
register_validator() {
    local name="$1"
    local func="$2"
    local desc="$3"
    
    REGISTERED_VALIDATORS+=("$name:$func:$desc")
    debug "Validator registriert: $name"
}

# Führe alle registrierten Validatoren aus
# Usage: run_all_validators
run_all_validators() {
    for entry in "${REGISTERED_VALIDATORS[@]}"; do
        local name="${entry%%:*}"
        local rest="${entry#*:}"
        local func="${rest%%:*}"
        local desc="${rest#*:}"
        
        section "$desc"
        "$func"
        print ""
    done
}

# Führe einen spezifischen Validator aus
# Usage: run_validator <name>
run_validator() {
    local target="$1"
    
    for entry in "${REGISTERED_VALIDATORS[@]}"; do
        local name="${entry%%:*}"
        local rest="${entry#*:}"
        local func="${rest%%:*}"
        local desc="${rest#*:}"
        
        if [[ "$name" == "$target" ]]; then
            section "$desc"
            "$func"
            return $?
        fi
    done
    
    err "Validator '$target' nicht gefunden"
    return 1
}

# Liste verfügbare Validatoren
# Usage: list_validators
list_validators() {
    print "Verfügbare Validatoren:"
    for entry in "${REGISTERED_VALIDATORS[@]}"; do
        local name="${entry%%:*}"
        local rest="${entry#*:}"
        local desc="${rest#*:}"
        print "  ${CYAN}$name${NC} - $desc"
    done
}

# Markiere lib als geladen (am Ende der Datei)
VALIDATOR_LIB_LOADED=1
