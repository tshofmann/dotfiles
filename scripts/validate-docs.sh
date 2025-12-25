#!/usr/bin/env zsh
# ============================================================
# validate-docs.sh - Dokumentations-Validierung
# ============================================================
# Zweck   : Prüft ob Dokumentation mit Code übereinstimmt
# Aufruf  : ./scripts/validate-docs.sh [--all|--quick|VALIDATOR]
# Version : 3.0 - Modulare Architektur
# ============================================================
# Validiert:
#   ✔ Brewfile Einträge (Namen + Anzahlen)
#   ✔ Bootstrap-Schritte (CURRENT_STEP vs installation.md)
#   ✔ CLI-Tools (health-check.sh vs tools.md)
#   ✔ macOS Mindestversion (Code vs Docs)
#   ✔ Starship-Preset (Code vs Docs)
#   ✔ Alias-Dateien (Anzahlen pro Datei)
#   ✔ Alias-Namen (Existenz prüfen)        [NEU v3.0]
#   ✔ FZF-Funktionen (Code vs Docs)        [NEU v3.0]
#   ✔ Code-Block Befehle (Gültigkeit)      [NEU v3.0]
#   ✔ Config-Dateien (Existenz + Dokumentation)
#   ✔ Symlink-Kategorien
# ============================================================
# Modulare Erweiterung:
#   Neue Validatoren in scripts/validators/ ablegen
#   Format: source lib.sh + register_validator() aufrufen
# ============================================================

set -euo pipefail

# Pfad-Setup
SCRIPT_DIR="${0:A:h}"
DOTFILES_DIR="${SCRIPT_DIR:h}"
DOCS_DIR="$DOTFILES_DIR/docs"
SETUP_DIR="$DOTFILES_DIR/setup"
VALIDATORS_DIR="$SCRIPT_DIR/validators"

# Lade gemeinsame Bibliothek
if [[ -f "$VALIDATORS_DIR/lib.sh" ]]; then
    source "$VALIDATORS_DIR/lib.sh"
else
    # Fallback wenn lib.sh nicht existiert
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'
fi

# Legacy-Kompatibilität
errors=0
warnings=0

log()  { print "→ $*"; }
ok()   { print "${GREEN}✔${NC} $*"; }
warn() { print "${YELLOW}⚠${NC} $*"; ((warnings++)); }
err()  { print "${RED}✖${NC} $*"; ((errors++)); }
info() { print "${BLUE}ℹ${NC} $*"; }

# ------------------------------------------------------------
# macOS Mindestversion prüfen
# ------------------------------------------------------------
check_macos_version() {
    log "Prüfe macOS Versionsangaben..."
    
    local bootstrap="$SETUP_DIR/bootstrap.sh"
    local install_doc="$DOCS_DIR/installation.md"
    local readme="$DOTFILES_DIR/README.md"
    
    # Extrahiere MACOS_MIN_VERSION aus bootstrap.sh
    local code_version
    code_version=$(grep -E '^readonly MACOS_MIN_VERSION=' "$bootstrap" 2>/dev/null | sed 's/.*=//') || true
    
    if [[ -z "$code_version" ]]; then
        warn "MACOS_MIN_VERSION nicht in bootstrap.sh gefunden"
        return
    fi
    
    # Prüfe installation.md
    if grep -qE "macOS ${code_version}(\+| |\))" "$install_doc" 2>/dev/null; then
        ok "installation.md: macOS $code_version+"
    else
        err "installation.md: macOS Version stimmt nicht (erwartet: $code_version)"
    fi
    
    # Prüfe README.md
    if grep -qE "macOS ${code_version}(\+| |\))" "$readme" 2>/dev/null; then
        ok "README.md: macOS $code_version+"
    else
        err "README.md: macOS Version stimmt nicht (erwartet: $code_version)"
    fi
}

# ------------------------------------------------------------
# Bootstrap-Schritte gegen installation.md prüfen
# ------------------------------------------------------------
check_bootstrap_steps() {
    log "Prüfe Bootstrap-Schritte..."
    
    local bootstrap="$SETUP_DIR/bootstrap.sh"
    local install_doc="$DOCS_DIR/installation.md"
    
    # Zähle CURRENT_STEP Zuweisungen (ohne Initialisierung)
    local code_step_count
    code_step_count=$(grep -c 'CURRENT_STEP=' "$bootstrap" 2>/dev/null || echo 0)
    # Minus 1 für die Initialisierung
    code_step_count=$((code_step_count - 1))
    
    ok "Bootstrap-Schritte im Code: $code_step_count"
    
    # Prüfe ob kritische Schritte in installation.md dokumentiert sind
    local -a critical_keywords=("Netzwerk" "Homebrew" "Brewfile" "Font" "Terminal" "Starship" "ZSH")
    local missing=0
    
    for keyword in "${critical_keywords[@]}"; do
        if ! grep -qi "$keyword" "$install_doc" 2>/dev/null; then
            warn "Keyword '$keyword' nicht in installation.md"
            ((missing++)) || true
        fi
    done
    
    if (( missing == 0 )); then
        ok "Alle Bootstrap-Schritte in installation.md referenziert"
    fi
}

