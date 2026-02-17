#!/usr/bin/env zsh
# ============================================================
# core.sh - Hauptlogik für tldr-Patch/Page Generierung
# ============================================================
# Zweck       : Öffentliche API: generate_tldr_patches()
# Pfad        : .github/scripts/generators/tldr/core.sh
# Quellen     : .alias-Dateien (primär), Config-Verzeichnisse (sekundär)
# ============================================================

# Abhängigkeiten: common.sh, tldr/*.sh Module

# ------------------------------------------------------------
# Helper: tldr-Cache aktuell halten
# ------------------------------------------------------------
# Prüft ob der tealdeer-Cache älter als 7 Tage ist und aktualisiert
# automatisch. Verhindert falsche patch↔page Konvertierungen wenn
# neue offizielle tldr-Seiten hinzugefügt werden.
_ensure_tldr_cache_fresh() {
    command -v tldr >/dev/null 2>&1 || return 0

    local cache_base
    case "$OSTYPE" in
        darwin*) cache_base="${HOME}/Library/Caches/tealdeer/tldr-pages" ;;
        *)       cache_base="${XDG_CACHE_HOME:-$HOME/.cache}/tealdeer/tldr-pages" ;;
    esac

    # Kein Cache → Update nötig
    if [[ ! -d "$cache_base" ]]; then
        dim "  tldr-Cache nicht vorhanden – aktualisiere..."
        if ! tldr --update >/dev/null 2>&1; then
            warn "  tldr-Cache-Update fehlgeschlagen"
        fi
        return 0
    fi

    # Cache-Alter prüfen (7 Tage = 604800 Sekunden)
    local cache_age_max=604800
    local now=$(date +%s)
    local cache_mtime

    # Plattform-kompatible Zeitstempel-Abfrage
    case "$OSTYPE" in
        darwin*) cache_mtime=$(stat -f "%m" "$cache_base" 2>/dev/null) ;;
        *)       cache_mtime=$(stat -c "%Y" "$cache_base" 2>/dev/null) ;;
    esac

    # stat-Fehler → Update erzwingen
    if [[ -z "$cache_mtime" ]]; then
        dim "  tldr-Cache-Zeitstempel nicht lesbar – aktualisiere..."
        tldr --update >/dev/null 2>&1
        return 0
    fi

    local age=$(( now - cache_mtime ))
    if (( age > cache_age_max )); then
        local days=$(( age / 86400 ))
        dim "  tldr-Cache veraltet (${days} Tage) – aktualisiere..."
        if ! tldr --update >/dev/null 2>&1; then
            warn "  tldr-Cache-Update fehlgeschlagen – arbeite mit vorhandenem Cache"
        fi
    fi
}

