#!/usr/bin/env zsh
# ============================================================
# backup.sh - Backup-System für sichere dotfiles-Installation
# ============================================================
# Zweck       : Sichert existierende Dateien vor Überschreibung
# Pfad        : setup/modules/backup.sh
# Benötigt    : _core.sh
#
# STEP        : Backup | Sichert existierende Konfigurationen | 🔒 Sicher
#
# Das Backup-System:
# - Erstellt beim ERSTEN Mal ein Backup aller zu überschreibenden Dateien
# - Speichert Metadaten in einem JSON-Manifest
# - Ist idempotent: Erstes Backup wird nie überschrieben
# - Ermöglicht vollständige Wiederherstellung via restore.sh
# ============================================================

# Guard: Core muss geladen sein
[[ -z "${_BOOTSTRAP_CORE_LOADED:-}" ]] && {
    echo "FEHLER: _core.sh muss vor backup.sh geladen werden" >&2
    return 1
}

# ------------------------------------------------------------
# Konfiguration
# ------------------------------------------------------------
readonly BACKUP_DIR="${DOTFILES_DIR}/.backup"
readonly BACKUP_MANIFEST="${BACKUP_DIR}/manifest.json"
readonly BACKUP_LOG="${BACKUP_DIR}/backup.log"
readonly BACKUP_HOME="${BACKUP_DIR}/home"

# ------------------------------------------------------------
# Logging (in Datei und stdout)
# ------------------------------------------------------------
_backup_log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $*"
    echo "$msg" >> "$BACKUP_LOG"
}

# ------------------------------------------------------------
# Hilfsfunktionen
# ------------------------------------------------------------

# Ermittelt Stow-Packages dynamisch aus Verzeichnisstruktur
# Ein Package ist ein Verzeichnis mit mindestens einer Datei die mit . beginnt
# oder ein .config Unterverzeichnis hat
_get_stow_packages() {
    local dir
    for dir in "${DOTFILES_DIR}"/*/; do
        [[ -d "$dir" ]] || continue
        local name="${dir%/}"
        name="${name##*/}"

        # Überspringe bekannte Nicht-Packages
        [[ "$name" == "setup" ]] && continue
        [[ "$name" == "docs" ]] && continue
        [[ "$name" == ".git" ]] && continue
        [[ "$name" == ".backup" ]] && continue
        [[ "$name" == ".github" ]] && continue

        # Prüfe ob es Dotfiles oder .config enthält
        if [[ -n "$(find "$dir" -maxdepth 1 -name '.*' -not -name '.DS_Store' -type f 2>/dev/null | head -1)" ]] ||
           [[ -d "${dir}.config" ]]; then
            echo "$name"
        fi
    done
}

# Ermittelt alle Zieldateien die von Stow verlinkt würden
# Gibt pro Zeile aus: <source>|<target>
_get_stow_targets() {
    local pkg source_file target_file

    while IFS= read -r pkg; do
        local pkg_dir="${DOTFILES_DIR}/${pkg}"
        [[ -d "$pkg_dir" ]] || continue

        # Finde alle Dateien im Package (keine Verzeichnisse, keine .DS_Store)
        find "$pkg_dir" -type f -not -name '.DS_Store' 2>/dev/null | while read -r source_file; do
            # Entferne Package-Prefix um Ziel zu berechnen
            # terminal/.zshrc -> .zshrc
            # terminal/.config/foo/bar -> .config/foo/bar
            local relative="${source_file#${pkg_dir}/}"
            target_file="${HOME}/${relative}"
            echo "${source_file}|${target_file}"
        done
    done < <(_get_stow_packages)
}

# Ermittelt den Typ einer Datei
# Rückgabe: file|symlink|directory|broken_symlink|none
_get_file_type() {
    local filepath="$1"

    if [[ ! -e "$filepath" && ! -L "$filepath" ]]; then
        echo "none"
    elif [[ -L "$filepath" ]]; then
        if [[ -e "$filepath" ]]; then
            echo "symlink"
        else
            echo "broken_symlink"
        fi
    elif [[ -d "$filepath" ]]; then
        echo "directory"
    elif [[ -f "$filepath" ]]; then
        echo "file"
    else
        echo "unknown"
    fi
}

# Prüft ob ein Symlink ins dotfiles-Repo zeigt
_is_dotfiles_symlink() {
    local filepath="$1"
    [[ -L "$filepath" ]] || return 1

    local target resolved_target
    target=$(/usr/bin/readlink "$filepath" 2>/dev/null) || return 1

    # Variante 1: Absoluter Pfad direkt ins dotfiles-Repo
    [[ "$target" == "${DOTFILES_DIR}/"* ]] && return 0

    # Variante 2: Relativer Pfad mit "dotfiles" im Namen
    [[ "$target" == *"dotfiles/"* ]] && return 0

    # Variante 3: Auflösen und prüfen (ZSH :A modifier = realpath)
    # :A = absolute path with symlinks resolved
    resolved_target="${filepath:A}"
    [[ "$resolved_target" == "${DOTFILES_DIR}/"* ]] && return 0

    return 1
}

