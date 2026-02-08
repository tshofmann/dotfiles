# ============================================================
# platform.zsh - Plattform-Abstraktionen
# ============================================================
# Zweck       : Einheitliche Funktionen für macOS und Linux
# Pfad        : ~/.config/platform.zsh (nach stow)
# Geladen     : Früh in .zshrc (vor Aliase)
# ============================================================
# Funktionen:
#   clip      - Clipboard schreiben (stdin → Zwischenablage)
#   clippaste - Clipboard lesen (Zwischenablage → stdout)
#   xopen     - Datei/URL mit Standard-App öffnen
#   sedi      - In-place sed (BSD/GNU kompatibel)
# ============================================================
# Plattformen:
#   macOS     - Apple Silicon (arm64) + Intel (x86_64)
#   Fedora    - Desktop/Server
#   Debian    - Desktop/Server (inkl. Raspberry Pi OS, DietPi)
#   Arch      - Desktop/Server
# ============================================================
# Display-Systeme:
#   macOS     - Immer Display (pbcopy/pbpaste, open)
#   Wayland   - GNOME, KDE, Hyprland, labwc (wl-clipboard, xdg-open)
# ============================================================
# Headless-Systeme:
#   Ohne Display ($XDG_SESSION_TYPE != wayland, kein $WAYLAND_DISPLAY)
#   werden clip/clippaste/xopen als stille No-Ops definiert.
# ============================================================
# HINWEIS: Variablen werden beim ersten Laden gecacht und nicht
#          aktualisiert. Nach Wechsel des Display-Systems
#          (tty → Wayland): exec zsh
# ============================================================

# Verhindere mehrfaches Laden (Shell-Variable für aktuelle Shell)
[[ -n "${_PLATFORM_LOADED:-}" ]] && return 0
typeset -g _PLATFORM_LOADED=1

# ------------------------------------------------------------
# Plattform-Erkennung (einmalig beim Laden, exportiert für Subshells)
# ------------------------------------------------------------
# Exportierte Variablen ermöglichen schnelles Re-Laden in Subshells
# (z.B. fzf execute-silent) ohne erneute $OSTYPE-Checks.

if [[ -z "${_PLATFORM_OS+x}" ]]; then
    # Erstmalige Erkennung via ZSH-Builtin $OSTYPE (kein Subshell nötig)
    case "$OSTYPE" in
        darwin*) _PLATFORM_OS="macos" ;;
        linux*)  _PLATFORM_OS="linux" ;;
        *)       _PLATFORM_OS="unknown" ;;
    esac
    export _PLATFORM_OS
fi

if [[ -z "${_PLATFORM_DISTRO+x}" ]]; then
    # Linux-Distribution via /etc/os-release (freedesktop-Standard)
    # ID_LIKE behandelt Derivate (z.B. Ubuntu → debian, Manjaro → arch)
    # SYNC-CHECK: Parallele POSIX-Variante in setup/install.sh detect_platform()
    # Bei Änderung der ID-Cases hier auch install.sh anpassen.
    # Sync wird via CI validiert (validate.yml → Plattform-Sync prüfen)
    # IDs: fedora | debian|ubuntu|raspbian | arch|manjaro
    if [[ "$_PLATFORM_OS" == "linux" ]]; then
        _detect_distro() {
            local _osrelease=""
            [[ -f /etc/os-release ]] && _osrelease="/etc/os-release"
            [[ -z "$_osrelease" && -f /usr/lib/os-release ]] && _osrelease="/usr/lib/os-release"

            if [[ -n "$_osrelease" ]]; then
                local _distro_id _distro_id_like _distro_info
                # Einmal sourcen, beide Werte in einer Subshell lesen
                _distro_info=$(. "$_osrelease" 2>/dev/null && printf '%s\n%s' "$ID" "${ID_LIKE:-}")
                _distro_id="${_distro_info%%$'\n'*}"
                _distro_id_like="${_distro_info#*$'\n'}"
                case "$_distro_id" in
                    fedora)                  _PLATFORM_DISTRO="fedora" ;;
                    debian|ubuntu|raspbian)  _PLATFORM_DISTRO="debian" ;;
                    arch|manjaro)            _PLATFORM_DISTRO="arch" ;;
                    *)
                        # Fallback: ID_LIKE für unbekannte Derivate prüfen
                        case "$_distro_id_like" in
                            *debian*) _PLATFORM_DISTRO="debian" ;;
                            *fedora*) _PLATFORM_DISTRO="fedora" ;;
                            *arch*)   _PLATFORM_DISTRO="arch" ;;
                            *)        _PLATFORM_DISTRO="unknown" ;;
                        esac
                        ;;
                esac
            else
                _PLATFORM_DISTRO="unknown"
            fi
        }
        _detect_distro
        unfunction _detect_distro
    else
        _PLATFORM_DISTRO=""
    fi
    export _PLATFORM_DISTRO
fi

