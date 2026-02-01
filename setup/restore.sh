#!/usr/bin/env zsh
# ============================================================
# restore.sh - Wiederherstellung des Original-Zustands
# ============================================================
# Zweck       : Stellt Backup wieder her und entfernt Symlinks
# Pfad        : setup/restore.sh
# Benötigt    : Ein vorhandenes Backup unter .backup/
# Aufruf      : ./setup/restore.sh [--yes]
# Optionen    : --yes  Keine Bestätigung erforderlich
#
# Diese Datei macht die dotfiles-Installation rückgängig:
# 1. Entfernt alle Symlinks die auf dotfiles zeigen
# 2. Stellt gesicherte Originaldateien wieder her
# 3. Setzt Terminal-Profil auf "Basic" zurück
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
# Farben laden
# ------------------------------------------------------------
if [[ -f "${DOTFILES_DIR}/terminal/.config/theme-style" ]]; then
    source "${DOTFILES_DIR}/terminal/.config/theme-style"
else
    # Fallback-Farben (mit echten Escape-Bytes)
    C_RED=$'\033[0;31m'
    C_GREEN=$'\033[0;32m'
    C_YELLOW=$'\033[0;33m'
    C_BLUE=$'\033[0;34m'
    C_RESET=$'\033[0m'
fi

# ------------------------------------------------------------
# Logging
# ------------------------------------------------------------
log() { echo "${C_BLUE}→${C_RESET} $*"; }
ok() { echo "${C_GREEN}✔${C_RESET} $*"; }
err() { echo "${C_RED}✖${C_RESET} $*" >&2; }
warn() { echo "${C_YELLOW}⚠${C_RESET} $*"; }

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
# Manifest parsen (JSON ohne jq)
# ------------------------------------------------------------
# Zählt die Einträge im Manifest
get_manifest_count() {
    grep -c '"source":' "$BACKUP_MANIFEST" 2>/dev/null || echo "0"
}

