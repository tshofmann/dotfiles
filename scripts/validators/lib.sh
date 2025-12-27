#!/usr/bin/env zsh
# ============================================================
# lib.sh - Gemeinsame Bibliothek für Validatoren
# ============================================================
# Zweck   : Shared Utilities, Logging, Registry
# Aufruf  : source validators/lib.sh
# ============================================================

# Verhindere doppeltes Laden
[[ -n "${VALIDATOR_LIB_LOADED:-}" ]] && return 0

# ============================================================
# ABSCHNITT 1: Farben & Terminal
# ============================================================
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

# ============================================================
# ABSCHNITT 2: Globale Zähler
# ============================================================
typeset -gi VALIDATOR_ERRORS=0
typeset -gi VALIDATOR_WARNINGS=0
typeset -gi VALIDATOR_PASSED=0

# ============================================================
# ABSCHNITT 3: Logging-Funktionen
# ============================================================
log()     { print "→ $*"; }
ok()      { print "${GREEN}✔${NC} $*"; ((VALIDATOR_PASSED++)) || true; }
warn()    { print "${YELLOW}⚠${NC} $*"; ((VALIDATOR_WARNINGS++)) || true; }
err()     { print "${RED}✖${NC} $*"; ((VALIDATOR_ERRORS++)) || true; }
info()    { print "${BLUE}ℹ${NC} $*"; }
debug()   { [[ -n "${VALIDATE_DEBUG:-}" ]] && print "${CYAN}⚙${NC} $*" || true; }
section() { print "\n${BOLD}━━━ $* ━━━${NC}"; }

# ============================================================
# ABSCHNITT 4: Pfad-Konfiguration
# ============================================================
: ${DOTFILES_DIR:="${0:A:h:h:h}"}
: ${DOCS_DIR:="$DOTFILES_DIR/docs"}
: ${SETUP_DIR:="$DOTFILES_DIR/setup"}
: ${SCRIPTS_DIR:="$DOTFILES_DIR/scripts"}
: ${TERMINAL_DIR:="$DOTFILES_DIR/terminal"}
: ${ALIAS_DIR:="$TERMINAL_DIR/.config/alias"}
: ${CONFIG_DIR:="$TERMINAL_DIR/.config"}

# ============================================================
# ABSCHNITT 5: Code-Extraktion (für Alias-Validierung)
# ============================================================

# Extrahiere Alias-Namen aus einer Datei
extract_aliases_from_file() {
    local file="$1"
    grep -oE "^[[:space:]]*alias [a-z][a-z0-9_-]*=" "$file" 2>/dev/null | \
        sed 's/.*alias //' | sed 's/=.*//' | sort -u
}

# Extrahiere Funktionsnamen aus einer Datei
extract_functions_from_file() {
    local file="$1"
    grep -oE "^[[:space:]]*[a-z][a-z0-9_]*\(\)[[:space:]]*\{" "$file" 2>/dev/null | \
        sed 's/().*//' | sed 's/^[[:space:]]*//' | sort -u
}

# Extrahiere dokumentierte Aliase/Funktionen aus einer Markdown-Sektion
# Unterstützt mehrere Namen pro Zeile: | `cmd1`, `cmd2` |
extract_aliases_from_docs() {
    local file="$1"
    local section="$2"
    
    # Extrahiere alle Backtick-Wörter aus dem Abschnitt
    sed -n "/### ${section}/,/^### /p" "$file" 2>/dev/null | \
        grep -oE "\`[a-z][a-z0-9_-]*\`" | \
        sed 's/`//g' | \
        grep -v '^\(path\|query\)$' | \
        sort -u
}

# Lade alle Aliase und Funktionen aus dem Alias-Verzeichnis
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
    
    ALL_ALIASES=(${(u)ALL_ALIASES})
    ALL_FUNCTIONS=(${(u)ALL_FUNCTIONS})
    
    debug "Geladen: ${#ALL_ALIASES[@]} Aliase, ${#ALL_FUNCTIONS[@]} Funktionen"
}

# ============================================================
# ABSCHNITT 6: Validator-Registry
# ============================================================
typeset -ga REGISTERED_VALIDATORS=()
typeset -ga CORE_VALIDATORS=()
typeset -ga EXTENDED_VALIDATORS=()

