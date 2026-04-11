#!/usr/bin/env zsh
# ============================================================
# ssh-keys.sh - Interaktiver SSH-Key Assistent
# ============================================================
# Zweck       : Generiert SSH-Keys, konfiguriert Git-Signing und SSH-Hosts
# Pfad        : setup/modules/ssh-keys.sh
# Benötigt    : _core.sh
# Nutzt       : ssh-keygen, gh, git
#
# STEP        : SSH-Keys | Interaktiver Assistent für SSH & Git-Signing | ⏭ Optional
# Hinweis     : Wird NACH dem Bootstrap-Banner aufgerufen, nicht als reguläres Modul.
#               Gesamter Ablauf ist optional und interaktiv.
# ============================================================

# Standalone: Core laden bevor Guard greift
if [[ "${ZSH_EVAL_CONTEXT}" == "toplevel" ]]; then
    source "${0:A:h}/_core.sh" || { echo "FEHLER: _core.sh nicht gefunden" >&2; exit 1; }
fi

# Guard: Core muss geladen sein (fängt source ohne Core ab)
[[ -z "${_BOOTSTRAP_CORE_LOADED:-}" ]] && {
    echo "FEHLER: _core.sh muss vor ssh-keys.sh geladen werden" >&2
    return 1
}

# ------------------------------------------------------------
# Konfiguration
# ------------------------------------------------------------
typeset -g _SSH_DIR="$HOME/.ssh"
typeset -g _SSH_KEY="$_SSH_DIR/id_ed25519"
typeset -g _SSH_KEY_PUB="$_SSH_DIR/id_ed25519.pub"
typeset -g _SSH_CONFIG="$_SSH_DIR/config"
typeset -g _ALLOWED_SIGNERS="$_SSH_DIR/allowed_signers"

# ------------------------------------------------------------
# Helper: Ja/Nein-Abfrage (set -e sicher)
# ------------------------------------------------------------
# read -r gibt immer Exit 0 zurück (solange stdin offen).
# read -q würde Exit 1 bei "Nein" geben → set -e Crash.
_ask_yes_no() {
    local prompt="$1"
    local answer
    # Prompt auf /dev/tty statt stdout – sonst ist er bei Umleitung unsichtbar
    print -rn -- "${C_MAUVE}?${C_RESET} ${prompt} [j/N] " >/dev/tty
    if ! read -r answer; then
        # EOF (Ctrl-D) → wie "Nein" behandeln
        print -r -- "" >/dev/tty
        return 1
    fi
    [[ "$answer" == [jJ] ]]
}

# ------------------------------------------------------------
# Helper: Eingabe mit optionalem Vorschlag
# ------------------------------------------------------------
_ask_input() {
    local prompt="$1"
    local default="${2:-}"
    local answer

    # Prompt auf /dev/tty statt stdout – sonst fängt $() den Prompt ab
    if [[ -n "$default" ]]; then
        print -rn -- "${C_MAUVE}?${C_RESET} ${prompt} ${C_DIM}[$default]${C_RESET} " >/dev/tty
    else
        print -rn -- "${C_MAUVE}?${C_RESET} ${prompt} " >/dev/tty
    fi
    if ! read -r answer; then
        # EOF (Ctrl-D) → Default zurückgeben
        print -r -- "" >/dev/tty
        print -r -- "$default"
        return 0
    fi
    print -r -- "${answer:-$default}"
}

# ------------------------------------------------------------
# SSH-Key generieren
# ------------------------------------------------------------
_generate_ssh_key() {
    section "SSH-Key Generierung"

    # Prüfe ob Key bereits existiert
    if [[ -f "$_SSH_KEY" ]]; then
        ok "SSH-Key bereits vorhanden: $_SSH_KEY"
        log "Fingerprint: $(ssh-keygen -l -f "$_SSH_KEY" 2>/dev/null || echo "unbekannt")"

        if ! _ask_yes_no "Bestehenden Key verwenden?"; then
            warn "Abgebrochen – bestehender Key bleibt unverändert"
            return 1
        fi
        return 0
    fi

    # E-Mail für Key-Kommentar abfragen
    local email
    email=$(_ask_input "E-Mail-Adresse für den SSH-Key:")

    if [[ -z "$email" ]]; then
        warn "Keine E-Mail angegeben – Key-Generierung übersprungen"
        return 1
    fi

    # Verzeichnis sicherstellen
    if [[ ! -d "$_SSH_DIR" ]]; then
        if [[ -e "$_SSH_DIR" ]]; then
            err "Pfad existiert bereits, ist aber kein Verzeichnis: $_SSH_DIR"
            return 1
        fi
        mkdir -m 700 "$_SSH_DIR"
        ok "Verzeichnis erstellt: $_SSH_DIR"
    fi

    # Key generieren (interaktiv: Passphrase wird von ssh-keygen abgefragt)
    log "Generiere Ed25519 SSH-Key..."
    if ssh-keygen -t ed25519 -C "$email" -f "$_SSH_KEY"; then
        ok "SSH-Key generiert: $_SSH_KEY"
        log "Fingerprint: $(ssh-keygen -l -f "$_SSH_KEY")"
    else
        err "SSH-Key Generierung fehlgeschlagen"
        return 1
    fi

    return 0
}

