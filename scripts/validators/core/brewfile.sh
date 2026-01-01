#!/usr/bin/env zsh
# ============================================================
# brewfile.sh - Brewfile Validierung
# ============================================================
# Prüft: Brewfile Einträge vs architecture.md + tools.md
# Dynamisch: Extrahiert alle Einträge aus Brewfile
# ============================================================

[[ -z "${VALIDATOR_LIB_LOADED:-}" ]] && source "${0:A:h:h}/lib.sh"

# Extrahiert Namen aus Brewfile-Zeilen (brew "name", cask "name", mas "name")
_extract_brewfile_names() {
    local type="$1"
    local file="$2"
    grep "^${type} \"" "$file" 2>/dev/null | sed -E 's/^'"${type}"' "([^"]+)".*/\1/'
}

check_brewfile() {
    log "Prüfe Brewfile-Dokumentation..."
    
    local brewfile="$SETUP_DIR/Brewfile"
    local arch_doc="$DOCS_DIR/architecture.md"
    local tools_doc="$DOCS_DIR/tools.md"
    
    # Zähle brew-Einträge im Brewfile
    local brew_count cask_count mas_count
    brew_count=$(grep -c '^brew "' "$brewfile" 2>/dev/null || echo 0)
    cask_count=$(grep -c '^cask "' "$brewfile" 2>/dev/null || echo 0)
    mas_count=$(grep -c '^mas "' "$brewfile" 2>/dev/null || echo 0)
    
    # Zähle Einträge im Docs-Beispiel (architecture.md)
    local docs_brew docs_cask docs_mas
    docs_brew=$(sed -n '/```ruby/,/```/p' "$arch_doc" | grep -c '^brew "' 2>/dev/null || echo 0)
    docs_cask=$(sed -n '/```ruby/,/```/p' "$arch_doc" | grep -c '^cask "' 2>/dev/null || echo 0)
    docs_mas=$(sed -n '/```ruby/,/```/p' "$arch_doc" | grep -c '^mas "' 2>/dev/null || echo 0)
    
    [[ "$brew_count" -eq "$docs_brew" ]] && ok "brew Formulae: $brew_count" || err "brew Formulae: Code=$brew_count, Docs=$docs_brew"
    [[ "$cask_count" -eq "$docs_cask" ]] && ok "cask Formulae: $cask_count" || err "cask Formulae: Code=$cask_count, Docs=$docs_cask"
    [[ "$mas_count" -eq "$docs_mas" ]] && ok "mas Apps: $mas_count" || err "mas Apps: Code=$mas_count, Docs=$docs_mas"
    
    # Dynamisch: Prüfe ALLE Brewfile-Einträge gegen tools.md
    log "Prüfe Brewfile-Einträge in tools.md..."
    local -a missing_tools=()
    local name
    
    # brew Formulae (CLI-Tools + ZSH-Plugins)
    while IFS= read -r name; do
        [[ -z "$name" ]] && continue
        if ! grep -qE "^\| \*\*${name}\*\*" "$tools_doc" 2>/dev/null; then
            missing_tools+=("brew:$name")
        fi
    done < <(_extract_brewfile_names "brew" "$brewfile")
    
    # cask Formulae (Desktop Apps + Fonts)
    while IFS= read -r name; do
        [[ -z "$name" ]] && continue
        if ! grep -qE "^\| \*\*${name}\*\*" "$tools_doc" 2>/dev/null; then
            missing_tools+=("cask:$name")
        fi
    done < <(_extract_brewfile_names "cask" "$brewfile")
    
    # mas Apps (Mac App Store)
    while IFS= read -r name; do
        [[ -z "$name" ]] && continue
        if ! grep -qE "^\| \*\*${name}\*\*" "$tools_doc" 2>/dev/null; then
            missing_tools+=("mas:$name")
        fi
    done < <(_extract_brewfile_names "mas" "$brewfile")
    
    if (( ${#missing_tools[@]} == 0 )); then
        ok "Alle Brewfile-Einträge in tools.md dokumentiert"
    else
        err "Einträge fehlen in tools.md: ${missing_tools[*]}"
    fi
}

register_validator "brewfile" "check_brewfile" "Brewfile-Einträge" "core"