# ------------------------------------------------------------
# Brewfile-Einträge prüfen (Namen + Anzahlen)
# ------------------------------------------------------------
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

# ------------------------------------------------------------
# Health-Check Tools gegen tools.md prüfen
# ------------------------------------------------------------
check_healthcheck_tools() {
    log "Prüfe Health-Check Tool-Liste..."
    
    local health_check="$SCRIPT_DIR/health-check.sh"
    local tools_doc="$DOCS_DIR/tools.md"
    
    # Zähle check_tool Aufrufe
    local tool_count
    tool_count=$(grep -c 'check_tool "' "$health_check" 2>/dev/null || echo 0)
    
    ok "Health-Check prüft $tool_count Tools"
    
    # Prüfe kritische Tools
    local -a critical=(fzf stow starship zoxide eza bat fd btop gh)
    local missing=0
    
    for tool in "${critical[@]}"; do
        if ! grep -q "check_tool \"$tool\"" "$health_check" 2>/dev/null; then
            # Einige haben andere Befehlsnamen
            if [[ "$tool" == "ripgrep" ]] && grep -q 'check_tool "rg"' "$health_check" 2>/dev/null; then
                continue
            fi
            warn "Tool '$tool' nicht in health-check.sh"
            ((missing++)) || true
        fi
    done
    
    if (( missing == 0 )); then
        ok "Alle kritischen Tools werden geprüft"
    fi
}

# ------------------------------------------------------------
# Starship-Preset prüfen
# ------------------------------------------------------------
check_starship_preset() {
    log "Prüfe Starship-Preset Dokumentation..."
    
    local bootstrap="$SETUP_DIR/bootstrap.sh"
    local config_doc="$DOCS_DIR/configuration.md"
    local arch_doc="$DOCS_DIR/architecture.md"
    
    # Extrahiere Default-Preset aus bootstrap.sh
    local code_preset
    code_preset=$(grep -E '^readonly STARSHIP_PRESET_DEFAULT=' "$bootstrap" 2>/dev/null | sed 's/.*="//' | sed 's/".*//') || true
    
    if [[ -z "$code_preset" ]]; then
        warn "STARSHIP_PRESET_DEFAULT nicht in bootstrap.sh gefunden"
        return
    fi
    
    ok "Code-Preset: $code_preset"
    
    # Prüfe configuration.md
    if grep -q "$code_preset" "$config_doc" 2>/dev/null; then
        ok "configuration.md: Preset dokumentiert"
    else
        warn "Preset '$code_preset' nicht in configuration.md erwähnt"
    fi
    
    # Prüfe architecture.md  
    if grep -q "$code_preset" "$arch_doc" 2>/dev/null; then
        ok "architecture.md: Preset dokumentiert"
    else
        warn "Preset '$code_preset' nicht in architecture.md erwähnt"
    fi
}

