#!/usr/bin/env zsh
# ============================================================
# terminal-profile.sh - Terminal.app Profil-Konfiguration
# ============================================================
# Zweck       : Importiert und aktiviert Terminal-Profil
# Pfad        : setup/modules/terminal-profile.sh
# Benötigt    : _core.sh, font.sh (Font muss vorhanden sein)
#
# STEP        : Terminal-Profil | Importiert `catppuccin-mocha.terminal` als Standard | ⚠️ Warnung
# Profil      : Catppuccin Mocha (.terminal-Datei in setup/)
# ============================================================

# Guard: Core muss geladen sein
[[ -z "${_BOOTSTRAP_CORE_LOADED:-}" ]] && {
    echo "FEHLER: _core.sh muss vor terminal-profile.sh geladen werden" >&2
    return 1
}

# ------------------------------------------------------------
# Konfiguration
# ------------------------------------------------------------
# Terminal-Profil Import Timeout (Sekunden)
# Kann via PROFILE_IMPORT_TIMEOUT überschrieben werden (z.B. für langsame Systeme/VMs)
PROFILE_IMPORT_TIMEOUT_DEFAULT=20
PROFILE_IMPORT_TIMEOUT="${PROFILE_IMPORT_TIMEOUT:-$PROFILE_IMPORT_TIMEOUT_DEFAULT}"

# Validiere Timeout (muss positive Ganzzahl >= 1 sein)
if [[ ! "$PROFILE_IMPORT_TIMEOUT" =~ ^[1-9][0-9]*$ ]]; then
    warn "PROFILE_IMPORT_TIMEOUT='$PROFILE_IMPORT_TIMEOUT' ungültig, nutze Default: ${PROFILE_IMPORT_TIMEOUT_DEFAULT}s"
    PROFILE_IMPORT_TIMEOUT="$PROFILE_IMPORT_TIMEOUT_DEFAULT"
fi
readonly PROFILE_IMPORT_TIMEOUT_DEFAULT PROFILE_IMPORT_TIMEOUT

# Terminal-Profil dynamisch ermitteln (alphabetisch erste .terminal-Datei in setup/)
detect_profile_file() {
    local profile_file
    profile_file=$(find "$SCRIPT_DIR" -maxdepth 1 -name "*.terminal" -type f 2>/dev/null | sort | head -1)

    if [[ -z "$profile_file" ]]; then
        err "Keine .terminal-Datei in setup/ gefunden"
        return 1
    fi

    # Warnung wenn mehrere .terminal-Dateien existieren
    local terminal_count
    terminal_count=$(find "$SCRIPT_DIR" -maxdepth 1 -name "*.terminal" -type f 2>/dev/null | wc -l | tr -d ' ')
    if (( terminal_count > 1 )); then
        warn "Mehrere .terminal-Dateien gefunden, verwende: ${profile_file:t}"
    fi

    echo "$profile_file"
}

# ------------------------------------------------------------
# Profil-Existenz prüfen
# ------------------------------------------------------------
profile_exists() {
    local profile_name="$1"
    local profile_grep_pattern="(^[[:space:]]+\"$profile_name\"|^[[:space:]]+$profile_name)[[:space:]]+="

    local settings
    settings=$(defaults read com.apple.Terminal "Window Settings" 2>/dev/null || true)
    [[ -z "$settings" ]] && return 1
    print -r -- "$settings" | grep -qE "$profile_grep_pattern"
}

# ------------------------------------------------------------
# Profil importieren
# ------------------------------------------------------------
import_profile() {
    local profile_file="$1"
    local profile_name="$2"

    CURRENT_STEP="Terminal-Profil Import"

    # Profil-Datei prüfen
    if [[ ! -f "$profile_file" ]]; then
        err "Profil-Datei nicht gefunden: $profile_file"
        return 1
    fi

    if profile_exists "$profile_name"; then
        ok "Profil '$profile_name' bereits vorhanden"
        return 0
    fi

    log "Importiere Profil '$profile_name'"
    open "$profile_file"

    # Warte auf Registrierung im System
    local import_success=0
    for attempt in {1..$PROFILE_IMPORT_TIMEOUT}; do
        sleep 1
        if profile_exists "$profile_name"; then
            ok "Profil '$profile_name' importiert"
            import_success=1
            break
        fi
    done

    if (( import_success == 0 )); then
        warn "Profil-Import konnte nicht verifiziert werden (${PROFILE_IMPORT_TIMEOUT}s Timeout)"
    fi

    return 0
}

# ------------------------------------------------------------
# Profil als Standard setzen (AppleScript)
# ------------------------------------------------------------
# Verwendet AppleScript, da defaults write bei laufendem Terminal nicht persistiert
set_profile_as_default() {
    local profile_name="$1"

    osascript <<EOF
tell application "Terminal"
    set targetProfile to null
    repeat with s in settings sets
        if name of s is "$profile_name" then
            set targetProfile to s
            exit repeat
        end if
    end repeat

    if targetProfile is not null then
        set default settings to targetProfile
        set startup settings to targetProfile
        return "success"
    else
        return "profile not found"
    end if
end tell
EOF
}

configure_default_profile() {
    local profile_name="$1"

    CURRENT_STEP="Terminal-Profil Default"

    # Aktuelle Einstellungen prüfen
    local current_default current_startup
    current_default=$(defaults read com.apple.Terminal "Default Window Settings" 2>/dev/null || true)
    current_startup=$(defaults read com.apple.Terminal "Startup Window Settings" 2>/dev/null || true)

    if [[ "$current_default" == "$profile_name" && "$current_startup" == "$profile_name" ]]; then
        ok "Profil '$profile_name' bereits als Standard gesetzt"
        return 0
    fi

    log "Setze '$profile_name' als Standard- und Startprofil"

    local applescript_result
    applescript_result=$(set_profile_as_default "$profile_name")
    if [[ "$applescript_result" != "success" ]]; then
        warn "AppleScript konnte Profil nicht direkt setzen: $applescript_result"
    fi

    # Verifiziere die Änderung
    sleep 1
    local verify_default verify_startup
    verify_default=$(defaults read com.apple.Terminal "Default Window Settings" 2>/dev/null || true)
    verify_startup=$(defaults read com.apple.Terminal "Startup Window Settings" 2>/dev/null || true)

    if [[ "$verify_default" == "$profile_name" && "$verify_startup" == "$profile_name" ]]; then
        ok "Profil '$profile_name' als Standard gesetzt"
    else
        warn "Konnte Standardprofil nicht verifizieren"
        warn "  Default: $verify_default (erwartet: $profile_name)"
        warn "  Startup: $verify_startup (erwartet: $profile_name)"
    fi

    return 0
}

# ------------------------------------------------------------
# Haupt-Setup-Funktion
# ------------------------------------------------------------
setup_terminal_profile() {
    local profile_file profile_name

    # Profil-Datei ermitteln
    profile_file=$(detect_profile_file) || return 1

    # Profil-Name aus Dateiname extrahieren (ohne .terminal-Endung)
    profile_name="${${profile_file:t}%.terminal}"

    # Exportiere für andere Module
    export PROFILE_FILE="$profile_file"
    export PROFILE_NAME="$profile_name"

    import_profile "$profile_file" "$profile_name" || return 1
    configure_default_profile "$profile_name" || return 1

    return 0
}
