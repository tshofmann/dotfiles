# ============================================================
# platform.zsh - Plattform-Abstraktionen
# ============================================================
# Zweck       : Einheitliche Funktionen für macOS und Linux
# Pfad        : ~/.config/platform.zsh (nach stow)
# Geladen     : Früh in .zshrc (vor Aliase)
# ============================================================
# Funktionen:
#   clip      - Clipboard schreiben (stdin → Zwischenablage)
#   paste     - Clipboard lesen (Zwischenablage → stdout)
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
#   Wayland   - GNOME, KDE, Hyprland (wl-clipboard, xdg-open)
# ============================================================
# Headless-Systeme:
#   Ohne Wayland ($WAYLAND_DISPLAY) werden clip/paste/xopen
#   als stille No-Ops definiert um Fehlermeldungen zu vermeiden.
# ============================================================

# Verhindere mehrfaches Laden (Shell-Variable für aktuelle Shell)
[[ -n "${_PLATFORM_LOADED:-}" ]] && return 0
typeset -g _PLATFORM_LOADED=1

# ------------------------------------------------------------
# Plattform-Erkennung (einmalig beim Laden, exportiert für Subshells)
# ------------------------------------------------------------
# Exportierte Variablen ermöglichen schnelles Re-Laden in Subshells
# (z.B. fzf execute-silent) ohne erneute uname/Datei-Checks.

if [[ -z "${_PLATFORM_OS+x}" ]]; then
    # Erstmalige Erkennung
    case "$(uname -s)" in
        Darwin) _PLATFORM_OS="macos" ;;
        Linux)  _PLATFORM_OS="linux" ;;
        *)      _PLATFORM_OS="unknown" ;;
    esac
    export _PLATFORM_OS
fi

if [[ -z "${_PLATFORM_DISTRO+x}" ]]; then
    # Linux-Distribution (für zukünftige distro-spezifische Logik)
    if [[ "$_PLATFORM_OS" == "linux" ]]; then
        if [[ -f /etc/fedora-release ]]; then
            _PLATFORM_DISTRO="fedora"
        elif [[ -f /etc/debian_version ]]; then
            # Debian, Ubuntu, Raspberry Pi OS, DietPi, etc.
            _PLATFORM_DISTRO="debian"
        elif [[ -f /etc/arch-release ]]; then
            _PLATFORM_DISTRO="arch"
        else
            _PLATFORM_DISTRO="unknown"
        fi
    else
        _PLATFORM_DISTRO=""
    fi
    export _PLATFORM_DISTRO
fi

if [[ -z "${_PLATFORM_HAS_DISPLAY+x}" ]]; then
    # Display-Erkennung (für Clipboard/Open-Funktionen)
    # macOS hat immer Display, Linux nur mit Wayland
    if [[ "$_PLATFORM_OS" == "macos" ]]; then
        _PLATFORM_HAS_DISPLAY=1
    elif [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
        _PLATFORM_HAS_DISPLAY=1
    else
        _PLATFORM_HAS_DISPLAY=0
    fi
    export _PLATFORM_HAS_DISPLAY
fi

# ------------------------------------------------------------
# Clipboard: clip (schreiben) und paste (lesen)
# ------------------------------------------------------------
# Verwendung: echo "text" | clip
#             paste → gibt Clipboard aus
#
# Headless: Stille No-Ops (kein Fehler, Daten werden verworfen)
# Desktop Linux: Wayland mit wl-clipboard (GNOME, KDE, Hyprland)

case "$_PLATFORM_OS" in
    macos)
        clip()  { pbcopy; }
        paste() { pbpaste; }
        ;;
    linux)
        if (( _PLATFORM_HAS_DISPLAY )); then
            # Wayland Desktop: wl-clipboard
            if (( $+commands[wl-copy] )); then
                clip()  { wl-copy; }
                paste() { wl-paste; }
            else
                # Wayland ohne wl-clipboard: Warnung
                clip() {
                    echo "clip: wl-clipboard nicht gefunden" >&2
                    echo "      Installiere: wl-clipboard" >&2
                    cat >/dev/null
                    return 1
                }
                paste() {
                    echo "paste: wl-clipboard nicht gefunden" >&2
                    return 1
                }
            fi
        else
            # Headless: Stille No-Ops (Server, Raspberry Pi ohne Desktop)
            clip()  { cat >/dev/null; }
            paste() { :; }
        fi
        ;;
    *)
        clip() {
            echo "clip: Plattform nicht unterstützt ($_PLATFORM_OS)" >&2
            cat >/dev/null
            return 1
        }
        paste() {
            echo "paste: Plattform nicht unterstützt ($_PLATFORM_OS)" >&2
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
        echo "Display: $(( _PLATFORM_HAS_DISPLAY )) (Wayland: ${WAYLAND_DISPLAY:-none})"
        echo "clip:    $(whence -w clip 2>/dev/null || echo 'undefined')"
        echo "paste:   $(whence -w paste 2>/dev/null || echo 'undefined')"
        echo "xopen:   $(whence -w xopen 2>/dev/null || echo 'undefined')"
        echo "sedi:    $(whence -w sedi 2>/dev/null || echo 'undefined')"
    }
fi
