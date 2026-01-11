#!/usr/bin/env zsh
# ============================================================
# lib.sh - Gemeinsame Bibliothek für Dokumentations-Generatoren
# ============================================================
# Zweck   : Parser, Hilfsfunktionen, Konfiguration
# Pfad    : .github/scripts/generators/lib.sh
# ============================================================

# ------------------------------------------------------------
# Konfiguration
# ------------------------------------------------------------
SCRIPT_DIR="${0:A:h}"
GENERATORS_DIR="${SCRIPT_DIR}"                # .github/scripts/generators
DOTFILES_DIR="${GENERATORS_DIR:h:h:h}"        # .github/scripts/generators → dotfiles
ALIAS_DIR="$DOTFILES_DIR/terminal/.config/alias"
DOCS_DIR="$DOTFILES_DIR/docs"
FZF_CONFIG="$DOTFILES_DIR/terminal/.config/fzf/config"
TEALDEER_DIR="$DOTFILES_DIR/terminal/.config/tealdeer/pages"
BOOTSTRAP="$DOTFILES_DIR/setup/bootstrap.sh"
BOOTSTRAP_MODULES="$DOTFILES_DIR/setup/modules"
SHELL_COLORS="$DOTFILES_DIR/terminal/.config/theme-style"

# BREWFILE nur setzen wenn nicht bereits definiert (Konflikt mit homebrew.sh vermeiden)
[[ -z "${BREWFILE:-}" ]] && BREWFILE="$DOTFILES_DIR/setup/Brewfile"

# Farben (Catppuccin Mocha) – zentral definiert
[[ -f "$SHELL_COLORS" ]] && source "$SHELL_COLORS"

# dothelp-Kategorien (Single Source of Truth für readme.sh + tldr.sh)
readonly DOTHELP_CAT_ALIASES="Aliase"
readonly DOTHELP_CAT_KEYBINDINGS="Keybindings"
readonly DOTHELP_CAT_FZF="fzf-Shortcuts"
readonly DOTHELP_CAT_REPLACEMENTS="Tool-Ersetzungen"

# ------------------------------------------------------------
# macOS Version Helper
# ------------------------------------------------------------
# Mapping: Major-Version → Codename
get_macos_codename() {
    local version="${1:-14}"
    case "$version" in
        11) echo "Big Sur" ;;
        12) echo "Monterey" ;;
        13) echo "Ventura" ;;
        14) echo "Sonoma" ;;
        15) echo "Sequoia" ;;
        26) echo "Tahoe" ;;  # macOS 26 (2025)
        *)  echo "macOS $version" ;;
    esac
}

# Extrahiert MACOS_MIN_VERSION aus bootstrap.sh (unterstützt ab)
extract_macos_min_version() {
    [[ -f "$BOOTSTRAP" ]] || { echo "26"; return; }
    local version=$(grep "^readonly MACOS_MIN_VERSION=" "$BOOTSTRAP" | sed 's/.*=\([0-9]*\).*/\1/')
    echo "${version:-26}"
}

# Extrahiert MACOS_TESTED_VERSION aus bootstrap.sh (zuletzt getestet auf)
extract_macos_tested_version() {
    [[ -f "$BOOTSTRAP" ]] || { echo "26"; return; }
    local version=$(grep "^readonly MACOS_TESTED_VERSION=" "$BOOTSTRAP" | sed 's/.*=\([0-9]*\).*/\1/')
    echo "${version:-26}"
}

# ------------------------------------------------------------
# Bootstrap-Modul Parser
# ------------------------------------------------------------
# Prüft ob modulare Bootstrap-Struktur existiert
has_bootstrap_modules() {
    [[ -d "$BOOTSTRAP_MODULES" && -f "$BOOTSTRAP_MODULES/_core.sh" ]]
}

