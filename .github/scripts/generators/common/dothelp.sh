#!/usr/bin/env zsh
# ============================================================
# dothelp.sh - dothelp Kategorien-Generator
# ============================================================
# Zweck       : Ermittelt dothelp-Kategorien aus echten Quellen
# Pfad        : .github/scripts/generators/common/dothelp.sh
# ============================================================

# Abhängigkeit: config.sh und parsers.sh müssen vorher geladen sein

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
