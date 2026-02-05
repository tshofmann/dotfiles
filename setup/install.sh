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
            # Falls doch nicht vorhanden: via Homebrew
            if command -v brew >/dev/null 2>&1; then
                log "Installiere zsh via Homebrew..."
                brew install zsh
            else
                err "Homebrew nicht gefunden. Bitte zuerst installieren:"
                err "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
                exit 1
            fi
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
# Hauptlogik
# ------------------------------------------------------------
main() {
    printf "\n${BOLD}Dotfiles Installation${RESET}\n"
    printf "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n"

    # Plattform erkennen
    platform=$(detect_platform)
    log "Plattform erkannt: $platform"

    # zsh-Verfügbarkeit prüfen
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
