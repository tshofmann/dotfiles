#!/usr/bin/env zsh
# ============================================================
# _core.sh - Gemeinsame Basis für Bootstrap-Module
# ============================================================
# Zweck   : Farben, Logging, Helper-Funktionen
# Pfad    : setup/modules/_core.sh
# Geladen : Automatisch von allen Modulen
# ============================================================

# Verhindere mehrfaches Laden
[[ -n "${_BOOTSTRAP_CORE_LOADED:-}" ]] && return 0
readonly _BOOTSTRAP_CORE_LOADED=1

# ------------------------------------------------------------
# Farben (Catppuccin Mocha)
# ------------------------------------------------------------
# WICHTIG: Synchron halten mit terminal/.config/theme-style!
#          Nur Subset hier, da bootstrap.sh vor stow läuft.
C_RESET='\033[0m'
C_MAUVE='\033[38;2;203;166;247m'
C_GREEN='\033[38;2;166;227;161m'
C_RED='\033[38;2;243;139;168m'
C_YELLOW='\033[38;2;249;226;175m'
C_BLUE='\033[38;2;137;180;250m'
C_TEXT='\033[38;2;205;214;244m'
C_OVERLAY0='\033[38;2;108;112;134m'
# Text Styles
C_BOLD='\033[1m'
C_DIM='\033[2m'

# ------------------------------------------------------------
# Logging-Helper
# ------------------------------------------------------------
# Format: Emoji + Nachricht (für konsistente Ausgabe)
log()  { echo -e "${C_BLUE}→${C_RESET} $*"; }
ok()   { echo -e "${C_GREEN}✔${C_RESET} $*"; }
err()  { echo -e "${C_RED}✖${C_RESET} $*" >&2; }
warn() { echo -e "${C_YELLOW}⚠${C_RESET} $*"; }

# ------------------------------------------------------------
# Modul-Status Tracking
# ------------------------------------------------------------
# CURRENT_STEP wird von Modulen gesetzt für aussagekräftige Fehlermeldungen
CURRENT_STEP="Initialisierung"

# ------------------------------------------------------------
# Defensive Helper für Dateioperationen
# ------------------------------------------------------------
# Prüft ob ein Verzeichnis erstellt werden kann (oder bereits existiert und schreibbar ist)
# Rückgabe: 0 = OK, 1 = Fehler
ensure_dir_writable() {
    local dir="$1"
    local description="${2:-Verzeichnis}"

    # Falls Verzeichnis existiert, prüfe ob schreibbar
    if [[ -d "$dir" ]]; then
        if [[ -w "$dir" ]]; then
            return 0
        else
            err "$description nicht schreibbar: $dir"
            return 1
        fi
    fi

    # Verzeichnis existiert nicht, prüfe ob Elternverzeichnis schreibbar ist
    local parent="${dir:h}"
    if [[ ! -w "$parent" ]]; then
        err "Kann $description nicht erstellen, Elternverzeichnis nicht schreibbar: $parent"
        return 1
    fi

    # Versuche Verzeichnis zu erstellen
    if ! mkdir -p "$dir" 2>/dev/null; then
        err "Konnte $description nicht erstellen: $dir"
        return 1
    fi

    return 0
}

# Prüft ob eine Datei geschrieben werden kann (Verzeichnis existiert und ist schreibbar)
# Rückgabe: 0 = OK, 1 = Fehler
ensure_file_writable() {
    local file="$1"
    local description="${2:-Datei}"
    local dir="${file:h}"

    # Prüfe ob Zielverzeichnis schreibbar ist
    if ! ensure_dir_writable "$dir" "Zielverzeichnis für $description"; then
        return 1
    fi

    # Falls Datei existiert, prüfe ob überschreibbar
    if [[ -e "$file" && ! -w "$file" ]]; then
        err "$description existiert aber ist nicht schreibbar: $file"
        return 1
    fi

    return 0
}

# ------------------------------------------------------------
# Modul-Runner mit Fehlerisolierung
# ------------------------------------------------------------
# Führt eine Modul-Funktion aus und fängt Fehler ab
# Argumente:
#   $1 - Modul-Name (für Logging)
#   $2 - Funktions-Name
# Rückgabe: 0 = Erfolg, 1 = Fehler, 2 = Übersprungen
run_module() {
    local module="$1"
    local func="$2"

    # Prüfe ob Funktion existiert
    if (( ! $+functions[$func] )); then
        err "Funktion '$func' nicht gefunden in Modul '$module'"
        return 1
    fi

    # Führe Funktion aus
    "$func"
    local rc=$?

    case $rc in
        0) ok "Modul '$module' abgeschlossen" ;;
        2) warn "Modul '$module' übersprungen" ;;
        *) err "Modul '$module' fehlgeschlagen (Exit $rc)"; return 1 ;;
    esac

    return $rc
}

# ------------------------------------------------------------
# Konfiguration (readonly verhindert versehentliche Überschreibung)
# ------------------------------------------------------------
# Diese Variablen werden von allen Modulen verwendet
# MODULES_DIR wird vom Orchestrator gesetzt, hier Fallback
if [[ -z "${MODULES_DIR:-}" ]]; then
    MODULES_DIR="${0:A:h}"
fi
if [[ -z "${SCRIPT_DIR:-}" ]]; then
    SCRIPT_DIR="${MODULES_DIR:h}"
fi
if [[ -z "${DOTFILES_DIR:-}" ]]; then
    DOTFILES_DIR="${SCRIPT_DIR:h}"
fi
