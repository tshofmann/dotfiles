#!/usr/bin/env zsh
# ============================================================
# parsers.sh - Parser für tldr-spezifische Formate
# ============================================================
# Zweck       : Keybindings, Parameter, fzf-Config, Yazi-Keymap, Config-Dateien Parser
# Pfad        : .github/scripts/generators/tldr/parsers.sh
# ============================================================

# Abhängigkeit: common.sh muss vorher geladen sein

# ------------------------------------------------------------
# Helper: Prüfe ob offizielle tldr-Seite existiert
# ------------------------------------------------------------
# Prüft im tealdeer-Cache ob eine offizielle Seite vorhanden ist
# Cache-Pfad: macOS  → ~/Library/Caches/tealdeer/tldr-pages/
#             Linux  → ${XDG_CACHE_HOME:-~/.cache}/tealdeer/tldr-pages/
has_official_tldr_page() {
    local tool_name="$1"
    local cache_base

    # Plattform-spezifischer Cache-Pfad (tealdeer nutzt OS-Konventionen)
    case "$OSTYPE" in
        darwin*) cache_base="${HOME}/Library/Caches/tealdeer/tldr-pages" ;;
        *)       cache_base="${XDG_CACHE_HOME:-$HOME/.cache}/tealdeer/tldr-pages" ;;
    esac

    # Prüfe in allen Sprachen und Plattformen
    for lang_dir in "$cache_base"/pages.*(N); do
        for platform in common osx linux; do
            [[ -f "$lang_dir/$platform/${tool_name}.md" ]] && return 0
        done
    done

    return 1
}

