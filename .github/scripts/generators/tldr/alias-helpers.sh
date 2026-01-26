#!/usr/bin/env zsh
# ============================================================
# alias-helpers.sh - Helper für Alias-Datei Verarbeitung
# ============================================================
# Zweck       : Extraktion von Alias-Namen, Beschreibungen, Sektionen
# Pfad        : .github/scripts/generators/tldr/alias-helpers.sh
# ============================================================

# Abhängigkeit: common.sh muss vorher geladen sein

# ------------------------------------------------------------
# Helper: Extrahiere erste N Alias-Namen aus einer .alias Datei
# ------------------------------------------------------------
extract_alias_names() {
    local file="$1"
    local max="${2:-3}"
    local aliases=()
    local count=0

    while IFS= read -r line; do
        if [[ "$line" =~ "^alias ([a-zA-Z0-9_-]+)=" ]]; then
            aliases+=("${match[1]}")
            (( count++ )) || true
            (( count >= max )) && break
        fi
    done < "$file"

    echo "${(j:, :)aliases}"
}

# ------------------------------------------------------------
# Helper: Extrahiere Alias-Beschreibung aus Kommentar
# ------------------------------------------------------------
# Format: # Beschreibung – Details
# Rückgabe: "Beschreibung" (Teil vor " – ")
extract_alias_desc() {
    local file="$1"
    local alias_name="$2"
    local desc_comment=""

    while IFS= read -r line; do
        # Beschreibungskommentar merken
        if [[ "$line" == "# "* && "$line" != "# ---"* && "$line" != "# ==="* ]]; then
            desc_comment="${line#\# }"
        elif [[ "$line" == "alias ${alias_name}="* ]]; then
            # Fand den Alias – gib Beschreibung zurück (Teil vor " – ")
            echo "${desc_comment%% –*}"
            return
        else
            # Reset wenn wir keinen Kommentar direkt vor dem Alias haben
            [[ "$line" != "" ]] && desc_comment=""
        fi
    done < "$file"
}

# ------------------------------------------------------------
# Helper: Extrahiere Funktionsbeschreibung aus Kommentar
# ------------------------------------------------------------
# Format: # Beschreibung – Details (ignoriert # Nutzt, # Voraussetzung etc.)
extract_function_desc() {
    local file="$1"
    local func_name="$2"
    local desc_comment=""
    local in_section=false

    while IFS= read -r line; do
        # Sektionsheader gefunden
        if [[ "$line" == "# ---"* ]]; then
            in_section=true
            desc_comment=""
            continue
        fi

        # Beschreibungskommentar (nicht Nutzt, Voraussetzung, Docs etc.)
        if [[ "$line" == "# "* && "$line" != "# ==="* ]]; then
            local content="${line#\# }"
            local first_word="${content%% *}"
            case "$first_word" in
                Nutzt|Voraussetzung|Docs|Guard|Hinweis) ;;
                *) [[ "$in_section" == true && -z "$desc_comment" ]] && desc_comment="$content" ;;
            esac
        elif [[ "$line" == "${func_name}() {" || "$line" == "${func_name}()"* ]]; then
            # Fand die Funktion – gib Beschreibung zurück
            echo "${desc_comment%% –*}"
            return
        fi
    done < "$file"
}

# ------------------------------------------------------------
# Helper: Extrahiere alle Items (Aliase UND Funktionen) aus einer Sektion
# ------------------------------------------------------------
# Parameter:
#   $1 = Datei
#   $2 = Sektionsname (z.B. "Update & Wartung", "Dotfiles Wartung")
# Ausgabe: Pro Zeile "name|beschreibung" für jedes gefundene Item
# Erkennt: alias name='...' und name() {
extract_section_items() {
    local file="$1"
    local section_name="$2"
    local in_section=false
    local prev_comment=""

    local found_header=false      # Sektionsheader gefunden
    local in_header_block=false   # Zwischen den Trennlinien des Headers
    local skip_next_sep=false     # Nächste Trennlinie (nach Header) überspringen

    while IFS= read -r line; do
        # Trennlinie behandeln
        if [[ "$line" == "# ---"* ]]; then
            if [[ "$skip_next_sep" == true ]]; then
                # Trennlinie direkt nach Sektionsheader → überspringen
                skip_next_sep=false
                continue
            fi
            if [[ "$in_section" == true && "$found_header" == true ]]; then
                # Bereits in Sektion und neue Trennlinie → nächste Sektion beginnt → beenden
                break
            fi
            # Trennlinie könnte Header-Block starten
            in_header_block=true
            continue
        fi

        # Sektionsheader gefunden (nach Trennlinie)
        if [[ "$in_header_block" == true && "$line" == "# ${section_name}" ]]; then
            in_section=true
            found_header=true
            in_header_block=false
            skip_next_sep=true  # Nächste Trennlinie (unter Header) überspringen
            continue
        fi

        # Reset header block wenn keine Trennlinie mehr
        in_header_block=false

        # Nächste Sektion oder Datei-Header beendet aktuelle Sektion
        if [[ "$in_section" == true ]]; then
            # Neue Sektion beginnt (aber nicht Trennlinie)
            if [[ "$line" == "# "* && "$line" != "# ---"* ]]; then
                local content="${line#\# }"
                # Prüfe ob es ein neuer Sektionsheader ist (keine Metadaten)
                local first_word="${content%% *}"
                case "$first_word" in
                    Nutzt|Voraussetzung|Docs|Guard|Hinweis)
                        # Metadaten ignorieren
                        ;;
                    *)
                        # Prüfe ob nächste Zeile ein Sektionstrennlinie ist
                        # Wenn der Kommentar kein Metadaten-Keyword hat, ist es eine Beschreibung
                        prev_comment="${content%% –*}"
                        ;;
                esac
            # Alias gefunden
            elif [[ "$line" =~ "^alias ([a-z0-9][a-z0-9_-]*)=" ]]; then
                local name="${match[1]}"
                [[ -n "$prev_comment" ]] && echo "${name}|${prev_comment}"
                prev_comment=""
            # Funktion gefunden
            elif [[ "$line" =~ "^([a-z0-9][a-z0-9_-]*)\(\) \{" ]]; then
                local name="${match[1]}"
                [[ -n "$prev_comment" ]] && echo "${name}|${prev_comment}"
                prev_comment=""
            # Datei-Header beendet alles
            elif [[ "$line" == "# ==="* ]]; then
                break
            # Leere Zeile behält Kommentar (für mehrzeilige Kommentare)
            elif [[ "$line" != "" ]]; then
                prev_comment=""
            fi
        fi
    done < "$file"
}

