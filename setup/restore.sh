#!/usr/bin/env zsh
# ============================================================
# restore.sh - Wiederherstellung des Original-Zustands
# ============================================================
# Zweck       : Stellt Backup wieder her und entfernt Symlinks
# Pfad        : setup/restore.sh
# Benötigt    : Ein vorhandenes Backup unter .backup/, jq
# Aufruf      : ./setup/restore.sh [--yes] [--cleanup [--dry-run]]
# Optionen    : --yes      Keine Bestätigung erforderlich
#               --cleanup   Erweiterte Deinstallation (Pakete + Repo)
#               --dry-run   Zeigt was --cleanup tun würde (keine Aktion)
#
# DOCS-SECTION: Deinstallation
# DOCS-TITLE  : Dotfiles entfernen / Wiederherstellung
# DOCS-DESC   : So wird die dotfiles-Installation rückgängig gemacht
#
# Diese Datei macht die dotfiles-Installation rückgängig:
# 1. Entfernt alle Symlinks die auf dotfiles zeigen
# 2. Stellt gesicherte Originaldateien wieder her
# 3. Setzt Terminal-Profil auf "Basic" zurück
# Mit --cleanup zusätzlich:
# 4. Entfernt Homebrew-Pakete aus dem Brewfile (interaktiv)
# 5. Entfernt das Repository ~/dotfiles
# ============================================================

set -euo pipefail

# ------------------------------------------------------------
# Pfad-Setup
# ------------------------------------------------------------
SCRIPT_DIR="${0:A:h}"
DOTFILES_DIR="${SCRIPT_DIR:h}"
BACKUP_DIR="${DOTFILES_DIR}/.backup"
BACKUP_MANIFEST="${BACKUP_DIR}/manifest.json"
BACKUP_HOME="${BACKUP_DIR}/home"

# ------------------------------------------------------------
# Farben laden (theme-style hat Vorrang, dann Logging-Fallback)
# ------------------------------------------------------------
if [[ -f "${DOTFILES_DIR}/terminal/.config/theme-style" ]]; then
    source "${DOTFILES_DIR}/terminal/.config/theme-style"
fi

# Logging-Funktionen laden (nutzt theme-style Farben oder Fallback)
if [[ -f "${SCRIPT_DIR}/lib/logging.sh" ]]; then
    source "${SCRIPT_DIR}/lib/logging.sh"
else
    # Minimaler Fallback (sollte nie auftreten)
    log()     { echo "→ $*"; }
    ok()      { echo "✔ $*"; }
    err()     { echo "✖ $*" >&2; }
    warn()    { echo "⚠ $*"; }
    section() { echo "━━━ $* ━━━"; }
    dim()     { echo "$*"; }
fi

# ------------------------------------------------------------
# Prüfungen
# ------------------------------------------------------------
check_backup_exists() {
    if [[ ! -f "$BACKUP_MANIFEST" ]]; then
        err "Kein Backup gefunden unter: $BACKUP_MANIFEST"
        echo ""
        echo "Mögliche Gründe:"
        echo "  • dotfiles wurden nie installiert (kein Backup nötig)"
        echo "  • Backup wurde manuell gelöscht"
        echo ""
        return 1
    fi
    return 0
}

# ------------------------------------------------------------
# Manifest-Hilfsfunktionen
# ------------------------------------------------------------
# Zählt die Einträge im Manifest
get_manifest_count() {
    jq 'if (.files | type) == "array" then (.files | length) else 0 end' "$BACKUP_MANIFEST" 2>/dev/null || echo "0"
}

# ------------------------------------------------------------
# Prüft ob ein Pfad ein Symlink ins dotfiles-Repo ist
# ------------------------------------------------------------
is_dotfiles_symlink() {
    local filepath="$1"
    [[ -L "$filepath" ]] || return 1

    local target
    target=$(/usr/bin/readlink "$filepath" 2>/dev/null) || return 1

    # Prüfe verschiedene Varianten
    [[ "$target" == "${DOTFILES_DIR}/"* ]] && return 0
    [[ "$target" == *"dotfiles/"* ]] && return 0

    # Auflösen für relative Symlinks (ZSH :A modifier = realpath)
    local resolved
    resolved="${filepath:A}"
    [[ "$resolved" == "${DOTFILES_DIR}/"* ]] && return 0

    return 1
}

