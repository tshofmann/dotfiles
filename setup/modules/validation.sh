#!/usr/bin/env zsh
# ============================================================
# validation.sh - System-Validierungen für Bootstrap
# ============================================================
# Zweck       : Prüft Voraussetzungen (Architektur, macOS, Netzwerk, Rechte)
# Pfad        : setup/modules/validation.sh
# Benötigt    : _core.sh
# CURRENT_STEP: Architektur-Check, macOS-Version-Check, Netzwerk-Prüfung,
#               Schreibrechte-Prüfung, Xcode CLI Tools
# ============================================================

# Guard: Core muss geladen sein
[[ -z "${_BOOTSTRAP_CORE_LOADED:-}" ]] && {
    echo "FEHLER: _core.sh muss vor validation.sh geladen werden" >&2
    return 1
}

# ------------------------------------------------------------
# Konfiguration
# ------------------------------------------------------------
# macOS-Versionen (Single Source of Truth für Generatoren)
# Homebrew Tier 1 Support: macOS 14+, siehe https://docs.brew.sh/Support-Tiers
readonly MACOS_MIN_VERSION=26     # Unterstützt ab (ändert sich selten)
readonly MACOS_TESTED_VERSION=26  # Zuletzt getestet auf (ändert sich bei Upgrade)

# Homebrew-Prefix für Apple Silicon
readonly BREW_PREFIX="/opt/homebrew"

# ------------------------------------------------------------
# Architektur-Prüfung
# ------------------------------------------------------------
# Nur Apple Silicon (arm64) wird unterstützt
validate_architecture() {
    CURRENT_STEP="Architektur-Check"

    if [[ $(uname -m) != "arm64" ]]; then
        err "Dieses Setup ist nur für Apple Silicon (arm64) vorgesehen"
        return 1
    fi

    ok "Apple Silicon (arm64) erkannt"
    return 0
}

# ------------------------------------------------------------
# macOS-Version Prüfung
# ------------------------------------------------------------
validate_macos_version() {
    CURRENT_STEP="macOS-Version-Check"

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
    return 0
}

# ------------------------------------------------------------
# Netzwerk-Prüfung
# ------------------------------------------------------------
# Erforderlich für Homebrew-Installation und Downloads
validate_network() {
    CURRENT_STEP="Netzwerk-Prüfung"

    # Verwendet curl HEAD-Request mit kurzem Timeout gegen Apple-Server
    if ! curl -sfL --head --connect-timeout 5 --max-time 10 "https://apple.com" >/dev/null 2>&1; then
        err "Keine Internetverbindung verfügbar"
        err "Das Bootstrap-Skript benötigt eine aktive Internetverbindung für:"
        err "  • Homebrew-Installation"
        err "  • Download von CLI-Tools und Fonts"
        err "  • Mac App Store Apps (optional)"
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
# Xcode Command Line Tools
# ------------------------------------------------------------
# Voraussetzung für git/clang und Homebrew
validate_xcode_cli() {
    CURRENT_STEP="Xcode CLI Tools"

    if ! xcode-select -p >/dev/null 2>&1; then
        log "Xcode Command Line Tools werden benötigt (für git/Homebrew). Starte Installation..."
        xcode-select --install || true
        err "Bitte Installation der Command Line Tools abschließen und Skript danach erneut ausführen."
        return 1
    fi

    ok "Xcode CLI Tools vorhanden"
    return 0
}

# ------------------------------------------------------------
# Haupt-Setup-Funktion
# ------------------------------------------------------------
# Führt alle Validierungen in der richtigen Reihenfolge aus
setup_validation() {
    validate_architecture || return 1
    validate_macos_version || return 1
    validate_network || return 1
    validate_write_permissions || return 1
    validate_xcode_cli || return 1

    return 0
}
