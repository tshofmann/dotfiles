#!/usr/bin/env zsh
# ============================================================
# check-brewfile-mapping.sh - Brewfile ↔ BREW_TO_ALT Sync prüfen
# ============================================================
# Zweck       : Prüft ob alle Brewfile-Formulae in BREW_TO_ALT
#               gemappt sind (verhindert fehlende Linux-Pakete)
# Pfad        : .github/scripts/check-brewfile-mapping.sh
# Aufruf      : ./.github/scripts/check-brewfile-mapping.sh
# Nutzt       : lib/log.sh (Logging + Farben), grep, sed
# Generiert   : Nichts (nur Validierung)
# ============================================================
# Hintergrund:
#   setup/modules/apt-packages.sh enthält BREW_TO_ALT – eine
#   Mapping-Tabelle die jede Brewfile-Formula einer Linux-
#   Installationsmethode zuordnet (apt, cargo, npm oder skip).
#   Ohne Eintrag wird ein neues Brew-Paket auf Linux ignoriert.
#
#   Prüfrichtungen:
#     Vorwärts (Brewfile → BREW_TO_ALT): FEHLER wenn fehlend
#     Rückwärts (BREW_TO_ALT → Brewfile): WARNUNG wenn verwaist
# ============================================================

set -uo pipefail

# Dotfiles-Verzeichnis ermitteln
SCRIPT_DIR="${0:A:h}"
DOTFILES_DIR="${SCRIPT_DIR:h:h}"  # .github/scripts → dotfiles

# Logging + Farben (geteilte Library)
source "${0:A:h}/lib/log.sh"

# ------------------------------------------------------------
# Brewfile ↔ BREW_TO_ALT Mapping prüfen
# ------------------------------------------------------------
check_brewfile_mapping() {
    local brewfile="$DOTFILES_DIR/setup/Brewfile"
    local apt_packages="$DOTFILES_DIR/setup/modules/apt-packages.sh"
    local errors=0

    # Datei-Existenz prüfen
    if [[ ! -f "$brewfile" ]]; then
        err "Brewfile nicht gefunden: ${brewfile#$DOTFILES_DIR/}"
        return 1
    fi
    if [[ ! -f "$apt_packages" ]]; then
        err "apt-packages.sh nicht gefunden: ${apt_packages#$DOTFILES_DIR/}"
        return 1
    fi

    # Brewfile-Formulae extrahieren (identischer Parser wie _parse_brewfile())
    local -a brew_formulae=()
    while IFS= read -r formula; do
        [[ -n "$formula" ]] && brew_formulae+=("$formula")
    done < <(grep -E '^brew "[^"]+"' "$brewfile" | sed 's/brew "\([^"]*\)".*/\1/')

    # BREW_TO_ALT Keys extrahieren (statisch, ohne Sourcing)
    # Liest den Block zwischen 'typeset -A BREW_TO_ALT=(' und ')'
    local -a mapping_keys=()
    local in_block=0
    while IFS= read -r line; do
        if [[ "$line" == *'typeset -A BREW_TO_ALT='* ]]; then
            in_block=1
            continue
        fi
        if (( in_block )); then
            # Block-Ende: Zeile die nur ')' enthält (ggf. mit Whitespace)
            if [[ "$line" =~ '^[[:space:]]*\)$' ]]; then
                break
            fi
            # Key extrahieren: [key]=value
            # Erlaubte Zeichen: a-z 0-9 _ - @ . / (deckt versionierte
            # Formulae wie python@3.12 und Taps wie homebrew/core/llvm ab)
            if [[ "$line" =~ '\[([a-z0-9_@./-]+)\]=' ]]; then
                mapping_keys+=("${match[1]}")
            fi
        fi
    done < "$apt_packages"

    # Plausibilitäts-Check: Wurden überhaupt Daten gefunden?
    if (( ${#brew_formulae[@]} == 0 )); then
        err "Keine Formulae im Brewfile gefunden – Parser-Fehler?"
        return 1
    fi
    if (( ${#mapping_keys[@]} == 0 )); then
        err "Keine Keys in BREW_TO_ALT gefunden – Parser-Fehler?"
        return 1
    fi

    # 1. Vorwärts: Brewfile → BREW_TO_ALT (FEHLER wenn fehlend)
    local -a unmapped=()
    for formula in "${brew_formulae[@]}"; do
        if ! (( ${mapping_keys[(Ie)$formula]} )); then
            unmapped+=("$formula")
        fi
    done

    if (( ${#unmapped[@]} > 0 )); then
        err "${#unmapped[@]} Brewfile-Formula(e) ohne BREW_TO_ALT Mapping:"
        for f in "${unmapped[@]}"; do
            err "  $f → Eintrag in setup/modules/apt-packages.sh ergänzen"
        done
        errors=${#unmapped[@]}
    fi

    # 2. Rückwärts: BREW_TO_ALT → Brewfile (WARNUNG wenn verwaist)
    local -a orphaned=()
    for key in "${mapping_keys[@]}"; do
        if ! (( ${brew_formulae[(Ie)$key]} )); then
            orphaned+=("$key")
        fi
    done

    if (( ${#orphaned[@]} > 0 )); then
        warn "${#orphaned[@]} BREW_TO_ALT-Eintrag/Einträge ohne Brewfile-Formula:"
        for f in "${orphaned[@]}"; do
            warn "  $f → aus BREW_TO_ALT entfernen oder Brewfile ergänzen"
        done
    fi

    # Ergebnis
    if (( errors > 0 )); then
        return 1
    fi

    ok "Brewfile-Mapping vollständig (${#brew_formulae[@]} Formulae ↔ ${#mapping_keys[@]} Mappings)"
    return 0
}

# ------------------------------------------------------------
# Hauptprogramm
# ------------------------------------------------------------
log "Prüfe Brewfile ↔ BREW_TO_ALT Mapping..."
check_brewfile_mapping
