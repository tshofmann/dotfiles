#!/usr/bin/env zsh
# ============================================================
# check-header-alignment.sh - Header-Einrückungen prüfen
# ============================================================
# Zweck       : Prüft ob Header-Felder korrekt auf 12 Zeichen
#               gepaddet sind (Feldname + Spaces + ' :')
# Pfad        : .github/scripts/check-header-alignment.sh
# Aufruf      : ./.github/scripts/check-header-alignment.sh
# Nutzt       : lib/log.sh (Logging + Farben)
# Generiert   : Nichts (nur Validierung)
# ============================================================

set -uo pipefail
setopt extendedglob

# Dotfiles-Verzeichnis ermitteln
SCRIPT_DIR="${0:A:h}"
DOTFILES_DIR="${SCRIPT_DIR:h:h}"  # .github/scripts → dotfiles

# Logging + Farben (geteilte Library)
source "${0:A:h}/lib/log.sh"

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
        "Kommandos   :"
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

    # Korrekte Einrückungen als assoziatives Array (Feldname → volle Zeile)
    local -A correct_alignment
    for field in "${fields[@]}"; do
        correct_alignment[${field%% *}]="$field"
    done

    for file in "${files[@]}"; do
        [[ ! -f "$file" ]] && continue
        local relpath="${file#$DOTFILES_DIR/}"
        local header_sep_count=0

        # Datei einmal lesen – nur Header-Block prüfen
        while IFS= read -r line; do
            # Header-Ende erkennen: 3. "# ====" oder "# Guard"
            if [[ "$line" == "# ===="* ]]; then
                (( header_sep_count++ )) || true
                (( header_sep_count >= 3 )) && break
                continue
            fi
            [[ "$line" == "# Guard"* ]] && break

            # Nur Kommentarzeilen mit "# Feldname...:" matchen
            [[ "$line" != "# "* ]] && continue
            local content="${line#\# }"
            # Feldname extrahieren (Buchstaben inkl. Umlaute)
            local fieldname="${content%%[^a-zA-ZäöüÄÖÜ]*}"
            # Ist dieser Feldname einer der bekannten?
            [[ -z "${correct_alignment[$fieldname]:-}" ]] && continue
            # Prüfe ob nach dem Feldnamen nur Whitespace und ":" folgt
            # (schließt "# Kommandos (via ...)" aus – Klammer ist kein Whitespace)
            local after_name="${content#"$fieldname"}"
            [[ "$after_name" != [[:space:]]#:* ]] && continue
            # Feld gefunden – korrekte Einrückung prüfen
            local expected="# ${correct_alignment[$fieldname]}"
            if [[ "$line" != "$expected"* ]]; then
                err "$relpath: '# ${fieldname}' falsch eingerückt (Standard: '# ${correct_alignment[$fieldname]}')"
                (( errors++ )) || true
            fi
        done < "$file"
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