# ------------------------------------------------------------
# Prüft ob ein Pfad ein Symlink ins dotfiles-Repo ist
# ------------------------------------------------------------
is_dotfiles_symlink() {
    local path="$1"
    [[ -L "$path" ]] || return 1

    local target
    target=$(/usr/bin/readlink "$path" 2>/dev/null) || return 1

    # Prüfe verschiedene Varianten
    [[ "$target" == "${DOTFILES_DIR}/"* ]] && return 0
    [[ "$target" == *"dotfiles/"* ]] && return 0

    # Auflösen für relative Symlinks
    # Pfad als Argument übergeben um Code-Injection zu vermeiden
    local resolved
    resolved=$(python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' -- "$path" 2>/dev/null)
    [[ "$resolved" == "${DOTFILES_DIR}/"* ]] && return 0

    return 1
}

# ------------------------------------------------------------
# Symlink entfernen und ggf. Backup wiederherstellen
# ------------------------------------------------------------
restore_single_file() {
    local target="$1"
    local backup="$2"
    local type="$3"
    local symlink_target="$4"
    local permissions="$5"

    # Nur dotfiles-Symlinks entfernen
    if [[ -L "$target" ]] && is_dotfiles_symlink "$target"; then
        /bin/rm "$target"
        log "Entfernt: $target"
    elif [[ -L "$target" ]]; then
        warn "Übersprungen (fremder Symlink): $target"
        return 0
    elif [[ -e "$target" ]]; then
        warn "Übersprungen (keine Symlink): $target"
        return 0
    fi

    # Backup wiederherstellen wenn vorhanden
    if [[ "$backup" != "null" && -n "$backup" ]]; then
        local backup_path="${DOTFILES_DIR}/${backup}"
        if [[ -e "$backup_path" ]]; then
            # Verzeichnis erstellen falls nötig
            /bin/mkdir -p "$(dirname "$target")"

            # Datei/Verzeichnis wiederherstellen
            if [[ -d "$backup_path" ]]; then
                /bin/cp -Rp "$backup_path" "$target"
            else
                /bin/cp -p "$backup_path" "$target"
            fi

            # Permissions setzen wenn bekannt
            if [[ "$permissions" != "null" && -n "$permissions" ]]; then
                /bin/chmod "$permissions" "$target" 2>/dev/null || true
            fi

            ok "Wiederhergestellt: $target"
        else
            warn "Backup nicht gefunden: $backup_path"
        fi
    elif [[ "$type" == "symlink" && "$symlink_target" != "null" && -n "$symlink_target" ]]; then
        # Fremden Symlink wiederherstellen
        /bin/mkdir -p "$(dirname "$target")"
        /bin/ln -s "$symlink_target" "$target"
        ok "Symlink wiederhergestellt: $target -> $symlink_target"
    fi
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
# Hauptfunktion
# ------------------------------------------------------------
main() {
    local skip_confirm=false

    # Argumente parsen
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --yes|-y)
                skip_confirm=true
                shift
                ;;
            --help|-h)
                echo "Verwendung: ./setup/restore.sh [--yes]"
                echo ""
                echo "Stellt den Zustand vor der dotfiles-Installation wieder her."
                echo ""
                echo "Optionen:"
                echo "  --yes, -y    Keine Bestätigung erforderlich"
                echo "  --help, -h   Diese Hilfe anzeigen"
                return 0
                ;;
            *)
                err "Unbekannte Option: $1"
                return 1
                ;;
        esac
    done

    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║          DOTFILES RESTORE - Wiederherstellung              ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""

    # Prüfen ob Backup existiert
    if ! check_backup_exists; then
        return 1
    fi

    # Backup-Info anzeigen
    local created count
    created=$(grep '"created"' "$BACKUP_MANIFEST" | head -1 | sed 's/.*": *"//' | sed 's/".*//')
    count=$(get_manifest_count)

    echo "Backup gefunden:"
    echo "  Erstellt:  $created"
    echo "  Einträge:  $count"
    echo ""

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

    # Alle Einträge aus Manifest verarbeiten
    # Wir parsen das JSON Zeile für Zeile
    local current_target="" current_backup="" current_type="" current_symlink="" current_permissions=""

    while IFS= read -r line; do
        case "$line" in
            *'"target":'*)
                current_target=$(echo "$line" | sed 's/.*"target": *"//' | sed 's/".*//')
                ;;
            *'"backup":'*)
                current_backup=$(echo "$line" | sed 's/.*"backup": *//' | sed 's/,$//' | sed 's/"//g')
                ;;
            *'"type":'*)
                current_type=$(echo "$line" | sed 's/.*"type": *"//' | sed 's/".*//')
                ;;
            *'"symlinkTarget":'*)
                current_symlink=$(echo "$line" | sed 's/.*"symlinkTarget": *//' | sed 's/,$//' | sed 's/"//g')
                ;;
            *'"permissions":'*)
                current_permissions=$(echo "$line" | sed 's/.*"permissions": *//' | sed 's/,$//' | sed 's/"//g')
                ;;
            *'}'*)
                # Ende eines Eintrags
                if [[ -n "$current_target" ]]; then
                    # Nur verarbeiten wenn nicht dotfiles_symlink (die wurden von uns erstellt)
                    if [[ "$current_type" == "dotfiles_symlink" ]]; then
                        # Entferne unseren Symlink
                        if [[ -L "$current_target" ]]; then
                            /bin/rm "$current_target" 2>/dev/null && {
                                (( removed++ )) || true
                            }
                        fi
                    elif [[ "$current_type" != "none" ]]; then
                        # Wiederherstellen wenn:
                        # 1. Ziel ist noch unser Symlink → entfernen und Original wiederherstellen
                        # 2. Ziel existiert nicht mehr → User hat manuell gelöscht → Original wiederherstellen
                        # 3. Ziel existiert aber ist kein dotfiles-Symlink → überspringen (User hat geändert)
                        if [[ -L "$current_target" ]] && is_dotfiles_symlink "$current_target"; then
                            # Fall 1: Unser Symlink existiert noch
                            /bin/rm "$current_target" 2>/dev/null
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
                fi
                # Reset für nächsten Eintrag
                current_target=""
                current_backup=""
                current_type=""
                current_symlink=""
                current_permissions=""
                ;;
        esac
    done < "$BACKUP_MANIFEST"

    echo ""
    ok "Wiederherstellung abgeschlossen"
    echo "  Symlinks entfernt:  $removed"
    echo "  Dateien restored:   $restored"
    echo "  Übersprungen:       $skipped"
    echo ""

    # Terminal-Profil zurücksetzen
    reset_terminal_profile

    echo ""
    echo "Fertig! Die dotfiles wurden deinstalliert."
    echo ""
    echo "Das Backup bleibt erhalten unter: ${BACKUP_DIR#${DOTFILES_DIR}/}"
    echo "Um es zu löschen: rm -rf \"$BACKUP_DIR\""
}

# Skript ausführen
main "$@"
