#!/usr/bin/env zsh
# ============================================================
# validate-docs.sh - Dokumentations-Validierung
# ============================================================
# Zweck   : Prüft ob Dokumentation mit Code übereinstimmt
# Aufruf  : ./setup/validate-docs.sh
# ============================================================

set -euo pipefail

# Farben
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

SCRIPT_DIR="${0:A:h}"
DOTFILES_DIR="${SCRIPT_DIR:h}"
DOCS_DIR="$DOTFILES_DIR/docs"

errors=0
warnings=0

log()  { print "→ $*"; }
ok()   { print "${GREEN}✔${NC} $*"; }
warn() { print "${YELLOW}⚠${NC} $*"; ((warnings++)); }
err()  { print "${RED}✖${NC} $*"; ((errors++)); }

# ------------------------------------------------------------
# Brewfile-Einträge prüfen
# ------------------------------------------------------------
check_brewfile() {
    log "Prüfe Brewfile-Dokumentation..."
    
    local brewfile="$DOTFILES_DIR/setup/Brewfile"
    local arch_doc="$DOCS_DIR/architecture.md"
    
    # Zähle brew-Einträge im Brewfile (ohne Kommentare)
    local brew_count=$(grep -c '^brew "' "$brewfile" 2>/dev/null || echo 0)
    local cask_count=$(grep -c '^cask "' "$brewfile" 2>/dev/null || echo 0)
    local mas_count=$(grep -c '^mas "' "$brewfile" 2>/dev/null || echo 0)
    
    # Zähle Einträge im Docs-Beispiel
    local docs_brew=$(sed -n '/```ruby/,/```/p' "$arch_doc" | grep -c '^brew "' 2>/dev/null || echo 0)
    local docs_cask=$(sed -n '/```ruby/,/```/p' "$arch_doc" | grep -c '^cask "' 2>/dev/null || echo 0)
    local docs_mas=$(sed -n '/```ruby/,/```/p' "$arch_doc" | grep -c '^mas "' 2>/dev/null || echo 0)
    
    [[ "$brew_count" -eq "$docs_brew" ]] && ok "brew Formulae: $brew_count" || err "brew Formulae: Code=$brew_count, Docs=$docs_brew"
    [[ "$cask_count" -eq "$docs_cask" ]] && ok "cask Formulae: $cask_count" || err "cask Formulae: Code=$cask_count, Docs=$docs_cask"
    [[ "$mas_count" -eq "$docs_mas" ]] && ok "mas Apps: $mas_count" || err "mas Apps: Code=$mas_count, Docs=$docs_mas"
}

