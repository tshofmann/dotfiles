#!/usr/bin/env zsh
# ============================================================
# bootstrap.sh - macOS Bootstrap Orchestrator
# ============================================================
# Zweck   : Lädt und führt Bootstrap-Module in definierter Reihenfolge aus
# Aufruf  : ./bootstrap.sh
# Docs    : https://github.com/tshofmann/dotfiles#readme
# Module  : setup/modules/ (validation, homebrew, font, terminal-profile, starship, xcode-theme, zsh-sessions)
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
# Argumente:
#   $1 - Modul-Name (ohne .sh)
# Rückgabe: 0 = Erfolg, 1 = Fehler, 2 = Übersprungen
load_module() {
    local module="$1"
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
readonly -a MODULES=(
    validation         # Architektur, macOS, Netzwerk, Rechte, Xcode CLI
    homebrew           # Homebrew + Brewfile (benötigt: validation)
    font               # Font-Verifikation (benötigt: homebrew)
    terminal-profile   # Terminal-Profil Import (benötigt: font)
    starship           # Starship-Theme (benötigt: homebrew)
    xcode-theme        # Xcode Theme (optional, wenn Xcode installiert)
    zsh-sessions       # ZSH Sessions Check (Info-Modul)
)

# ------------------------------------------------------------
# Hauptprogramm
# ------------------------------------------------------------
main() {
    # macOS-Version für Banner (wird von validation.sh gesetzt, hier Fallback)
    local macos_version
    macos_version=$(sw_vers -productVersion 2>/dev/null || echo "unbekannt")

    print "==> ${C_BOLD}macOS Bootstrap${C_RESET} ${C_DIM}(Version $macos_version)${C_RESET}"

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
    print ""
    ok "Setup abgeschlossen"
    print ""
    log "${C_BOLD}Nächste Schritte:${C_RESET}"
    log "  ${C_BOLD}1.${C_RESET} Terminal.app neu starten für vollständige Übernahme aller Einstellungen"
    log "  ${C_BOLD}2.${C_RESET} Konfigurationsdateien verlinken: ${C_DIM}cd $DOTFILES_DIR && stow --adopt -R terminal editor && git reset --hard HEAD${C_RESET}"
    log "  ${C_BOLD}3.${C_RESET} Git-Hooks aktivieren: ${C_DIM}git config core.hooksPath .github/hooks${C_RESET}"
    log "  ${C_BOLD}4.${C_RESET} bat Theme-Cache bauen: ${C_DIM}bat cache --build${C_RESET}"
    log "  ${C_BOLD}5.${C_RESET} tldr-Pages herunterladen: ${C_DIM}tldr --update${C_RESET}"
    print ""
    print "  ${C_GREEN}💡 Gib im Terminal '${C_BOLD}dothelp${C_RESET}${C_GREEN}' ein für Hilfe/Dokumentation${C_RESET}"
    print ""
}

main "$@"
