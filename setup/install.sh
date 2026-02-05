#!/bin/sh
# ============================================================
# install.sh - POSIX-kompatibler Bootstrap-Einstiegspunkt
# ============================================================
# Zweck       : Stellt sicher, dass zsh verfügbar ist und startet Bootstrap
# Aufruf      : ./install.sh oder curl ... | sh
# Kompatibel  : POSIX sh, bash, dash, zsh
# Plattformen : macOS, Fedora, Debian, Arch
# ============================================================
# Dieser Wrapper ist absichtlich POSIX-kompatibel, da zsh auf
# frischen Linux-Systemen möglicherweise nicht installiert ist.
# ============================================================

set -eu

# ------------------------------------------------------------
# Farben (POSIX-kompatibel, ohne print -P)
# ------------------------------------------------------------
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    BOLD='\033[1m'
    RESET='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    BOLD=''
    RESET=''
fi

log()  { printf "${BLUE}→${RESET} %s\n" "$1"; }
ok()   { printf "${GREEN}✔${RESET} %s\n" "$1"; }
warn() { printf "${YELLOW}⚠${RESET} %s\n" "$1"; }
err()  { printf "${RED}✖${RESET} %s\n" "$1" >&2; }

# ------------------------------------------------------------
# Plattform-Erkennung (POSIX-kompatibel)
# ------------------------------------------------------------
detect_platform() {
    case "$(uname -s)" in
        Darwin)
            echo "macos"
            ;;
        Linux)
            if [ -f /etc/fedora-release ]; then
                echo "fedora"
            elif [ -f /etc/debian_version ]; then
                echo "debian"
            elif [ -f /etc/arch-release ]; then
                echo "arch"
            else
                echo "linux-unknown"
            fi
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# ------------------------------------------------------------
# zsh-Installation nach Plattform
# ------------------------------------------------------------
install_zsh() {
    platform="$1"

    case "$platform" in
        macos)
            # macOS hat zsh seit Catalina (10.15) als Standard-Shell
            # Sollte nie erreicht werden, aber als Fallback vorhanden
            err "zsh sollte auf macOS vorinstalliert sein."
            err "Falls nicht: brew install zsh"
            exit 1
            ;;
        fedora)
            log "Installiere zsh via dnf..."
            sudo dnf install -y zsh
            ;;
        debian)
            log "Installiere zsh via apt..."
            sudo apt-get update
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
# Default-Shell auf zsh ändern
# ------------------------------------------------------------
change_default_shell() {
    current_shell=$(basename "$SHELL")
    zsh_path=$(command -v zsh)

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

    # Bestätigung einholen
    printf "\n"
    printf "Default-Shell auf zsh ändern? [y/N] "
    read -r response

    case "$response" in
        [yY]|[yY][eE][sS])
            log "Ändere Default-Shell zu zsh..."
            if chsh -s "$zsh_path"; then
                ok "Default-Shell geändert zu: $zsh_path"
                warn "Änderung wird nach erneutem Login aktiv"
            else
                warn "chsh fehlgeschlagen - Shell manuell ändern mit: chsh -s $zsh_path"
            fi
            ;;
        *)
            warn "Default-Shell nicht geändert"
            warn "Manuell ändern mit: chsh -s $zsh_path"
            ;;
    esac
}

# ------------------------------------------------------------
# Hauptlogik
# ------------------------------------------------------------
main() {
    printf "\n${BOLD}Dotfiles Installation${RESET}\n"
    printf "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n"

    # Plattform erkennen
    platform=$(detect_platform)
    log "Plattform erkannt: $platform"

    # zsh-Verfügbarkeit prüfen
    zsh_was_installed=false
    if command -v zsh >/dev/null 2>&1; then
        zsh_version=$(zsh --version | head -1)
        ok "zsh gefunden: $zsh_version"
    else
        warn "zsh nicht gefunden"

        # Interaktive Bestätigung für sudo-Operationen
        printf "\n"
        printf "zsh muss installiert werden (benötigt sudo auf Linux).\n"
        printf "Fortfahren? [y/N] "
        read -r response

        case "$response" in
            [yY]|[yY][eE][sS])
                install_zsh "$platform"

                # Verifizieren
                if command -v zsh >/dev/null 2>&1; then
                    ok "zsh erfolgreich installiert"
                    zsh_was_installed=true
                else
                    err "zsh-Installation fehlgeschlagen"
                    exit 1
                fi
                ;;
            *)
                err "Installation abgebrochen"
                exit 1
                ;;
        esac
    fi

    # Default-Shell prüfen/ändern (nur auf Linux, macOS hat bereits zsh)
    if [ "$platform" != "macos" ]; then
        change_default_shell
    fi

    # Script-Verzeichnis ermitteln (POSIX-kompatibel)
    # Funktioniert auch bei Symlinks und ./install.sh Aufruf
    script_dir="$(cd "$(dirname "$0")" && pwd)"
    bootstrap_script="$script_dir/bootstrap.sh"

    # Bootstrap existiert?
    if [ ! -f "$bootstrap_script" ]; then
        err "bootstrap.sh nicht gefunden: $bootstrap_script"
        exit 1
    fi

    # Bootstrap mit zsh ausführen
    printf "\n"
    log "Starte Bootstrap mit zsh..."
    printf "\n"

    exec zsh "$bootstrap_script"
}

main "$@"
