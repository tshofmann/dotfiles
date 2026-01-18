#!/usr/bin/env zsh
# ============================================================
# core.sh - Hauptlogik für tldr-Patch/Page Generierung
# ============================================================
# Zweck       : Öffentliche API: generate_tldr_patches()
# Pfad        : .github/scripts/generators/tldr/core.sh
# ============================================================

# Abhängigkeiten: common.sh, tldr/*.sh Module

# ------------------------------------------------------------
# Öffentliche Funktion: Alle tldr-Patches generieren/prüfen
# ------------------------------------------------------------
generate_tldr_patches() {
    local mode="${1:---check}"
    local errors=0

    case "$mode" in
        --check)
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

            # Prüfe dotfiles.page.md
            generate_dotfiles_tldr --check || (( errors++ )) || true

            # Prüfe catppuccin.page.md
            generate_catppuccin_tldr --check || (( errors++ )) || true

            # Prüfe zsh.patch.md
            generate_zsh_tldr --check || (( errors++ )) || true

            return $errors
            ;;

        --generate)
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

            # Generiere dotfiles.page.md
            generate_dotfiles_tldr --generate

            # Generiere catppuccin.page.md
            generate_catppuccin_tldr --generate

            # Generiere zsh.patch.md
            generate_zsh_tldr --generate
            ;;
    esac
}