# ------------------------------------------------------------
# Helper: Extrahiere Header-Infos aus Alias-Datei für Page-Generierung
# ------------------------------------------------------------
# Liest Zweck, Docs und Nutzt aus dem Header-Block einer .alias-Datei
extract_alias_header_info() {
    local alias_file="$1"
    local zweck=""
    local docs=""
    local nutzt=""
    local config=""
    local tool_name=""

    while IFS= read -r line; do
        [[ "$line" == "# Guard"* ]] && break

        # Erste Zeile: "# tool.alias - Beschreibung" (muss " - " enthalten)
        if [[ "$line" == "# "*.alias" - "* ]]; then
            tool_name="${line#\# }"
            tool_name="${tool_name%%.alias*}"
        elif [[ "$line" == "# Zweck"*":"* ]]; then
            zweck="${line#*: }"
        elif [[ "$line" == "# Docs"*":"* ]]; then
            docs="${line#*: }"
        elif [[ "$line" == "# Nutzt"*":"* ]]; then
            nutzt="${line#*: }"
        elif [[ "$line" == "# Config"*":"* ]]; then
            config="${line#*: }"
        fi
    done < "$alias_file"

    # Fallback: Config aus Config-Datei extrahieren wenn nicht in .alias
    if [[ -z "$config" && -n "$tool_name" ]]; then
        config=$(find_config_path "$tool_name")
    fi

    echo "${tool_name}|${zweck}|${docs}|${nutzt}|${config}"
}

# ------------------------------------------------------------
# Helper: Config-Pfad aus Config-Datei extrahieren
# ------------------------------------------------------------
# Sucht in ~/.config/<tool>/ nach Config-Dateien mit # Pfad : Header
# Berücksichtigt Alias→Verzeichnis-Mapping (rg→ripgrep, etc.)
find_config_path() {
    local tool_name="$1"

    # Mapping: Alias-Name → Config-Verzeichnisname
    local -A config_dir_map=(
        [rg]=ripgrep
        [mdl]=markdownlint-cli2
        [markdownlint]=markdownlint-cli2
    )

    local dir_name="${config_dir_map[$tool_name]:-$tool_name}"
    local config_dir="$DOTFILES_DIR/terminal/.config/${dir_name}"

    [[ ! -d "$config_dir" ]] && return

    # Suche Config-Dateien (inkl. versteckte, mit Pfad-Header)
    for cfg in "$config_dir"/*(D.N); do
        [[ ! -f "$cfg" ]] && continue

        # Extrahiere Pfad aus Header (unterstützt # und // Kommentare)
        local pfad=$(grep -m1 -E "^(#|//) Pfad[[:space:]]*:" "$cfg" 2>/dev/null | sed -E 's/^(#|\/\/) Pfad[[:space:]]*:[[:space:]]*//')
        if [[ -n "$pfad" ]]; then
            # Optional: Zweck als Beschreibung anhängen
            local zweck=$(grep -m1 -E "^(#|//) Zweck[[:space:]]*:" "$cfg" 2>/dev/null | sed -E 's/^(#|\/\/) Zweck[[:space:]]*:[[:space:]]*//')
            [[ -n "$zweck" ]] && pfad="${pfad} (${zweck})"
            echo "$pfad"
            return
        fi
    done
}