# ------------------------------------------------------------
# SSH-Config: Globale Defaults schreiben
# ------------------------------------------------------------
# Stellt sicher dass Host * Block mit AddKeysToAgent und
# IdentityFile existiert. UseKeychain nur auf macOS.
_ensure_ssh_config_defaults() {
    # Verzeichnis sicherstellen
    if [[ ! -d "$_SSH_DIR" ]]; then
        mkdir -m 700 "$_SSH_DIR"
    else
        chmod 700 "$_SSH_DIR" 2>/dev/null
    fi

    # Config existiert und hat bereits Host * Block
    if [[ -f "$_SSH_CONFIG" ]] && grep -Eq '^[[:space:]]*Host[[:space:]]+\*$' "$_SSH_CONFIG" 2>/dev/null; then
        chmod 600 "$_SSH_CONFIG" 2>/dev/null
        ok "SSH-Config Defaults bereits vorhanden"
        return 0
    fi

    log "Schreibe SSH-Config Defaults..."

    if [[ -f "$_SSH_CONFIG" ]]; then
        # Bestehende Config: Defaults voranstellen
        local existing
        existing=$(<"$_SSH_CONFIG")
        {
            print -r -- "Host *"
            print -r -- "    AddKeysToAgent yes"
            is_macos && print -r -- "    UseKeychain yes"
            print -r -- "    IdentityFile \"$_SSH_KEY\""
            print -r -- ""
            print -r -- "$existing"
        } > "$_SSH_CONFIG"
    else
        {
            print -r -- "Host *"
            print -r -- "    AddKeysToAgent yes"
            is_macos && print -r -- "    UseKeychain yes"
            print -r -- "    IdentityFile \"$_SSH_KEY\""
        } > "$_SSH_CONFIG"
    fi

    chmod 600 "$_SSH_CONFIG"
    ok "SSH-Config Defaults geschrieben"
}

# ------------------------------------------------------------
# Key zu GitHub hochladen
# ------------------------------------------------------------
_upload_to_github() {
    section "GitHub Key-Upload"

    # gh verfügbar?
    if ! command -v gh >/dev/null 2>&1; then
        warn "gh CLI nicht gefunden – GitHub-Upload übersprungen"
        log "Installiere gh und führe manuell aus:"
        log "  gh ssh-key add $_SSH_KEY_PUB --title \"\$(hostname)\""
        return 0
    fi

    # Eingeloggt?
    if ! gh auth status >/dev/null 2>&1; then
        warn "Nicht bei GitHub angemeldet – Upload übersprungen"
        log "Melde dich an mit: gh auth login"
        log "Dann lade den Key hoch:"
        log "  gh ssh-key add $_SSH_KEY_PUB --title \"\$(hostname)\""
        return 0
    fi

    # Key-Fingerprint für Duplikat-Check
    local fingerprint
    fingerprint=$(ssh-keygen -l -f "$_SSH_KEY_PUB" 2>/dev/null | awk '{print $2}')

    if [[ -z "$fingerprint" ]]; then
        warn "Kann Key-Fingerprint nicht lesen – Upload übersprungen"
        return 0
    fi

    # Prüfe ob Key bereits auf GitHub registriert ist
    local existing_keys
    existing_keys=$(gh ssh-key list 2>/dev/null || echo "")

    if echo "$existing_keys" | grep -qF "$fingerprint"; then
        ok "SSH-Key bereits auf GitHub registriert"
        return 0
    fi

    local hostname
    hostname=$(hostname -s 2>/dev/null || hostname)

    # Authentication Key hochladen
    if _ask_yes_no "SSH-Key als Authentication-Key zu GitHub hochladen?"; then
        if gh ssh-key add "$_SSH_KEY_PUB" --title "$hostname"; then
            ok "Authentication-Key hochgeladen: $hostname"
        else
            warn "Upload fehlgeschlagen (Key eventuell bereits vorhanden)"
        fi
    fi

    # Signing Key hochladen
    if _ask_yes_no "SSH-Key als Signing-Key zu GitHub hochladen (für Verified-Badge)?"; then
        if gh ssh-key add "$_SSH_KEY_PUB" --title "$hostname (signing)" --type signing; then
            ok "Signing-Key hochgeladen: $hostname (signing)"
        else
            warn "Upload fehlgeschlagen (Key eventuell bereits vorhanden)"
        fi
    fi

    return 0
}

