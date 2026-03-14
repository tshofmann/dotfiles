#!/usr/bin/env zsh
# ============================================================
# homebrew.sh - Homebrew Installation und Brewfile
# ============================================================
# Zweck       : Installiert Homebrew und führt Brewfile aus
# Pfad        : setup/modules/homebrew.sh
# Benötigt    : _core.sh, validation.sh (für BREW_PREFIX)
#
# STEP        : Homebrew | Installiert/prüft Homebrew (arm64/x86_64/Linuxbrew) | ❌ Exit
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
typeset -gr BREWFILE="${SCRIPT_DIR}/Brewfile"

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

    # HOMEBREW_NO_AUTO_UPDATE=1: Kein automatisches 'brew update' vor Installation
    # --no-upgrade: Bestehende Formulae nicht upgraden (schneller, reproduzierbarer)
    log "Installiere Abhängigkeiten aus Brewfile"

    # mas-Downloads benötigen --verbose, damit der Fortschrittsbalken sichtbar ist.
    # Ohne --verbose schluckt brew bundle den Output (IO.popen statt system()),
    # mas erkennt kein Terminal und zeigt keinen Fortschritt → sieht aus wie ein Hänger.
    # Deshalb: brew/cask/tap kompakt, mas-Einträge separat mit --verbose.
    if grep -q '^mas ' "$BREWFILE" && is_macos; then
        local tmpfile_main tmpfile_mas
        tmpfile_main=$(mktemp) || { err "Kann temporäre Datei nicht erstellen"; return 1; }
        tmpfile_mas=$(mktemp) || { rm -f "$tmpfile_main"; err "Kann temporäre Datei nicht erstellen"; return 1; }

        grep -v '^mas ' "$BREWFILE" > "$tmpfile_main"
        grep '^mas ' "$BREWFILE" > "$tmpfile_mas"

        # Schritt 1: brew/cask/tap (kompakter Output)
        if ! HOMEBREW_NO_AUTO_UPDATE=1 brew bundle --no-upgrade --file="$tmpfile_main"; then
            rm -f "$tmpfile_main" "$tmpfile_mas"
            err "Brew Bundle fehlgeschlagen – Setup wird abgebrochen"
            return 1
        fi

        # Schritt 2: mas-Apps (verbose → Fortschrittsbalken sichtbar)
        log "Installiere App Store Apps (Administratorrechte können nötig sein)"
        if ! HOMEBREW_NO_AUTO_UPDATE=1 brew bundle --no-upgrade --verbose --file="$tmpfile_mas"; then
            rm -f "$tmpfile_main" "$tmpfile_mas"
            err "Brew Bundle fehlgeschlagen – Setup wird abgebrochen"
            return 1
        fi

        rm -f "$tmpfile_main" "$tmpfile_mas"
    else
        if ! HOMEBREW_NO_AUTO_UPDATE=1 brew bundle --no-upgrade --file="$BREWFILE"; then
            err "Brew Bundle fehlgeschlagen – Setup wird abgebrochen"
            return 1
        fi
    fi

    ok "Abhängigkeiten installiert"
    return 0
}

# ------------------------------------------------------------
# Haupt-Setup-Funktion
# ------------------------------------------------------------
setup_homebrew() {
    section "Homebrew"

    # 32-bit ARM: Homebrew/Linuxbrew unterstützt nur arm64/x86_64
    # Tools werden stattdessen über apt-packages.sh installiert
    if [[ "$PLATFORM_ARCH" == armv* ]]; then
        warn "Homebrew übersprungen – $PLATFORM_ARCH nicht unterstützt"
        warn "Tools werden via apt/cargo installiert (apt-packages Modul)"
        return 0
    fi

    install_homebrew || return 1
    install_brewfile || return 1

    return 0
}