# ------------------------------------------------------------
# Helper: Finde Config-Verzeichnisse ohne .alias-Datei
# ------------------------------------------------------------
# Gibt Tool-Namen zurück die Config haben aber keine .alias
find_config_only_tools() {
    local config_base="$DOTFILES_DIR/terminal/.config"

    # Alle Verzeichnisse in .config (außer alias, tealdeer, zsh)
    for dir in "$config_base"/*(N/); do
        local dir_name="${dir:t}"

        # Überspringe: alias (enthält .alias-Dateien), tealdeer (Pages), zsh (nur Theme)
        case "$dir_name" in
            alias|tealdeer|zsh|.DS_Store) continue ;;
        esac

        # Prüfe ob es eine .alias-Datei für dieses Tool gibt
        # Berücksichtige Namens-Mappings (ripgrep→rg, markdownlint-cli2→markdownlint)
        local has_alias=false
        for alias_file in "$ALIAS_DIR"/*.alias(N); do
            local alias_name="${${alias_file:t}%.alias}"
            # Direkter Match oder bekanntes Mapping
            if [[ "$alias_name" == "$dir_name" ]]; then
                has_alias=true
                break
            fi
            # Mapping: rg→ripgrep, markdownlint→markdownlint-cli2
            case "$alias_name" in
                rg)          [[ "$dir_name" == "ripgrep" ]] && has_alias=true ;;
                markdownlint) [[ "$dir_name" == "markdownlint-cli2" ]] && has_alias=true ;;
            esac
            [[ "$has_alias" == true ]] && break
        done

        # Kein .alias → prüfe ob Config-Datei mit Header existiert
        if [[ "$has_alias" == false ]]; then
            local main_config=$(find_main_config_file "$dir")
            if [[ -n "$main_config" ]]; then
                echo "$dir_name"
            fi
        fi
    done
}

# ------------------------------------------------------------
# Helper: Finde Haupt-Config-Datei in einem Verzeichnis
# ------------------------------------------------------------
# Sucht nach typischen Config-Dateinamen mit gültigem Header
find_main_config_file() {
    local dir="$1"
    local dir_name="${dir:t}"

    # Typische Config-Dateinamen (in Prioritätsreihenfolge)
    local -a config_names=(
        "${dir_name}.conf"           # kitty.conf
        "config"                      # allgemeines Format
        "config.toml"                 # TOML-Format
        "config.yaml"                 # YAML-Format
        "config.yml"                  # YAML-Format alt
        "config.jsonc"                # JSON mit Kommentaren
        "${dir_name}.toml"           # package.toml (yazi)
    )

    for name in "${config_names[@]}"; do
        local file="$dir/$name"
        if [[ -f "$file" ]]; then
            # Prüfe ob Datei gültigen Header hat (# Pfad : oder # Zweck :)
            if grep -qE "^# (Pfad|Zweck)[[:space:]]*:" "$file" 2>/dev/null; then
                echo "$file"
                return 0
            fi
        fi
    done

    return 1
}

# ------------------------------------------------------------
# Parser: Config-Datei Header zu tldr-Patch
# ------------------------------------------------------------
# Extrahiert Header-Felder und generiert tldr-Einträge
parse_config_file_header() {
    local config_file="$1"
    local -A header_fields=()

    # Header-Felder extrahieren (bis Guard oder leere Zeile nach Header)
    local in_header=false
    local header_ended=false

    while IFS= read -r line; do
        # Header-Block Start erkennen
        [[ "$line" == "# ===="* ]] && { in_header=true; continue; }

        # Header-Block Ende (zweite ====)
        if [[ "$in_header" == true && "$line" == "# ===="* ]]; then
            header_ended=true
            continue
        fi

        # Nach Header: Stoppen bei Guard oder leerem Block
        if [[ "$header_ended" == true ]]; then
            [[ "$line" == "# Guard"* || -z "$line" ]] && break
        fi

        # Header-Felder extrahieren
        if [[ "$in_header" == true || "$header_ended" == true ]]; then
            if [[ "$line" =~ "^# ([A-Za-z_-]+)[[:space:]]*:[[:space:]]*(.*)" ]]; then
                local field="${match[1]}"
                local value="${match[2]}"
                header_fields[$field]="$value"
            fi
        fi
    done < "$config_file"

    # Rückgabe als assoziatives Array (via printf für zsh-Kompatibilität)
    for key in "${(@k)header_fields}"; do
        printf "%s|%s\n" "$key" "${header_fields[$key]}"
    done
}

# ------------------------------------------------------------
# Parser: Keybindings zu tldr-Format
# ------------------------------------------------------------
# Eingabe: Enter=Öffnen, Ctrl+S=man↔tldr
# Ausgabe: (`<Enter>` Öffnen, `<Ctrl s>` man↔tldr)
format_keybindings_for_tldr() {
    local keybindings="$1"
    [[ -z "$keybindings" ]] && return

    # Prüfe ob überhaupt Keybindings vorhanden sind
    case "$keybindings" in
        *Enter* | *Tab* | *Ctrl* | *Shift* | *Alt* | *Esc*) ;;
        *) return ;;
    esac

    local result=""
    local IFS=','

    for binding in ${=keybindings}; do
        binding="${binding## }"
        binding="${binding%% }"

        [[ "$binding" != *"="* ]] && continue

        local key="${binding%%=*}"
        local action="${binding#*=}"

        case "$key" in
            Enter | Tab | Esc | Ctrl+* | Shift+* | Alt+*) ;;
            *) continue ;;
        esac

        key="${key//+/ }"
        if [[ "$key" == *" "* ]]; then
            local modifier="${key%% *}"
            local letter="${key##* }"
            [[ "$letter" == [A-Za-z] ]] && key="${modifier} ${(L)letter}"
        fi

        [[ -n "$result" ]] && result+=", "
        result+="\`<${key}>\` ${action}"
    done

    [[ -n "$result" ]] && echo "($result)"
}

# ------------------------------------------------------------
# Parser: Parameter zu tldr-Format
# ------------------------------------------------------------
format_param_for_tldr() {
    local param="$1"
    [[ -z "$param" ]] && return

    # Defaults und ? pro Parameter entfernen (nicht global)
    local result=""
    local IFS=','
    local parts
    read -rA parts <<< "$param"
    for p in "${parts[@]}"; do
        p="${p## }"   # Leerzeichen vorne
        p="${p%% }"   # Leerzeichen hinten
        p="${p%%=*}"  # Default-Wert entfernen
        p="${p%%\?}"  # Optional-Marker entfernen
        [[ -n "$result" ]] && result+=", "
        result+="$p"
    done

    echo "{{${result}}}"
}

# ------------------------------------------------------------
# Parser: fzf/config globale Keybindings
# ------------------------------------------------------------
parse_fzf_config_keybindings() {
    local config="$1"
    local output=""
    local prev_comment=""

    while IFS= read -r line; do
        # Keybinding-Kommentar gefunden (Ctrl+X : Beschreibung oder Tab : Beschreibung)
        if [[ "$line" == "# Ctrl"*":"* || "$line" == "# Alt"*":"* || "$line" == "# Tab"*":"* ]]; then
            prev_comment="${line#\# }"
        elif [[ "$line" == "--bind="* && -n "$prev_comment" ]]; then
            # --bind Zeile folgt → Keybinding ausgeben
            local key="${prev_comment%% :*}"
            local action="${prev_comment#*: }"

            key="${key//+/ }"
            if [[ "$key" == *" "* ]]; then
                local modifier="${key%% *}"
                local letter="${key##* }"
                [[ "$letter" =~ ^[A-Za-z]+$ ]] && letter="${(L)letter}"
                key="${modifier} ${letter}"
            fi

            output+="- dotfiles: ${action}:\n\n\`<${key}>\`\n\n"
            prev_comment=""
        elif [[ "$line" == "# (kein --bind"* && -n "$prev_comment" ]]; then
            # Dokumentierter Default ohne --bind → trotzdem ausgeben
            local key="${prev_comment%% :*}"
            local action="${prev_comment#*: }"
            # Klammer-Teil entfernen (z.B. "(fzf-Default)")
            action="${action% \(*}"

            output+="- dotfiles: ${action}:\n\n\`<${key}>\`\n\n"
            prev_comment=""
        else
            prev_comment=""
        fi
    done < "$config"

    echo -e "$output"
}

# ------------------------------------------------------------
# Parser: Yazi keymap.toml Keybindings
# ------------------------------------------------------------
# Extrahiert Custom-Keybindings und Bookmarks aus keymap.toml
# Format: [[mgr.prepend_keymap]] mit on, run, desc
# Ausgabe: Menschenlesbar mit Sektionen
parse_yazi_keymap() {
    local keymap="$1"
    local output=""
    local current_section=""
    local section_printed=""
    local on_value=""
    local desc_value=""

    [[ ! -f "$keymap" ]] && return

    while IFS= read -r line; do
        # Sektionskommentar erkennen (z.B. "# Bookmarks (g → Ziel)")
        if [[ "$line" == "# ---"* ]]; then
            continue
        elif [[ "$line" == "# "* && "$line" != "# ==="* ]]; then
            local content="${line#\# }"
            # Sektionsheader erkennen (enthalten Klammern)
            if [[ "$content" == *"("*")"* ]]; then
                current_section="$content"
                section_printed=""
            fi
        # Keybinding-Block Start
        elif [[ "$line" == "[[mgr.prepend_keymap]]" ]]; then
            on_value=""
            desc_value=""
        # on = ["key"] oder on = ["key1", "key2"]
        elif [[ "$line" == "on = "* ]]; then
            on_value="${line#on = }"
            # Array-Format parsen: ["g", "d"] → "g d"
            on_value="${on_value//\[/}"
            on_value="${on_value//\]/}"
            on_value="${on_value//\"/}"
            on_value="${on_value//, / }"
            # <C-p> → Ctrl+p (menschenlesbar)
            on_value="${on_value//<C-/Ctrl+}"
            on_value="${on_value//>/}"
        # desc = "Beschreibung"
        elif [[ "$line" == "desc = "* ]]; then
            desc_value="${line#desc = }"
            desc_value="${desc_value//\"/}"
            # Ausgabe wenn on und desc vorhanden
            if [[ -n "$on_value" && -n "$desc_value" ]]; then
                # Sektionsheader nur einmal ausgeben
                if [[ -n "$current_section" && -z "$section_printed" ]]; then
                    output+="\n# dotfiles: ${current_section}\n\n"
                    section_printed="yes"
                fi
                # Format: `g d` → Downloads
                output+="- \`${on_value}\` → ${desc_value}\n"
            fi
        fi
    done < "$keymap"

    # Abschließende Leerzeile für saubere Trennung
    [[ -n "$output" ]] && output+="\n"
    printf '%b' "$output"
}

# ------------------------------------------------------------
# Parser: Shell-Keybindings aus fzf.alias Header
# ------------------------------------------------------------
parse_shell_keybindings() {
    local file="$1"
    local output=""
    local in_section=false

    while IFS= read -r line; do
        [[ "$line" == *"Shell-Keybindings"* ]] && { in_section=true; continue; }
        [[ "$in_section" == true && "$line" == "# ----"* ]] && continue
        [[ "$in_section" == true && "$line" == *"ZOXIDE"* ]] && break

        if [[ "$in_section" == true && "$line" == "# Ctrl+X "* ]]; then
            local rest="${line#\# Ctrl+X }"
            local num="${rest%%:*}"
            local desc="${rest#*: }"
            output+="- dotfiles: ${desc}:\n\n\`<Ctrl x> ${num}\`\n\n"
        fi
    done < "$file"

    echo -e "$output"
}

# ------------------------------------------------------------
# Parser: Cross-Referenzen aus Header-Block
# ------------------------------------------------------------
parse_cross_references() {
    local file="$1"
    local output=""

    while IFS= read -r line; do
        [[ "$line" == "# Guard"* ]] && break

        if [[ "$line" == *".alias"*"→"* ]]; then
            local temp="${line#*- }"
            local tool="${temp%%.alias*}"
            tool="${tool// /}"

            local after_arrow="${line#*→ }"
            local funcs="$after_arrow"
            while [[ "$funcs" == *'('*')'* ]]; do
                funcs="${funcs%%\(*}${funcs#*\)}"
            done
            funcs="${funcs// /}"

            [[ -n "$tool" && -n "$funcs" ]] && output+="${tool}|${funcs}\n"
        fi
    done < "$file"

    echo -e "$output"
}
