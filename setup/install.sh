#!/bin/sh
# ============================================================
# install.sh - POSIX-kompatibler Bootstrap-Einstiegspunkt
# ============================================================
# Zweck       : Stellt zsh/Abhängigkeiten bereit und startet Bootstrap
# Aufruf      : Aus geklontem/entpacktem Repo: ./install.sh
# Kompatibel  : POSIX sh, bash, dash, zsh
# Plattformen : macOS, Fedora, Debian, Arch
# ============================================================
# Dieser Wrapper ist absichtlich POSIX-kompatibel, da zsh auf
# frischen Linux-Systemen möglicherweise nicht installiert ist.
#
# zsh ist eine feste Abhängigkeit – keine interaktive Bestätigung.
# ============================================================

set -eu

# Script-Verzeichnis ermitteln (POSIX-kompatibel)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ------------------------------------------------------------
# Logging laden (Farben + Funktionen)
# ------------------------------------------------------------
# Shared Library mit POSIX-kompatiblen Logging-Funktionen
. "$SCRIPT_DIR/lib/logging.sh"

# ------------------------------------------------------------
# Plattform-Erkennung (POSIX-kompatibel)
# HINWEIS: Parallele ZSH-Variante in terminal/.config/platform.zsh _detect_distro()
# ------------------------------------------------------------
detect_platform() {
    case "$(uname -s)" in
        Darwin)
            echo "macos"
            ;;
        Linux)
            # /etc/os-release ist freedesktop-Standard (Fedora, Debian, Arch, Ubuntu, ...)
            # ID_LIKE behandelt Derivate (z.B. Ubuntu → debian)
            # Empfohlenes Pattern: einmal sourcen (systemd os-release Dokumentation)
            _osrelease=""
            if [ -f /etc/os-release ]; then
                _osrelease="/etc/os-release"
            elif [ -f /usr/lib/os-release ]; then
                _osrelease="/usr/lib/os-release"
            fi

            _distro_id=""
            _distro_id_like=""
            if [ -n "$_osrelease" ]; then
                # Einmal sourcen, beide Werte per Separator ausgeben
                # ID/ID_LIKE enthalten per freedesktop-Spec nur [a-z0-9._- ]
                _distro_info=$(. "$_osrelease" && printf '%s:%s' "$ID" "${ID_LIKE:-}")
                _distro_id="${_distro_info%%:*}"
                _distro_id_like="${_distro_info#*:}"
            fi

            case "$_distro_id" in
                fedora)         echo "fedora" ;;
                debian|ubuntu)  echo "debian" ;;
                arch|manjaro)   echo "arch" ;;
                *)
                    # Fallback: ID_LIKE für unbekannte Derivate
                    case "$_distro_id_like" in
                        *debian*) echo "debian" ;;
                        *fedora*) echo "fedora" ;;
                        *arch*)   echo "arch" ;;
                        *)        echo "linux-unknown" ;;
                    esac
                    ;;
            esac
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# ------------------------------------------------------------
# sudo-Verfügbarkeit prüfen (nur Linux)
# ------------------------------------------------------------
check_sudo() {
    if ! command -v sudo >/dev/null 2>&1; then
        err "sudo nicht gefunden – wird für Paketinstallation benötigt"
        err "Als root: apt install sudo / dnf install sudo / pacman -S sudo"
        exit 1
    fi
}

# ------------------------------------------------------------
# zsh-Installation nach Plattform (nicht-interaktiv)
# ------------------------------------------------------------
install_zsh() {
    platform="$1"

    case "$platform" in
        macos)
            # macOS hat zsh seit Catalina (10.15) als Standard-Shell
            # Sollte nie erreicht werden
            err "zsh sollte auf macOS vorinstalliert sein."
            exit 1
            ;;
        fedora)
            log "Installiere zsh via dnf..."
            sudo dnf install -y zsh
            ;;
        debian)
            log "Installiere zsh via apt..."
            sudo apt-get update -qq
            sudo apt-get install -y zsh
            ;;
        arch)
            log "Installiere zsh via pacman..."
            sudo pacman -S --noconfirm zsh
            ;;
        *)
            err "Unbekannte Plattform: $platform"
            err "Bitte zsh manuell installieren und erneut ausführen."
            exit 1
            ;;
    esac
}

