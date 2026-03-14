#!/usr/bin/env zsh
# ============================================================
# check-alias-format.sh - Alias-Datei-Format prüfen
# ============================================================
# Zweck       : Prüft Format-Konventionen der .alias-Dateien
#               (Header, Guard, Pflichtfelder, Sektionen,
#               Beschreibungskommentare)
# Pfad        : .github/scripts/check-alias-format.sh
# Aufruf      : ./.github/scripts/check-alias-format.sh
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
# Alias-Datei-Format prüfen
# ------------------------------------------------------------
# Prüft 6 Konventionen aus CONTRIBUTING.md:
#   1. Header-Block (^# ====) in den ersten 3 Zeilen
#   2. Guard-Check (command -v) vorhanden
#   3. Pflichtfelder (Zweck, Pfad, Docs, Nutzt, Ersetzt) im Header
#   4. Mindestens eine Sektion mit Trennern (^# ----)
#   5. Beschreibungskommentar über jeder alias/function-Definition
#      (private Funktionen mit _prefix sind ausgenommen)
#   6. Feldordnung im Header (Zweck → Pfad → Docs → Config → Generiert → Nutzt → Ersetzt → ...)
# ------------------------------------------------------------
check_alias_format() {
    local errors=0
    local name field sep_count lnum prevline defline funcline
    local fo_fld fo_ln fo_prev fo_prev_ln header_end header_block
    typeset -A fo_lines

    for file in "$DOTFILES_DIR"/terminal/.config/alias/*.alias(N); do
        name=$(basename "$file")

        # 1. Header-Block vorhanden?
        if ! head -3 "$file" | grep -q "^# ===="; then
            err "$name: Kein Header-Block"
            (( errors++ )) || true
        fi

        # Header-Block extrahieren (Zeile 1 bis zur 3. # ====)
        # Struktur: Opening ==== / Titel / ==== / Felder / ==== (3.)
        # Prüfungen 3 und 6 suchen NUR im Header, nicht in Sektions-Kommentaren
        header_end=$(grep -n "^# ====" "$file" | sed -n '3p' | cut -d: -f1)
        header_block=$(head -"${header_end:-20}" "$file")

        # 2. Guard-Check vorhanden?
        if ! grep -q "command -v.*>/dev/null" "$file"; then
            err "$name: Kein Guard-Check"
            (( errors++ )) || true
        fi

        # 3. Pflichtfelder im Header (CONTRIBUTING.md: Zweck, Pfad, Docs, Nutzt, Ersetzt)
        for field in Zweck Pfad Docs Nutzt Ersetzt; do
            if ! printf '%s\n' "$header_block" | grep -q "^# ${field}[[:space:]]"; then
                err "$name: Pflichtfeld '${field}' fehlt im Header"
                (( errors++ )) || true
            fi
        done

        # 4. Sektions-Trenner (mindestens eine Sektion nach dem Header)
        sep_count=$(grep -c "^# ----" "$file") || true
        if (( sep_count < 2 )); then
            err "$name: Keine Sektions-Trenner (erwartet: mindestens 2)"
            (( errors++ )) || true
        fi

        # 5. Beschreibungskommentar über alias- und Funktionsdefinitionen
        #    CONTRIBUTING.md: "Jede Funktion und jeder Alias benötigt einen
        #    Beschreibungskommentar direkt darüber"
        #    Private Funktionen (_prefix) sind durch das grep-Pattern
        #    ^[[:space:]]*[a-zA-Z] bereits ausgeschlossen.

        # 5a. Aliases prüfen
        while IFS=: read -r lnum _; do
            prevline=$(sed -n "$((lnum - 1))p" "$file")
            if [[ "$prevline" != *"#"* ]]; then
                defline=$(sed -n "${lnum}p" "$file")
                defline="${defline#"${defline%%[![:space:]]*}"}"
                err "$name:$lnum: Beschreibungskommentar fehlt über '${defline%%=*}'"
                (( errors++ )) || true
            fi
        done < <(grep -n "^[[:space:]]*alias [a-zA-Z]" "$file")

        # 5b. Funktionen prüfen (^[a-zA-Z] schließt _prefix aus)
        while IFS=: read -r lnum _; do
            prevline=$(sed -n "$((lnum - 1))p" "$file")
            if [[ "$prevline" != *"#"* ]]; then
                funcline=$(sed -n "${lnum}p" "$file")
                funcline="${funcline%%\(\)*}"
                funcline="${funcline#"${funcline%%[![:space:]]*}"}"
                err "$name:$lnum: Beschreibungskommentar fehlt über '${funcline}()'"
                (( errors++ )) || true
            fi
        done < <(grep -n "^[[:space:]]*[a-zA-Z][a-zA-Z0-9_-]*() {" "$file")

        # 6. Feldordnung im Header prüfen
        #    Standard: Zweck → Pfad → Docs → Config → Generiert → Nutzt → Ersetzt → Kommandos → Aliase
        fo_lines=()
        for fo_fld in Zweck Pfad Docs Config Generiert Nutzt Ersetzt Kommandos Aliase; do
            fo_ln=$(printf '%s\n' "$header_block" | grep -n "^# ${fo_fld}[[:space:]]" 2>/dev/null | head -1 | cut -d: -f1)
            [[ -n "$fo_ln" ]] && fo_lines[$fo_fld]=$fo_ln
        done
        fo_prev="" fo_prev_ln=0
        for fo_fld in Zweck Pfad Docs Config Generiert Nutzt Ersetzt Kommandos Aliase; do
            if [[ -n "${fo_lines[$fo_fld]:-}" ]]; then
                if [[ -n "$fo_prev" ]] && (( fo_lines[$fo_fld] < fo_prev_ln )); then
                    err "$name: Feldordnung: '${fo_fld}' (Zeile ${fo_lines[$fo_fld]}) steht vor '${fo_prev}' (Zeile ${fo_prev_ln})"
                    (( errors++ )) || true
                fi
                fo_prev="$fo_fld"
                fo_prev_ln=${fo_lines[$fo_fld]}
            fi
        done
    done

    if (( errors > 0 )); then
        err "$errors Alias-Datei(en) mit Format-Fehlern"
        return 1
    fi

    ok "Alias-Format OK"
    return 0
}

# ------------------------------------------------------------
# Hauptprogramm
# ------------------------------------------------------------
log "Prüfe Alias-Datei-Format..."
check_alias_format
