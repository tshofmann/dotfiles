#!/usr/bin/env zsh
# ============================================================
# tldr.sh - Generator für tldr-Patches und Pages
# ============================================================
# Zweck   : Generiert tldr-Patches aus .alias-Dateien
#           Falls keine offizielle tldr-Seite existiert,
#           wird stattdessen eine .page.md generiert
# Pfad    : .github/scripts/generators/tldr.sh
# Hinweis : Ersetzt scripts/generate-tldr-patches.sh
# ============================================================

source "${0:A:h}/lib.sh"

# ------------------------------------------------------------
# Helper: Prüfe ob offizielle tldr-Seite existiert
# ------------------------------------------------------------
# Prüft im tealdeer-Cache ob eine offizielle Seite vorhanden ist
# Cache-Pfad: ~/Library/Caches/tealdeer/tldr-pages/pages.{lang}/{platform}/
has_official_tldr_page() {
    local tool_name="$1"
    local cache_base="${HOME}/Library/Caches/tealdeer/tldr-pages"

    # Prüfe in allen Sprachen und Plattformen
    for lang_dir in "$cache_base"/pages.*(N); do
        for platform in common osx linux; do
            [[ -f "$lang_dir/$platform/${tool_name}.md" ]] && return 0
        done
    done

    return 1
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

    param="${param%%\?}"
    param="${param%%=*}"

    echo "{{${param}}}"
}

