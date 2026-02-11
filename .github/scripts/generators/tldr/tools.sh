#!/usr/bin/env zsh
# ============================================================
# tools.sh - Spezial-Generatoren für dotfiles, catppuccin, zsh
# ============================================================
# Zweck       : Tool-spezifische Page-Generatoren
# Pfad        : .github/scripts/generators/tldr/tools.sh
# ============================================================

# Abhängigkeiten: common.sh, tldr/parsers.sh, tldr/alias-helpers.sh

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
    output+="> ${PROJECT_TAGLINE}\n"
    output+="> Mehr Informationen: <https://github.com/tshofmann/dotfiles>\n\n"

    # Abhängigkeiten aus dotfiles.alias (Konsistenz mit anderen Pages)
    local nutzt=$(parse_header_field "$dotfiles_alias" "Nutzt")
    [[ -n "$nutzt" ]] && output+="- dotfiles: Nutzt \`${nutzt}\`\n\n"

    # Einstiegspunkte – prominenter Block
    output+="- Diese Hilfe (Schnellreferenz):\n\n\`dothelp\`\n\n"
    output+="- Alle Aliase+Funktionen interaktiv durchsuchen:\n\n\`cmds {{suche}}\`\n\n"
    output+="- Vollständige Tool-Dokumentation:\n\n\`tldr {{tool}}\`\n"

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

    # Verfügbare Hilfeseiten – mit Vollständigkeits-Hinweis
    output+="# Vollständige Dokumentation\n\n"
    output+="- Jedes Tool hat ALLE Aliase+Funktionen dokumentiert:\n\n"

    local patches=()
    local pages=()
    for f in "$TEALDEER_DIR"/*.patch.md(N); do
        patches+=("${${f:t}%.patch.md}")
    done
    for f in "$TEALDEER_DIR"/*.page.md(N); do
        local name="${${f:t}%.page.md}"
        [[ "$name" != "dotfiles" ]] && pages+=("$name")
    done

    local sorted_patches=(${(o)patches})
    output+="\`tldr {{${(j:|:)sorted_patches}}}\`\n\n"

    if (( ${#pages[@]} > 0 )); then
        output+="- Eigene Seiten (ohne offizielle tldr-Basis):\n\n"
        local sorted_pages=(${(o)pages})
        output+="\`tldr {{${(j:|:)sorted_pages}|dotfiles}}\`\n"
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
> Hinweis: Terminal.app und Xcode sind macOS-spezifisch.
> Mehr Informationen: https://catppuccin.com/palette

- Zeige alle Theme-Dateien in diesem Repository:

\`fd -HI -e theme -e tmTheme -e xccolortheme catppuccin ~/dotfiles\`

- Themes aus offiziellen Catppuccin-Repositories (unverändert):

"
    # Sortierte Ausgabe der Upstream-Themes (explizit sortiert für Konsistenz)
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
# Generator: zsh.patch.md aus .zshrc und .zshenv
# ------------------------------------------------------------
# Dokumentiert dotfiles-spezifische ZSH-Konfiguration
# Parst .zshenv und .zshrc dynamisch (SSOT)
generate_zsh_page() {
    local zshrc="$DOTFILES_DIR/terminal/.zshrc"
    local zshenv="$DOTFILES_DIR/terminal/.zshenv"
    local output=""

    # Header mit Links zu Startup-Files Dokumentation
    output+="# dotfiles: Konfigurationsdateien\n\n"
    output+="- dotfiles: \`~/.zshenv\` – Umgebungsvariablen (XDG-Pfade)\n\n"
    output+="- dotfiles: \`~/.zshrc\` – Hauptkonfiguration für interaktive Shells\n\n"
    output+="- dotfiles: Lade-Reihenfolge: \`.zshenv → .zprofile → .zshrc → .zlogin\`\n\n"

    # --- XDG Base Directory aus .zshenv parsen ---
    output+="# dotfiles: XDG Base Directory\n\n"
    if [[ -f "$zshenv" ]]; then
        # XDG_CONFIG_HOME extrahieren
        local xdg_value
        xdg_value=$(grep -m1 '^export XDG_CONFIG_HOME=' "$zshenv" | sed 's/.*="\(.*\)"/\1/' | sed 's|\$HOME|~|')
        [[ -n "$xdg_value" ]] && output+="- dotfiles: \`\$XDG_CONFIG_HOME\` → \`${xdg_value}\` für alle Tool-Configs\n\n"

        # Explizite XDG-Overrides sammeln (EZA_CONFIG_DIR, TEALDEER_CONFIG_DIR, etc.)
        local -a xdg_overrides=()
        while IFS= read -r line; do
            if [[ "$line" =~ ^export\ ([A-Z_]+_(CONFIG_DIR|CONFIG))= ]]; then
                local varname="${match[1]}"
                if [[ "$varname" != "XDG_CONFIG_HOME" ]]; then
                    xdg_overrides+=("\`\$${varname}\`")
                fi
            fi
        done < "$zshenv"
        if (( ${#xdg_overrides[@]} > 0 )); then
            output+="- dotfiles: ${(j: und :)xdg_overrides} explizit gesetzt (macOS)\n\n"
        fi
    fi

    # --- History-Konfiguration aus .zshrc parsen ---
    output+="# dotfiles: History-Konfiguration\n\n"
    if [[ -f "$zshrc" ]]; then
        # SAVEHIST dynamisch extrahieren und formatieren (25000 → 25.000)
        local savehist
        savehist=$(grep -m1 '^SAVEHIST=' "$zshrc" | cut -d= -f2)
        if [[ -n "$savehist" ]]; then
            # Tausender-Punkt: Zahl in "Prefix.letzten3" aufteilen
            local formatted
            if (( savehist >= 1000 )); then
                formatted="${savehist[1,-4]}.${savehist[-3,-1]}"
            else
                formatted="$savehist"
            fi
            output+="- dotfiles: Zentrale History in \`~/.zsh_history\` (${formatted} Einträge)\n\n"
        fi

        # SHELL_SESSIONS_DISABLE aus .zshenv prüfen
        if [[ -f "$zshenv" ]] && grep -q '^SHELL_SESSIONS_DISABLE=1' "$zshenv"; then
            output+="- dotfiles: \`SHELL_SESSIONS_DISABLE=1\` – keine separate History pro Tab\n\n"
        fi

        # HIST_IGNORE_SPACE aus setopt-Zeilen erkennen
        if grep -q '^setopt HIST_IGNORE_SPACE' "$zshrc"; then
            output+="- dotfiles: Führende Leerzeichen verbergen Befehle aus History (\`HIST_IGNORE_SPACE\`)\n\n"
        fi
    fi

    # --- Alias-System aus .zshrc erkennen ---
    output+="# dotfiles: Alias-System\n\n"
    if [[ -f "$zshrc" ]]; then
        # Alias-Lade-Schleife erkennen
        if grep -q '\.alias' "$zshrc"; then
            output+="- dotfiles: Alle \`.alias\`-Dateien aus \`~/.config/alias/\` werden geladen\n\n"
        fi
        # Theme-style source erkennen
        if grep -q 'theme-style' "$zshrc"; then
            output+="- dotfiles: Farben aus \`~/.config/theme-style\` (\`\$C_GREEN\`, \`\$C_RED\`, etc.)\n\n"
        fi
    fi

    # --- Tool-Integrationen dynamisch aus .zshrc parsen ---
    # Erkennt: command -v <tool> Blöcke mit zugehörigen Inline-Kommentaren
    output+="# dotfiles: Tool-Integrationen\n\n"
    if [[ -f "$zshrc" ]]; then
        # fzf: eigene init.zsh
        if grep -q 'command -v fzf' "$zshrc"; then
            output+="- dotfiles: fzf – \`~/.config/fzf/init.zsh\` und \`config\`\n\n"
        fi

        # zoxide: z/zi Beschreibung aus Kommentar parsen
        if grep -q 'command -v zoxide' "$zshrc"; then
            local zoxide_desc=""
            zoxide_desc=$(grep -A1 'command -v zoxide' "$zshrc" | grep '^    # ' | head -1 | sed 's/^    # //')
            if [[ -n "$zoxide_desc" ]]; then
                # Winkelklammern escapen, damit z <query> in Markdown sichtbar bleibt
                local zoxide_desc_escaped="${zoxide_desc//</&lt;}"
                zoxide_desc_escaped="${zoxide_desc_escaped//>/&gt;}"
                output+="- dotfiles: zoxide – ${zoxide_desc_escaped}\n\n"
            else
                output+="- dotfiles: zoxide – Schnelle Verzeichniswechsel\n\n"
            fi
        fi

        # bat: MANPAGER erkennen
        if grep -q 'command -v bat' "$zshrc" && grep -q 'MANPAGER' "$zshrc"; then
            output+="- dotfiles: bat – Man-Pages mit Syntax-Highlighting (\`\$MANPAGER\`)\n\n"
        fi

        # starship: Inline-Kommentar parsen
        if grep -q 'command -v starship' "$zshrc"; then
            local starship_desc=""
            starship_desc=$(grep 'starship init' "$zshrc" | grep '#' | sed 's/.*# //')
            [[ -n "$starship_desc" ]] && output+="- dotfiles: starship – ${starship_desc} (tldr starship)\n\n" \
                                      || output+="- dotfiles: starship – Shell-Prompt (tldr starship)\n\n"
        fi

        # gh: Completions erkennen
        if grep -q 'command -v gh' "$zshrc"; then
            local gh_desc=""
            gh_desc=$(grep 'gh completion' "$zshrc" | grep '#' | sed 's/.*# //')
            [[ -n "$gh_desc" ]] && output+="- dotfiles: gh – ${gh_desc}\n\n" \
                                || output+="- dotfiles: gh – GitHub CLI Completions\n\n"
        fi
    fi

    # --- ZSH-Plugins aus .zshrc parsen ---
    output+="# dotfiles: ZSH-Plugins\n\n"
    if [[ -f "$zshrc" ]]; then
        # Autosuggestions: Keybindings aus Kommentaren extrahieren
        if grep -q 'zsh-autosuggestions' "$zshrc"; then
            # Keybinding-Kommentare sammeln (Format: #   Key   Beschreibung)
            local -a as_keys=()
            local in_as_block=false
            while IFS= read -r line; do
                [[ "$line" == *"Autosuggestions"* ]] && in_as_block=true
                if $in_as_block; then
                    if [[ "$line" == "#   →"* || "$line" == "#   Alt+→"* || "$line" == "#   Escape"* || "$line" == "#   Esc"* ]]; then
                        local content="${line#\#   }"
                        # Key = alles vor doppeltem Space, Desc = alles danach
                        local key="${content%%  *}"
                        local desc="${content#*  }"
                        while [[ "$desc" == " "* ]]; do desc="${desc# }"; done
                        as_keys+=("${key} ${desc}")
                    fi
                    # Block endet bei nächster Nicht-Kommentar-Zeile nach Keys
                    if (( ${#as_keys[@]} > 0 )) && [[ "$line" != "#"* && -n "$line" ]]; then
                        break
                    fi
                fi
            done < "$zshrc"

            output+="- dotfiles: zsh-autosuggestions – Vorschläge aus History:\n\n"
            if (( ${#as_keys[@]} > 0 )); then
                output+="\`${(j:, :)as_keys}\`\n\n"
            fi
        fi

        # Syntax-Highlighting: Farb-Beschreibungen aus Kommentaren
        if grep -q 'zsh-syntax-highlighting' "$zshrc"; then
            local -a sh_colors=()
            local in_sh_block=false
            while IFS= read -r line; do
                # Block startet bei "Syntax-Highlighting: Farben zeigen"
                [[ "$line" == *"Syntax-Highlighting:"*"Farben"* ]] && in_sh_block=true
                if $in_sh_block; then
                    if [[ "$line" =~ ^#\ \ \ ([A-Za-zÜÖÄüöä]+)\ +(.+)$ ]]; then
                        local color_name="${match[1]}"
                        local color_desc="${match[2]}"
                        sh_colors+=("${color_name}=${color_desc}")
                    fi
                    # Block endet bei WICHTIG-Kommentar oder Nicht-Kommentar
                    [[ "$line" == "# WICHTIG"* ]] && break
                fi
            done < "$zshrc"

            output+="- dotfiles: zsh-syntax-highlighting – Farbige Befehlsvalidierung:\n\n"
            if (( ${#sh_colors[@]} > 0 )); then
                output+="\`${(j:, :)sh_colors}\`\n\n"
            fi
        fi
    fi

    # --- Completion-System aus .zshrc erkennen ---
    output+="# dotfiles: Completion-System\n\n"
    if [[ -f "$zshrc" ]]; then
        # compinit-Logik erkennen (tägliche Cache-Erneuerung)
        if grep -q 'compinit' "$zshrc"; then
            output+="- dotfiles: Tab-Vervollständigung mit täglicher Cache-Erneuerung\n\n"
            output+="- dotfiles: \`compinit\` läuft nur einmal täglich vollständig\n\n"
        fi
    fi

    echo -e "$output"
}

generate_zsh_tldr() {
    local mode="${1:---check}"
    local patch_file="$TEALDEER_DIR/zsh.patch.md"

    case "$mode" in
        --check)
            local generated=$(generate_zsh_page)
            local current=""
            [[ -f "$patch_file" ]] && current=$(cat "$patch_file")

            if [[ "$generated" != "$current" ]]; then
                err "zsh.patch.md ist veraltet"
                return 1
            fi
            return 0
            ;;
        --generate)
            local generated=$(generate_zsh_page)
            write_if_changed "$patch_file" "$generated"
            ;;
    esac
}