# ------------------------------------------------------------
# Öffentliche Funktion: Alle tldr-Patches generieren/prüfen
# ------------------------------------------------------------
generate_tldr_patches() {
    local mode="${1:---check}"
    local errors=0

    # Cache-Frische sicherstellen (verhindert falsche patch↔page Konvertierungen)
    _ensure_tldr_cache_fresh

    case "$mode" in
        --check)
            # 1. Alias-basierte Patches prüfen
            for alias_file in "$ALIAS_DIR"/*.alias(N); do
                local tool_name=$(basename "$alias_file" .alias)
                local patch_file="$TEALDEER_DIR/${tool_name}.patch.md"
                local page_file="$TEALDEER_DIR/${tool_name}.page.md"

                # Spezialfälle: dotfiles und catppuccin haben eigene Generatoren
                [[ "$tool_name" == "dotfiles" || "$tool_name" == "catppuccin" ]] && continue

                # Prüfe ob offizielle Seite existiert (bestimmt ob Patch oder Page)
                local is_page=false
                has_official_tldr_page "$tool_name" || is_page=true

                local generated=$(generate_complete_patch "$tool_name" "$is_page")
                local trimmed="${generated//[[:space:]]/}"

                # Keine Inhalte generiert → überspringen
                [[ -z "$trimmed" ]] && continue

                if [[ "$is_page" == "false" ]]; then
                    # Offizielle Seite existiert → .patch.md verwenden
                    if [[ -f "$page_file" ]]; then
                        err "${tool_name}.page.md sollte gelöscht werden (offizielle tldr-Seite existiert)"
                        (( errors++ )) || true
                    fi

                    if [[ -f "$patch_file" ]]; then
                        local current=$(cat "$patch_file")
                        if [[ "$generated" != "$current" ]]; then
                            err "${tool_name}.patch.md ist veraltet"
                            (( errors++ )) || true
                        fi
                    else
                        err "${tool_name}.patch.md fehlt"
                        (( errors++ )) || true
                    fi
                else
                    # Keine offizielle Seite → .page.md verwenden
                    if [[ -f "$patch_file" ]]; then
                        err "${tool_name}.patch.md sollte gelöscht werden (keine offizielle tldr-Seite)"
                        (( errors++ )) || true
                    fi

                    if [[ -f "$page_file" ]]; then
                        local current=$(cat "$page_file")
                        if [[ "$generated" != "$current" ]]; then
                            err "${tool_name}.page.md ist veraltet"
                            (( errors++ )) || true
                        fi
                    else
                        err "${tool_name}.page.md fehlt"
                        (( errors++ )) || true
                    fi
                fi
            done

            # 2. Config-only Tools prüfen (Tools ohne .alias aber mit Config)
            for tool_name in $(find_config_only_tools); do
                local patch_file="$TEALDEER_DIR/${tool_name}.patch.md"
                local page_file="$TEALDEER_DIR/${tool_name}.page.md"

                local is_page=false
                has_official_tldr_page "$tool_name" || is_page=true

                local generated=$(generate_config_only_patch "$tool_name" "$is_page")
                local trimmed="${generated//[[:space:]]/}"

                [[ -z "$trimmed" ]] && continue

                if [[ "$is_page" == "false" ]]; then
                    if [[ -f "$patch_file" ]]; then
                        local current=$(cat "$patch_file")
                        if [[ "$generated" != "$current" ]]; then
                            err "${tool_name}.patch.md ist veraltet (Config-only Tool)"
                            (( errors++ )) || true
                        fi
                    else
                        err "${tool_name}.patch.md fehlt (Config-only Tool)"
                        (( errors++ )) || true
                    fi
                else
                    if [[ -f "$page_file" ]]; then
                        local current=$(cat "$page_file")
                        if [[ "$generated" != "$current" ]]; then
                            err "${tool_name}.page.md ist veraltet (Config-only Tool)"
                            (( errors++ )) || true
                        fi
                    else
                        err "${tool_name}.page.md fehlt (Config-only Tool)"
                        (( errors++ )) || true
                    fi
                fi
            done

            # 3. Spezial-Generatoren prüfen
            generate_dotfiles_tldr --check || (( errors++ )) || true
            generate_catppuccin_tldr --check || (( errors++ )) || true
            generate_zsh_tldr --check || (( errors++ )) || true

            return $errors
            ;;

        --generate)
            # 1. Alias-basierte Patches generieren
            for alias_file in "$ALIAS_DIR"/*.alias(N); do
                local tool_name=$(basename "$alias_file" .alias)
                local patch_file="$TEALDEER_DIR/${tool_name}.patch.md"
                local page_file="$TEALDEER_DIR/${tool_name}.page.md"

                # Spezialfälle: dotfiles und catppuccin haben eigene Generatoren
                [[ "$tool_name" == "dotfiles" || "$tool_name" == "catppuccin" ]] && continue

                # Prüfe ob offizielle Seite existiert (bestimmt ob Patch oder Page)
                local is_page=false
                has_official_tldr_page "$tool_name" || is_page=true

                local generated=$(generate_complete_patch "$tool_name" "$is_page")
                local trimmed="${generated//[[:space:]]/}"

                # Keine Inhalte generiert → beide Dateien löschen falls vorhanden
                if [[ -z "$trimmed" ]]; then
                    [[ -f "$patch_file" ]] && rm "$patch_file"
                    [[ -f "$page_file" ]] && rm "$page_file"
                    continue
                fi

                if [[ "$is_page" == "false" ]]; then
                    # Offizielle Seite existiert → .patch.md verwenden
                    [[ -f "$page_file" ]] && rm "$page_file" && dim "  Gelöscht: ${tool_name}.page.md (offizielle tldr-Seite existiert)"
                    write_if_changed "$patch_file" "$generated"
                else
                    # Keine offizielle Seite → .page.md verwenden
                    [[ -f "$patch_file" ]] && rm "$patch_file" && dim "  Gelöscht: ${tool_name}.patch.md (keine offizielle tldr-Seite)"
                    write_if_changed "$page_file" "$generated"
                fi
            done

            # 2. Config-only Tools generieren
            for tool_name in $(find_config_only_tools); do
                local patch_file="$TEALDEER_DIR/${tool_name}.patch.md"
                local page_file="$TEALDEER_DIR/${tool_name}.page.md"

                local is_page=false
                has_official_tldr_page "$tool_name" || is_page=true

                local generated=$(generate_config_only_patch "$tool_name" "$is_page")
                local trimmed="${generated//[[:space:]]/}"

                if [[ -z "$trimmed" ]]; then
                    [[ -f "$patch_file" ]] && rm "$patch_file"
                    [[ -f "$page_file" ]] && rm "$page_file"
                    continue
                fi

                if [[ "$is_page" == "false" ]]; then
                    [[ -f "$page_file" ]] && rm "$page_file" && dim "  Gelöscht: ${tool_name}.page.md (offizielle tldr-Seite existiert)"
                    write_if_changed "$patch_file" "$generated"
                else
                    [[ -f "$patch_file" ]] && rm "$patch_file" && dim "  Gelöscht: ${tool_name}.patch.md (keine offizielle tldr-Seite)"
                    write_if_changed "$page_file" "$generated"
                fi
            done

            # 3. Spezial-Generatoren ausführen
            generate_dotfiles_tldr --generate
            generate_catppuccin_tldr --generate
            generate_zsh_tldr --generate
            ;;
    esac
}