# Extrahiert MACOS_MIN_VERSION aus validation.sh (modulare Struktur)
extract_macos_min_version_from_module() {
    local validation="$BOOTSTRAP_MODULES/validation.sh"
    [[ -f "$validation" ]] || { echo "26"; return; }
    local version=$(grep "readonly MACOS_MIN_VERSION=" "$validation" | sed 's/.*=\([0-9]*\).*/\1/')
    echo "${version:-26}"
}

# Extrahiert MACOS_TESTED_VERSION aus validation.sh (modulare Struktur)
extract_macos_tested_version_from_module() {
    local validation="$BOOTSTRAP_MODULES/validation.sh"
    [[ -f "$validation" ]] || { echo "26"; return; }
    local version=$(grep "readonly MACOS_TESTED_VERSION=" "$validation" | sed 's/.*=\([0-9]*\).*/\1/')
    echo "${version:-26}"
}

# Smart-Extraktor: Prüft zuerst Module, dann bootstrap.sh
extract_macos_min_version_smart() {
    if has_bootstrap_modules; then
        extract_macos_min_version_from_module
    else
        extract_macos_min_version
    fi
}

extract_macos_tested_version_smart() {
    if has_bootstrap_modules; then
        extract_macos_tested_version_from_module
    else
        extract_macos_tested_version
    fi
}

# Extrahiert STEP-Metadaten aus einem Modul (neues Format)
# Format: # STEP: Name | Beschreibung | Fehlerverhalten
# Rückgabe: Zeilenweise "Name|Beschreibung|Fehlerverhalten"
# Ersetzt Platzhalter: ${MACOS_MIN_VERSION} → tatsächlicher Wert
extract_module_step_metadata() {
    local module_file="$1"
    [[ -f "$module_file" ]] || return 1

    # macOS-Version für Platzhalter-Ersetzung holen
    local macos_min macos_min_name
    macos_min=$(extract_macos_min_version_smart)
    macos_min_name=$(get_macos_codename "$macos_min")

    grep "^# STEP:" "$module_file" 2>/dev/null | while read -r line; do
        # Entferne "# STEP: " Prefix
        local data="${line#\# STEP: }"
        # Ersetze Platzhalter
        data="${data//\$\{MACOS_MIN_VERSION\}/${macos_min}+ (${macos_min_name})}"
        # Gib Name|Beschreibung|Fehlerverhalten aus
        echo "$data"
    done
}

# Legacy: Extrahiert CURRENT_STEP Zuweisungen (für Abwärtskompatibilität)
extract_module_steps() {
    local module_file="$1"
    [[ -f "$module_file" ]] || return 1

    grep "CURRENT_STEP=" "$module_file" 2>/dev/null | while read -r line; do
        local step="${line#*CURRENT_STEP=}"
        step="${step#\"}"
        step="${step%\"}"
        [[ -n "$step" && "$step" != "Initialisierung" ]] && echo "$step"
    done
}

# Extrahiert Header-Feld aus Modul (z.B. "Zweck", "Benötigt", "CURRENT_STEP")
# Format im Modul: # Feldname   : Wert
extract_module_header_field() {
    local module_file="$1"
    local field="$2"
    [[ -f "$module_file" ]] || return 1

    # Suche nach "# Feldname" gefolgt von ":" und extrahiere Wert
    local value
    value=$(grep -E "^# ${field}[[:space:]]*:" "$module_file" 2>/dev/null | head -1 | sed "s/^# ${field}[[:space:]]*:[[:space:]]*//")
    echo "$value"
}

