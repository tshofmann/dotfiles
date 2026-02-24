#!/usr/bin/env zsh
# ============================================================
# check-header-sync.sh – Keybinding-Sync: Kommentar ↔ header-wrap
# ============================================================
# Zweck       : Stellt sicher, dass Keybinding-Texte in
#             : Beschreibungskommentaren und header-wrap-Argumenten
#             : identisch sind (Drift-Prävention)
# Pfad        : .github/scripts/check-header-sync.sh
# Docs        : CONTRIBUTING.md (Keybinding-Architektur)
# ============================================================

set -uo pipefail
setopt TYPESET_SILENT

SCRIPT_DIR="${0:A:h}"
DOTFILES_DIR="${SCRIPT_DIR:h:h}"
SHELL_COLORS="$DOTFILES_DIR/terminal/.config/theme-style"
[[ -f "$SHELL_COLORS" ]] && source "$SHELL_COLORS"

log()  { echo -e "${C_BLUE:-}→${C_RESET:-} $1"; }
ok()   { echo -e "${C_GREEN:-}✔${C_RESET:-} $1"; }
warn() { echo -e "${C_YELLOW:-}⚠${C_RESET:-} $1"; }
err()  { echo -e "${C_RED:-}✖${C_RESET:-} $1" >&2; }

ALIAS_DIR="$DOTFILES_DIR/terminal/.config/alias"
FZF_INIT="$DOTFILES_DIR/terminal/.config/fzf/init.zsh"

# ── Normalisierung ──────────────────────────────────────────

# Beschreibungskommentar-Keybindings → sortierte "Key\tAktion" Zeilen
# Input: "Enter=Beenden, Tab=Mehrfach, Ctrl+S=Apps ↔ Alle"
normalize_comment() {
    local text="$1"
    local -a parts=("${(@s:, :)text}")
    local part
    for part in "${parts[@]}"; do
        [[ -z "$part" ]] && continue
        echo "${part%%=*}	${part#*=}"
    done | sort
}

# header-wrap Argumente → sortierte "Key\tAktion" Zeilen
# Überspringt Legenden ('[X]=Text' Muster, z.B. '[F]=Formula [C]=Cask')
# Input: vollständige Zeile mit header-wrap 'Arg1' 'Arg2' ...
normalize_header_wrap() {
    local line="$1"
    local args="${line#*header-wrap }"

    # Single-Quoted Gruppen extrahieren
    local rest="$args"
    while [[ "$rest" == *"'"*"'"* ]]; do
        rest="${rest#*\'}"
        local group="${rest%%\'*}"
        rest="${rest#*\'}"

        # Legenden überspringen: enthält [X]=Text Muster
        [[ "$group" == *'['?']='* ]] && continue

        # Bindings innerhalb einer Gruppe durch " | " getrennt
        local -a bindings=("${(@s: | :)group}")
        local binding
        for binding in "${bindings[@]}"; do
            [[ -z "$binding" ]] && continue
            echo "${binding%%: *}	${binding#*: }"
        done
    done | sort
}

# ── Hauptprüfung ────────────────────────────────────────────