# Holt Permissions einer Datei (macOS + Linux kompatibel)
# HINWEIS: Variable heißt "filepath" statt "path", weil ZSH $path
# als Spezialvariable (tied to $PATH) reserviert hat.
_get_permissions() {
    local filepath="$1"
    if is_macos; then
        stat -f "%OLp" "$filepath" 2>/dev/null || echo "644"
    else
        stat -c "%a" "$filepath" 2>/dev/null || echo "644"
    fi
}

# System-Default-Pfad für bekannte Dateien
_get_system_default() {
    local target="$1"

    case "$target" in
        */.zshrc|*/.zprofile|*/.zshenv|*/.zlogin)
            echo "/etc/zshrc"
            ;;
        *)
            echo ""
            ;;
    esac
}

# ------------------------------------------------------------
# Backup einer einzelnen Datei
# ------------------------------------------------------------
# Rückgabe via stdout: JSON-Objekt für Manifest
_backup_single_file() {
    local source="$1"
    local target="$2"

    local file_type existed symlink_target permissions backup_path system_default
    file_type=$(_get_file_type "$target")
    existed="false"
    symlink_target=""
    permissions=""
    backup_path=""
    system_default=$(_get_system_default "$target")

    case "$file_type" in
        none)
            # Datei existiert nicht - nichts zu sichern
            existed="false"
            _backup_log "SKIP: $target (existiert nicht)"
            ;;

        symlink)
            existed="true"
            symlink_target=$(/usr/bin/readlink "$target" 2>/dev/null)

            if _is_dotfiles_symlink "$target"; then
                # Bereits ein dotfiles-Symlink - überspringen
                _backup_log "SKIP: $target (bereits dotfiles-Symlink)"
                file_type="dotfiles_symlink"
            else
                # Fremder Symlink - Ziel speichern und warnen
                warn "$target ist Symlink auf fremdes Ziel: $symlink_target"
                _backup_log "WARN: $target ist fremder Symlink -> $symlink_target"
                # Kein Datei-Backup nötig, nur Symlink-Ziel merken
            fi
            ;;

        broken_symlink)
            existed="true"
            symlink_target=$(/usr/bin/readlink "$target" 2>/dev/null)
            warn "$target ist defekter Symlink (Ziel existiert nicht)"
            _backup_log "WARN: $target ist defekter Symlink -> $symlink_target"
            ;;

        file)
            existed="true"
            permissions=$(_get_permissions "$target")

            # Backup-Pfad berechnen (spiegelt ~-Struktur)
            local relative="${target#${HOME}/}"
            backup_path="${BACKUP_HOME}/${relative}"

            # Verzeichnis erstellen
            mkdir -p "$(dirname "$backup_path")"

            # Datei kopieren (mit Permissions)
            if cp -p "$target" "$backup_path" 2>/dev/null; then
                _backup_log "BACKUP: $target -> $backup_path"
            else
                _backup_log "ERROR: Konnte $target nicht sichern"
                backup_path=""
            fi
            ;;

        directory)
            existed="true"
            # Verzeichnis mit eigenen Dateien - rekursiv sichern
            local relative="${target#${HOME}/}"
            backup_path="${BACKUP_HOME}/${relative}"

            # Parent-Verzeichnis für Backup anlegen
            mkdir -p "$(dirname "$backup_path")"

            if cp -Rp "$target" "$(dirname "$backup_path")/" 2>/dev/null; then
                _backup_log "BACKUP: $target (Verzeichnis) -> $backup_path"
            else
                _backup_log "ERROR: Konnte Verzeichnis $target nicht sichern"
                backup_path=""
            fi
            ;;
    esac

    # JSON-Objekt via jq ausgeben (sicheres Escaping aller Werte)
    local -a jq_args=(
        --arg source "${source#${DOTFILES_DIR}/}"
        --arg target "$target"
        --arg type "$file_type"
        --argjson existed "$existed"
    )

    if [[ -n "$backup_path" ]]; then
        jq_args+=(--arg backup "${backup_path#${DOTFILES_DIR}/}")
    else
        jq_args+=(--argjson backup "null")
    fi

    if [[ -n "$symlink_target" ]]; then
        jq_args+=(--arg symlinkTarget "$symlink_target")
    else
        jq_args+=(--argjson symlinkTarget "null")
    fi

    if [[ -n "$permissions" ]]; then
        jq_args+=(--arg permissions "$permissions")
    else
        jq_args+=(--argjson permissions "null")
    fi

    if [[ -n "$system_default" ]]; then
        jq_args+=(--arg systemDefault "$system_default")
    else
        jq_args+=(--argjson systemDefault "null")
    fi

    jq -n "${jq_args[@]}" '{
        source: $source,
        target: $target,
        backup: $backup,
        type: $type,
        existed: $existed,
        symlinkTarget: $symlinkTarget,
        permissions: $permissions,
        systemDefault: $systemDefault
    }'
}

