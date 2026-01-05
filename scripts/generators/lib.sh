#!/usr/bin/env zsh
# ============================================================
# lib.sh - Gemeinsame Bibliothek für Dokumentations-Generatoren
# ============================================================
# Zweck   : Shared Utilities für Code→Docs Generierung
# Aufruf  : source generators/lib.sh
# ============================================================

# Verhindere doppeltes Laden
[[ -n "${GENERATOR_LIB_LOADED:-}" ]] && return 0

# ============================================================
# ABSCHNITT 1: Farben & Terminal
# ============================================================
if [[ -t 1 ]]; then
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    NC='\033[0m'
else
    GREEN='' YELLOW='' BLUE='' CYAN='' NC=''
fi

# ============================================================
# ABSCHNITT 2: Logging-Funktionen
# ============================================================
log()   { print "→ $*"; }
ok()    { print "${GREEN}✔${NC} $*"; }
warn()  { print "${YELLOW}⚠${NC} $*"; }
info()  { print "${BLUE}ℹ${NC} $*"; }
debug() { [[ -n "${GEN_DEBUG:-}" ]] && print "${CYAN}⚙${NC} $*" || true; }

# ============================================================
# ABSCHNITT 3: Pfad-Konfiguration
# ============================================================
: ${DOTFILES_DIR:="${0:A:h:h:h}"}
: ${DOCS_DIR:="$DOTFILES_DIR/docs"}
: ${SETUP_DIR:="$DOTFILES_DIR/setup"}
: ${SCRIPTS_DIR:="$DOTFILES_DIR/scripts"}
: ${TERMINAL_DIR:="$DOTFILES_DIR/terminal"}
: ${ALIAS_DIR:="$TERMINAL_DIR/.config/alias"}
: ${CONFIG_DIR:="$TERMINAL_DIR/.config"}

# ============================================================
# ABSCHNITT 4: Marker-Konstanten
# ============================================================
marker_start() {
    local section="$1"
    print "<!-- BEGIN:GENERATED:${section} -->"
}

marker_end() {
    local section="$1"
    print "<!-- END:GENERATED:${section} -->"
}

# ============================================================
# ABSCHNITT 5: Code-Extraktion (erweitert)
# ============================================================

# Extrahiere Aliase mit Beschreibungen aus einer Datei
# Format: | `alias` | `befehl` | Beschreibung |
extract_alias_table() {
    local file="$1"
    local -a lines=()
    local desc="" alias_name="" alias_cmd=""
    
    while IFS= read -r line; do
        # Beschreibungskommentar vor Alias
        if [[ "$line" =~ ^[[:space:]]*#[[:space:]](.+)$ ]]; then
            desc="${match[1]}"
            continue
        fi
        
        # Alias-Definition
        if [[ "$line" =~ ^[[:space:]]*alias[[:space:]]+([a-z][a-z0-9_-]*)=(.+)$ ]]; then
            alias_name="${match[1]}"
            alias_cmd="${match[2]}"
            
            # Entferne Quotes
            alias_cmd="${alias_cmd#\'}"
            alias_cmd="${alias_cmd%\'}"
            alias_cmd="${alias_cmd#\"}"
            alias_cmd="${alias_cmd%\"}"
            
            # Escape Pipe-Zeichen für Markdown
            alias_cmd="${alias_cmd//|/\\|}"
            
            # Nutze Beschreibung oder leeren String
            lines+=("| \`${alias_name}\` | \`${alias_cmd}\` | ${desc:-} |")
            desc=""
        fi
    done < "$file"
    
    # Gebe Zeilen aus
    for line in "${lines[@]}"; do
        print "$line"
    done
}

# Extrahiere Funktionen mit Beschreibungen aus einer Datei
# Format: | `funktion` | Beschreibung |
extract_function_table() {
    local file="$1"
    local -a lines=()
    local desc="" func_name=""
    
    while IFS= read -r line; do
        # Beschreibungskommentar vor Funktion
        if [[ "$line" =~ ^[[:space:]]*#[[:space:]](.+)$ ]]; then
            desc="${match[1]}"
            continue
        fi
        
        # Funktions-Definition (nicht private mit _)
        if [[ "$line" =~ ^[[:space:]]*([a-z][a-z0-9_-]*)\(\)[[:space:]]*\{ ]]; then
            func_name="${match[1]}"
            
            # Ignoriere private Funktionen
            [[ "$func_name" == _* ]] && { desc=""; continue; }
            
            # Nutze Beschreibung oder leeren String
            lines+=("| \`${func_name}\` | ${desc:-} |")
            desc=""
        fi
    done < "$file"
    
    # Gebe Zeilen aus
    for line in "${lines[@]}"; do
        print "$line"
    done
}

# ============================================================
# ABSCHNITT 6: Markdown-Ersetzung
# ============================================================

# Ersetzt Inhalt zwischen Markern in einer Datei
# Usage: replace_marked_section <file> <section> <content>
replace_marked_section() {
    local file="$1"
    local section="$2"
    local content="$3"
    
    [[ ! -f "$file" ]] && { warn "Datei nicht gefunden: $file"; return 1; }
    
    local start_marker="<!-- BEGIN:GENERATED:${section} -->"
    local end_marker="<!-- END:GENERATED:${section} -->"
    
    # Prüfe ob Marker existieren
    if ! grep -q "$start_marker" "$file" 2>/dev/null; then
        warn "Marker nicht gefunden: $section in $file"
        return 1
    fi
    
    # Temporäre Datei
    local tmp_file="${file}.tmp"
    
    # Schreibe neue Datei
    local in_section=false
    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" == *"$start_marker"* ]]; then
            # Schreibe Start-Marker
            print "$line"
            print "<!-- AUTO-GENERATED – Änderungen werden überschrieben -->"
            print "$content"
            in_section=true
        elif [[ "$line" == *"$end_marker"* ]]; then
            # Schreibe End-Marker
            print "$line"
            in_section=false
        elif ! $in_section; then
            # Schreibe Zeile wenn nicht in Sektion
            print "$line"
        fi
    done < "$file" > "$tmp_file"
    
    # Ersetze Original
    mv "$tmp_file" "$file"
    ok "Aktualisiert: $section in $(basename $file)"
}

# Markiere lib als geladen
GENERATOR_LIB_LOADED=1