check_header_sync() {
    local errors=0
    local checked=0
    local -a files=("$ALIAS_DIR"/*.alias(N) "$FZF_INIT")

    local file
    for file in "${files[@]}"; do
        local name
        name=$(basename "$file")

        # Datei in Array einlesen (schneller als wiederholtes sed)
        local -a flines=("${(@f)$(< "$file")}")
        local total=${#flines}

        # header-wrap Zeilen finden (keine Kommentare)
        local -a hw_nums=()
        local i
        for (( i = 1; i <= total; i++ )); do
            [[ "${flines[$i]}" == *"header-wrap "* ]] || continue
            [[ "${flines[$i]}" =~ '^[[:space:]]*#' ]] && continue
            hw_nums+=("$i")
        done

        (( ${#hw_nums} == 0 )) && continue

        # header-wrap Zeilen nach Funktion gruppieren
        local -A func_of_hw=()
        local -A comment_of_func=()

        local hw
        for hw in "${hw_nums[@]}"; do
            # Aufwärts zur Funktionsdefinition/Export suchen
            local func_num=""
            for (( i = hw - 1; i >= 1; i-- )); do
                if [[ "${flines[$i]}" =~ '^[[:space:]]*[a-zA-Z0-9][a-zA-Z0-9_-]*\(\)' ]] || \
                   [[ "${flines[$i]}" =~ '^export FZF_' ]]; then
                    func_num="$i"
                    break
                fi
            done
            if [[ -z "$func_num" ]]; then
                warn "$name:$hw: header-wrap ohne zugehörige Funktion"
                continue
            fi
            func_of_hw[$hw]="$func_num"

            # Beschreibungskommentar finden (einmal pro Funktion)
            [[ -n "${comment_of_func[$func_num]:-}" ]] && continue
            local comment_num=""
            for (( i = func_num - 1; i >= 1; i-- )); do
                local l="${flines[$i]}"
                # Eingerückte Kommentare berücksichtigen (z.B. in if-Blöcken)
                if [[ "$l" =~ '^[[:space:]]*#' ]]; then
                    if [[ "$l" == *" – "* ]] && [[ "$l" == *=* ]]; then
                        comment_num="$i"
                        break
                    fi
                    continue
                fi
                # Nicht-Kommentar → Suche beenden
                break
            done
            comment_of_func[$func_num]="${comment_num:-NONE}"
        done

        # Pro Funktion: Vereinigte header-wrap Keys mit Kommentar vergleichen
        local -a done_funcs=()
        for hw in "${hw_nums[@]}"; do
            local func_num="${func_of_hw[$hw]:-}"
            [[ -z "$func_num" ]] && continue

            # Nur einmal pro Funktion
            if (( ${done_funcs[(Ie)$func_num]} )); then
                continue
            fi
            done_funcs+=("$func_num")

            local comment_num="${comment_of_func[$func_num]:-NONE}"
            if [[ "$comment_num" == "NONE" ]]; then
                warn "$name: Funktion (Zeile $func_num) hat header-wrap ohne Beschreibungskommentar"
                continue
            fi

            # Kommentar-Keybindings normalisieren
            local comment_text="${flines[$comment_num]}"
            local comment_kb="${comment_text#* – }"
            local comment_sorted
            comment_sorted=$(normalize_comment "$comment_kb")

            # Alle header-wrap Zeilen dieser Funktion vereinigen
            local -A merged=()
            local h
            for h in "${hw_nums[@]}"; do
                [[ "${func_of_hw[$h]:-}" == "$func_num" ]] || continue
                local key action
                while IFS=$'\t' read -r key action; do
                    [[ -z "$key" ]] && continue
                    merged[$key]="$action"
                done < <(normalize_header_wrap "${flines[$h]}")
            done

            # Merged-Set → sortierter String zum Vergleich
            local merged_sorted=""
            local k
            for k in "${(@ko)merged}"; do
                [[ -n "$merged_sorted" ]] && merged_sorted+=$'\n'
                merged_sorted+="${k}	${merged[$k]}"
            done

            (( checked++ )) || true

            # Vergleich: Kommentar ↔ vereinigte header-wrap Bindings
            if [[ "$comment_sorted" != "$merged_sorted" ]]; then
                local -A comment_map=()
                local ckey caction
                while IFS=$'\t' read -r ckey caction; do
                    [[ -z "$ckey" ]] && continue
                    comment_map[$ckey]="$caction"
                done <<< "$comment_sorted"

                # header-wrap Keys die im Kommentar fehlen
                for k in "${(@ko)merged}"; do
                    if [[ -z "${comment_map[$k]:-}" ]]; then
                        err "$name:$comment_num: header-wrap Key '$k' fehlt im Kommentar"
                        (( errors++ )) || true
                    fi
                done

                # Kommentar-Keys die im header-wrap fehlen oder abweichen
                for k in "${(@ko)comment_map}"; do
                    if [[ -z "${merged[$k]:-}" ]]; then
                        err "$name:$comment_num: Kommentar-Key '$k' fehlt in header-wrap"
                        (( errors++ )) || true
                    elif [[ "${merged[$k]}" != "${comment_map[$k]}" ]]; then
                        err "$name:$comment_num: '$k' → Kommentar='${comment_map[$k]}' ≠ header-wrap='${merged[$k]}'"
                        (( errors++ )) || true
                    fi
                done
            fi

            # Cleanup für nächste Funktion
            merged=()
        done
    done

    if (( errors > 0 )); then
        err "${errors} Keybinding-Sync-Fehler"
        return 1
    fi
    ok "Keybinding-Sync OK ($checked Funktionen geprüft)"
    return 0
}

# ── Hauptprogramm ───────────────────────────────────────────

log "Prüfe Keybinding-Sync..."
check_header_sync