# ------------------------------------------------------------
# Git für SSH-Signing konfigurieren
# ------------------------------------------------------------
_configure_git_signing() {
    section "Git-Signatur Konfiguration"

    if ! _ask_yes_no "Git für signierte Commits konfigurieren?"; then
        log "Git-Signatur übersprungen"
        return 0
    fi

    # user.name abfragen
    local current_name
    current_name=$(git config --global user.name 2>/dev/null || echo "")
    local name
    name=$(_ask_input "Git user.name:" "$current_name")

    if [[ -z "$name" ]]; then
        warn "Kein Name angegeben – Git-Signatur übersprungen"
        return 0
    fi

    # user.email abfragen (Vorschlag: Kommentar aus SSH-Key)
    local current_email key_email
    current_email=$(git config --global user.email 2>/dev/null || echo "")
    key_email=$(ssh-keygen -l -f "$_SSH_KEY_PUB" 2>/dev/null | awk '{print $3}' || echo "")
    local email_default="${current_email:-$key_email}"
    local email
    email=$(_ask_input "Git user.email:" "$email_default")

    if [[ -z "$email" ]]; then
        warn "Keine E-Mail angegeben – Git-Signatur übersprungen"
        return 0
    fi

    # Git-Konfiguration setzen
    git config --global user.name "$name"
    git config --global user.email "$email"
    git config --global gpg.format ssh
    git config --global user.signingkey "$_SSH_KEY_PUB"
    git config --global commit.gpgsign true
    git config --global tag.gpgsign true

    ok "Git-Konfiguration gesetzt (user: $name <$email>)"
    ok "SSH-Signing aktiviert (commit + tag)"

    # allowed_signers für lokale Verifikation
    local pub_key
    pub_key=$(<"$_SSH_KEY_PUB")

    # Prüfe E-Mail+Key Kombination (nicht nur E-Mail), damit bei
    # Key-Regeneration der neue Key hinzugefügt wird (Key-Rotation)
    if [[ -f "$_ALLOWED_SIGNERS" ]] && grep -qF "$email $pub_key" "$_ALLOWED_SIGNERS" 2>/dev/null; then
        chmod 600 "$_ALLOWED_SIGNERS" 2>/dev/null
        ok "allowed_signers bereits konfiguriert"
    else
        print -r -- "$email $pub_key" >> "$_ALLOWED_SIGNERS"
        chmod 600 "$_ALLOWED_SIGNERS"
        ok "allowed_signers aktualisiert: $_ALLOWED_SIGNERS"
    fi

    git config --global gpg.ssh.allowedSignersFile "$_ALLOWED_SIGNERS"

    return 0
}

