#!/usr/bin/env zsh
# ============================================================
# _core.sh - Gemeinsame Basis für Bootstrap-Module
# ============================================================
# Zweck       : Farben, Logging, Helper-Funktionen
# Pfad        : setup/modules/_core.sh
# Geladen     : Automatisch von allen Modulen
# ============================================================

# Verhindere mehrfaches Laden
[[ -n "${_BOOTSTRAP_CORE_LOADED:-}" ]] && return 0
readonly _BOOTSTRAP_CORE_LOADED=1

# ------------------------------------------------------------
# Plattform-Detection (via platform.zsh)
# ------------------------------------------------------------
# Sourced platform.zsh als Single Source of Truth, leitet
# Bootstrap-Variablen (PLATFORM_OS, PLATFORM_ARCH) davon ab.
_platform_file="${0:A:h:h:h}/terminal/.config/platform.zsh"
if [[ -f "$_platform_file" ]]; then
    source "$_platform_file"
else
    echo "WARNUNG: platform.zsh nicht gefunden: $_platform_file" >&2
fi
unset _platform_file

# Bootstrap-Variablen aus platform.zsh ableiten
# PLATFORM_OS = distro-spezifisch (damit is_fedora() etc. funktionieren)
if [[ "${_PLATFORM_OS:-}" == "linux" && -n "${_PLATFORM_DISTRO:-}" && "$_PLATFORM_DISTRO" != "unknown" ]]; then
    readonly PLATFORM_OS="$_PLATFORM_DISTRO"
else
    readonly PLATFORM_OS="${_PLATFORM_OS:-unknown}"
fi

# Architektur via uname -m (Hardware-Architektur, nicht ZSH-Compile-Target)
# $MACHTYPE gibt die Compile-Time-Architektur des ZSH-Binaries zurück,
# die bei Rosetta-Nutzung von der echten Hardware abweichen kann.
case "$(uname -m)" in
    arm64|aarch64) readonly PLATFORM_ARCH="arm64" ;;
    x86_64|amd64)  readonly PLATFORM_ARCH="x86_64" ;;
    armv7*)        readonly PLATFORM_ARCH="armv7" ;;
    armv6*)        readonly PLATFORM_ARCH="armv6" ;;
    *)             readonly PLATFORM_ARCH="unknown" ;;
esac

# Helper: Prüft ob wir auf macOS sind
is_macos() { [[ "$PLATFORM_OS" == "macos" ]]; }

# Helper: Prüft ob wir auf Linux sind (beliebige Distro)
# _PLATFORM_OS ist immer "linux" (generisch), während PLATFORM_OS
# den Distro-Namen enthält – so muss is_linux() keine Distros auflisten.
is_linux() { [[ "${_PLATFORM_OS:-}" == "linux" ]]; }

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
#
# Nutzt print -r (raw output): Keine %-Expansion, keine \-Interpretation.
# Sicher bei beliebigem Text (Dateinamen, URLs, Prozentwerte).
# Die Check-Skripte nutzen identisch .github/scripts/lib/log.sh (print -r).
log()  { print -r -- "${C_BLUE}→${C_RESET} $*"; }
ok()   { print -r -- "${C_GREEN}✔${C_RESET} $*"; }
err()  { print -r -- "${C_RED}✖${C_RESET} $*" >&2; }
warn() { print -r -- "${C_YELLOW}⚠${C_RESET} $*"; }
skip() { print -r -- "${C_OVERLAY0}⏭${C_RESET} $*"; }

# Sektions-Header (wie brew-list)
# Verwendung  : section "Titel"
section() {
    print -r -- ""
    print -r -- "${C_MAUVE}━━━ ${C_BOLD}$1${C_RESET}${C_MAUVE} ━━━${C_RESET}"
}

# Sektions-Abschluss mit Status
# Verwendung  : section_end "3 Pakete installiert"
section_end() {
    print -r -- "${C_OVERLAY0}    └─ $*${C_RESET}"
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
# mkdir -p erstellt fehlende Elternverzeichnisse automatisch,
# daher kein manueller Parent-Check nötig.
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

    # Versuche Verzeichnis (inkl. Elternverzeichnisse) zu erstellen
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
# Input-Validierung für interaktive Module
# ------------------------------------------------------------
# Prüft ob ein SSH-Host-Alias gültig ist (keine Wildcards, keine Leerzeichen)
# SSH interpretiert *, ?, !, [] als Pattern – diese MÜSSEN abgelehnt werden.
# Erlaubt: Beginnt mit Buchstabe, dann alphanumerisch + Punkt/Unterstrich/Bindestrich
# Rückgabe: 0 = gültig, 1 = ungültig (Fehlermeldung via warn)
validate_ssh_alias() {
    local alias_name="$1"

    if [[ -z "$alias_name" ]]; then
        warn "Host-Alias darf nicht leer sein"
        return 1
    fi

    if [[ ! "$alias_name" =~ ^[a-zA-Z][a-zA-Z0-9._-]*$ ]]; then
        warn "Ungültiger Host-Alias '$alias_name' – erlaubt: Buchstaben, Zahlen, Punkt, Unterstrich, Bindestrich (muss mit Buchstabe beginnen)"
        return 1
    fi

    return 0
}

# Prüft ob ein Port im gültigen Bereich liegt (1–65535)
# Rückgabe: 0 = gültig, 1 = ungültig (Fehlermeldung via warn)
validate_port() {
    local port="$1"

    if [[ "$port" != <-> ]]; then
        warn "Ungültiger Port '$port' – muss eine Zahl sein"
        return 1
    fi

    if (( port < 1 || port > 65535 )); then
        warn "Port '$port' außerhalb des gültigen Bereichs (1–65535)"
        return 1
    fi

    return 0
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
