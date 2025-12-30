#!/usr/bin/env zsh
# ============================================================
# readme.sh - README Konsistenz-Validierung
# ============================================================
# Prüft: README ↔ installation.md Synchronität
# ============================================================

[[ -z "${VALIDATOR_LIB_LOADED:-}" ]] && source "${0:A:h:h}/lib.sh"

check_readme_consistency() {
    local readme="$DOTFILES_DIR/README.md"
    local installation="$DOCS_DIR/installation.md"
    local errors=0
    
    # 1. Prüfe ob Quickstart-Befehle konsistent sind
    # README hat einen Einzeiler, installation.md hat separate Schritte
    # Prüfe dass alle Teile vorhanden sind
    
    local readme_cmd
    readme_cmd=$(grep -A5 "Nach Terminal-Neustart:" "$readme" | grep "stow" | head -1 | sed 's/^[[:space:]]*//')
    
    if [[ -z "$readme_cmd" ]]; then
        err "README: Kein Stow-Befehl gefunden"
        (( errors++ )) || true
    else
        # Prüfe ob alle wichtigen Teile vorhanden sind
        local missing=()
        
        [[ "$readme_cmd" != *"stow --adopt -R terminal"* ]] && missing+=("stow --adopt -R terminal")
        [[ "$readme_cmd" != *"git reset --hard HEAD"* ]] && missing+=("git reset --hard HEAD")
        [[ "$readme_cmd" != *"bat cache --build"* ]] && missing+=("bat cache --build")
        
        if (( ${#missing[@]} > 0 )); then
            err "README Quickstart fehlt: ${missing[*]}"
            (( errors++ )) || true
        else
            ok "README Quickstart enthält alle Schritte"
        fi
        
        # Prüfe ob installation.md dieselben Schritte dokumentiert
        if ! grep -q "stow --adopt -R terminal" "$installation"; then
            err "installation.md: stow-Befehl fehlt"
            (( errors++ )) || true
        fi
        if ! grep -q "bat cache --build" "$installation"; then
            err "installation.md: bat cache --build fehlt"
            (( errors++ )) || true
        fi
        
        if (( errors == 0 )); then
            ok "installation.md enthält alle Quickstart-Schritte"
        fi
    fi
    
    # 2. Prüfe ob curl-Befehl identisch ist
    local readme_curl installation_curl
    
    readme_curl=$(grep "curl -fsSL.*bootstrap" "$readme" 2>/dev/null | head -1 | sed 's/^[[:space:]]*//')
    installation_curl=$(grep "curl -fsSL.*bootstrap" "$installation" 2>/dev/null | head -1 | sed 's/^[[:space:]]*//')
    
    if [[ -n "$readme_curl" && -n "$installation_curl" ]]; then
        if [[ "$readme_curl" != "$installation_curl" ]]; then
            err "Bootstrap-Befehl unterschiedlich:"
            err "  README:         $readme_curl"
            err "  installation:   $installation_curl"
            (( errors++ )) || true
        else
            ok "Bootstrap-Befehl synchron mit installation.md"
        fi
    fi
    
    # 3. Prüfe ob alle Doku-Links existieren
    local target link_errors=0
    while IFS= read -r link; do
        # Extrahiere den Pfad aus dem Link [text](pfad)
        target="${link#*']('}"; target="${target%')'}"
        # Nur relative Links prüfen (keine http/https)
        if [[ "$target" != http* && -n "$target" ]]; then
            if [[ ! -f "$DOTFILES_DIR/$target" ]]; then
                err "Toter Link in README: $target"
                (( link_errors++ )) || true
            fi
        fi
    done < <(grep -oE '\[[^]]+\]\([^)]+\)' "$readme" 2>/dev/null)
    
    if (( link_errors == 0 )); then
        ok "Alle README-Links gültig"
    fi
    
    (( errors += link_errors )) || true
    return $errors
}

register_validator "readme" "check_readme_consistency" "README Konsistenz" "extended"
