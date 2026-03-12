#!/usr/bin/env zsh
# ============================================================
# validation.sh - System-Validierungen für Bootstrap
# ============================================================
# Zweck       : Prüft Voraussetzungen (Architektur, OS, Netzwerk, Rechte)
# Pfad        : setup/modules/validation.sh
# Benötigt    : _core.sh
# Plattform   : Universell (macOS + Linux)
#
# STEP        : Architektur-Check | Prüft ob arm64 oder x86_64 | ❌ Exit
# STEP        : macOS-Version-Check | Prüft ob macOS ${MACOS_MIN_VERSION} installiert ist | ❌ Exit
# STEP        : Debian-Version-Check | Prüft ob Debian Trixie (13+) auf 32-bit ARM | ❌ Exit
# STEP        : Netzwerk-Check | Prüft Internetverbindung | ❌ Exit
# STEP        : Schreibrechte-Check | Prüft ob `$HOME` schreibbar ist | ❌ Exit
# STEP        : Xcode CLI Tools | Installiert/prüft Developer Tools | ❌ Exit
# STEP        : Build-Tools | Installiert Build-Essentials (Linux) | ❌ Exit
# ============================================================

# Guard: Core muss geladen sein
[[ -z "${_BOOTSTRAP_CORE_LOADED:-}" ]] && {
    echo "FEHLER: _core.sh muss vor validation.sh geladen werden" >&2
    return 1
}

# ------------------------------------------------------------
# Konfiguration (plattformspezifisch)
# ------------------------------------------------------------
# WICHTIG: Variablen müssen exportiert werden, da Module innerhalb
# einer Funktion (load_module) gesourced werden!
if is_macos; then
    # macOS-Versionen (Single Source of Truth für Generatoren)
    # Homebrew Tier 1: macOS 14+ (https://docs.brew.sh/Support-Tiers)
    # Dotfiles-Minimum liegt höher, da wir aktuelle APIs/Features nutzen
    MACOS_MIN_VERSION=26     # Unterstützt ab (ändert sich selten)
    MACOS_TESTED_VERSION=26  # Zuletzt getestet auf (ändert sich bei Upgrade)
    export MACOS_MIN_VERSION MACOS_TESTED_VERSION
    readonly MACOS_MIN_VERSION MACOS_TESTED_VERSION

    # Homebrew-Prefix (architekturabhängig)
    if [[ "$PLATFORM_ARCH" == "arm64" ]]; then
        BREW_PREFIX="/opt/homebrew"      # Apple Silicon
    else
        BREW_PREFIX="/usr/local"         # Intel
    fi
elif is_linux; then
    # Linuxbrew-Prefix
    BREW_PREFIX="/home/linuxbrew/.linuxbrew"

    # Debian-Mindestversion für 32-bit ARM (Single Source of Truth)
    # apt-packages.sh setzt Trixie voraus – ältere Versionen haben
    # starship, eza, lazygit, fastfetch u.a. nicht in den offiziellen Repos.
    # Trixie ist seit Oktober 2025 das Standard-Raspberry Pi OS.
    typeset -A DEBIAN_VERSION_MAP=(
        [buster]=10
        [bullseye]=11
        [bookworm]=12
        [trixie]=13
        [forky]=14
    )
    DEBIAN_MIN_CODENAME="trixie"
    DEBIAN_MIN_VERSION=13
    export DEBIAN_MIN_CODENAME DEBIAN_MIN_VERSION
    readonly DEBIAN_MIN_CODENAME DEBIAN_MIN_VERSION
fi
export BREW_PREFIX
readonly BREW_PREFIX

