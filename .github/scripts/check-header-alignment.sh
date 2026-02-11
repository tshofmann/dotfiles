#!/usr/bin/env zsh
# ============================================================
# check-header-alignment.sh - Header-Einrückungen prüfen
# ============================================================
# Zweck       : Prüft ob Header-Felder korrekt auf 12 Zeichen
#               gepaddet sind (Feldname + Spaces + ' :')
# Pfad        : .github/scripts/check-header-alignment.sh
# Aufruf      : ./.github/scripts/check-header-alignment.sh
# Nutzt       : theme-style (Farben)
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
# Header-Einrückungen prüfen (Feldname auf 12 Zeichen gepaddet)
# ------------------------------------------------------------
check_header_alignment() {
    local errors=0

    # Standard-Felder: Feldname wird mit Leerzeichen auf 12 Zeichen gepaddet,
    # dann folgt " :". Bei 12-Zeichen-Feldnamen (z.B. Alternativen) nur " :" anhängen.
    local -a fields=(
        "Zweck       :"
        "Pfad        :"
        "Docs        :"
        "Config      :"
        "Nutzt       :"
        "Ersetzt     :"
        "Aliase      :"
        "Aufruf      :"
        "Hinweis     :"
        "Verwendung  :"
        "Theme       :"
        "Laden       :"
        "Geladen     :"
        "STEP        :"
        "Benötigt    :"
        "Plattform   :"
        "Font        :"
        "Speicherort :"
        "Packages    :"
        "Hooks       :"
        "Cache       :"
        "Aktivierung :"
        "Zielort     :"
        "Profil      :"
        "Alternativen :"
        "Lizenz      :"
        "Generiert   :"
    )

    # Alle Dateien mit Header-Blöcken prüfen
    local files=(
        "$DOTFILES_DIR"/terminal/.config/alias/*.alias(N)
        "$DOTFILES_DIR"/terminal/.config/fzf/*(N.)
        "$DOTFILES_DIR"/terminal/.config/zsh/*.zsh(N)
        "$DOTFILES_DIR"/terminal/.config/*/config(N)
        "$DOTFILES_DIR"/terminal/.config/*/*.toml(N)
        "$DOTFILES_DIR"/terminal/.config/*/*.yml(N)
        "$DOTFILES_DIR"/terminal/.config/theme-style(N)
        "$DOTFILES_DIR"/terminal/.config/fd/ignore(N)
        "$DOTFILES_DIR"/terminal/.config/shellcheckrc(N)
        "$DOTFILES_DIR"/terminal/.zsh*(N)
        "$DOTFILES_DIR"/terminal/.zprofile(N)
        "$DOTFILES_DIR"/terminal/.zlogin(N)
        "$DOTFILES_DIR"/setup/*.sh(N)
        "$DOTFILES_DIR"/setup/modules/*.sh(N)
        "$DOTFILES_DIR"/setup/Brewfile(N)
        "$DOTFILES_DIR"/.github/scripts/**/*.sh(N)
    )

    for file in "${files[@]}"; do
        [[ ! -f "$file" ]] && continue
        local relpath="${file#$DOTFILES_DIR/}"

        for field in "${fields[@]}"; do
            local fieldname="${field%% *}"
            # Prüfe ob Feld existiert aber falsch eingerückt ist
            if grep -q "^# ${fieldname}[[:space:]]*:" "$file" 2>/dev/null; then
                if ! grep -q "^# ${field}" "$file" 2>/dev/null; then
                    err "$relpath: '# ${fieldname}' falsch eingerückt (Standard: '# ${field}')"
                    (( errors++ )) || true
                fi
            fi
        done
    done

    if (( errors > 0 )); then
        err "$errors Header-Feld(er) mit falscher Einrückung"
        echo ""
        echo "  Standard: Feldname auf 12 Zeichen padden + ' :'"
        echo "    # Zweck       :  (5 Zeichen + 7 Spaces = 12)"
        echo "    # Alternativen :  (12 Zeichen + 0 Spaces = 12)"
        return 1
    fi

    ok "Header-Einrückungen OK"
    return 0
}

# ------------------------------------------------------------
# Hauptprogramm
# ------------------------------------------------------------
log "Prüfe Header-Einrückungen..."
check_header_alignment
