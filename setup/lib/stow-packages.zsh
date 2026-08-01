#!/usr/bin/env zsh
# ============================================================
# stow-packages.zsh - Stow-Package-Erkennung (geteilte Quelle)
# ============================================================
# Zweck       : Erkennt Stow-Packages dynamisch aus der Repo-Struktur
# Pfad        : setup/lib/stow-packages.zsh
# Geladen     : setup/modules/backup.sh (Bootstrap),
#               dotstow() in terminal/.config/alias/dotfiles.alias (Laufzeit)
# Nutzt       : - (bewusst ohne _core.sh: dotstow lädt kein Bootstrap-Core)
# ============================================================

# Mehrfaches Laden verhindern
[[ -n "${_STOW_PACKAGES_LOADED:-}" ]] && return 0
readonly _STOW_PACKAGES_LOADED=1

# Ermittelt Stow-Packages dynamisch aus der Verzeichnisstruktur.
# Ein Package ist ein Verzeichnis mit mindestens einer Dotfile
# oder einem .config-Unterverzeichnis.
# Aufruf: _get_stow_packages [basis-verzeichnis]
# Ohne Argument wird $DOTFILES_DIR verwendet (Bootstrap-Kontext).
_get_stow_packages() {
    # Lokal normalisierte Optionen: User-Shells (dotstow) können
    # glob_dots/nomatch abweichend gesetzt haben
    emulate -L zsh

    local base="${1:-${DOTFILES_DIR:-}}"
    if [[ -z "$base" || ! -d "$base" ]]; then
        echo "FEHLER: _get_stow_packages: Basis-Verzeichnis fehlt oder existiert nicht: '$base'" >&2
        return 1
    fi

    local dir name
    for dir in "$base"/*/(N); do
        name="${dir%/}"
        name="${name##*/}"

        # Bekannte Nicht-Packages überspringen
        # (Dot-Verzeichnisse zusätzlich als Schutz bei aktivem glob_dots)
        [[ "$name" == "setup" ]] && continue
        [[ "$name" == "docs" ]] && continue
        [[ "$name" == ".git" ]] && continue
        [[ "$name" == ".backup" ]] && continue
        [[ "$name" == ".github" ]] && continue

        # Package-Heuristik: Dotfiles oder .config-Unterverzeichnis
        if [[ -n "$(find "$dir" -maxdepth 1 -name '.*' -not -name '.DS_Store' -type f 2>/dev/null | head -1)" ]] ||
           [[ -d "${dir}.config" ]]; then
            echo "$name"
        fi
    done
}