# ------------------------------------------------------------
# Alias-Dateien prüfen
# ------------------------------------------------------------
check_alias_files() {
    log "Prüfe Alias-Dokumentation..."
    
    local alias_dir="$DOTFILES_DIR/terminal/.config/alias"
    local tools_doc="$DOCS_DIR/tools.md"
    
    # Bekannte bedingte Aliase (nur mit bestimmten Tools verfügbar)
    # Format: "datei:anzahl_bedingte"
    local -A conditional_aliases=(
        [homebrew]=1   # brewup variiert je nach mas
        [bat]=1        # bat-preview nur mit fzf
    )
    
    for alias_file in "$alias_dir"/*.alias; do
        local name=$(basename "$alias_file")
        local base="${name%.alias}"
        
        # fzf.alias enthält Funktionen statt Aliase
        if [[ "$base" == "fzf" ]]; then
            local code_count=$(grep -cE "^[a-z]+\(\)[[:space:]]*\{" "$alias_file" 2>/dev/null || echo 0)
            ok "$name: $code_count Funktionen (nicht validiert)"
            continue
        fi
        
        # Zähle Aliase im Code
        local code_count=$(grep -cE "^[[:space:]]*alias [a-z]" "$alias_file" 2>/dev/null || echo 0)
        
        # Prüfe ob Datei in Docs erwähnt wird
        if grep -q "### ${base}.alias" "$tools_doc" 2>/dev/null; then
            local docs_count=$(sed -n "/### ${base}.alias/,/^### /p" "$tools_doc" | grep -cE "^\| \`[a-z]" 2>/dev/null || echo 0)
            
            # Prüfe ob diese Datei bekannte bedingte Aliase hat
            local tolerance=${conditional_aliases[$base]:-0}
            
            if [[ "$code_count" -eq "$docs_count" ]]; then
                ok "$name: $code_count Aliase"
            elif [[ "$tolerance" -gt 0 ]] && [[ "$code_count" -eq "$((docs_count + tolerance))" ]]; then
                ok "$name: $code_count Aliase (inkl. $tolerance bedingte)"
            else
                err "$name: Code=$code_count, Docs=$docs_count"
            fi
        else
            err "$name: Nicht in tools.md dokumentiert"
        fi
    done
}

# ------------------------------------------------------------
# Config-Dateien prüfen
# ------------------------------------------------------------
check_config_files() {
    log "Prüfe Config-Dokumentation..."
    
    local config_dir="$DOTFILES_DIR/terminal/.config"
    local arch_doc="$DOCS_DIR/architecture.md"
    
    for tool in fzf bat ripgrep; do
        local config_file="$config_dir/$tool/config"
        
        if [[ -f "$config_file" ]]; then
            # Zähle nicht-kommentierte Optionen
            local code_opts=$(grep -c "^--" "$config_file" 2>/dev/null || echo 0)
            
            # Docs zeigen nur Auszug - prüfe nur ob dokumentiert
            if grep -q "#### ${tool}.*Config" "$arch_doc" 2>/dev/null; then
                ok "$tool config: $code_opts Optionen (Docs zeigen Auszug)"
            else
                err "$tool config: Nicht in architecture.md dokumentiert"
            fi
        fi
    done
}

# ------------------------------------------------------------
# Symlink-Tabelle prüfen
# ------------------------------------------------------------
check_symlinks() {
    log "Prüfe Symlink-Dokumentation..."
    
    local install_doc="$DOCS_DIR/installation.md"
    local terminal_dir="$DOTFILES_DIR/terminal"
    
    # Zähle tatsächliche Symlink-Kategorien
    local code_count=0
    
    # Shell-Dateien
    [[ -f "$terminal_dir/.zshrc" ]] && code_count=$((code_count + 1))
    [[ -f "$terminal_dir/.zprofile" ]] && code_count=$((code_count + 1))
    
    # Config-Verzeichnisse (als Gruppen gezählt)
    [[ -d "$terminal_dir/.config/alias" ]] && code_count=$((code_count + 1))
    [[ -d "$terminal_dir/.config/fzf" ]] && code_count=$((code_count + 1))
    [[ -d "$terminal_dir/.config/bat" ]] && code_count=$((code_count + 1))
    [[ -d "$terminal_dir/.config/ripgrep" ]] && code_count=$((code_count + 1))
    
    # Zähle Tabellenzeilen in installation.md
    local docs_count=$(sed -n '/## Ergebnis: Symlink/,/^### /p' "$install_doc" | grep -cE "^\| \`~/" || echo 0)
    
    if [[ "$code_count" -eq "$docs_count" ]]; then
        ok "Symlink-Kategorien: $code_count"
    else
        err "Symlink-Kategorien: Code=$code_count, Docs=$docs_count"
    fi
}

# ------------------------------------------------------------
# Main
# ------------------------------------------------------------
print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print "📖 Dokumentations-Validierung"
print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print ""

check_brewfile
print ""
check_alias_files
print ""
check_config_files
print ""
check_symlinks

print ""
print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if (( errors > 0 )); then
    print "${RED}❌ $errors Fehler gefunden${NC}"
    print "   Dokumentation weicht vom Code ab!"
    exit 1
elif (( warnings > 0 )); then
    print "${YELLOW}⚠️  $warnings Warnungen${NC}"
    print "   Kleine Abweichungen (evtl. Beispiele gekürzt)"
    exit 0
else
    print "${GREEN}✅ Dokumentation ist synchron${NC}"
    exit 0
fi