# ------------------------------------------------------------
# Parser: fzf/config globale Keybindings
# ------------------------------------------------------------
parse_fzf_config_keybindings() {
    local config="$1"
    local output=""
    local prev_comment=""

    while IFS= read -r line; do
        if [[ "$line" == "# Ctrl"*":"* || "$line" == "# Alt"*":"* ]]; then
            prev_comment="${line#\# }"
        elif [[ "$line" == "--bind="* && -n "$prev_comment" ]]; then
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
        else
            prev_comment=""
        fi
    done < "$config"

    output+="- dotfiles: Einzelnen Eintrag zur Auswahl hinzufügen:\n\n\`<Tab>\`\n\n"

    echo -e "$output"
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
        if [[ "$trimmed" =~ "^[a-zA-Z][a-zA-Z0-9_-]*\(\) \{" ]]; then
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
        if [[ "$trimmed" =~ "^alias[[:space:]]+[a-zA-Z][a-zA-Z0-9_-]*=" ]]; then
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
            (( count++ ))
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

    while IFS= read -r line; do
        # Sektionsheader gefunden (exakter Match)
        if [[ "$line" == "# ${section_name}" ]]; then
            in_section=true
            continue
        fi

        # Trennlinie überspringen
        [[ "$in_section" == true && "$line" == "# ---"* ]] && continue

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
            elif [[ "$line" =~ "^alias ([a-z_-]+)=" ]]; then
                local name="${match[1]}"
                [[ -n "$prev_comment" ]] && echo "${name}|${prev_comment}"
                prev_comment=""
            # Funktion gefunden
            elif [[ "$line" =~ "^([a-z_-]+)\(\) \{" ]]; then
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
# Generator: dotfiles.page.md Schnellreferenz
# ------------------------------------------------------------
# Quellen (alle dynamisch extrahiert):
#   - .zshrc: Shell-Keybindings (Tab, Autosuggestions)
#   - fzf/init.zsh: Globale Ctrl+X Keybindings
#   - *.alias Header: Ersetzt-Feld für moderne Ersetzungen
#   - *.alias Header: Aliase-Feld für Beispiele
#   - brew.alias: Sektionen "Update & Wartung", "Versionsübersicht"
#   - dotfiles.alias: Sektion "Dotfiles Wartung"
#   - pages/*.patch.md, *.page.md: Verfügbare Hilfeseiten
generate_dotfiles_page() {
    local output=""
    local zshrc="$DOTFILES_DIR/terminal/.zshrc"
    local fzf_init="$DOTFILES_DIR/terminal/.config/fzf/init.zsh"
    local brew_alias="$ALIAS_DIR/brew.alias"
    local dotfiles_alias="$ALIAS_DIR/dotfiles.alias"

    # Header
    output+="# dotfiles\n\n"
    output+="> macOS-Konfiguration mit ZSH, Catppuccin und modernen CLI-Tools.\n"
    output+="> Mehr Informationen: <https://github.com/tshofmann/dotfiles>\n\n"

    # Abhängigkeiten aus dotfiles.alias (Konsistenz mit anderen Pages)
    local nutzt=$(parse_header_field "$dotfiles_alias" "Nutzt")
    [[ -n "$nutzt" ]] && output+="- dotfiles: Nutzt \`${nutzt}\`\n\n"

    # Einstiegspunkte
    output+="- Diese Hilfe anzeigen:\n\n\`dothelp\`\n"

    # Aliase-Sektion mit fa
    output+="\n# ${DOTHELP_CAT_ALIASES}\n\n"
    output+="- Interaktiv durchsuchen (Enter=ausführen, Ctrl+Y=kopieren):\n\n\`fa {{suche}}\`\n"

    # Shell-Keybindings aus .zshrc (Format: #   Key   Beschreibung)
    output+="\n# ${DOTHELP_CAT_KEYBINDINGS}\n\n"
    if [[ -f "$zshrc" ]]; then
        while IFS= read -r line; do
            # Format: #   →        Vorschlag komplett übernehmen
            if [[ "$line" == "#   →"* || "$line" == "#   Alt+"* || "$line" == "#   Escape"* ]]; then
                local content="${line#\#   }"
                # Spalte bei mehreren Spaces
                local key="${content%%  *}"
                local desc="${content#*  }"
                # Führende Spaces entfernen
                while [[ "$desc" == " "* ]]; do desc="${desc# }"; done
                output+="- ${desc}:\n\n\`${key}\`\n\n"
            fi
        done < "$zshrc"
    fi

    # Globale Keybindings aus fzf/init.zsh
    output+="# ${DOTHELP_CAT_FZF} (Ctrl+X Prefix)\n\n"
    if [[ -f "$fzf_init" ]]; then
        while IFS= read -r line; do
            if [[ "$line" == "bindkey '^X"*"'"*"# Ctrl+X"* ]]; then
                # Extrahiere: bindkey '^X1' fzf-history-widget  # Ctrl+X 1 = History
                local comment="${line#*\# }"
                local key="${comment%% =*}"
                local desc="${comment#*= }"
                output+="- ${desc}:\n\n\`${key}\`\n\n"
            fi
        done < "$fzf_init"
    fi

    # Moderne Ersetzungen aus *.alias Ersetzt-Feldern + Aliase-Feld
    output+="# ${DOTHELP_CAT_REPLACEMENTS}\n\n"
    local -A replacements=()
    for alias_file in "$ALIAS_DIR"/*.alias(N); do
        local tool_name=$(basename "$alias_file" .alias)
        local ersetzt=$(parse_header_field "$alias_file" "Ersetzt")
        if [[ -n "$ersetzt" && "$ersetzt" == *"("* ]]; then
            local original="${ersetzt%% \(*}"
            local desc="${ersetzt#*\(}"
            desc="${desc%\)}"
            # Bevorzuge explizites Aliase-Feld, sonst extrahiere aus Code
            local examples=$(parse_header_field "$alias_file" "Aliase")
            [[ -z "$examples" ]] && examples=$(extract_alias_names "$alias_file" 4)
            replacements[$tool_name]="${original}|${desc}|${examples}"
        fi
    done

    # Sortierte Ausgabe mit dynamischen Beispielen
    for tool in ${(ko)replacements}; do
        local data="${replacements[$tool]}"
        local original="${data%%|*}"
        local rest="${data#*|}"
        local desc="${rest%%|*}"
        local examples="${rest#*|}"
        output+="- ${original} → ${tool} (${desc}):\n\n"
        if [[ -n "$examples" ]]; then
            output+="\`${examples}\`\n\n"
        else
            output+="\`${tool}\`\n\n"
        fi
    done

    # Homebrew – dynamisch alle Items aus "Update & Wartung" und "Versionsübersicht"
    output+="# Homebrew\n\n"
    if [[ -f "$brew_alias" ]]; then
        local item
        # Update & Wartung Sektion
        while IFS='|' read -r name desc; do
            [[ -n "$name" && -n "$desc" ]] && output+="- ${desc}:\n\n\`${name}\`\n\n"
        done < <(extract_section_items "$brew_alias" "Update & Wartung")
        # Versionsübersicht Sektion
        while IFS='|' read -r name desc; do
            [[ -n "$name" && -n "$desc" ]] && output+="- ${desc}:\n\n\`${name}\`\n\n"
        done < <(extract_section_items "$brew_alias" "Versionsübersicht")
    fi

    # Dotfiles-Wartung – dynamisch alle Items aus "Dotfiles Wartung"
    output+="# Dotfiles-Wartung\n\n"
    if [[ -f "$dotfiles_alias" ]]; then
        while IFS='|' read -r name desc; do
            [[ -n "$name" && -n "$desc" ]] && output+="- ${desc}:\n\n\`${name}\`\n\n"
        done < <(extract_section_items "$dotfiles_alias" "Dotfiles Wartung")
    fi

    # Verfügbare Hilfeseiten
    output+="\n# Verfügbare Hilfeseiten\n\n"
    local patches=()
    local pages=()
    for f in "$TEALDEER_DIR"/*.patch.md(N); do
        patches+=("${${f:t}%.patch.md}")
    done
    for f in "$TEALDEER_DIR"/*.page.md(N); do
        local name="${${f:t}%.page.md}"
        [[ "$name" != "dotfiles" ]] && pages+=("$name")
    done

    output+="- Tools mit dotfiles-Patches (tldr <tool>):\n\n"
    local sorted_patches=(${(o)patches})
    output+="\`${(j:, :)sorted_patches}\`\n\n"

    if (( ${#pages[@]} > 0 )); then
        output+="- Eigene Seiten:\n\n"
        local sorted_pages=(${(o)pages})
        output+="\`${(j:, :)sorted_pages}, dotfiles\`\n"
    fi

    echo -e "$output"
}

# ------------------------------------------------------------
# Generator: dotfiles.page.md prüfen/generieren
# ------------------------------------------------------------
generate_dotfiles_tldr() {
    local mode="${1:---check}"
    local page_file="$TEALDEER_DIR/dotfiles.page.md"

    case "$mode" in
        --check)
            local generated=$(generate_dotfiles_page)
            local current=""
            [[ -f "$page_file" ]] && current=$(cat "$page_file")

            if [[ "$generated" != "$current" ]]; then
                err "dotfiles.page.md ist veraltet"
                return 1
            fi
            return 0
            ;;
        --generate)
            local generated=$(generate_dotfiles_page)
            write_if_changed "$page_file" "$generated"
            ;;
    esac
}

# ------------------------------------------------------------
# Generator: catppuccin.page.md aus theme-style
# ------------------------------------------------------------
# Parst Theme-Quellen aus ~/.config/theme-style Header
# Format: tool | config-pfad | upstream-repo | status
# ------------------------------------------------------------
generate_catppuccin_page() {
    local -A themes_upstream=()      # unverändert aus Upstream
    local -A themes_modified=()      # Upstream mit Anpassungen
    local -A themes_manual=()        # manuell konfiguriert
    local -A theme_paths=()          # Pfad zur Config
    local -A theme_repos=()          # Upstream-Repo URL

    local theme_style_file="$DOTFILES_DIR/terminal/.config/theme-style"
    [[ ! -f "$theme_style_file" ]] && return 1

    # Parse Theme-Quellen Block aus theme-style
    local in_block=false
    while IFS= read -r line; do
        # Block-Start erkennen
        if [[ "$line" == "# Format:"* ]]; then
            in_block=true
            continue
        fi
        [[ "$in_block" != true ]] && continue

        # Block-Ende bei Status-Legende oder leerem Kommentar
        [[ "$line" == "# Status-Legende:"* ]] && break
        [[ "$line" == "#" ]] && continue

        # Nur Zeilen mit "#   tool | ..." parsen
        [[ "$line" != "#   "* ]] && continue
        [[ "$line" != *"|"* ]] && continue

        # Parse: #   tool | path | source | status
        line="${line#\#   }"
        local tc_tool="${line%%|*}"
        line="${line#*|}"
        local tc_path="${line%%|*}"
        line="${line#*|}"
        local tc_repo="${line%%|*}"
        local tc_status="${line#*|}"

        # Trim all leading/trailing whitespace
        tc_tool="${tc_tool#"${tc_tool%%[![:space:]]*}"}"; tc_tool="${tc_tool%"${tc_tool##*[![:space:]]}"}"
        tc_path="${tc_path#"${tc_path%%[![:space:]]*}"}"; tc_path="${tc_path%"${tc_path##*[![:space:]]}"}"
        tc_repo="${tc_repo#"${tc_repo%%[![:space:]]*}"}"; tc_repo="${tc_repo%"${tc_repo##*[![:space:]]}"}"
        tc_status="${tc_status#"${tc_status%%[![:space:]]*}"}"; tc_status="${tc_status%"${tc_status##*[![:space:]]}"}"

        [[ -z "$tc_tool" ]] && continue

        theme_paths[$tc_tool]="$tc_path"
        theme_repos[$tc_tool]="$tc_repo"

        # Kategorisieren nach Status
        case "$tc_status" in
            upstream)
                themes_upstream[$tc_tool]="$tc_repo"
                ;;
            upstream+*|upstream-*)
                # Extrahiere Anpassungsbeschreibung
                local mod="${tc_status#upstream}"
                mod="${mod#+}"; mod="${mod#-}"
                themes_modified[$tc_tool]="$tc_repo | $mod"
                ;;
            generated)
                themes_modified[$tc_tool]="$tc_repo | generiert (bootstrap)"
                ;;
            manual)
                themes_manual[$tc_tool]="kein offizielles Repo"
                ;;
        esac
    done < "$theme_style_file"

    # 3. Generiere Markdown
    local output="# catppuccin

> Catppuccin Mocha Theme-Konfiguration für alle Tools.
> Mehr Informationen: https://catppuccin.com/palette

- Zeige alle Theme-Dateien in diesem Repository:

\`fd -HI -e theme -e tmTheme -e xccolortheme catppuccin ~/dotfiles\`

- Themes aus offiziellen Catppuccin-Repositories (unverändert):

"
    # Sortierte Ausgabe der Upstream-Themes (explizit sortiert für Konsistenz)
    # Verwende 'sort' für locale-unabhängige Sortierung
    local t p i n r
    local sorted_keys
    sorted_keys=($(echo "${(k)themes_upstream}" | tr ' ' '\n' | LC_ALL=C sort))
    for t in $sorted_keys; do
        p="${theme_paths[$t]}"
        output+="\`${t}: ${p}\`\n"
    done

    output+="
- Themes aus Upstream mit lokalen Anpassungen:

"
    sorted_keys=($(echo "${(k)themes_modified}" | tr ' ' '\n' | LC_ALL=C sort))
    for t in $sorted_keys; do
        p="${theme_paths[$t]}"
        i="${themes_modified[$t]}"
        n="${i#*| }"
        output+="\`${t}: ${p} (${n})\`\n"
    done

    output+="
- Manuell konfiguriert (basierend auf catppuccin.com/palette):

"
    sorted_keys=($(echo "${(k)themes_manual}" | tr ' ' '\n' | LC_ALL=C sort))
    for t in $sorted_keys; do
        p="${theme_paths[$t]}"
        n="${themes_manual[$t]}"
        output+="\`${t}: ${p} (${n})\`\n"
    done

    output+="
- Zentrale Shell-Farbvariablen in Skripten nutzen:

\`source ~/.config/theme-style && echo \"\\\${C_GREEN}Erfolg\\\${C_RESET}\"\`

- Upstream Theme-Repositories:

"
    # Alle Upstream-Repos (aus beiden Kategorien)
    local -A all_repos=()
    for t in ${(k)themes_upstream}; do
        all_repos[$t]="${themes_upstream[$t]}"
    done
    for t in ${(k)themes_modified}; do
        i="${themes_modified[$t]}"
        all_repos[$t]="${i%%|*}"
    done

    sorted_keys=($(echo "${(k)all_repos}" | tr ' ' '\n' | LC_ALL=C sort))
    for t in $sorted_keys; do
        r="${all_repos[$t]}"
        r="${r## }"; r="${r%% }"
        output+="\`${t}: ${r}\`\n"
    done

    # Entferne trailing newline für konsistente Ausgabe (echo -e fügt eines hinzu)
    output="${output%\\n}"

    echo -e "$output"
}

# ------------------------------------------------------------
# Generator: catppuccin.page.md prüfen/generieren
# ------------------------------------------------------------
generate_catppuccin_tldr() {
    local mode="${1:---check}"
    local page_file="$TEALDEER_DIR/catppuccin.page.md"

    case "$mode" in
        --check)
            # Generiere in temp-Datei für konsistenten Vergleich
            local temp_file=$(mktemp)
            generate_catppuccin_page > "$temp_file"
            echo "" >> "$temp_file"  # trailing newline

            if ! diff -q "$page_file" "$temp_file" >/dev/null 2>&1; then
                rm -f "$temp_file"
                err "catppuccin.page.md ist veraltet"
                return 1
            fi
            rm -f "$temp_file"
            return 0
            ;;
        --generate)
            local temp_file=$(mktemp)
            generate_catppuccin_page > "$temp_file"
            echo "" >> "$temp_file"  # trailing newline

            if diff -q "$page_file" "$temp_file" >/dev/null 2>&1; then
                rm -f "$temp_file"
                dim "  Unverändert: catppuccin.page.md"
            else
                mv "$temp_file" "$page_file"
                ok "Generiert: catppuccin.page.md"
            fi
            ;;
    esac
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
        output+="- dotfiles: \`config\` – Globale fzf-Optionen (Farben, Layout, Keybindings)\n\n"
        output+="- dotfiles: \`init.zsh\` – Shell-Integration (Ctrl+X Keybindings, FZF_DEFAULT_COMMAND)\n\n"
        output+="- dotfiles: \`preview-file\` – Datei-Vorschau mit bat und Syntax-Highlighting\n\n"
        output+="- dotfiles: \`preview-dir\` – Verzeichnis-Vorschau mit eza --tree\n\n"
        output+="- dotfiles: \`fman-preview\` – Man-Page/tldr Vorschau für fman-Funktion\n\n"
        output+="- dotfiles: \`fa-preview\` – Alias/Funktions-Code-Vorschau für fa-Funktion\n\n"
        output+="- dotfiles: \`fkill-list\` – Prozessliste für fkill-Funktion\n\n"
        output+="- dotfiles: \`safe-action\` – Sichere Aktionen (copy, edit, git-diff, etc.)\n\n"
        output+="\n# dotfiles: Funktionen (aus fzf.alias)\n\n"
    fi

    output+=$(generate_patch_for_alias "$alias_file")

    if [[ "$tool_name" == "fzf" ]]; then
        output+="\n# dotfiles: Shell-Keybindings (Ctrl+X Prefix)\n\n"
        output+=$(parse_shell_keybindings "$alias_file")
        output+="\n# dotfiles: Tool-spezifische fzf-Funktionen\n\n"
        output+=$(generate_cross_references)
    fi

    echo -e "$output"
}

# ------------------------------------------------------------
# Öffentliche Funktion: Alle tldr-Patches generieren/prüfen
# ------------------------------------------------------------
generate_tldr_patches() {
    local mode="${1:---check}"
    local errors=0

    case "$mode" in
        --check)
            for alias_file in "$ALIAS_DIR"/*.alias(N); do
                local tool_name=$(basename "$alias_file" .alias)
                local patch_file="$TEALDEER_DIR/${tool_name}.patch.md"
                local page_file="$TEALDEER_DIR/${tool_name}.page.md"

                # Spezialfälle: dotfiles und catppuccin haben eigene Generatoren
                [[ "$tool_name" == "dotfiles" || "$tool_name" == "catppuccin" ]] && continue

                # Prüfe ob offizielle Seite existiert (bestimmt ob Patch oder Page)
                local is_page=false
                has_official_tldr_page "$tool_name" || is_page=true

                local generated=$(generate_complete_patch "$tool_name" "$is_page")
                local trimmed="${generated//[[:space:]]/}"

                # Keine Inhalte generiert → überspringen
                [[ -z "$trimmed" ]] && continue

                if [[ "$is_page" == "false" ]]; then
                    # Offizielle Seite existiert → .patch.md verwenden
                    if [[ -f "$page_file" ]]; then
                        err "${tool_name}.page.md sollte gelöscht werden (offizielle tldr-Seite existiert)"
                        (( errors++ )) || true
                    fi

                    if [[ -f "$patch_file" ]]; then
                        local current=$(cat "$patch_file")
                        if [[ "$generated" != "$current" ]]; then
                            err "${tool_name}.patch.md ist veraltet"
                            (( errors++ )) || true
                        fi
                    else
                        err "${tool_name}.patch.md fehlt"
                        (( errors++ )) || true
                    fi
                else
                    # Keine offizielle Seite → .page.md verwenden
                    if [[ -f "$patch_file" ]]; then
                        err "${tool_name}.patch.md sollte gelöscht werden (keine offizielle tldr-Seite)"
                        (( errors++ )) || true
                    fi

                    if [[ -f "$page_file" ]]; then
                        local current=$(cat "$page_file")
                        if [[ "$generated" != "$current" ]]; then
                            err "${tool_name}.page.md ist veraltet"
                            (( errors++ )) || true
                        fi
                    else
                        err "${tool_name}.page.md fehlt"
                        (( errors++ )) || true
                    fi
                fi
            done

            # Prüfe dotfiles.page.md
            generate_dotfiles_tldr --check || (( errors++ )) || true

            # Prüfe catppuccin.page.md
            generate_catppuccin_tldr --check || (( errors++ )) || true

            return $errors
            ;;

        --generate)
            for alias_file in "$ALIAS_DIR"/*.alias(N); do
                local tool_name=$(basename "$alias_file" .alias)
                local patch_file="$TEALDEER_DIR/${tool_name}.patch.md"
                local page_file="$TEALDEER_DIR/${tool_name}.page.md"

                # Spezialfälle: dotfiles und catppuccin haben eigene Generatoren
                [[ "$tool_name" == "dotfiles" || "$tool_name" == "catppuccin" ]] && continue

                # Prüfe ob offizielle Seite existiert (bestimmt ob Patch oder Page)
                local is_page=false
                has_official_tldr_page "$tool_name" || is_page=true

                local generated=$(generate_complete_patch "$tool_name" "$is_page")
                local trimmed="${generated//[[:space:]]/}"

                # Keine Inhalte generiert → beide Dateien löschen falls vorhanden
                if [[ -z "$trimmed" ]]; then
                    [[ -f "$patch_file" ]] && rm "$patch_file"
                    [[ -f "$page_file" ]] && rm "$page_file"
                    continue
                fi

                if [[ "$is_page" == "false" ]]; then
                    # Offizielle Seite existiert → .patch.md verwenden
                    [[ -f "$page_file" ]] && rm "$page_file" && dim "  Gelöscht: ${tool_name}.page.md (offizielle tldr-Seite existiert)"
                    write_if_changed "$patch_file" "$generated"
                else
                    # Keine offizielle Seite → .page.md verwenden
                    [[ -f "$patch_file" ]] && rm "$patch_file" && dim "  Gelöscht: ${tool_name}.patch.md (keine offizielle tldr-Seite)"
                    write_if_changed "$page_file" "$generated"
                fi
            done

            # Generiere dotfiles.page.md
            generate_dotfiles_tldr --generate

            # Generiere catppuccin.page.md
            generate_catppuccin_tldr --generate
            ;;
    esac
}

# Nur ausführen wenn direkt aufgerufen (nicht gesourct)
[[ -z "${_SOURCED_BY_GENERATOR:-}" ]] && generate_tldr_patches "$@" || true