# ------------------------------------------------------------
# Default-Shell auf zsh ändern (nicht-interaktiv)
# ------------------------------------------------------------
set_default_shell() {
    # sudo wird für /etc/shells und chsh benötigt
    check_sudo

    zsh_path=$(command -v zsh)

    # Aktuelle Default-Shell ermitteln
    # $SHELL kann veraltet sein (z.B. nach chsh ohne Neulogin),
    # daher auf Linux getent als zuverlässigere Quelle nutzen
    if command -v getent >/dev/null 2>&1; then
        current_shell=$(basename "$(getent passwd "$(whoami)" | cut -d: -f7)")
    else
        current_shell=$(basename "$SHELL")
    fi

    # Bereits zsh?
    if [ "$current_shell" = "zsh" ]; then
        ok "Default-Shell ist bereits zsh"
        return 0
    fi

    log "Aktuelle Default-Shell: $current_shell"

    # zsh zu /etc/shells hinzufügen falls nicht vorhanden
    if ! grep -qx "$zsh_path" /etc/shells 2>/dev/null; then
        log "Füge $zsh_path zu /etc/shells hinzu..."
        echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
    fi

    # Shell ändern
    log "Ändere Default-Shell zu zsh..."
    if chsh -s "$zsh_path"; then
        ok "Default-Shell geändert zu: $zsh_path"
        warn "Änderung wird nach erneutem Login aktiv"
    else
        warn "chsh fehlgeschlagen (evtl. LDAP/AD-Umgebung)"
        warn "Manuell ändern mit: chsh -s $zsh_path"
    fi
}

# ------------------------------------------------------------
# Hauptlogik
# ------------------------------------------------------------
main() {
    printf "\n${C_BOLD}${C_MAUVE}%s${C_RESET}\n" "Dotfiles Installation"
    printf "${C_DIM}%s${C_RESET}\n\n" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Nicht als root ausführen (sudo wird nur gezielt eingesetzt)
    if [ "$(id -u)" = "0" ]; then
        err "install.sh darf nicht als root ausgeführt werden."
        err "Starte ohne sudo – bei Bedarf wird gezielt nach dem Passwort gefragt."
        exit 1
    fi

    # Plattform erkennen
    platform=$(detect_platform)
    log "Plattform: $platform"

    # zsh ist eine feste Abhängigkeit
    if command -v zsh >/dev/null 2>&1; then
        zsh_version=$(zsh --version | head -1)
        ok "zsh: $zsh_version"
    else
        log "zsh nicht gefunden – installiere..."
        check_sudo
        install_zsh "$platform"

        # Verifizieren
        if command -v zsh >/dev/null 2>&1; then
            ok "zsh erfolgreich installiert"
        else
            err "zsh-Installation fehlgeschlagen"
            exit 1
        fi
    fi

    # Default-Shell auf zsh setzen (nur auf Linux)
    if [ "$platform" != "macos" ]; then
        set_default_shell
    fi

    # Bootstrap-Pfad (SCRIPT_DIR bereits am Datei-Anfang gesetzt)
    bootstrap_script="$SCRIPT_DIR/bootstrap.sh"

    # Bootstrap existiert?
    if [ ! -f "$bootstrap_script" ]; then
        err "bootstrap.sh nicht gefunden: $bootstrap_script"
        exit 1
    fi

    # Bootstrap mit zsh ausführen
    printf "\n"
    log "Starte Bootstrap..."
    printf "\n"

    exec zsh "$bootstrap_script"
}

main "$@"