# Liste aller Bootstrap-Module in der definierten Reihenfolge
# Liest MODULES Array aus bootstrap.sh oder bootstrap-new.sh
get_bootstrap_module_order() {
    local bootstrap
    # Prüfe zuerst neuen Orchestrator, dann alten
    if [[ -f "$DOTFILES_DIR/setup/bootstrap-new.sh" ]]; then
        bootstrap="$DOTFILES_DIR/setup/bootstrap-new.sh"
    else
        bootstrap="$BOOTSTRAP"
    fi

    [[ -f "$bootstrap" ]] || return 1

    # Extrahiere MODULES Array
    local in_modules=false
    while IFS= read -r line; do
        # Whitespace trimmen
        local trimmed="${line#"${line%%[![:space:]]*}"}"
        trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"

        # Array-Start erkennen
        if [[ "$trimmed" == "readonly -a MODULES="* || "$trimmed" == "MODULES=("* ]]; then
            in_modules=true
            continue
        fi

        # Array-Ende erkennen
        if $in_modules && [[ "$trimmed" == ")" ]]; then
            break
        fi

        # Modul-Namen extrahieren (Format: "modulname  # Kommentar" oder "prefix:modulname")
        if $in_modules; then
            # Kommentar entfernen und trimmen
            local module="${trimmed%%#*}"
            module="${module#"${module%%[![:space:]]*}"}"
            module="${module%"${module##*[![:space:]]}"}"

            # Plattform-Prefix entfernen falls vorhanden (macos:, linux:, etc.)
            if [[ "$module" == *":"* ]]; then
                module="${module#*:}"
            fi

            # Nur gültige Modul-Namen (alphanumerisch + Bindestrich)
            [[ "$module" =~ ^[a-z][a-z0-9-]*$ ]] && echo "$module"
        fi
    done < "$bootstrap"
}

# Generiert Bootstrap-Schritte-Tabelle aus Modulen (Markdown-Format)
# Nutzt STEP-Metadaten: # STEP: Name | Beschreibung | Fehlerverhalten
# Rückgabe: Markdown-Tabellenzeilen
generate_bootstrap_steps_table() {
    local -a modules
    modules=($(get_bootstrap_module_order))

    for module in "${modules[@]}"; do
        local module_file="$BOOTSTRAP_MODULES/${module}.sh"
        [[ -f "$module_file" ]] || continue

        # STEP-Metadaten aus Modul extrahieren
        while IFS= read -r step_data; do
            [[ -z "$step_data" ]] && continue
            # Format: "Name | Beschreibung | Fehlerverhalten"
            # Umwandeln in Markdown-Tabellenzeile
            echo "| $step_data |"
        done < <(extract_module_step_metadata "$module_file")
    done
}

# Legacy: Generiert nur Schritt-Namen (für Abwärtskompatibilität)
generate_bootstrap_steps_from_modules() {
    local -a modules
    modules=($(get_bootstrap_module_order))

    for module in "${modules[@]}"; do
        local module_file="$BOOTSTRAP_MODULES/${module}.sh"
        [[ -f "$module_file" ]] || continue

        # CURRENT_STEP Werte aus Modul extrahieren
        extract_module_steps "$module_file"
    done
}

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
# Breite der Trennlinie (46 Zeichen = Standard)
readonly UI_LINE_WIDTH=46
readonly UI_LINE=$(printf '━%.0s' {1..46})

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
# Parser: Header-Block Metadaten
# ------------------------------------------------------------
# Extrahiert Metadaten aus Header-Blöcken:
#   # Zweck   : Beschreibung
#   # Docs    : https://...
#   # Hinweis : Kann mehrzeilig sein
#               Fortsetzung mit Einrückung
# Rückgabe: Wert oder leer
parse_header_field() {
    local file="$1"
    local field="$2"
    local value=""
    local in_field=false

    while IFS= read -r line; do
        # Header endet bei Guard oder ====== Abschluss nach gefundenem Feld
        [[ "$line" == "# Guard"* ]] && break

        # Field-Pattern: # Field   : Value
        if [[ "$line" == "# ${field}"*":"* ]]; then
            value="${line#*: }"
            in_field=true
            continue
        fi

        # Fortsetzungszeile (mit Einrückung, Teil des aktuellen Felds)
        if $in_field; then
            if [[ "$line" == "#           "* ]]; then
                # Fortsetungszeile - füge zum Wert hinzu
                local continuation="${line#\#           }"
                value+=" $continuation"
            else
                # Keine Fortsetzung mehr
                break
            fi
        fi
    done < "$file"

    echo "$value"
}

# ------------------------------------------------------------
# Parser: Beschreibungskommentar (für Aliase/Funktionen)
# ------------------------------------------------------------
# Format: # Name(param?) – Key1=Aktion1, Key2=Aktion2
# Rückgabe: name|param|keybindings|description
parse_description_comment() {
    local comment="$1"
    local name param keybindings description

    # Entferne führendes "# "
    comment="${comment#\# }"
    comment="${comment#\#}"
    comment="${comment## }"

    # Extrahiere Name (vor Klammer oder Dash)
    if [[ "$comment" == *[a-zA-Z0-9]'('* ]]; then
        # Klammer direkt nach Wort → Parameter-Notation
        name="${comment%%\(*}"
        name="${name%% }"
        local param_part="${comment#*\(}"
        param="${param_part%%\)*}"
    elif [[ "$comment" == *' ('* ]]; then
        # Leerzeichen vor Klammer → nur Hinweis, kein Parameter
        name="${comment%% \(*}"
        name="${name%% –*}"
        name="${name%% -*}"
        param=""
    else
        name="${comment%% –*}"
        name="${name%% -*}"
        param=""
    fi

    # Keybindings extrahieren (nach – oder -)
    if [[ "$comment" == *" – "* ]]; then
        keybindings="${comment#* – }"
    elif [[ "$comment" == *" - "* ]]; then
        keybindings="${comment#* - }"
    else
        keybindings=""
    fi

    description="$name"

    echo "${name}|${param}|${keybindings}|${description}"
}

# ------------------------------------------------------------
# Parser: Alias-Befehl extrahieren
# ------------------------------------------------------------
# Format: alias name='command' oder alias name="command"  # optional comment
# Rückgabe: command (ohne äußere Quotes)
# Unterstützt:
#   - Einfache Aliase: alias x='cmd'
#   - Mit Pipes: alias x='cmd | grep foo'
#   - Escaped single quotes: alias x='echo '\''text'\''' → echo 'text'
#   - Escaped double quotes: alias x="say \"hello\"" → say "hello"
parse_alias_command() {
    local line="$1"
    local after_eq

    # Entferne "alias name="
    after_eq="${line#alias *=}"

    # Entferne trailing comment (nach schließendem Quote und Whitespace)
    # Aber vorsichtig – # innerhalb des Befehls behalten

    if [[ "$after_eq" == \'* ]]; then
        # Single-quoted alias
        after_eq="${after_eq#\'}"  # Öffnendes Quote entfernen

        # Bei '\'' Pattern: Ersetze durch einzelnes Quote für Ausgabe
        # Das Pattern '\'' ist: Ende-Quote + Escaped-Quote + Start-Quote
        # Für die Doku wollen wir das lesbare Ergebnis
        local result=""
        local rest="$after_eq"

        while [[ -n "$rest" ]]; do
            # Nimm alles bis zum nächsten Quote
            local segment="${rest%%\'*}"
            result+="$segment"
            rest="${rest#"$segment"}"

            # Prüfe was nach dem Quote kommt
            if [[ "$rest" == "'\\''"* ]]; then
                # Pattern '\'' gefunden – füge literal ' hinzu
                result+="'"
                rest="${rest#\"'\\''\"}"
                rest="${rest#\'\\\'\'}"
            elif [[ "$rest" == "'"* ]]; then
                # Normales schließendes Quote – fertig
                break
            else
                # Kein Quote mehr – fertig
                break
            fi
        done

        echo "$result"

    elif [[ "$after_eq" == \"* ]]; then
        # Double-quoted alias
        after_eq="${after_eq#\"}"  # Öffnendes Quote entfernen

        # Bei \" Pattern: Ersetze durch einzelnes Quote für Ausgabe
        local result=""
        local rest="$after_eq"

        while [[ -n "$rest" ]]; do
            local segment="${rest%%\"*}"

            # Prüfe ob das " escaped war (Backslash davor)
            if [[ "$segment" == *'\' ]]; then
                # Escaped quote – füge ohne Backslash + Quote hinzu
                result+="${segment%\\}\""
                rest="${rest#"$segment"\"}"
            else
                # Normales schließendes Quote
                result+="$segment"
                break
            fi
        done

        echo "$result"

    else
        # Kein Quote (ungewöhnlich)
        echo "${after_eq%%[[:space:]#]*}"
    fi
}

# ------------------------------------------------------------
# Parser: Brewfile
# ------------------------------------------------------------
# Extrahiert Tool-Name, Beschreibung und URL
# Format: brew "name"                # Beschreibung | URL
#         mas "name", id: 123456     # Beschreibung (URL wird aus ID generiert)
# Rückgabe: name|beschreibung|typ|url (brew/cask/mas)
parse_brewfile_entry() {
    local line="$1"
    local name description typ url

    case "$line" in
        brew\ *)
            typ="brew"
            name="${line#brew \"}"
            name="${name%%\"*}"
            ;;
        cask\ *)
            typ="cask"
            name="${line#cask \"}"
            name="${name%%\"*}"
            ;;
        mas\ *)
            typ="mas"
            name="${line#mas \"}"
            name="${name%%\"*}"
            # ID extrahieren und App Store URL generieren
            if [[ "$line" =~ id:[[:space:]]*([0-9]+) ]]; then
                url="https://apps.apple.com/app/id${match[1]}"
            fi
            ;;
        *)
            return 1
            ;;
    esac

    # Beschreibung und URL aus Kommentar (Format: # Beschreibung | URL)
    # MAS-Apps haben bereits URL aus ID, überschreibe nur wenn explizit angegeben
    if [[ "$line" == *"#"* ]]; then
        local comment="${line#*# }"
        if [[ "$comment" == *" | "* ]]; then
            description="${comment%% | *}"
            # Explizite URL überschreibt generierte
            url="${comment##* | }"
        else
            description="$comment"
            # url bleibt wie gesetzt (leer oder aus MAS-ID)
        fi
    else
        description=""
    fi

    echo "${name}|${description}|${typ}|${url}"
}

# ------------------------------------------------------------
# Parser: Tool-Nutzung aus Alias-Datei
# ------------------------------------------------------------
# Generiert Codeblock mit Alias-Beispielen pro Sektion
# Struktur: # ---- \n # Sektions-Titel \n # ---- \n # Beschreibung \n alias
extract_usage_codeblock() {
    local file="$1"
    local output=""
    local prev_line=""
    local prev_prev_line=""
    local current_section=""
    local in_header=true
    local first_section=true

    while IFS= read -r line; do
        local trimmed="${line#"${line%%[![:space:]]*}"}"

        # Header überspringen (bis Guard endet)
        # Guard kann einzeilig sein: if ...; then return 0; fi
        # Oder mehrzeilig mit 'fi' auf eigener Zeile
        if $in_header; then
            if [[ "$trimmed" == "fi" || "$trimmed" == *"; fi" || "$trimmed" == *";fi" ]]; then
                in_header=false
                prev_line=""
                prev_prev_line=""
            fi
            continue
        fi

        # Sektions-Titel erkennen:
        # Aktuelle Zeile ist "# ----" und prev_prev_line war auch "# ----"
        # Dann ist prev_line der Titel
        if [[ "$trimmed" == "# ----"* && "$prev_prev_line" == "# ----"* ]]; then
            local title="${prev_line#\# }"
            if [[ -n "$title" && "$title" != "$current_section" ]]; then
                if ! $first_section; then
                    output+="\n"
                fi
                first_section=false
                output+="# ${title}\n"
                current_section="$title"
            fi
            prev_prev_line="$prev_line"
            prev_line="$trimmed"
            continue
        fi

        # Alias-Zeile mit vorheriger Beschreibung
        if [[ "$trimmed" == alias\ * && "$prev_line" == "# "* && "$prev_line" != "# ----"* ]]; then
            local alias_part="${trimmed#alias }"
            local alias_name="${alias_part%%=*}"
            alias_name="${alias_name## }"
            alias_name="${alias_name%% }"

            local desc="${prev_line#\# }"

            # Alignment (max 18 Zeichen)
            local padding=$((18 - ${#alias_name}))
            [[ "$padding" -lt 1 ]] && padding=1
            local spaces=""
            for ((i=0; i<padding; i++)); do spaces+=" "; done

            output+="${alias_name}${spaces}# ${desc}\n"
        fi

        # Funktion mit vorheriger Beschreibung: name() {
        if [[ "$trimmed" == [a-z][a-z0-9_-]*"() "* && "$prev_line" == "# "* && "$prev_line" != "# ----"* ]]; then
            local func_name="${trimmed%%\(*}"
            local desc="${prev_line#\# }"

            # Alignment (max 18 Zeichen)
            local padding=$((18 - ${#func_name}))
            [[ "$padding" -lt 1 ]] && padding=1
            local spaces=""
            for ((i=0; i<padding; i++)); do spaces+=" "; done

            output+="${func_name}${spaces}# ${desc}\n"
        fi

        prev_prev_line="$prev_line"
        prev_line="$trimmed"
    done < "$file"

    echo -e "$output"
}

# ------------------------------------------------------------
# dothelp: Kategorien aus echten Quellen ermitteln
# ------------------------------------------------------------
# Quellen:
#   - terminal/.config/alias/*.alias → Aliase vorhanden?
#   - terminal/.zshrc → Shell-Keybindings vorhanden?
#   - terminal/.config/fzf/init.zsh → fzf-Keybindings vorhanden?
#   - terminal/.config/alias/*.alias (Ersetzt:-Feld) → Tool-Ersetzungen
# Rückgabe: Komma-separierte Kategorienliste
get_dothelp_categories() {
    local categories=()
    local zshrc="$DOTFILES_DIR/terminal/.zshrc"
    local fzf_init="$DOTFILES_DIR/terminal/.config/fzf/init.zsh"

    # Aliase – .alias Dateien vorhanden?
    local alias_count=$(ls -1 "$ALIAS_DIR"/*.alias 2>/dev/null | wc -l)
    (( alias_count > 0 )) && categories+=("$DOTHELP_CAT_ALIASES")

    # Shell-Keybindings (Autosuggestions) – Format in .zshrc: #   →  Beschreibung
    if [[ -f "$zshrc" ]] && grep -q "^#   →" "$zshrc"; then
        categories+=("$DOTHELP_CAT_KEYBINDINGS")
    fi

    # fzf-Keybindings – Format in init.zsh: bindkey '^X...# Ctrl+X
    if [[ -f "$fzf_init" ]] && grep -q "bindkey '^X.*# Ctrl+X" "$fzf_init"; then
        categories+=("$DOTHELP_CAT_FZF")
    fi

    # Tool-Ersetzungen – Ersetzt:-Feld in *.alias Dateien
    local has_replacements=false
    for alias_file in "$ALIAS_DIR"/*.alias(N); do
        local ersetzt=$(parse_header_field "$alias_file" "Ersetzt")
        if [[ -n "$ersetzt" ]]; then
            has_replacements=true
            break
        fi
    done
    $has_replacements && categories+=("$DOTHELP_CAT_REPLACEMENTS")

    # Ausgabe als Komma-separierte Liste
    echo "${(j:, :)categories}"
}

# ------------------------------------------------------------
# Datei-Vergleich
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

# ------------------------------------------------------------
# Datei schreiben (nur wenn geändert)
# ------------------------------------------------------------
write_if_changed() {
    local file="$1"
    local content="$2"

    if compare_content "$file" "$content"; then
        dim "  Unverändert: $(basename "$file")"
        return 0
    fi

    # printf statt echo um trailing newline zu vermeiden
    printf '%s\n' "$content" > "$file"
    ok "Generiert: $(basename "$file")"
    return 0
}
