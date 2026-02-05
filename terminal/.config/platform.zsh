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
#   macOS     - Apple Silicon (arm64)
#   Fedora    - Desktop/Server
#   Debian    - Desktop/Server (inkl. Raspberry Pi OS, DietPi)
#   Arch      - Desktop/Server
# ============================================================
# Headless-Systeme:
#   Ohne Display ($DISPLAY/$WAYLAND_DISPLAY) werden clip/paste/xopen
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

if [[ -z "${_PLATFORM_OS:-}" ]]; then
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
    # macOS hat immer Display, Linux nur wenn X11/Wayland läuft
    if [[ "$_PLATFORM_OS" == "macos" ]]; then
        _PLATFORM_HAS_DISPLAY=1
    elif [[ -n "${DISPLAY:-}" || -n "${WAYLAND_DISPLAY:-}" ]]; then
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
# Desktop Linux Priorität:
#   1. Wayland: wl-copy / wl-paste
#   2. X11: xsel --clipboard (stabiler)
#   3. X11: xclip -selection clipboard

case "$_PLATFORM_OS" in
    macos)
        clip()  { pbcopy; }
        paste() { pbpaste; }
        ;;
    linux)
        if (( _PLATFORM_HAS_DISPLAY )); then
            # Desktop: Clipboard-Tool ermitteln
            if [[ -n "${WAYLAND_DISPLAY:-}" ]] && (( $+commands[wl-copy] )); then
                clip()  { wl-copy; }
                paste() { wl-paste; }
            elif (( $+commands[xsel] )); then
                clip()  { xsel --clipboard --input; }
                paste() { xsel --clipboard --output; }
            elif (( $+commands[xclip] )); then
                clip()  { xclip -selection clipboard; }
                paste() { xclip -selection clipboard -o; }
            else
                # Desktop ohne Clipboard-Tool: Warnung
                clip() {
                    echo "clip: Kein Clipboard-Tool gefunden" >&2
                    echo "      Installiere: wl-clipboard (Wayland) oder xsel (X11)" >&2
                    return 1
                }
                paste() {
                    echo "paste: Kein Clipboard-Tool gefunden" >&2
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
        clip()  { cat >/dev/null; }
        paste() { :; }
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
        xopen() { open "$@"; }
        ;;
    linux)
        if (( _PLATFORM_HAS_DISPLAY )) && (( $+commands[xdg-open] )); then
            xopen() { xdg-open "$@" 2>/dev/null & disown; }
        elif (( _PLATFORM_HAS_DISPLAY )); then
            # Desktop ohne xdg-open
            xopen() {
                echo "xopen: xdg-open nicht gefunden" >&2
                echo "       Installiere: xdg-utils" >&2
                return 1
            }
        else
            # Headless: Stiller No-Op
            xopen() { :; }
        fi
        ;;
    *)
        xopen() { :; }
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
# Funktioniert auf allen Plattformen (keine Display-Abhängigkeit)

case "$_PLATFORM_OS" in
    macos)
        sedi() { sed -i '' "$@"; }
        ;;
    linux|*)
        sedi() { sed -i "$@"; }
        ;;
esac

# ------------------------------------------------------------
# Debug-Hilfsfunktion (nur wenn DEBUG gesetzt)
# ------------------------------------------------------------
if [[ -n "${DEBUG:-}" ]]; then
    _platform_info() {
        echo "OS:      $_PLATFORM_OS"
        echo "Distro:  ${_PLATFORM_DISTRO:-n/a}"
        echo "Display: $(( _PLATFORM_HAS_DISPLAY )) (${DISPLAY:-}${WAYLAND_DISPLAY:-})"
        echo "clip:    $(whence -w clip 2>/dev/null || echo 'undefined')"
        echo "xopen:   $(whence -w xopen 2>/dev/null || echo 'undefined')"
    }
fi