# ------------------------------------------------------------
# SSH-Hosts für Netzwerk-Rechner konfigurieren
# ------------------------------------------------------------
_configure_ssh_hosts() {
    section "SSH-Hosts Konfiguration"

    if ! _ask_yes_no "SSH-Verbindungen zu Netzwerk-Rechnern einrichten?"; then
        log "SSH-Hosts übersprungen"
        return 0
    fi

    local added=0
    local alias_name host_addr host_user host_port
    local last_alias

    while true; do
        print -r -- ""
        log "Neuen SSH-Host hinzufügen (leerer Alias = fertig)"

        alias_name=$(_ask_input "Host-Alias (z.B. homeserver):")
        [[ -z "$alias_name" ]] && break

        # Alias-Validierung: SSH interpretiert *, ?, !, [] als Pattern
        if ! validate_ssh_alias "$alias_name"; then
            continue
        fi

        host_addr=$(_ask_input "IP-Adresse oder Hostname:")
        [[ -z "$host_addr" ]] && { warn "Keine Adresse – Host übersprungen"; continue; }
        if ! validate_ssh_value "$host_addr" "Hostname/IP"; then
            continue
        fi

        host_user=$(_ask_input "Benutzername:" "$(whoami)")
        if ! validate_ssh_value "$host_user" "Benutzername"; then
            continue
        fi

        host_port=$(_ask_input "Port:" "22")

        # Port-Validierung (1–65535)
        if ! validate_port "$host_port"; then
            continue
        fi

        # Prüfe ob Host bereits in Config existiert
        if [[ -f "$_SSH_CONFIG" ]] && grep -qxF "Host $alias_name" "$_SSH_CONFIG" 2>/dev/null; then
            warn "Host '$alias_name' bereits in SSH-Config vorhanden – übersprungen"
            continue
        fi

        # Host-Eintrag anhängen
        {
            print -r -- ""
            print -r -- "Host $alias_name"
            print -r -- "    HostName $host_addr"
            print -r -- "    User $host_user"
            [[ "$host_port" != "22" ]] && print -r -- "    Port $host_port"
            print -r -- "    IdentityFile \"$_SSH_KEY\""
        } >> "$_SSH_CONFIG"

        ok "Host hinzugefügt: $alias_name → $host_user@$host_addr"
        last_alias="$alias_name"
        (( added++ )) || true

        _ask_yes_no "Weiteren Host hinzufügen?" || break
    done

    if (( added > 0 )); then
        section_end "$added Host(s) konfiguriert"
        print -r -- ""
        log "Verbindung testen: ${C_DIM}ssh $last_alias${C_RESET}"
    fi

    return 0
}

# ------------------------------------------------------------
# Hauptfunktion
# ------------------------------------------------------------
setup_ssh_keys() {
    # TTY-Guard: Ohne interaktives Terminal wird der Assistent übersprungen
    # (CI, Pipes, Headless – gibt eine Info-Meldung aus)
    if [[ ! -t 0 ]]; then
        log "Kein interaktives Terminal – SSH-Assistent übersprungen"
        return 0
    fi

    CURRENT_STEP="SSH-Keys (optional)"

    # Restriktive umask: SSH-Dateien direkt mit 600/700 erstellen
    # statt nachträglich chmod (Race Condition: CWE-362)
    local old_umask
    old_umask=$(umask)
    umask 077

    section "SSH-Key Assistent"
    log "Dieser Assistent hilft dir bei der Einrichtung von:"
    log "  • SSH-Key Generierung (Ed25519)"
    log "  • GitHub Key-Upload (Authentication + Signing)"
    log "  • Git Commit-Signatur (Verified-Badge)"
    log "  • SSH-Hosts für Netzwerk-Rechner"
    print -r -- ""

    if ! _ask_yes_no "SSH-Key Assistenten starten?"; then
        log "SSH-Assistent übersprungen"
        umask "$old_umask"
        return 0
    fi

    # 1. SSH-Key generieren (oder bestehenden verwenden)
    if ! _generate_ssh_key; then
        umask "$old_umask"
        return 0
    fi

    # 2. SSH-Config Defaults (Host *, AddKeysToAgent, UseKeychain)
    _ensure_ssh_config_defaults

    # 3. Key zu GitHub hochladen
    if [[ -f "$_SSH_KEY_PUB" ]]; then
        _upload_to_github
    fi

    # 4. Git für SSH-Signing konfigurieren
    if [[ -f "$_SSH_KEY_PUB" ]]; then
        _configure_git_signing
    fi

    # 5. SSH-Hosts für Netzwerk-Rechner (optional)
    _configure_ssh_hosts

    # Zusammenfassung
    print -r -- ""
    print -r -- "${C_GREEN}━━━ ${C_BOLD}SSH-Setup abgeschlossen${C_RESET}${C_GREEN} ━━━${C_RESET}"
    print -r -- ""
    if [[ -f "$_SSH_KEY_PUB" ]]; then
        log "Key: ${C_DIM}$_SSH_KEY${C_RESET}"
        log "Fingerprint: ${C_DIM}$(ssh-keygen -l -f "$_SSH_KEY" 2>/dev/null || echo "–")${C_RESET}"
    fi

    # umask wiederherstellen – sonst bleiben restriktive Permissions aktiv
    umask "$old_umask"

    return 0
}

# Standalone: Hauptfunktion aufrufen (Core wurde oben bereits geladen)
if [[ "${ZSH_EVAL_CONTEXT}" == "toplevel" ]]; then
    setup_ssh_keys
fi
