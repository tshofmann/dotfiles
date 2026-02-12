#!/usr/bin/env zsh
# ============================================================
# check-platform-sync.sh - Plattform-Synchronisation prüfen
# ============================================================
# Zweck       : Prüft ob platform.zsh und install.sh identische
#               Distro-ID Case-Patterns verwenden
# Pfad        : .github/scripts/check-platform-sync.sh
# Aufruf      : ./.github/scripts/check-platform-sync.sh
# Nutzt       : theme-style (Farben), grep, sed, sort
# Generiert   : Nichts (nur Validierung)
# ============================================================

set -uo pipefail

# Dotfiles-Verzeichnis ermitteln
SCRIPT_DIR="${0:A:h}"
DOTFILES_DIR="${SCRIPT_DIR:h:h}"  # .github/scripts → dotfiles

# Farben laden (optional – funktioniert auch ohne)
SHELL_COLORS="$DOTFILES_DIR/terminal/.config/theme-style"
[[ -f "$SHELL_COLORS" ]] && source "$SHELL_COLORS"

# Logging
log()  { echo -e "${C_BLUE:-}→${C_RESET:-} $1"; }
ok()   { echo -e "${C_GREEN:-}✔${C_RESET:-} $1"; }
err()  { echo -e "${C_RED:-}✖${C_RESET:-} $1" >&2; }

# ------------------------------------------------------------
# Plattform-Sync prüfen
# ------------------------------------------------------------
check_platform_sync() {
    local errors=0

    local platform_file="$DOTFILES_DIR/terminal/.config/platform.zsh"
    local install_file="$DOTFILES_DIR/setup/install.sh"

    if [[ ! -f "$platform_file" ]]; then
        err "platform.zsh nicht gefunden: $platform_file"
        return 1
    fi

    if [[ ! -f "$install_file" ]]; then
        err "install.sh nicht gefunden: $install_file"
        return 1
    fi

    # Distro-ID Case-Patterns extrahieren und vergleichen
    # Erfasst primäre IDs (z.B. fedora, debian|ubuntu|raspbian)
    # und ID_LIKE Fallbacks (z.B. *debian*, *fedora*)
    extract_patterns() {
        grep -E '^[[:space:]]+[*a-z][a-z0-9|*]*\)[[:space:]]+(echo[[:space:]]+"(fedora|debian|arch)"|_PLATFORM_DISTRO="(fedora|debian|arch)")' "$1" | \
            sed 's/^[[:space:]]*//' | \
            sed 's/)[[:space:]]*.*//' | \
            sort || true
    }

    local p_patterns
    local i_patterns
    p_patterns=$(extract_patterns "$platform_file")
    i_patterns=$(extract_patterns "$install_file")

    if [[ "$p_patterns" != "$i_patterns" ]]; then
        err "Distro-ID-Patterns nicht synchron!"
        echo ""
        echo "  platform.zsh:"
        echo "$p_patterns" | sed 's/^/    /'
        echo ""
        echo "  install.sh:"
        echo "$i_patterns" | sed 's/^/    /'
        echo ""
        echo "  Beide Dateien müssen identische case-Patterns haben."
        errors=$((errors + 1))
    fi

    # IDs-Zusammenfassung muss identisch sein
    local p_comment
    local i_comment
    p_comment=$(grep '# IDs:' "$platform_file" | head -1 | sed 's/^[[:space:]]*//' || true)
    i_comment=$(grep '# IDs:' "$install_file" | head -1 | sed 's/^[[:space:]]*//' || true)

    if [[ "$p_comment" != "$i_comment" ]]; then
        err "IDs-Zusammenfassung nicht synchron:"
        echo "  platform.zsh: $p_comment"
        echo "  install.sh:   $i_comment"
        errors=$((errors + 1))
    fi

    if [[ $errors -gt 0 ]]; then
        echo ""
        err "$errors Sync-Fehler"
        echo "  Siehe SYNC-CHECK Kommentare in beiden Dateien."
        return 1
    fi

    ok "Plattform-Sync OK"
    return 0
}

# ------------------------------------------------------------
# Hauptprogramm
# ------------------------------------------------------------
log "Prüfe Synchronisation platform.zsh ↔ install.sh..."
check_platform_sync
