#!/usr/bin/env zsh
# ============================================================
# contributing.sh - ToC-Generator für CONTRIBUTING.md
# ============================================================
# Zweck       : Generiert/aktualisiert Inhaltsverzeichnis in CONTRIBUTING.md
# Pfad        : .github/scripts/generators/contributing.sh
# Quelle      : CONTRIBUTING.md (manuell gepflegt, nur ToC wird generiert)
# ============================================================

source "${0:A:h}/common.sh"

# ------------------------------------------------------------
# Haupt-Generator für CONTRIBUTING.md
# ------------------------------------------------------------
# Liest CONTRIBUTING.md, trennt Header vom Body, überspringt ein
# vorhandenes "## Inhalt"-Abschnitt, generiert ToC aus dem Body,
# und setzt alles zusammen: Header + "## Inhalt" + ToC + Body.
generate_contributing_md() {
    local source_file="$DOTFILES_DIR/CONTRIBUTING.md"
    [[ -f "$source_file" ]] || { err "CONTRIBUTING.md nicht gefunden"; return 1; }

    local header="" body="" phase="header" in_code_block=false line

    while IFS= read -r line; do
        # Code-Blöcke tracken (``` öffnet/schließt)
        if [[ "$line" == '```'* ]]; then
            $in_code_block && in_code_block=false || in_code_block=true
        fi

        case "$phase" in
            header)
                if $in_code_block; then
                    header+="$line"$'\n'
                elif [[ "$line" == '## Inhalt' ]]; then
                    # Vorhandenes ToC gefunden → überspringen
                    phase="skip_toc"
                elif [[ "$line" == "---" || "$line" == '## '* ]]; then
                    # Ende des Headers, Start des Body
                    phase="body"
                    body+="$line"$'\n'
                else
                    header+="$line"$'\n'
                fi
                ;;
            skip_toc)
                # ToC-Zeilen überspringen bis --- oder ## (Body-Start)
                if ! $in_code_block && [[ "$line" == "---" || "$line" == '## '* ]]; then
                    phase="body"
                    body+="$line"$'\n'
                fi
                # Alles andere im ToC-Bereich überspringen
                ;;
            body)
                body+="$line"$'\n'
                ;;
        esac
    done < "$source_file"

    # Trailing Newline entfernen
    body="${body%$'\n'}"

    local toc
    toc=$(generate_toc "$body")

    # Zusammensetzen: Header + ToC-Sektion + Body
    printf '%s' "$header"
    echo "## Inhalt"
    echo ""
    printf '%s\n' "$toc"
    echo ""
    printf '%s\n' "$body"
}

# Nur ausführen wenn direkt aufgerufen (nicht gesourct)
[[ -z "${_SOURCED_BY_GENERATOR:-}" ]] && generate_contributing_md || true