# ------------------------------------------------------------
# Debian-Versionsprüfung (intern, von validate_platform aufgerufen)
# ------------------------------------------------------------
# Liest VERSION_CODENAME aus /etc/os-release und vergleicht mit Minimum.
# Unbekannte Codenames werden toleriert (Warnung), fehlende ignoriert.
# SYNC-CHECK: os-release-Pfad-Suche auch in setup/install.sh und
#             terminal/.config/platform.zsh – bei Änderung alle anpassen.
_validate_debian_version() {
    local codename="" osrelease=""

    [[ -f /etc/os-release ]] && osrelease="/etc/os-release"
    [[ -z "$osrelease" && -f /usr/lib/os-release ]] && osrelease="/usr/lib/os-release"

    if [[ -n "$osrelease" ]]; then
        codename=$(. "$osrelease" 2>/dev/null && printf '%s' "${VERSION_CODENAME:-}")
    fi

    if [[ -z "$codename" ]]; then
        warn "VERSION_CODENAME nicht in /etc/os-release gefunden"
        warn "Kann Debian-Version nicht prüfen – fahre fort"
        return 0
    fi

    local version="${DEBIAN_VERSION_MAP[$codename]:-0}"

    if (( version == 0 )); then
        warn "Unbekannter Debian-Codename: $codename"
        warn "Kann Debian-Version nicht prüfen – fahre fort"
        return 0
    fi

    if (( version < DEBIAN_MIN_VERSION )); then
        err "Debian $codename ($version) wird nicht unterstützt"
        err "Minimum: Debian ${DEBIAN_MIN_CODENAME} (${DEBIAN_MIN_VERSION})"
        err ""
        err "Die APT-Paketliste setzt Debian Trixie voraus."
        err "Auf älteren Versionen fehlen: starship, eza, lazygit, fastfetch u.a."
        err ""
        err "Raspberry Pi OS auf Trixie aktualisieren:"
        err "  Neues Image mit Raspberry Pi Imager schreiben (empfohlen)"
        err "  oder: sudo apt update && sudo apt full-upgrade"
        err ""
        err "Trixie ist seit Oktober 2025 das Standard-Raspberry Pi OS"
        err "und läuft auf allen Pi-Modellen (inkl. Pi 1 und Zero)."
        return 1
    fi

    ok "Debian $codename ($version) – Minimum ${DEBIAN_MIN_CODENAME} (${DEBIAN_MIN_VERSION}) erfüllt"
    return 0
}

# ------------------------------------------------------------
# Plattform-Prüfung
# ------------------------------------------------------------
validate_platform() {
    CURRENT_STEP="Plattform-Check"

    if is_macos; then
        # Unterstützte Architekturen: Apple Silicon (arm64) und Intel (x86_64)
        if [[ "$PLATFORM_ARCH" == "arm64" ]]; then
            ok "macOS auf Apple Silicon (arm64) erkannt"
        elif [[ "$PLATFORM_ARCH" == "x86_64" ]]; then
            # macOS 26 Tahoe = letzte Intel-Version (WWDC25 Platforms State of the Union)
            # Homebrew Intel-Support ist zeitlich begrenzt – Details siehe Support-Tiers-Doku
            ok "macOS auf Intel (x86_64) erkannt"
            warn "macOS 26 ist die letzte Intel-Version – Migration auf Apple Silicon empfohlen"
            warn "Homebrew Intel-Support läuft perspektivisch aus – Details: https://docs.brew.sh/Support-Tiers"
        else
            err "Nicht unterstützte Architektur: $PLATFORM_ARCH"
            err "Unterstützt: arm64 (Apple Silicon), x86_64 (Intel)"
            return 1
        fi

        # macOS-Version prüfen
        local macos_version macos_major
        macos_version=$(sw_vers -productVersion)
        macos_major=${macos_version%%.*}

        # Exportiere für andere Module
        export MACOS_VERSION="$macos_version"
        export MACOS_MAJOR="$macos_major"

        if (( macos_major < MACOS_MIN_VERSION )); then
            err "macOS $macos_version wird nicht unterstützt"
            err "Unterstützt ab: macOS $MACOS_MIN_VERSION"
            err "Getestet auf: macOS $MACOS_TESTED_VERSION"
            return 1
        fi
        ok "macOS $macos_version unterstützt"

    elif is_linux; then
        ok "Linux erkannt: $PLATFORM_OS ($PLATFORM_ARCH)"

        # 32-bit ARM: Plattform-Abstraktionen funktionieren, aber kein Homebrew
        if [[ "$PLATFORM_ARCH" == armv* ]]; then
            warn "32-bit ARM erkannt – Homebrew/Linuxbrew unterstützt nur arm64/x86_64"
            warn "Homebrew wird übersprungen – Tools via apt/cargo (siehe apt-packages.sh)"

            # Debian-Version prüfen (apt-packages.sh setzt Trixie voraus)
            if is_debian; then
                _validate_debian_version || return 1
            fi
        fi
    else
        err "Nicht unterstützte Plattform: $PLATFORM_OS"
        return 1
    fi

    return 0
}

