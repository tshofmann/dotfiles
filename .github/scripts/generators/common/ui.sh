#!/usr/bin/env zsh
# ============================================================
# ui.sh - UI-Komponenten und Logging
# ============================================================
# Zweck       : Konsistente Ausgabeformatierung für alle Generatoren
# Pfad        : .github/scripts/generators/common/ui.sh
# ============================================================

# Abhängigkeit: config.sh muss vorher geladen sein (für Farben)

# ------------------------------------------------------------
# Logging
# ------------------------------------------------------------
log()  { echo -e "${C_BLUE}→${C_RESET} $1"; }
ok()   { echo -e "${C_GREEN}✔${C_RESET} $1"; }
warn() { echo -e "${C_YELLOW}⚠${C_RESET} $1"; }
err()  { echo -e "${C_RED}✖${C_RESET} $1" >&2; }
dim()  { echo -e "${C_DIM}$1${C_RESET}"; }
bold() { echo -e "${C_BOLD}$1${C_RESET}"; }

# ------------------------------------------------------------
# UI-Komponenten (konsistent für alle Skripte)
# ------------------------------------------------------------
# Banner mit Titel (Hauptüberschrift eines Skripts)
# Usage: ui_banner "🔍" "Pre-Commit Checks"
ui_banner() {
    local emoji="$1"
    local title="$2"
    print ""
    print "${C_OVERLAY0}${UI_LINE}${C_RESET}"
    print "${C_MAUVE}${emoji} ${C_BOLD}${title}${C_RESET}"
    print "${C_OVERLAY0}${UI_LINE}${C_RESET}"
    print ""
}

# Section-Header (Unterabschnitt)
# Usage: ui_section "Symlinks"
ui_section() {
    print ""
    print "${C_MAUVE}━━━ ${C_BOLD}$1${C_RESET}${C_MAUVE} ━━━${C_RESET}"
}

# Footer mit Trennlinie
# Usage: ui_footer
ui_footer() {
    print ""
    print "${C_OVERLAY0}${UI_LINE}${C_RESET}"
}

# ------------------------------------------------------------
# Datei-Operationen
# ------------------------------------------------------------
# Vergleicht generierten Inhalt mit existierender Datei
# Return: 0 wenn gleich, 1 wenn unterschiedlich
compare_content() {
    local file="$1"
    local content="$2"

    [[ ! -f "$file" ]] && return 1

    local current=$(cat "$file")
    [[ "$current" == "$content" ]]
}

# Datei schreiben (nur wenn geändert)
write_if_changed() {
    local file="$1"
    local content="$2"

    if compare_content "$file" "$content"; then
        dim "  Unverändert: $(basename "$file")"
        return 0
    fi

    # Atomischer Write: tmp-Datei schreiben, dann umbenennen
    if printf '%s\n' "$content" > "${file}.tmp" \
        && mv "${file}.tmp" "$file"; then
        ok "Generiert: $(basename "$file")"
    else
        rm -f "${file}.tmp"
        err "Fehler beim Schreiben: $(basename "$file")"
        return 1
    fi
}