# ------------------------------------------------------------
# Symlink entfernen und ggf. Backup wiederherstellen
# Rückgabe: 0 = wiederhergestellt, 1 = übersprungen
# ------------------------------------------------------------
restore_single_file() {
    local target="$1"
    local backup="$2"
    local type="$3"
    local symlink_target="$4"
    local permissions="$5"

    # Nur dotfiles-Symlinks entfernen
    if [[ -L "$target" ]] && is_dotfiles_symlink "$target"; then
        if /bin/rm "$target" 2>/dev/null; then
            log "Entfernt: $target"
        else
            warn "Konnte Symlink nicht entfernen: $target"
            return 1
        fi
    elif [[ -L "$target" ]]; then
        warn "Übersprungen (fremder Symlink): $target"
        return 1
    elif [[ -e "$target" ]]; then
        warn "Übersprungen (keine Symlink): $target"
        return 1
    fi

    # Backup wiederherstellen wenn vorhanden
    if [[ "$backup" != "null" && -n "$backup" ]]; then
        local backup_path="${DOTFILES_DIR}/${backup}"
        if [[ -e "$backup_path" ]]; then
            # Verzeichnis erstellen falls nötig
            if ! /bin/mkdir -p "$(dirname "$target")" 2>/dev/null; then
                warn "Konnte Verzeichnis nicht erstellen: $(dirname "$target")"
                return 1
            fi

            # Datei/Verzeichnis wiederherstellen
            if [[ -d "$backup_path" ]]; then
                if ! /bin/cp -Rp "$backup_path" "$target" 2>/dev/null; then
                    warn "Konnte Verzeichnis nicht wiederherstellen: $target"
                    return 1
                fi
            else
                if ! /bin/cp -p "$backup_path" "$target" 2>/dev/null; then
                    warn "Konnte Datei nicht wiederherstellen: $target"
                    return 1
                fi
            fi

            # Permissions setzen wenn bekannt
            if [[ "$permissions" != "null" && -n "$permissions" ]]; then
                /bin/chmod "$permissions" "$target" 2>/dev/null || true
            fi

            ok "Wiederhergestellt: $target"
            return 0
        else
            warn "Backup nicht gefunden: $backup_path"
            return 1
        fi
    elif [[ "$type" == "symlink" && "$symlink_target" != "null" && -n "$symlink_target" ]]; then
        # Fremden Symlink wiederherstellen
        if ! /bin/mkdir -p "$(dirname "$target")" 2>/dev/null; then
            warn "Konnte Verzeichnis nicht erstellen: $(dirname "$target")"
            return 1
        fi
        if ! /bin/ln -s "$symlink_target" "$target" 2>/dev/null; then
            warn "Konnte Symlink nicht wiederherstellen: $target -> $symlink_target"
            return 1
        fi
        ok "Symlink wiederhergestellt: $target -> $symlink_target"
        return 0
    fi

    # Kein Backup nötig/vorhanden
    return 1
}

# ------------------------------------------------------------
# Terminal-Profil auf Basic zurücksetzen
# ------------------------------------------------------------
reset_terminal_profile() {
    if ! command -v defaults >/dev/null 2>&1; then
        return 0  # Nicht auf macOS
    fi

    log "Setze Terminal-Profil zurück..."

    # Standard-Profil auf "Basic" setzen
    defaults write com.apple.Terminal "Default Window Settings" -string "Basic"
    defaults write com.apple.Terminal "Startup Window Settings" -string "Basic"

    ok "Terminal-Profil auf 'Basic' zurückgesetzt"
    echo ""
    echo "Hinweis: Änderungen werden nach Terminal-Neustart wirksam."
}

