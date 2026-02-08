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
fi
export BREW_PREFIX
readonly BREW_PREFIX

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
            # Quelle: https://docs.brew.sh/Support-Tiers#future-macos-support
            # macOS 26 Tahoe = letzte Intel-Version (WWDC25 Platforms State of the Union)
            # Homebrew Intel: Tier 1 bis ~Sep 2026, Tier 3 bis ~Sep 2027, dann unsupported
            ok "macOS auf Intel (x86_64) erkannt"
            warn "macOS 26 ist die letzte Intel-Version – Migration auf Apple Silicon empfohlen"
            warn "Homebrew Intel: Tier 3 ab ~Sep 2026, unsupported ab ~Sep 2027"
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

    # Plattformunabhängiger Test gegen google.com (zuverlässiger als apple.com auf Linux)
    local test_url="https://google.com"
    if ! curl -sfL --head --connect-timeout 5 --max-time 10 "$test_url" >/dev/null 2>&1; then
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