# Registriere einen Validator
# Usage: register_validator <name> <function> <description> [type]
# type: "core" oder "extended" (default: extended)
register_validator() {
    local name="$1"
    local func="$2"
    local desc="$3"
    local type="${4:-extended}"
    
    REGISTERED_VALIDATORS+=("$name:$func:$desc:$type")
    
    if [[ "$type" == "core" ]]; then
        CORE_VALIDATORS+=("$name")
    else
        EXTENDED_VALIDATORS+=("$name")
    fi
    
    debug "Validator registriert: $name ($type)"
}

# Führe alle Core-Validatoren aus
run_core_validators() {
    for entry in "${REGISTERED_VALIDATORS[@]}"; do
        local name="${entry%%:*}"
        local rest="${entry#*:}"
        local func="${rest%%:*}"
        rest="${rest#*:}"
        local desc="${rest%%:*}"
        local type="${rest#*:}"
        
        if [[ "$type" == "core" ]]; then
            log ""
            "$func"
        fi
    done
}

# Führe alle Extended-Validatoren aus
run_extended_validators() {
    local has_extended=false
    
    for entry in "${REGISTERED_VALIDATORS[@]}"; do
        local type="${entry##*:}"
        if [[ "$type" == "extended" ]]; then
            has_extended=true
            break
        fi
    done
    
    $has_extended || return 0
    
    print ""
    print "━━━ Erweiterte Validierung ━━━"
    
    for entry in "${REGISTERED_VALIDATORS[@]}"; do
        local name="${entry%%:*}"
        local rest="${entry#*:}"
        local func="${rest%%:*}"
        rest="${rest#*:}"
        local desc="${rest%%:*}"
        local type="${rest#*:}"
        
        if [[ "$type" == "extended" ]]; then
            section "$desc"
            "$func"
            print ""
        fi
    done
}

# Führe alle Validatoren aus
run_all_validators() {
    run_core_validators
    run_extended_validators
}

# Führe einen spezifischen Validator aus
run_validator() {
    local target="$1"
    
    for entry in "${REGISTERED_VALIDATORS[@]}"; do
        local name="${entry%%:*}"
        local rest="${entry#*:}"
        local func="${rest%%:*}"
        rest="${rest#*:}"
        local desc="${rest%%:*}"
        
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
list_validators() {
    print "${BOLD}Core-Validatoren:${NC}"
    for entry in "${REGISTERED_VALIDATORS[@]}"; do
        local name="${entry%%:*}"
        local rest="${entry#*:}"
        rest="${rest#*:}"
        local desc="${rest%%:*}"
        local type="${rest#*:}"
        
        if [[ "$type" == "core" ]]; then
            print "  ${CYAN}$name${NC} - $desc"
        fi
    done
    
    print ""
    print "${BOLD}Erweiterte Validatoren:${NC}"
    for entry in "${REGISTERED_VALIDATORS[@]}"; do
        local name="${entry%%:*}"
        local rest="${entry#*:}"
        rest="${rest#*:}"
        local desc="${rest%%:*}"
        local type="${rest#*:}"
        
        if [[ "$type" == "extended" ]]; then
            print "  ${CYAN}$name${NC} - $desc"
        fi
    done
}

# ============================================================
# ABSCHNITT 7: Ergebnis-Zusammenfassung
# ============================================================
print_summary() {
    print ""
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if (( VALIDATOR_ERRORS > 0 )); then
        print "${RED}❌ $VALIDATOR_ERRORS Fehler gefunden${NC}"
        print "   Dokumentation weicht vom Code ab!"
        return 1
    elif (( VALIDATOR_WARNINGS > 0 )); then
        print "${YELLOW}⚠️  $VALIDATOR_WARNINGS Warnungen${NC}"
        print "   Kleine Abweichungen (evtl. Beispiele gekürzt)"
        return 0
    else
        print "${GREEN}✅ Dokumentation ist synchron${NC}"
        return 0
    fi
}

# Markiere lib als geladen
VALIDATOR_LIB_LOADED=1