# ------------------------------------------------------------
# Brewfile-Pakete interaktiv entfernen
# ------------------------------------------------------------
cleanup_brew_packages() {
    local skip_confirm="$1"
    local dry_run="$2"
    local brewfile="${DOTFILES_DIR}/setup/Brewfile"
    local response

    if ! command -v brew >/dev/null 2>&1; then
        warn "Homebrew nicht gefunden – Paketentfernung übersprungen"
        return 0
    fi

    if [[ ! -f "$brewfile" ]]; then
        warn "Brewfile nicht gefunden: $brewfile"
        return 0
    fi

    section "Homebrew-Pakete"
    echo ""

    # --- Formulae ---
    local brews
    brews=$(brew bundle list --brews --file="$brewfile" 2>/dev/null) || true
    if [[ -n "$brews" ]]; then
        # Nur tatsächlich installierte Formulae anzeigen
        local installed_brews
        installed_brews=$(brew list --formula 2>/dev/null) || true
        local to_remove=()
        while IFS= read -r pkg; do
            [[ -z "$pkg" ]] && continue
            if echo "$installed_brews" | grep -qxF "$pkg" 2>/dev/null; then
                to_remove+=("$pkg")
            fi
        done <<< "$brews"

        if (( ${#to_remove[@]} > 0 )); then
            echo "Formulae aus Brewfile (${#to_remove[@]} installiert):"
            for pkg in "${to_remove[@]}"; do
                echo "  • $pkg"
            done
            echo ""

            if [[ "$dry_run" == "true" ]]; then
                dim "[Dry-Run] Würde ${#to_remove[@]} Formulae entfernen"
            else
                local do_remove=true
                if [[ "$skip_confirm" != "true" ]]; then
                    echo -n "Diese ${#to_remove[@]} Formulae entfernen? [y/N] "
                    read -r response
                    [[ ! "$response" =~ ^[Yy]$ ]] && do_remove=false
                fi
                if [[ "$do_remove" == "true" ]]; then
                    for pkg in "${to_remove[@]}"; do
                        if brew uninstall "$pkg" 2>/dev/null; then
                            ok "Entfernt: $pkg"
                        else
                            warn "Konnte nicht entfernen (Abhängigkeit?): $pkg"
                        fi
                    done
                else
                    dim "Formulae-Entfernung übersprungen"
                fi
            fi
            echo ""
        fi
    fi

    # --- Casks ---
    local casks
    casks=$(brew bundle list --casks --file="$brewfile" 2>/dev/null) || true
    if [[ -n "$casks" ]]; then
        local installed_casks
        installed_casks=$(brew list --cask 2>/dev/null) || true
        local to_remove_casks=()
        while IFS= read -r pkg; do
            [[ -z "$pkg" ]] && continue
            if echo "$installed_casks" | grep -qxF "$pkg" 2>/dev/null; then
                to_remove_casks+=("$pkg")
            fi
        done <<< "$casks"

        if (( ${#to_remove_casks[@]} > 0 )); then
            echo "Casks aus Brewfile (${#to_remove_casks[@]} installiert):"
            for pkg in "${to_remove_casks[@]}"; do
                echo "  • $pkg"
            done
            echo ""
            echo "${C_YELLOW}Hinweis:${C_RESET} Casks wie VS Code oder Kitty haben eigene Einstellungen,"
            echo "die bei der Deinstallation verloren gehen können."
            echo ""

            if [[ "$dry_run" == "true" ]]; then
                dim "[Dry-Run] Würde ${#to_remove_casks[@]} Casks entfernen"
            else
                local do_remove=true
                if [[ "$skip_confirm" != "true" ]]; then
                    echo -n "Diese ${#to_remove_casks[@]} Casks entfernen? [y/N] "
                    read -r response
                    [[ ! "$response" =~ ^[Yy]$ ]] && do_remove=false
                fi
                if [[ "$do_remove" == "true" ]]; then
                    for pkg in "${to_remove_casks[@]}"; do
                        if brew uninstall --cask "$pkg" 2>/dev/null; then
                            ok "Entfernt: $pkg"
                        else
                            warn "Konnte nicht entfernen: $pkg"
                        fi
                    done
                else
                    dim "Cask-Entfernung übersprungen"
                fi
            fi
            echo ""
        fi
    fi

    # --- Mac App Store ---
    if command -v mas >/dev/null 2>&1; then
        local mas_apps
        mas_apps=$(brew bundle list --mas --file="$brewfile" 2>/dev/null) || true
        if [[ -n "$mas_apps" ]]; then
            local installed_mas
            installed_mas=$(mas list 2>/dev/null) || true
            local to_remove_mas=()
            local to_remove_mas_ids=()
            local app_name_entry app_id
            while IFS= read -r app_name_entry; do
                [[ -z "$app_name_entry" ]] && continue
                # mas list Format: " 409183694  Keynote         (14.5)"
                # Suche App-Name in mas list und extrahiere ID
                app_id=$(echo "$installed_mas" | awk -v name="$app_name_entry" 'index($0, name) {gsub(/^[[:space:]]+/, ""); print $1; exit}') || true
                if [[ -n "$app_id" ]]; then
                    to_remove_mas+=("$app_name_entry (ID: $app_id)")
                    to_remove_mas_ids+=("$app_id")
                fi
            done <<< "$mas_apps"

            if (( ${#to_remove_mas[@]} > 0 )); then
                echo "Mac App Store Apps aus Brewfile (${#to_remove_mas[@]} installiert):"
                for app in "${to_remove_mas[@]}"; do
                    echo "  • $app"
                done
                echo ""
                echo "${C_YELLOW}Hinweis:${C_RESET} MAS-Apps sind in der Regel unabhängig von den dotfiles."
                echo ""

                if [[ "$dry_run" == "true" ]]; then
                    dim "[Dry-Run] Würde ${#to_remove_mas[@]} MAS-Apps entfernen"
                else
                    local do_remove=true
                    if [[ "$skip_confirm" != "true" ]]; then
                        echo -n "Diese ${#to_remove_mas[@]} MAS-Apps entfernen? [y/N] "
                        read -r response
                        [[ ! "$response" =~ ^[Yy]$ ]] && do_remove=false
                    fi
                    if [[ "$do_remove" == "true" ]]; then
                        for app_id in "${to_remove_mas_ids[@]}"; do
                            if mas uninstall "$app_id" 2>/dev/null; then
                                ok "Entfernt: App ID $app_id"
                            else
                                warn "Konnte nicht entfernen: App ID $app_id"
                            fi
                        done
                    else
                        dim "MAS-Entfernung übersprungen"
                    fi
                fi
                echo ""
            fi
        fi
    fi

    # --- Taps ---
    local taps
    taps=$(brew bundle list --taps --file="$brewfile" 2>/dev/null) || true
    if [[ -n "$taps" ]]; then
        local installed_taps
        installed_taps=$(brew tap 2>/dev/null) || true
        local to_remove_taps=()
        while IFS= read -r tap; do
            [[ -z "$tap" ]] && continue
            if echo "$installed_taps" | grep -qxF "$tap" 2>/dev/null; then
                to_remove_taps+=("$tap")
            fi
        done <<< "$taps"

        if (( ${#to_remove_taps[@]} > 0 )); then
            echo "Taps aus Brewfile (${#to_remove_taps[@]} installiert):"
            for tap in "${to_remove_taps[@]}"; do
                echo "  • $tap"
            done
            echo ""

            if [[ "$dry_run" == "true" ]]; then
                dim "[Dry-Run] Würde ${#to_remove_taps[@]} Taps entfernen"
            else
                local do_remove=true
                if [[ "$skip_confirm" != "true" ]]; then
                    echo -n "Diese ${#to_remove_taps[@]} Taps entfernen? [y/N] "
                    read -r response
                    [[ ! "$response" =~ ^[Yy]$ ]] && do_remove=false
                fi
                if [[ "$do_remove" == "true" ]]; then
                    for tap in "${to_remove_taps[@]}"; do
                        if brew untap "$tap" 2>/dev/null; then
                            ok "Entfernt: $tap"
                        else
                            warn "Konnte nicht entfernen: $tap"
                        fi
                    done
                else
                    dim "Tap-Entfernung übersprungen"
                fi
            fi
            echo ""
        fi
    fi
}

# ------------------------------------------------------------
# Repository entfernen (letzte Aktion)
# ------------------------------------------------------------
cleanup_repository() {
    local skip_confirm="$1"
    local dry_run="$2"
    local response

    # Sicherheitscheck: DOTFILES_DIR muss gesetzt und nicht root sein
    if [[ -z "$DOTFILES_DIR" || "$DOTFILES_DIR" == "/" ]]; then
        err "DOTFILES_DIR ist ungültig – Abbruch"
        return 1
    fi

    section "Repository entfernen"
    echo ""
    echo "Verzeichnis: $DOTFILES_DIR"
    echo ""

    if [[ "$dry_run" == "true" ]]; then
        dim "[Dry-Run] Würde $DOTFILES_DIR entfernen"
        return 0
    fi

    if [[ "$skip_confirm" != "true" ]]; then
        echo "${C_YELLOW}WARNUNG:${C_RESET} Dies löscht das gesamte dotfiles-Repository unwiderruflich!"
        echo -n "Repository entfernen? [y/N] "
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            dim "Repository-Entfernung übersprungen"
            return 0
        fi
    fi

    /bin/rm -rf "$DOTFILES_DIR"
    ok "Repository entfernt: $DOTFILES_DIR"
}

# ------------------------------------------------------------
# Hauptfunktion
# ------------------------------------------------------------
main() {
    local skip_confirm=false
    local do_cleanup=false
    local dry_run=false
    local response

    # Argumente parsen
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --yes|-y)
                skip_confirm=true
                shift
                ;;
            --cleanup|-c)
                do_cleanup=true
                shift
                ;;
            --dry-run|-n)
                dry_run=true
                shift
                ;;
            --help|-h)
                echo "Verwendung: ./setup/restore.sh [Optionen]"
                echo ""
                echo "Stellt den Zustand vor der dotfiles-Installation wieder her."
                echo ""
                echo "Optionen:"
                echo "  --yes, -y      Keine Bestätigung erforderlich"
                echo "  --cleanup, -c  Erweiterte Deinstallation:"
                echo "                   1. Wiederherstellung (Symlinks + Backup)"
                echo "                   2. Homebrew-Pakete entfernen (interaktiv)"
                echo "                   3. Repository entfernen"
                echo "  --dry-run, -n  Zeigt was --cleanup tun würde (keine Aktion)"
                echo "                 Nur zusammen mit --cleanup verwendbar"
                echo "  --help, -h     Diese Hilfe anzeigen"
                return 0
                ;;
            *)
                err "Unbekannte Option: $1"
                return 1
                ;;
        esac
    done

    # --dry-run nur mit --cleanup gültig
    if [[ "$dry_run" == "true" && "$do_cleanup" != "true" ]]; then
        err "--dry-run ist nur zusammen mit --cleanup verwendbar"
        echo "Verwendung: ./setup/restore.sh --cleanup --dry-run"
        return 1
    fi

    echo ""
    if [[ "$do_cleanup" == "true" ]]; then
        echo "╔════════════════════════════════════════════════════════════╗"
        echo "║          DOTFILES VOLLSTÄNDIGE DEINSTALLATION              ║"
        echo "╚════════════════════════════════════════════════════════════╝"
    else
        echo "╔════════════════════════════════════════════════════════════╗"
        echo "║          DOTFILES WIEDERHERSTELLUNG                        ║"
        echo "╚════════════════════════════════════════════════════════════╝"
    fi
    echo ""

    if [[ "$dry_run" == "true" ]]; then
        echo "${C_YELLOW}[DRY-RUN]${C_RESET} Keine Aktionen – nur Vorschau"
        echo ""
    fi

    # Prüfen ob Backup existiert (vor jq-Guard, da kein jq benötigt)
    local has_backup=true
    if ! check_backup_exists; then
        if [[ "$do_cleanup" == "true" ]]; then
            warn "Kein Backup vorhanden – Wiederherstellung übersprungen"
            echo ""
            has_backup=false
        else
            return 1
        fi
    fi

    if [[ "$has_backup" == "true" ]]; then

    # jq-Abhängigkeit prüfen (nach --help und check_backup_exists)
    if ! command -v jq >/dev/null 2>&1; then
        err "jq ist nicht installiert – wird zum Lesen des Manifests benötigt"
        err "Installation: brew install jq"
        return 1
    fi

    # Backup-Info anzeigen
    local created count
    if ! created=$(jq -r '.created' "$BACKUP_MANIFEST" 2>/dev/null); then
        err "Backup-Manifest ist ungültig oder beschädigt: $BACKUP_MANIFEST"
        return 1
    fi
    if [[ -z "$created" || "$created" == "null" ]]; then
        err "Backup-Manifest ist ungültig: Feld .created fehlt oder ist leer"
        return 1
    fi
    count=$(get_manifest_count)

    echo "Backup gefunden:"
    echo "  Erstellt:  $created"
    echo "  Einträge:  $count"
    echo ""

    # Dry-Run: Nur Übersicht, keine Aktion
    if [[ "$dry_run" == "true" ]]; then
        dim "[Dry-Run] Würde $count Einträge wiederherstellen"
        echo ""
    else

    # Bestätigung
    if [[ "$skip_confirm" != "true" ]]; then
        echo "${C_YELLOW}WARNUNG:${C_RESET} Diese Aktion macht Folgendes:"
        echo "  • Entfernt alle dotfiles-Symlinks"
        echo "  • Stellt gesicherte Originaldateien wieder her"
        echo "  • Setzt Terminal-Profil auf 'Basic' zurück"
        echo ""
        echo -n "Fortfahren? [y/N] "
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            echo "Abgebrochen."
            return 0
        fi
        echo ""
    fi

    log "Starte Wiederherstellung..."
    echo ""

    # Zähler
    local removed=0 restored=0 skipped=0

    # Alle Einträge aus Manifest verarbeiten (via jq)
    local entries
    if ! entries=$(jq -c '.files[]' "$BACKUP_MANIFEST" 2>/dev/null); then
        err "Konnte Manifest nicht parsen – fehlt das 'files'-Array?"
        err "Datei: $BACKUP_MANIFEST"
        return 1
    fi

    local current_target current_backup current_type current_symlink current_permissions
    local fields

    while IFS= read -r entry; do
        [[ -z "$entry" ]] && continue

        # Alle Felder in einem jq-Aufruf extrahieren (Tab-separiert)
        if ! fields=$(jq -r '[.target, (.backup // "null"), .type, (.symlinkTarget // "null"), (.permissions // "null")] | @tsv' <<< "$entry" 2>/dev/null); then
            warn "Überspringe fehlerhaften Manifest-Eintrag"
            (( skipped++ )) || true
            continue
        fi

        IFS=$'\t' read -r current_target current_backup current_type current_symlink current_permissions <<< "$fields"

        [[ -z "$current_target" || "$current_target" == "null" ]] && continue

        if [[ "$current_type" == "dotfiles_symlink" ]]; then
            # Entferne nur unseren eigenen Symlink (der noch ins Dotfiles-Repo zeigt)
            if [[ -L "$current_target" ]]; then
                if is_dotfiles_symlink "$current_target"; then
                    if /bin/rm "$current_target" 2>/dev/null; then
                        log "Entfernt: $current_target"
                        (( removed++ )) || true
                    else
                        warn "Konnte Symlink nicht entfernen: $current_target"
                        (( skipped++ )) || true
                    fi
                else
                    # Fremder Symlink – nicht löschen
                    (( skipped++ )) || true
                fi
            fi
        elif [[ "$current_type" != "none" ]]; then
            # Wiederherstellen wenn:
            # 1. Ziel ist noch unser Symlink → entfernen und Original wiederherstellen
            # 2. Ziel existiert nicht mehr → User hat manuell gelöscht → Original wiederherstellen
            # 3. Ziel existiert aber ist kein dotfiles-Symlink → überspringen (User hat geändert)
            if [[ -L "$current_target" ]] && is_dotfiles_symlink "$current_target"; then
                # Fall 1: Unser Symlink existiert noch → restore_single_file entfernt und stellt her
                if restore_single_file "$current_target" "$current_backup" "$current_type" "$current_symlink" "$current_permissions"; then
                    (( restored++ )) || true
                else
                    (( skipped++ )) || true
                fi
            elif [[ ! -e "$current_target" ]] && [[ ! -L "$current_target" ]]; then
                # Fall 2: Ziel existiert nicht mehr (manuell gelöscht)
                if restore_single_file "$current_target" "$current_backup" "$current_type" "$current_symlink" "$current_permissions"; then
                    (( restored++ )) || true
                else
                    (( skipped++ )) || true
                fi
            else
                # Fall 3: Existiert aber kein dotfiles-Symlink
                (( skipped++ )) || true
            fi
        fi
    done <<< "$entries"

    echo ""
    ok "Wiederherstellung abgeschlossen"
    echo "  Symlinks entfernt:  $removed"
    echo "  Wiederhergestellt:  $restored"
    echo "  Übersprungen:       $skipped"
    echo ""

    # Terminal-Profil zurücksetzen
    reset_terminal_profile

    echo ""
    echo "Fertig! Die dotfiles wurden deinstalliert."
    echo ""
    echo "Das Backup bleibt erhalten unter: ${BACKUP_DIR#${DOTFILES_DIR}/}"
    echo "Um es zu löschen: rm -rf \"$BACKUP_DIR\""

    fi  # dry_run else

    fi  # has_backup

    # Cleanup-Phase (nur mit --cleanup)
    if [[ "$do_cleanup" == "true" ]]; then
        echo ""
        cleanup_brew_packages "$skip_confirm" "$dry_run"
        cleanup_repository "$skip_confirm" "$dry_run"
    fi
}

# Skript ausführen
main "$@"
