#!/bin/sh
# ============================================================
# install.sh - POSIX-kompatibler Bootstrap-Einstiegspunkt
# ============================================================
# Zweck       : Stellt ssh/Abhängigkeiten bereit und startet Bootstrap
# Aufruf      : ./install.sh oder curl ... | sh
# Kompatibel  : POSIX sh, bash, dash, zsh
# Plattformen : macOS, Fedora, Debian, Arch
# ============================================================
# Dieser Wrapper ist absichtlich POSIX-kompatibel, da zsh auf
# frischen Linux-Systemen möglicherweise nicht installiert ist.
#
# zsh ist eine feste Abhängigkeit – keine interaktive Bestätigung.
# ============================================================

set -eu

# ------------------------------------------------------------
# Farben (Catppuccin Mocha ANSI-Approximation)
# ------------------------------------------------------------
# Echte Theme-Farben sind noch nicht verfügbar (theme-style wird
# erst nach stow geladen). Diese Werte sind Catppuccin-nah.
if [ -t 1 ]; then
    RED='\033[38;5;210m'      # ~Red
    GREEN='\033[38;5;157m'    # ~Green
    YELLOW='\033[38;5;223m'   # ~Yellow
    BLUE='\033[38;5;111m'     # ~Blue
    MAUVE='\033[38;5;183m'    # ~Mauve
    TEXT='\033[38;5;253m'     # ~Text
    BOLD='\033[1m'
    DIM='\033[2m'
    RESET='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' MAUVE='' TEXT='' BOLD='' DIM='' RESET=''
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
    printf "\n${BOLD}${MAUVE}Dotfiles Installation${RESET}\n"
    printf "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n\n"

    # Plattform erkennen
    platform=$(detect_platform)
    log "Plattform: $platform"

    # zsh ist eine feste Abhängigkeit
    if command -v zsh >/dev/null 2>&1; then
        zsh_version=$(zsh --version | head -1)
        ok "zsh: $zsh_version"
    else
        log "zsh nicht gefunden – installiere..."
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

    # Script-Verzeichnis ermitteln (POSIX-kompatibel)
    script_dir="$(cd "$(dirname "$0")" && pwd)"
    bootstrap_script="$script_dir/bootstrap.sh"

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
