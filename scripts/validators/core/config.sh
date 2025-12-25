#!/usr/bin/env zsh
# ============================================================
# config.sh - Config-Dateien Validierung
# ============================================================
# Prüft: Config-Dateien Existenz + Dokumentation
# ============================================================

[[ -z "${VALIDATOR_LIB_LOADED:-}" ]] && source "${0:A:h:h}/lib.sh"

check_config_files() {
    log "Prüfe Config-Dokumentation..."
    
    local config_dir="$TERMINAL_DIR/.config"
    local arch_doc="$DOCS_DIR/architecture.md"
    
    local config_file code_opts
    for tool in fzf bat ripgrep; do
        config_file="$config_dir/$tool/config"
        
        if [[ -f "$config_file" ]]; then
            code_opts=$(grep -c "^--" "$config_file" 2>/dev/null || echo 0)
            
            if grep -q "#### ${tool}.*Config" "$arch_doc" 2>/dev/null; then
                ok "$tool config: $code_opts Optionen"
            else
                err "$tool config: Nicht in architecture.md dokumentiert"
            fi
        fi
    done
}

register_validator "config" "check_config_files" "Config-Dateien" "core"
