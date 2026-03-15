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
#
# Performance : O(Dateien) – jede Datei wird einmal gelesen,
#               alle Prüfungen via ZSH-Builtins (kein grep/sed-Fork)
# ------------------------------------------------------------
check_alias_format() {
    setopt LOCAL_OPTIONS extendedglob
    local errors=0
    local name line prevline field i
    local -a lines header_lines
    local total has_header header_end eq_count has_guard found
    local sep_count defline funcline
    local -A fo_lines
    local fo_fld fo_prev fo_prev_ln

    for file in "$DOTFILES_DIR"/terminal/.config/alias/*.alias(N); do
        name="${file:t}"

        # Datei einmal komplett lesen (O(1) I/O statt ~30 grep/sed-Forks)
        lines=("${(@f)$(<"$file")}")
        total=${#lines}

        # 1. Header-Block vorhanden? (# ==== in den ersten 3 Zeilen)
        has_header=0
        for i in 1 2 3; do
            (( i > total )) && break
            [[ "${lines[$i]}" == "# ===="* ]] && { has_header=1; break; }
        done
        if (( ! has_header )); then
            err "$name: Kein Header-Block"
            (( errors++ )) || true
        fi

        # Header-Block extrahieren (bis zur 3. ==== Zeile)
        # Struktur: Opening ==== / Titel / ==== / Felder / ==== (3.)
        # Prüfungen 3 und 6 suchen NUR im Header, nicht in Sektions-Kommentaren
        header_end=20
        eq_count=0
        for (( i = 1; i <= total; i++ )); do
            [[ "${lines[$i]}" == "# ===="* ]] && (( eq_count++ )) || true
            if (( eq_count >= 3 )); then
                header_end=$i
                break
            fi
        done
        header_lines=("${(@)lines[1,$header_end]}")

        # 2. Guard-Check vorhanden?
        has_guard=0
        for (( i = 1; i <= total; i++ )); do
            [[ "${lines[$i]}" == *"command -v"*">/dev/null"* ]] && { has_guard=1; break; }
        done
        if (( ! has_guard )); then
            err "$name: Kein Guard-Check"
            (( errors++ )) || true
        fi

        # 3. Pflichtfelder im Header (CONTRIBUTING.md: Zweck, Pfad, Docs, Nutzt, Ersetzt)
        for field in Zweck Pfad Docs Nutzt Ersetzt; do
            found=0
            for line in "${header_lines[@]}"; do
                [[ "$line" == "# ${field}"[[:space:]]* ]] && { found=1; break; }
            done
            if (( ! found )); then
                err "$name: Pflichtfeld '${field}' fehlt im Header"
                (( errors++ )) || true
            fi
        done

        # 4. Sektions-Trenner (mindestens eine Sektion nach dem Header)
        sep_count=0
        for line in "${lines[@]}"; do
            [[ "$line" == "# ----"* ]] && (( sep_count++ )) || true
        done
        if (( sep_count < 2 )); then
            err "$name: Keine Sektions-Trenner (erwartet: mindestens 2)"
            (( errors++ )) || true
        fi

        # 5. Beschreibungskommentar über alias- und Funktionsdefinitionen
        #    CONTRIBUTING.md: "Jede Funktion und jeder Alias benötigt einen
        #    Beschreibungskommentar direkt darüber"
        #    Private Funktionen (_prefix) sind durch das Pattern
        #    [a-zA-Z] am Anfang bereits ausgeschlossen.
        for (( i = 2; i <= total; i++ )); do
            line="${lines[$i]}"
            prevline="${lines[$((i-1))]}"

            # 5a. Aliases: ^[[:space:]]*alias [a-zA-Z]
            if [[ "$line" =~ '^[[:space:]]*alias [a-zA-Z]' ]]; then
                if [[ "$prevline" != *"#"* ]]; then
                    defline="${line#${line%%[![:space:]]*}}"
                    err "$name:$i: Beschreibungskommentar fehlt über '${defline%%=*}'"
                    (( errors++ )) || true
                fi
            fi

            # 5b. Funktionen: ^[a-zA-Z] schließt _prefix aus
            if [[ "$line" =~ '^[[:space:]]*[a-zA-Z][a-zA-Z0-9_-]*\(\) \{' ]]; then
                if [[ "$prevline" != *"#"* ]]; then
                    funcline="${line%%\(\)*}"
                    funcline="${funcline#${funcline%%[![:space:]]*}}"
                    err "$name:$i: Beschreibungskommentar fehlt über '${funcline}()'"
                    (( errors++ )) || true
                fi
            fi
        done

        # 6. Feldordnung im Header prüfen
        #    Standard: Zweck → Pfad → Docs → Config → Generiert → Nutzt → Ersetzt → Kommandos → Aliase
        fo_lines=()
        fo_prev=""
        fo_prev_ln=0
        for (( i = 1; i <= ${#header_lines}; i++ )); do
            for fo_fld in Zweck Pfad Docs Config Generiert Nutzt Ersetzt Kommandos Aliase; do
                if [[ "${header_lines[$i]}" == "# ${fo_fld}"[[:space:]]* ]] && [[ -z "${fo_lines[$fo_fld]:-}" ]]; then
                    fo_lines[$fo_fld]=$i
                fi
            done
        done
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
