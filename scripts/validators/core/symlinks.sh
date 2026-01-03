#!/usr/bin/env zsh
# ============================================================
# symlinks.sh - Symlink-Tabelle Validierung
# ============================================================
# Prüft: Symlink-Kategorien vs installation.md
# ============================================================

[[ -z "${VALIDATOR_LIB_LOADED:-}" ]] && source "${0:A:h:h}/lib.sh"

check_symlinks() {
    log "Prüfe Symlink-Dokumentation..."
    
    local install_doc="$DOCS_DIR/installation.md"
    local terminal_dir="$TERMINAL_DIR"
    
    local code_count=0
    
    # Shell-Dateien
    [[ -f "$terminal_dir/.zshenv" ]] && ((code_count++)) || true
    [[ -f "$terminal_dir/.zshrc" ]] && ((code_count++)) || true
    [[ -f "$terminal_dir/.zprofile" ]] && ((code_count++)) || true
    [[ -f "$terminal_dir/.zlogin" ]] && ((code_count++)) || true
    
    # Config-Verzeichnisse (alle in terminal/.config/)
    [[ -d "$terminal_dir/.config/alias" ]] && ((code_count++)) || true
    [[ -d "$terminal_dir/.config/bat" ]] && ((code_count++)) || true
    [[ -d "$terminal_dir/.config/btop" ]] && ((code_count++)) || true
    [[ -d "$terminal_dir/.config/eza" ]] && ((code_count++)) || true
    [[ -d "$terminal_dir/.config/fastfetch" ]] && ((code_count++)) || true
    [[ -d "$terminal_dir/.config/fd" ]] && ((code_count++)) || true
    [[ -d "$terminal_dir/.config/fzf" ]] && ((code_count++)) || true
    [[ -d "$terminal_dir/.config/lazygit" ]] && ((code_count++)) || true
    [[ -d "$terminal_dir/.config/ripgrep" ]] && ((code_count++)) || true
    [[ -f "$terminal_dir/.config/shell-colors" ]] && ((code_count++)) || true
    [[ -d "$terminal_dir/.config/tealdeer" ]] && ((code_count++)) || true
    [[ -d "$terminal_dir/.config/zsh" ]] && ((code_count++)) || true
    
    local docs_count
    docs_count=$(sed -n '/## Ergebnis: Symlink/,/^### /p' "$install_doc" | grep -cE "^\| \`~/" 2>/dev/null || echo 0)
    
    if [[ "$code_count" -eq "$docs_count" ]]; then
        ok "Symlink-Kategorien: $code_count"
    else
        err "Symlink-Kategorien: Code=$code_count, Docs=$docs_count"
    fi
}

register_validator "symlinks" "check_symlinks" "Symlink-Kategorien" "core"