# ------------------------------------------------------------
# Netzwerk-Prüfung
# ------------------------------------------------------------
# Erforderlich für Homebrew-Installation und Downloads
validate_network() {
    CURRENT_STEP="Netzwerk-Prüfung"

    # Fallback-Kette: github.com (Homebrew/Git), cloudflare.com (CDN), google.com
    local test_urls=("https://github.com" "https://cloudflare.com" "https://google.com")
    local connected=false
    for url in "${test_urls[@]}"; do
        if curl -sfL --head --connect-timeout 3 --max-time 3 "$url" >/dev/null 2>&1; then
            connected=true
            break
        fi
    done
    if [[ "$connected" != true ]]; then
        err "Keine Internetverbindung verfügbar"
        err "Das Bootstrap-Skript benötigt eine aktive Internetverbindung für:"
        err "  • Homebrew/Linuxbrew-Installation"
        err "  • Download von CLI-Tools und Fonts"
        is_macos && err "  • Mac App Store Apps (optional)"
        err ""
        err "Bitte Netzwerkverbindung herstellen und erneut versuchen."
        return 1
    fi

    ok "Internetverbindung verfügbar"
    return 0
}

# ------------------------------------------------------------
# Schreibrechte-Prüfung
# ------------------------------------------------------------
# Wichtig bei NFS/SMB-Mounts oder restriktiven Berechtigungen
validate_write_permissions() {
    CURRENT_STEP="Schreibrechte-Prüfung"

    if ! touch "$HOME/.dotfiles_write_test" 2>/dev/null; then
        err "Keine Schreibrechte im Home-Verzeichnis: $HOME"
        err "Das Bootstrap-Skript muss Dateien in ~ erstellen können."
        return 1
    fi
    rm -f "$HOME/.dotfiles_write_test"

    ok "Schreibrechte vorhanden"
    return 0
}

# ------------------------------------------------------------
# Build-Tools (plattformspezifisch)
# ------------------------------------------------------------
# macOS: Xcode CLI Tools, Linux: build-essential/Development Tools
validate_build_tools() {
    CURRENT_STEP="Build-Tools"

    if is_macos; then
        # Xcode Command Line Tools (Voraussetzung für git/clang und Homebrew)
        if ! xcode-select -p >/dev/null 2>&1; then
            log "Xcode Command Line Tools werden benötigt (für git/Homebrew). Starte Installation..."
            xcode-select --install || true
            err "Bitte Installation der Command Line Tools abschließen und Skript danach erneut ausführen."
            return 1
        fi
        ok "Xcode CLI Tools vorhanden"

    elif is_linux; then
        # Prüfe ob grundlegende Build-Tools vorhanden sind
        if ! command -v gcc >/dev/null 2>&1 && ! command -v clang >/dev/null 2>&1; then
            warn "Keine Build-Tools gefunden (gcc/clang)"
            if is_fedora; then
                log "Installiere mit: sudo dnf groupinstall 'Development Tools'"
            elif is_debian; then
                log "Installiere mit: sudo apt install build-essential"
            elif is_arch; then
                log "Installiere mit: sudo pacman -S base-devel"
            fi
            # Kein harter Fehler - Homebrew kann einiges selbst mitbringen
            warn "Homebrew wird versuchen, fehlende Tools zu installieren"
        else
            ok "Build-Tools vorhanden"
        fi
    fi

    return 0
}

# ------------------------------------------------------------
# Haupt-Setup-Funktion
# ------------------------------------------------------------
# Führt alle Validierungen in der richtigen Reihenfolge aus
setup_validation() {
    section "System-Prüfung"
    validate_platform || return 1
    validate_network || return 1
    validate_write_permissions || return 1
    validate_build_tools || return 1

    return 0
}
