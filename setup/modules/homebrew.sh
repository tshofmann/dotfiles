#!/usr/bin/env zsh
# ============================================================
# homebrew.sh - Homebrew Installation und Brewfile
# ============================================================
# Zweck       : Installiert Homebrew und führt Brewfile aus
# Pfad        : setup/modules/homebrew.sh
# Benötigt    : _core.sh, validation.sh (für BREW_PREFIX)
#
# STEP        : Homebrew | Installiert/prüft Homebrew unter `/opt/homebrew` | ❌ Exit
# STEP        : Brewfile | Installiert CLI-Tools via `brew bundle` | ❌ Exit
# ============================================================

# Guard: Core muss geladen sein
[[ -z "${_BOOTSTRAP_CORE_LOADED:-}" ]] && {
    echo "FEHLER: _core.sh muss vor homebrew.sh geladen werden" >&2
    return 1
}

# Guard: BREW_PREFIX muss definiert sein (von validation.sh)
[[ -z "${BREW_PREFIX:-}" ]] && {
    err "BREW_PREFIX nicht definiert - validation.sh fehlt?"
    return 1
}

# ------------------------------------------------------------
# Konfiguration
# ------------------------------------------------------------
readonly BREWFILE="${SCRIPT_DIR}/Brewfile"

# ------------------------------------------------------------
# Homebrew Installation
# ------------------------------------------------------------
# SICHERHEITSHINWEIS: Der offizielle Homebrew-Installer wird von HEAD geladen.
# Dies ist der empfohlene Installationsweg (https://brew.sh), birgt aber ein
# theoretisches Supply-Chain-Risiko. Alternativen (Pinning, lokale Kopie)
# würden manuelle Updates erfordern und schnell veralten.
# Das Homebrew-Team signiert die brew-Binaries nach Installation.
install_homebrew() {
    CURRENT_STEP="Homebrew Installation"

    if ! [[ -x "$BREW_PREFIX/bin/brew" ]]; then
        log "Homebrew nicht gefunden, starte Installation..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    # Homebrew-Umgebung initialisieren (idempotent)
    # Stellt sicher, dass PATH, HOMEBREW_PREFIX etc. korrekt gesetzt sind
    if [[ -x "$BREW_PREFIX/bin/brew" ]]; then
        eval "$("$BREW_PREFIX/bin/brew" shellenv)"
        ok "Homebrew bereit"
    else
        err "Homebrew-Binary nicht gefunden unter $BREW_PREFIX/bin/brew"
        return 1
    fi

    return 0
}

# ------------------------------------------------------------
# Brewfile Installation
# ------------------------------------------------------------
install_brewfile() {
    CURRENT_STEP="Brewfile Installation"

    # Brewfile prüfen
    if [[ ! -f "$BREWFILE" ]]; then
        err "Brewfile nicht gefunden: $BREWFILE"
        return 1
    fi

    # CLI-Tools und Font über Brewfile installieren
    # HOMEBREW_NO_AUTO_UPDATE=1: Kein automatisches 'brew update' vor Installation
    # --no-upgrade: Bestehende Formulae nicht upgraden (schneller, reproduzierbarer)
    log "Installiere Abhängigkeiten aus Brewfile"
    if ! HOMEBREW_NO_AUTO_UPDATE=1 brew bundle --no-upgrade --file="$BREWFILE"; then
        err "Brew Bundle fehlgeschlagen – Setup wird abgebrochen"
        return 1
    fi

    ok "Abhängigkeiten installiert"
    return 0
}

# ------------------------------------------------------------
# Haupt-Setup-Funktion
# ------------------------------------------------------------
setup_homebrew() {
    section "Homebrew"
    install_homebrew || return 1
    install_brewfile || return 1

    return 0
}
