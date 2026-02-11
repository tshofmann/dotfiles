#!/usr/bin/env zsh
# ============================================================
# check-executable-permissions.sh - Execute-Berechtigungen prüfen
# ============================================================
# Zweck       : Prüft ob alle relevanten Skripte und fzf-Helper
#               das Execute-Bit gesetzt haben
# Pfad        : .github/scripts/check-executable-permissions.sh
# Aufruf      : ./.github/scripts/check-executable-permissions.sh
# Generiert   : Nichts (nur Validierung)
# ============================================================

setopt errexit nounset pipefail

# Dotfiles-Verzeichnis ermitteln
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Logging
log() { echo "→ $1"; }
ok()  { echo "✔ $1"; }
err() { echo "✖ $1" >&2; }

# ------------------------------------------------------------
# Execute-Berechtigungen prüfen
# ------------------------------------------------------------
check_executable_permissions() {
    local errors=0

    # fzf-Helper müssen ausführbar sein (außer config und *.zsh)
    for file in "$DOTFILES_DIR"/terminal/.config/fzf/*(N); do
        [[ ! -f "$file" ]] && continue
        local name="${file:t}"
        # Überspringe config und .zsh Dateien (werden gesourced)
        [[ "$name" == "config" || "$name" == *.zsh ]] && continue

        if [[ ! -x "$file" ]]; then
            local relpath="${file#${DOTFILES_DIR}/}"
            err "fzf/$name: Fehlende Execute-Berechtigung"
            err "  \u2192 chmod +x $relpath"
            errors=$((errors + 1))
        fi
    done

    # Haupt-Skripte müssen ausführbar sein
    for file in \
        "$DOTFILES_DIR"/setup/bootstrap.sh \
        "$DOTFILES_DIR"/setup/install.sh \
        "$DOTFILES_DIR"/.github/scripts/generate-docs.sh \
        "$DOTFILES_DIR"/.github/scripts/health-check.sh \
        "$DOTFILES_DIR"/.github/scripts/check-header-alignment.sh \
        "$DOTFILES_DIR"/.github/scripts/check-platform-sync.sh \
        "$DOTFILES_DIR"/.github/scripts/check-alias-format.sh \
        "$DOTFILES_DIR"/.github/scripts/check-executable-permissions.sh; do
        if [[ -f "$file" && ! -x "$file" ]]; then
            err "$(basename "$file"): Fehlende Execute-Berechtigung"
            errors=$((errors + 1))
        fi
    done

    if [[ $errors -gt 0 ]]; then
        err "$errors Datei(en) ohne Execute-Berechtigung"
        return 1
    fi

    ok "Execute-Berechtigungen OK"
    return 0
}

# ------------------------------------------------------------
# Hauptprogramm
# ------------------------------------------------------------
log "Prüfe Execute-Berechtigungen..."
check_executable_permissions
