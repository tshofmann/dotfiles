#!/usr/bin/env zsh
# ============================================================
# brewfile.sh - Brewfile Validierung
# ============================================================
# Prüft: Brewfile Einträge vs architecture.md + tools.md
# ============================================================

[[ -z "${VALIDATOR_LIB_LOADED:-}" ]] && source "${0:A:h:h}/lib.sh"

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
    
    # Prüfe Tool-Namen gegen tools.md
    log "Prüfe CLI-Tool Namen in tools.md..."
    local -a required_tools=(fzf stow starship zoxide eza bat ripgrep fd btop gh)
    local missing_tools=()
    
    for tool in "${required_tools[@]}"; do
        if ! grep -qE "^\| \*\*$tool\*\*" "$tools_doc" 2>/dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    if (( ${#missing_tools[@]} == 0 )); then
        ok "Alle kritischen Tools in tools.md dokumentiert"
    else
        err "Tools fehlen in tools.md: ${missing_tools[*]}"
    fi
}

register_validator "brewfile" "check_brewfile" "Brewfile-Einträge" "core"