if [[ -z "${_PLATFORM_HAS_DISPLAY+x}" ]]; then
    # Display-Erkennung: macOS immer, Linux via XDG_SESSION_TYPE + WAYLAND_DISPLAY
    # XDG_SESSION_TYPE wird von systemd-logind gesetzt (wayland, x11, tty)
    if [[ "$_PLATFORM_OS" == "macos" ]]; then
        _PLATFORM_HAS_DISPLAY=1
    elif [[ "${XDG_SESSION_TYPE:-}" == "wayland" ]]; then
        _PLATFORM_HAS_DISPLAY=1
    elif [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
        # Fallback falls XDG_SESSION_TYPE nicht gesetzt (z.B. manueller Compositor-Start)
        _PLATFORM_HAS_DISPLAY=1
    else
        _PLATFORM_HAS_DISPLAY=0
    fi
    export _PLATFORM_HAS_DISPLAY
fi

# ------------------------------------------------------------
# Clipboard: clip (schreiben) und clippaste (lesen)
# ------------------------------------------------------------
# Verwendung: echo "text" | clip
#             clippaste → gibt Clipboard aus
#
# Headless: Stille No-Ops (kein Fehler, Daten werden verworfen)
# Desktop Linux: Wayland mit wl-clipboard (GNOME, KDE, Hyprland)

case "$_PLATFORM_OS" in
    macos)
        clip()      { pbcopy; }
        clippaste() { pbpaste; }
        ;;
    linux)
        if (( _PLATFORM_HAS_DISPLAY )); then
            # Wayland Desktop: wl-clipboard (beide Befehle prüfen)
            if (( $+commands[wl-copy] )) && (( $+commands[wl-paste] )); then
                clip()      { wl-copy; }
                clippaste() { wl-paste; }
            else
                # Wayland ohne wl-clipboard: Warnung
                clip() {
                    echo "clip: wl-clipboard nicht gefunden" >&2
                    echo "      Installiere: wl-clipboard" >&2
                    cat >/dev/null
                    return 1
                }
                clippaste() {
                    echo "clippaste: wl-clipboard nicht gefunden" >&2
                    return 1
                }
            fi
        else
            # Headless: Stille No-Ops (Server, Raspberry Pi ohne Desktop)
            clip()      { cat >/dev/null; }
            clippaste() { :; }
        fi
        ;;
    *)
        clip() {
            echo "clip: Plattform nicht unterstützt ($_PLATFORM_OS)" >&2
            cat >/dev/null
            return 1
        }
        clippaste() {
            echo "clippaste: Plattform nicht unterstützt ($_PLATFORM_OS)" >&2
            return 1
        }
        ;;
esac

# ------------------------------------------------------------
# Open: xopen (Datei/URL mit Standard-App öffnen)
# ------------------------------------------------------------
# Verwendung: xopen file.pdf
#             xopen https://example.com
#
# Headless: Stiller No-Op (return 0, kein Fehler)

case "$_PLATFORM_OS" in
    macos)
        xopen() { open -- "$@"; }
        ;;
    linux)
        if (( _PLATFORM_HAS_DISPLAY )) && (( $+commands[xdg-open] )); then
            xopen() {
                [[ -n "${DEBUG:-}" ]] && echo "xopen: xdg-open $*" >&2
                xdg-open "$@" 2>/dev/null &!
            }
        elif (( _PLATFORM_HAS_DISPLAY )); then
            # Desktop ohne xdg-open
            xopen() {
                echo "xopen: xdg-open nicht gefunden" >&2
                echo "       Installiere: xdg-utils" >&2
                return 1
            }
        else
            # Headless: Stiller No-Op
            xopen() { : "$@"; }
        fi
        ;;
    *)
        xopen() {
            echo "xopen: Plattform nicht unterstützt ($_PLATFORM_OS)" >&2
            return 1
        }
        ;;
esac

# ------------------------------------------------------------
# sed: sedi (In-place Bearbeitung, BSD/GNU kompatibel)
# ------------------------------------------------------------
# Verwendung: sedi 's/alt/neu/' datei.txt
#
# BSD (macOS): sed -i '' erfordert leeren Suffix
# GNU (Linux): sed -i akzeptiert keinen separaten Suffix
#
# Unterstützt macOS (BSD sed) und Linux (GNU sed).
# Auf unbekannten Plattformen: Fehlermeldung.

case "$_PLATFORM_OS" in
    macos)
        sedi() { sed -i '' "$@"; }
        ;;
    linux)
        sedi() { sed -i "$@"; }
        ;;
    *)
        sedi() {
            echo "sedi: Plattform nicht unterstützt ($_PLATFORM_OS)" >&2
            return 1
        }
        ;;
esac

# ------------------------------------------------------------
# Debug-Hilfsfunktion (nur wenn DEBUG gesetzt)
# ------------------------------------------------------------
if [[ -n "${DEBUG:-}" ]]; then
    _platform_info() {
        echo "OS:      $_PLATFORM_OS"
        echo "Distro:  ${_PLATFORM_DISTRO:-n/a}"
        echo "Display: $(( _PLATFORM_HAS_DISPLAY )) (Session: ${XDG_SESSION_TYPE:-unset}, Wayland: ${WAYLAND_DISPLAY:-none})"
        echo "clip:      $(whence -w clip 2>/dev/null || echo 'undefined')"
        echo "clippaste: $(whence -w clippaste 2>/dev/null || echo 'undefined')"
        echo "xopen:   $(whence -w xopen 2>/dev/null || echo 'undefined')"
        echo "sedi:    $(whence -w sedi 2>/dev/null || echo 'undefined')"
    }
fi