# ------------------------------------------------------------
# Alias-Dateien prüfen
# ------------------------------------------------------------
check_alias_files() {
    log "Prüfe Alias-Dokumentation..."
    
    local alias_dir="$DOTFILES_DIR/terminal/.config/alias"
    local tools_doc="$DOCS_DIR/tools.md"
    
    # Bekannte bedingte Aliase
    local -A conditional_aliases=(
        [homebrew]=1
        [bat]=1
    )
    
    local name base code_count docs_count tolerance
    for alias_file in "$alias_dir"/*.alias(N); do
        [[ -f "$alias_file" ]] || continue
        
        name=$(basename "$alias_file")
        base=${name%.alias}
        
        # fzf.alias enthält Funktionen
        if [[ "$base" == "fzf" ]]; then
            code_count=$(grep -cE "^[a-z]+\(\)[[:space:]]*\{" "$alias_file" 2>/dev/null || echo 0)
            ok "$name: $code_count Funktionen"
            continue
        fi
        
        # Zähle Aliase
        code_count=$(grep -cE "^[[:space:]]*alias [a-z]" "$alias_file" 2>/dev/null || echo 0)
        
        if grep -q "### ${base}.alias" "$tools_doc" 2>/dev/null; then
            docs_count=$(sed -n "/### ${base}.alias/,/^### /p" "$tools_doc" | grep -cE "^\| \`[a-z]" 2>/dev/null || echo 0)
            tolerance=${conditional_aliases[$base]:-0}
            
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

# ------------------------------------------------------------
# Symlink-Tabelle prüfen
# ------------------------------------------------------------
check_symlinks() {
    log "Prüfe Symlink-Dokumentation..."
    
    local install_doc="$DOCS_DIR/installation.md"
    local terminal_dir="$DOTFILES_DIR/terminal"
    
    local code_count=0
    
    # Shell-Dateien
    [[ -f "$terminal_dir/.zshenv" ]] && ((code_count++)) || true
    [[ -f "$terminal_dir/.zshrc" ]] && ((code_count++)) || true
    [[ -f "$terminal_dir/.zprofile" ]] && ((code_count++)) || true
    
    # Config-Verzeichnisse
    [[ -d "$terminal_dir/.config/alias" ]] && ((code_count++)) || true
    [[ -d "$terminal_dir/.config/fzf" ]] && ((code_count++)) || true
    [[ -d "$terminal_dir/.config/bat" ]] && ((code_count++)) || true
    [[ -d "$terminal_dir/.config/ripgrep" ]] && ((code_count++)) || true
    
    local docs_count
    docs_count=$(sed -n '/## Ergebnis: Symlink/,/^### /p' "$install_doc" | grep -cE "^\| \`~/" 2>/dev/null || echo 0)
    
    if [[ "$code_count" -eq "$docs_count" ]]; then
        ok "Symlink-Kategorien: $code_count"
    else
        err "Symlink-Kategorien: Code=$code_count, Docs=$docs_count"
    fi
}

# ------------------------------------------------------------
# Main
# ------------------------------------------------------------
show_help() {
    print "Verwendung: validate-docs.sh [OPTION|VALIDATOR]"
    print ""
    print "Optionen:"
    print "  --all, -a      Alle Validatoren ausführen (Standard)"
    print "  --quick, -q    Nur schnelle Core-Prüfungen"
    print "  --list, -l     Verfügbare Validatoren auflisten"
    print "  --help, -h     Diese Hilfe anzeigen"
    print ""
    print "Validatoren:"
    if [[ -d "$VALIDATORS_DIR" ]]; then
        for v in "$VALIDATORS_DIR"/*.sh(N); do
            [[ "$(basename "$v")" == "lib.sh" ]] && continue
            print "  $(basename "$v" .sh)"
        done
    fi
    print ""
    print "Beispiele:"
    print "  validate-docs.sh              # Alle Prüfungen"
    print "  validate-docs.sh --quick      # Nur Core-Prüfungen"
    print "  validate-docs.sh alias-names  # Nur Alias-Namen prüfen"
}

# Lade modulare Validatoren
load_validators() {
    [[ -d "$VALIDATORS_DIR" ]] || return 0
    
    for validator_file in "$VALIDATORS_DIR"/*.sh(N); do
        [[ "$(basename "$validator_file")" == "lib.sh" ]] && continue
        source "$validator_file"
    done
}

# Core-Prüfungen (immer ausführen)
run_core_checks() {
    print ""
    check_macos_version
    print ""
    check_bootstrap_steps
    print ""
    check_brewfile
    print ""
    check_healthcheck_tools
    print ""
    check_starship_preset
    print ""
    check_alias_files
    print ""
    check_config_files
    print ""
    check_symlinks
}

# Modulare Validatoren ausführen
run_module_validators() {
    if [[ -n "${REGISTERED_VALIDATORS:-}" ]] && (( ${#REGISTERED_VALIDATORS[@]} > 0 )); then
        print ""
        print "━━━ Erweiterte Validierung (Modulare Prüfungen) ━━━"
        run_all_validators
    fi
}

# Hauptprogramm
print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print "📖 Dokumentations-Validierung v3.0"
print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Argumente verarbeiten
case "${1:-}" in
    --help|-h)
        show_help
        exit 0
        ;;
    --list|-l)
        load_validators
        if [[ -n "${REGISTERED_VALIDATORS:-}" ]] && (( ${#REGISTERED_VALIDATORS[@]} > 0 )); then
            list_validators
        else
            print "Keine modularen Validatoren gefunden."
        fi
        exit 0
        ;;
    --quick|-q)
        run_core_checks
        ;;
    --all|-a|"")
        load_validators
        run_core_checks
        run_module_validators
        ;;
    *)
        # Spezifischer Validator
        load_validators
        if [[ -n "${REGISTERED_VALIDATORS:-}" ]] && (( ${#REGISTERED_VALIDATORS[@]} > 0 )); then
            if ! run_validator "$1"; then
                ((errors++)) || true
            fi
        else
            err "Validator '$1' nicht gefunden"
        fi
        ;;
esac

print ""
print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Kombiniere Fehler aus Legacy und Modul-System
if [[ -n "${VALIDATOR_ERRORS:-}" ]] && (( VALIDATOR_ERRORS > 0 )); then
    ((errors += VALIDATOR_ERRORS)) || true
fi
if [[ -n "${VALIDATOR_WARNINGS:-}" ]] && (( VALIDATOR_WARNINGS > 0 )); then
    ((warnings += VALIDATOR_WARNINGS)) || true
fi

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
