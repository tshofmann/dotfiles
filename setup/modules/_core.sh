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
# Plattform-Detection
# ------------------------------------------------------------
# Erkennt Betriebssystem und Architektur für plattformspezifische Module
detect_platform() {
    local os arch

    case "$(uname -s)" in
        Darwin) os="macos" ;;
        Linux)
            # Linux-Distribution erkennen
            if [[ -f /etc/fedora-release ]]; then
                os="fedora"
            elif [[ -f /etc/debian_version ]]; then
                os="debian"
            elif [[ -f /etc/arch-release ]]; then
                os="arch"
            else
                os="linux"
            fi
            ;;
        *) os="unknown" ;;
    esac

    case "$(uname -m)" in
        arm64|aarch64) arch="arm64" ;;
        x86_64|amd64)  arch="x86_64" ;;
        *)             arch="unknown" ;;
    esac

    echo "${os}|${arch}"
}

# Plattform-Variablen (readonly nach Initialisierung)
_platform_info=$(detect_platform)
readonly PLATFORM_OS="${_platform_info%%|*}"
readonly PLATFORM_ARCH="${_platform_info##*|}"
unset _platform_info

# Helper: Prüft ob wir auf macOS sind
is_macos() { [[ "$PLATFORM_OS" == "macos" ]]; }

# Helper: Prüft ob wir auf Linux sind (beliebige Distro)
is_linux() { [[ "$PLATFORM_OS" == "linux" || "$PLATFORM_OS" == "fedora" || "$PLATFORM_OS" == "debian" || "$PLATFORM_OS" == "arch" ]]; }

# Helper: Prüft ob spezifische Distro
is_fedora() { [[ "$PLATFORM_OS" == "fedora" ]]; }
is_debian() { [[ "$PLATFORM_OS" == "debian" ]]; }
is_arch()   { [[ "$PLATFORM_OS" == "arch" ]]; }

# ------------------------------------------------------------
# Farben (aus theme-style laden)
# ------------------------------------------------------------
# theme-style ist Teil des Repos – kein stow nötig!
# Pfad wird relativ zu diesem Skript berechnet.
_THEME_STYLE="${0:A:h:h:h}/terminal/.config/theme-style"

if [[ -f "$_THEME_STYLE" ]]; then
    source "$_THEME_STYLE"
else
    # Fallback falls theme-style fehlt (sollte nie passieren)
    echo "WARNUNG: theme-style nicht gefunden: $_THEME_STYLE" >&2
    echo "         Verwende minimale Farben als Fallback" >&2
    typeset -gx C_RESET=$'\033[0m'
    typeset -gx C_BOLD=$'\033[1m'
    typeset -gx C_DIM=$'\033[2m'
    typeset -gx C_GREEN=$'\033[32m'
    typeset -gx C_RED=$'\033[31m'
    typeset -gx C_YELLOW=$'\033[33m'
    typeset -gx C_BLUE=$'\033[34m'
    typeset -gx C_MAUVE=$'\033[35m'
    typeset -gx C_TEXT=$'\033[37m'
    typeset -gx C_OVERLAY0=$'\033[90m'
fi
unset _THEME_STYLE

# ------------------------------------------------------------
# Logging-Helper
# ------------------------------------------------------------
# Format: Emoji + Nachricht (für konsistente Ausgabe)
log()  { print -P "${C_BLUE}→${C_RESET} $*"; }
ok()   { print -P "${C_GREEN}✔${C_RESET} $*"; }
err()  { print -P "${C_RED}✖${C_RESET} $*" >&2; }
warn() { print -P "${C_YELLOW}⚠${C_RESET} $*"; }

# Sektions-Header (wie brewv)
# Verwendung: section "Titel"
section() {
    print -P "\n${C_MAUVE}━━━ ${C_BOLD}$1${C_RESET}${C_MAUVE} ━━━${C_RESET}"
}

# Sektions-Abschluss mit Status
# Verwendung: section_end "3 Pakete installiert"
section_end() {
    print -P "${C_OVERLAY0}    └─ $*${C_RESET}"
}

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
# Konfiguration (Pfade für Module)
# ------------------------------------------------------------
# Diese Variablen werden von allen Modulen verwendet
# MODULES_DIR wird vom Orchestrator gesetzt, hier Fallback für direktes Sourcing
if [[ -z "${MODULES_DIR:-}" ]]; then
    MODULES_DIR="${0:A:h}"
fi
if [[ -z "${SCRIPT_DIR:-}" ]]; then
    SCRIPT_DIR="${MODULES_DIR:h}"
fi
if [[ -z "${DOTFILES_DIR:-}" ]]; then
    DOTFILES_DIR="${SCRIPT_DIR:h}"
fi

# Exportiere für Subprozesse
export MODULES_DIR SCRIPT_DIR DOTFILES_DIR
