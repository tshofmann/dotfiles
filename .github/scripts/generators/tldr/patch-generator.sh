#!/usr/bin/env zsh
# ============================================================
# patch-generator.sh - Generator für Tool-Patches
# ============================================================
# Zweck   : Generiert Patch/Page für einzelne .alias-Dateien
# Pfad    : .github/scripts/generators/tldr/patch-generator.sh
# ============================================================

# Abhängigkeiten: common.sh, tldr/parsers.sh, tldr/alias-helpers.sh

# ------------------------------------------------------------
# Generator: Patch für eine .alias Datei
# ------------------------------------------------------------
generate_patch_for_alias() {
    local alias_file="$1"
    local output=""
    local prev_comment=""

    while IFS= read -r line; do
        local trimmed="${line#"${line%%[![:space:]]*}"}"

        if [[ "$trimmed" == \#* && "$trimmed" != \#\ ----* && "$trimmed" != \#\ ====* ]]; then
            local content="${trimmed#\# }"
            local first_word="${content%%[[:space:]]*}"

            # Ignorieren: Header-Felder und Meta-Kommentare (behalten prev_comment)
            case "$first_word" in
                Zweck|Hinweis|Pfad|Docs|Guard|Voraussetzung|Nutzt|Ersetzt|Aliase|Kommandos|Umgebungsvariablen|Datenbank)
                    # Nicht überschreiben, einfach weiter
                    continue
                    ;;
            esac

            # Gültige Beschreibung: enthält Trennzeichen (– oder -)
            if [[ "$content" == *" – "* || "$content" == *" - "* ]]; then
                prev_comment="$content"
            else
                # Einfacher Kommentar ohne Trennzeichen – nur übernehmen wenn kein Doppelpunkt
                if [[ "$content" != *":"* ]]; then
                    prev_comment="$content"
                fi
                # Bei Doppelpunkt: prev_comment behalten
            fi
            continue
        fi

        # Funktionen: func() {
        if [[ "$trimmed" =~ "^[a-zA-Z0-9][a-zA-Z0-9_-]*\(\) \{" ]]; then
            local func_name="${trimmed%%\(*}"

            [[ "$func_name" == _* ]] && { prev_comment=""; continue; }

            if [[ -n "$prev_comment" ]]; then
                local parsed=$(parse_description_comment "$prev_comment")
                local name="${parsed%%|*}"
                local rest="${parsed#*|}"
                local param="${rest%%|*}"
                local keybindings="${rest#*|}"
                keybindings="${keybindings%%|*}"

                local tldr_param=$(format_param_for_tldr "$param")
                local tldr_keys=$(format_keybindings_for_tldr "$keybindings")

                output+="- dotfiles: ${name}"
                [[ -n "$tldr_keys" ]] && output+=" ${tldr_keys}"
                output+=":\n\n"
                output+="\`${func_name}"
                [[ -n "$tldr_param" ]] && output+=" ${tldr_param}"
                output+="\`\n\n"
            fi

            prev_comment=""
        fi

        # Aliase: alias name='command' (auch eingerückte)
        if [[ "$trimmed" =~ "^alias[[:space:]]+[a-zA-Z0-9][a-zA-Z0-9_-]*=" ]]; then
            local alias_def="${trimmed#alias }"
            local alias_name="${alias_def%%=*}"

            if [[ -n "$prev_comment" ]]; then
                output+="- dotfiles: ${prev_comment}:\n\n"
                output+="\`${alias_name}\`\n\n"
            fi

            prev_comment=""
        fi
    done < "$alias_file"

    echo -e "$output"
}

# ------------------------------------------------------------
# Generator: Cross-Referenzen für fzf.patch.md
# ------------------------------------------------------------
generate_cross_references() {
    local fzf_alias="$ALIAS_DIR/fzf.alias"
    local output=""

    local refs=$(parse_cross_references "$fzf_alias")

    while IFS='|' read -r tool funcs; do
        [[ -z "$tool" ]] && continue
        output+="- dotfiles: Siehe \`tldr ${tool}\` für \`${funcs//,/\`, \`}\`\n"
    done <<< "$refs"

    echo -e "$output"
}

# ------------------------------------------------------------
# Generator: fzf Helper-Beschreibungen aus Dateien (SSOT)
# ------------------------------------------------------------
# Extrahiert # Zweck aus allen fzf-Helper-Skripten dynamisch
generate_fzf_helper_descriptions() {
    local output=""

    # Alle Dateien im fzf-Verzeichnis durchgehen (außer versteckte)
    for helper in "$FZF_DIR"/*(.N); do
        local name="${helper:t}"

        # Überspringe Dateien die nicht dokumentiert werden sollen
        [[ "$name" == "fzf-lib" ]] && continue

        # Extrahiere # Zweck aus der Datei
        local zweck=""
        local _line_count=0
        while IFS= read -r line; do
            if [[ "$line" == "# Zweck"*":"* ]]; then
                zweck="${line#*: }"
                zweck="${zweck## }"  # Führende Leerzeichen entfernen
                break
            fi
            # Abbrechen nach den ersten 15 Zeilen (Header-Bereich)
            (( ++_line_count > 15 )) && break
        done < "$helper"

        # Nur ausgeben wenn Zweck gefunden wurde
        if [[ -n "$zweck" ]]; then
            output+="- dotfiles: \`${name}\` – ${zweck}\n\n"
        fi
    done

    echo -e "$output"
}

# ------------------------------------------------------------
# Generator: Kompletter Patch/Page für ein Tool
# ------------------------------------------------------------
generate_complete_patch() {
    local tool_name="$1"
    local for_page="${2:-false}"  # true wenn für .page.md (Header benötigt)
    local alias_file="$ALIAS_DIR/${tool_name}.alias"
    local output=""

    [[ ! -f "$alias_file" ]] && { err "Alias-Datei nicht gefunden: $alias_file"; return 1; }

    # Header-Infos aus Alias-Datei extrahieren
    local header_info=$(extract_alias_header_info "$alias_file")
    local parsed_name="${header_info%%|*}"
    local rest="${header_info#*|}"
    local zweck="${rest%%|*}"
    rest="${rest#*|}"
    local docs="${rest%%|*}"
    rest="${rest#*|}"
    local nutzt="${rest%%|*}"
    local config="${rest#*|}"

    # Für Pages: Header aus Alias-Datei generieren
    if [[ "$for_page" == "true" ]]; then
        output+="# ${tool_name}\n\n"
        [[ -n "$zweck" ]] && output+="> ${zweck}.\n"
        [[ -n "$docs" ]] && output+="> Mehr Informationen: <${docs}>\n"
        output+="\n"
    fi

    # Konfigurationspfad anzeigen (für Pages und Patches)
    if [[ -n "$config" ]]; then
        output+="- dotfiles: Config \`${config}\`\n\n"
    fi

    # Abhängigkeiten anzeigen (für Pages und Patches)
    if [[ -n "$nutzt" ]]; then
        output+="- dotfiles: Nutzt \`${nutzt}\`\n\n"
    fi

    if [[ "$tool_name" == "fzf" ]]; then
        output+="# dotfiles: Globale Tastenkürzel (in allen fzf-Dialogen)\n\n"
        output+=$(parse_fzf_config_keybindings "$FZF_CONFIG")
        output+="\n# dotfiles: Helper-Skripte (~/.config/fzf/)\n\n"
        output+=$(generate_fzf_helper_descriptions)
        output+="\n# dotfiles: Funktionen (aus fzf.alias)\n\n"
    fi

    if [[ "$tool_name" == "yazi" ]]; then
        local yazi_keymap="$DOTFILES_DIR/terminal/.config/yazi/keymap.toml"
        local yazi_keys=$(parse_yazi_keymap "$yazi_keymap")
        [[ -n "$yazi_keys" ]] && output+="${yazi_keys}\n\n"
        output+="# dotfiles: Shell-Wrapper\n\n"
    fi

    local alias_output=$(generate_patch_for_alias "$alias_file")
    [[ -n "$alias_output" ]] && output+="${alias_output}"

    if [[ "$tool_name" == "fzf" ]]; then
        output+="\n# dotfiles: Shell-Keybindings (Ctrl+X Prefix)\n\n"
        output+=$(parse_shell_keybindings "$alias_file")
        output+="\n# dotfiles: Tool-spezifische fzf-Funktionen\n\n"
        output+=$(generate_cross_references)
    fi

    echo -e "$output"
}
