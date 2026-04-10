# ============================================================
# toc.sh - Inhaltsverzeichnis-Generierung (GitHub-kompatibel)
# ============================================================
# Zweck       : heading_to_anchor(), generate_toc(), inject_toc()
# Pfad        : .github/scripts/generators/common/toc.sh
# Genutzt von : readme.sh, setup.sh, customization.sh, contributing.sh
# ============================================================

# ------------------------------------------------------------
# Helper: GitHub-Anker aus Überschrift generieren
# ------------------------------------------------------------
# Konvertiert eine Markdown-Überschrift in einen GitHub-kompatiblen Anker.
# Bildet das Verhalten von github-slugger (v2) nach:
# 1. Kleinschreibung
# 2. Nicht-erlaubte Zeichen entfernen (behält Buchstaben, Ziffern, Leerzeichen, Bindestriche)
# 3. Leerzeichen → Bindestriche
# Subshell mit LC_ALL=C.UTF-8: GNU tr (Ubuntu) konvertiert Unicode-Case nicht,
# daher ZSH-eigene ${(L)} Expansion für Lowercase + sed für Zeichenfilterung.
heading_to_anchor() {
    (
        LC_ALL=C.UTF-8
        local heading="$1"
        printf '%s' "${(L)heading}" | sed 's/[^[:alnum:] -]//g; s/ /-/g'
    )
}

# ------------------------------------------------------------
# Helper: Inhaltsverzeichnis aus generiertem Inhalt ableiten
# ------------------------------------------------------------
# Parst ## und ### Überschriften, generiert Markdown-Links mit Ankern.
# Dedupliziert Anker bei mehrfach vorkommenden Überschriften
# (GitHub hängt -1, -2, … an) mittels Slug-Usage-Map.
generate_toc() {
    local content="$1"
    local toc=""
    local title anchor base_anchor prefix
    local in_code_block=false
    typeset -A slug_count

    while IFS= read -r line; do
        # Code-Blöcke tracken (``` öffnet/schließt)
        if [[ "$line" == '```'* ]]; then
            $in_code_block && in_code_block=false || in_code_block=true
            continue
        fi
        $in_code_block && continue

        if [[ "$line" == '## '* ]]; then
            title="${line#\#\# }"
            prefix="- "
        elif [[ "$line" == '### '* ]]; then
            title="${line#\#\#\# }"
            prefix="  - "
        else
            continue
        fi

        base_anchor=$(heading_to_anchor "$title")
        if (( ${slug_count[$base_anchor]:-0} > 0 )); then
            anchor="${base_anchor}-${slug_count[$base_anchor]}"
        else
            anchor="$base_anchor"
        fi
        (( slug_count[$base_anchor]++ )) || true

        toc+="${prefix}[${title}](#${anchor})"$'\n'
    done <<< "$content"

    # Abschließenden Zeilenumbruch entfernen
    printf '%s' "${toc%$'\n'}"
}

# ------------------------------------------------------------
# Helper: ToC in generierten Inhalt injizieren
# ------------------------------------------------------------
# Teilt den Inhalt in Header (vor erster ## Überschrift oder ---) und Body
# (ab erster ## Überschrift oder ---), generiert ToC aus Body, und setzt
# Header + "## Inhalt" + ToC + Body zusammen.
# Nutzung: printf '%s\n' "$(inject_toc "$full_content")"
inject_toc() {
    local content="$1"
    local header="" body="" in_header=true in_code_block=false line

    while IFS= read -r line; do
        # Code-Blöcke tracken (``` öffnet/schließt)
        if [[ "$line" == '```'* ]]; then
            $in_code_block && in_code_block=false || in_code_block=true
        fi
        if $in_header && ! $in_code_block && [[ "$line" == '## '* || "$line" == "---" ]]; then
            in_header=false
        fi
        if $in_header; then
            header+="$line"$'\n'
        else
            body+="$line"$'\n'
        fi
    done <<< "$content"

    # Trailing Newline entfernen
    body="${body%$'\n'}"

    local toc
    toc=$(generate_toc "$body")

    printf '%s' "$header"
    echo "## Inhalt"
    echo ""
    printf '%s\n' "$toc"
    echo ""
    printf '%s\n' "$body"
}