# ------------------------------------------------------------
# Manifest erstellen
# ------------------------------------------------------------
_create_manifest() {
    local hostname username commit timestamp

    hostname=$(hostname -s 2>/dev/null || echo "unknown")
    username=$(whoami 2>/dev/null || echo "unknown")
    commit=$(cd "$DOTFILES_DIR" && git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

    # Datei-Einträge sammeln (ein JSON-Objekt pro Datei)
    local entries=""
    local source target

    while IFS='|' read -r source target; do
        entries+=$(_backup_single_file "$source" "$target")
    done < <(_get_stow_targets)

    # Manifest aus Header-Metadaten und Datei-Einträgen zusammenbauen
    echo "$entries" | jq -s \
        --argjson version 1 \
        --arg created "$timestamp" \
        --arg hostname "$hostname" \
        --arg username "$username" \
        --arg commit "$commit" \
        '{
            version: $version,
            created: $created,
            hostname: $hostname,
            username: $username,
            dotfiles_commit: $commit,
            files: .
        }' > "$BACKUP_MANIFEST"
}

# ------------------------------------------------------------
# Hauptfunktion: Backup erstellen (falls noch nicht vorhanden)
# ------------------------------------------------------------
backup_create_if_needed() {
    CURRENT_STEP="Backup erstellen"

    # Prüfe ob Backup bereits existiert (Idempotenz!)
    if [[ -f "$BACKUP_MANIFEST" ]]; then
        local created
        created=$(jq -r '.created' "$BACKUP_MANIFEST")
        skip "Backup existiert bereits (erstellt: $created)"
        _backup_log "SKIP: Backup existiert bereits"
        return 0
    fi

    log "Erstelle Backup vor Installation..."

    # Backup-Verzeichnis erstellen
    if ! ensure_dir_writable "$BACKUP_DIR" "Backup-Verzeichnis"; then
        err "Kann Backup-Verzeichnis nicht erstellen"
        return 1
    fi

    # Log initialisieren
    echo "# Backup-Log für dotfiles" > "$BACKUP_LOG"
    echo "# Erstellt: $(date)" >> "$BACKUP_LOG"
    echo "" >> "$BACKUP_LOG"
    _backup_log "START: Backup wird erstellt"

    # Zähle zu sichernde Dateien
    # Process Substitution statt Pipe, damit Zähler nicht in Subshell verloren gehen
    local total_files=0 existing_files=0
    local source target file_type

    while IFS='|' read -r source target; do
        (( total_files++ )) || true
        file_type=$(_get_file_type "$target")
        if [[ "$file_type" != "none" ]]; then
            (( existing_files++ )) || true
        fi
    done < <(_get_stow_targets)

    log "Analysiere $total_files Dateien..."

    # Manifest erstellen (inkl. Backups)
    _create_manifest

    _backup_log "END: Backup abgeschlossen"

    # Zusammenfassung
    local backed_up
    backed_up=$(find "$BACKUP_HOME" -type f 2>/dev/null | wc -l | tr -d ' ' || echo "0")
    ok "Backup erstellt: $backed_up Dateien gesichert"
    section_end "Manifest: ${BACKUP_MANIFEST#${DOTFILES_DIR}/}"

    return 0
}

# ------------------------------------------------------------
# Prüft ob ein Backup existiert
# ------------------------------------------------------------
backup_exists() {
    [[ -f "$BACKUP_MANIFEST" ]]
}

# ------------------------------------------------------------
# Gibt Backup-Info aus
# ------------------------------------------------------------
backup_info() {
    if ! backup_exists; then
        warn "Kein Backup vorhanden"
        return 1
    fi

    local created files_count
    created=$(jq -r '.created' "$BACKUP_MANIFEST")
    files_count=$(jq '.files | length' "$BACKUP_MANIFEST")

    log "Backup-Info:"
    echo "  Erstellt:     $created"
    echo "  Dateien:      $files_count"
    echo "  Speicherort:  ${BACKUP_DIR#${DOTFILES_DIR}/}"
}

# ------------------------------------------------------------
# Hauptfunktion für Modul-System
# ------------------------------------------------------------
setup_backup() {
    CURRENT_STEP="Backup Setup"
    backup_create_if_needed
}
