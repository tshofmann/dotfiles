#!/usr/bin/env zsh
# ============================================================
# bootstrap.sh - macOS Bootstrap Orchestrator
# ============================================================
# Zweck       : Lädt und führt Bootstrap-Module in definierter Reihenfolge aus
# Aufruf      : ./bootstrap.sh
# Docs        : https://github.com/tshofmann/dotfiles#readme
# Module      : setup/modules/ (validation, homebrew, stow, git-hooks, font, terminal-profile, starship, bat, tealdeer, xcode-theme, zsh-sessions)
# ============================================================

set -euo pipefail

# ------------------------------------------------------------
# Konfiguration
# ------------------------------------------------------------
readonly SCRIPT_DIR="${0:A:h}"
readonly MODULES_DIR="$SCRIPT_DIR/modules"
readonly DOTFILES_DIR="${SCRIPT_DIR:h}"

# Exportiere Pfade für Module
export SCRIPT_DIR MODULES_DIR DOTFILES_DIR

# ------------------------------------------------------------
# Core-Bibliothek laden
# ------------------------------------------------------------
if [[ ! -f "$MODULES_DIR/_core.sh" ]]; then
    echo "FEHLER: Core-Modul nicht gefunden: $MODULES_DIR/_core.sh" >&2
    exit 1
fi
source "$MODULES_DIR/_core.sh"

# ------------------------------------------------------------
# Trap-Handler für Abbruch/Fehler
# ------------------------------------------------------------
cleanup() {
    local exit_code=$?
    if (( exit_code != 0 )); then
        print ""
        warn "Bootstrap abgebrochen bei: $CURRENT_STEP"
        warn "Exit-Code: $exit_code"
        print ""
        log "Das Skript ist idempotent – du kannst es erneut ausführen."
        log "Bereits installierte Komponenten werden übersprungen."
    fi
}
trap cleanup EXIT

# ------------------------------------------------------------
# Modul-Loader
# ------------------------------------------------------------
# Lädt ein Modul und führt dessen setup_* Funktion aus
# Unterstützt Plattform-Prefixe: "macos:", "linux:", "fedora:" etc.
# Argumente:
#   $1 - Modul-Spezifikation (z.B. "validation" oder "macos:terminal-profile")
# Rückgabe: 0 = Erfolg, 1 = Fehler, 2 = Übersprungen
load_module() {
    local spec="$1"
    local platform_prefix=""
    local module=""

    # Plattform-Prefix extrahieren falls vorhanden
    if [[ "$spec" == *":"* ]]; then
        platform_prefix="${spec%%:*}"
        module="${spec#*:}"
    else
        module="$spec"
    fi

    # Plattform-Filter anwenden
    if [[ -n "$platform_prefix" ]]; then
        case "$platform_prefix" in
            macos)  is_macos || { log "Überspringe $module (nicht macOS)"; return 2; } ;;
            linux)  is_linux || { log "Überspringe $module (nicht Linux)"; return 2; } ;;
            fedora) is_fedora || { log "Überspringe $module (nicht Fedora)"; return 2; } ;;
            debian) is_debian || { log "Überspringe $module (nicht Debian)"; return 2; } ;;
            arch)   is_arch || { log "Überspringe $module (nicht Arch)"; return 2; } ;;
            *)      warn "Unbekannter Plattform-Prefix: $platform_prefix" ;;
        esac
    fi

    local module_file="$MODULES_DIR/${module}.sh"

    # Modul-Datei prüfen
    if [[ ! -f "$module_file" ]]; then
        err "Modul nicht gefunden: $module_file"
        return 1
    fi

    # Modul laden
    source "$module_file" || {
        err "Fehler beim Laden von: $module"
        return 1
    }

    # Setup-Funktion ermitteln (Bindestriche → Unterstriche)
    local func="setup_${module//-/_}"

    # Setup-Funktion ausführen wenn vorhanden
    if (( $+functions[$func] )); then
        "$func"
        return $?
    fi

    return 0
}

# ------------------------------------------------------------
# Modul-Reihenfolge (Abhängigkeitsgraph)
# ------------------------------------------------------------
# WICHTIG: Reihenfolge beachten! Module können von vorherigen abhängen.
# Dokumentation in jedem Modul unter "Benötigt:"
#
# Plattform-spezifische Module:
#   - Prefix "macos:" = nur auf macOS laden
#   - Prefix "linux:" = nur auf Linux laden
#   - Prefix "fedora:" = nur auf Fedora laden
#   - Ohne Prefix = auf allen Plattformen laden
readonly -a MODULES=(
    validation              # Architektur, OS, Netzwerk, Rechte (plattformübergreifend)
    homebrew                # Homebrew/Linuxbrew + Brewfile
    stow                    # Symlinks für Configs (muss vor Tool-spezifischen Modulen laufen)
    git-hooks               # Pre-Commit Hooks aktivieren
    font                    # Font-Verifikation
    macos:terminal-profile  # Terminal-Profil Import (nur macOS)
    starship                # Starship-Theme (plattformübergreifend)
    bat                     # bat Theme-Cache bauen
    tealdeer                # tldr-Pages herunterladen
    macos:xcode-theme       # Xcode Theme (nur macOS)
    macos:zsh-sessions      # ZSH Sessions Check (nur macOS)
)

# ------------------------------------------------------------
# Hauptprogramm
# ------------------------------------------------------------
main() {
    # Versions-Info für Banner
    local os_version
    if is_macos; then
        os_version="macOS $(sw_vers -productVersion 2>/dev/null || echo "?")"
    elif is_linux; then
        os_version="$PLATFORM_OS ($PLATFORM_ARCH)"
    else
        os_version="$PLATFORM_OS"
    fi

    # Banner (minimalistisch wie brew-list)
    print -P ""
    print -P "${C_MAUVE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
    print -P "${C_MAUVE}  ${C_BOLD}Dotfiles Bootstrap${C_RESET}  ${C_DIM}$os_version${C_RESET}"
    print -P "${C_MAUVE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"

    # Module in definierter Reihenfolge laden und ausführen
    for module in "${MODULES[@]}"; do
        load_module "$module"
        local rc=$?

        case $rc in
            0) ;;  # Erfolg, weiter
            2) ;;  # Übersprungen (warn wurde im Modul ausgegeben), weiter
            *)
                err "Bootstrap fehlgeschlagen bei Modul: $module"
                exit 1
                ;;
        esac
    done

    # Erfolgreicher Abschluss – CURRENT_STEP zurücksetzen für sauberen Exit
    CURRENT_STEP=""

    # Abschluss-Meldung
    print -P ""
    print -P "${C_GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
    print -P "${C_GREEN}  ✔ Setup abgeschlossen${C_RESET}"
    print -P "${C_GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
    print -P ""
    section "Nächster Schritt"

    # OS-spezifisch: Terminal neu starten
    if is_macos; then
        print -P "  ${C_MAUVE}1.${C_RESET} Terminal.app neu starten für vollständige Übernahme aller Einstellungen"
    elif is_linux; then
        print -P "  ${C_MAUVE}1.${C_RESET} Terminal neu starten oder Shell neuladen: ${C_DIM}exec zsh${C_RESET}"
    fi

    print -P ""
    print -P "  ${C_GREEN}💡 Gib im Terminal '${C_BOLD}dothelp${C_RESET}${C_GREEN}' ein für Hilfe/Dokumentation${C_RESET}"
    print -P ""
}

main "$@"
