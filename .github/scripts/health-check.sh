#!/usr/bin/env zsh
# ============================================================
# health-check.sh - Systemprüfung der dotfiles-Installation
# ============================================================
# Zweck       : Prüft ob alle Komponenten korrekt INSTALLIERT sind
#           (Symlinks, Tools, Konfigurationen, Abhängigkeiten)
#
# HINWEIS : Dieser Check prüft die INSTALLATION auf dem System.
#           Für Konsistenz Doku↔Code: ./scripts/validate-docs.sh
#
# Design  : SOLL-IST-VERGLEICH – vollständig dynamisch!
#
#           SOLL (was sein sollte):
#           - Alle Dateien in terminal/ → Symlinks in ~/
#           - Alle brew-Formulae in Brewfile → installierte Tools
#           - Alle zsh-* in Brewfile → ZSH-Plugins
#           - Alle font-* in Brewfile → Fonts (nur macOS)
#
#           IST (was tatsächlich existiert):
#           - Symlinks im Home-Verzeichnis
#           - Installierte Binaries (command -v)
#           - Plugin-Verzeichnisse in $(brew --prefix)/share/
#             oder /usr/share/ (apt-basierte Systeme)
#           - Font-Dateien in ~/Library/Fonts/ (nur macOS)
#
#           → Neue Dateien werden AUTOMATISCH erkannt!
#           → Keine manuellen Updates bei neuen Configs nötig!
#
# Plattform   : macOS und Linux (inkl. 32-bit ARM Raspberry Pi)
#               macOS-spezifische Sektionen (Font, Terminal.app,
#               ZSH-Sessions) werden auf Linux uebersprungen.
#               Auf armv* ohne Homebrew werden Tools direkt via
#               command -v geprueft (apt/cargo/gh-Release Installation).
#
# Aufruf      : ./scripts/health-check.sh
# Docs        : https://github.com/tshofmann/dotfiles#readme
# ============================================================

set -uo pipefail

# ------------------------------------------------------------
# Konfiguration
# ------------------------------------------------------------
readonly SCRIPT_DIR="${0:A:h}"
readonly DOTFILES_DIR="${SCRIPT_DIR:h:h}"  # .github/scripts → dotfiles
readonly SHELL_COLORS="$DOTFILES_DIR/terminal/.config/theme-style"

# Farben (Catppuccin Mocha) – zentral definiert
[[ -f "$SHELL_COLORS" ]] && source "$SHELL_COLORS"

# Fallback falls theme-style fehlt (z.B. vor stow, in CI)
# Verhindert Crash durch set -u bei ungesetzten C_*-Variablen
if [[ -z "${C_RESET:-}" ]]; then
    C_RESET=$'\033[0m' C_BOLD=$'\033[1m' C_DIM=$'\033[2m'
    C_GREEN=$'\033[32m' C_RED=$'\033[31m' C_YELLOW=$'\033[33m'
    C_BLUE=$'\033[34m' C_MAUVE=$'\033[35m'
    C_TEXT=$'\033[37m' C_OVERLAY0=$'\033[90m'
fi

readonly TERMINAL_DIR="$DOTFILES_DIR/terminal"
readonly EDITOR_DIR="$DOTFILES_DIR/editor"
readonly BREWFILE="$DOTFILES_DIR/setup/Brewfile"

# Plattform-Erkennung (für bedingte Sektionen)
# platform.zsh wird später erneut geladen für isolierten Test,
# hier nur für Guard-Logik der Sektionen
typeset _hc_os="macos"
if [[ "$(uname -s)" == "Linux" ]]; then
  _hc_os="linux"
fi
typeset _hc_arch
_hc_arch="$(uname -m)"

# Zähler für Ergebnisse
typeset -i passed=0
typeset -i failed=0
typeset -i warnings=0

# ------------------------------------------------------------
# Ausgabe-Helper
# ------------------------------------------------------------
pass()    { echo -e "  ${C_GREEN}✔${C_RESET} $*"; (( passed++ )) || true; }
fail()    { echo -e "  ${C_RED}✖${C_RESET} $*"; (( failed++ )) || true; }
warn()    { echo -e "  ${C_YELLOW}⚠${C_RESET} $*"; (( warnings++ )) || true; }
section() { print ""; print "${C_MAUVE}━━━ ${C_BOLD}$*${C_RESET}${C_MAUVE} ━━━${C_RESET}"; }

# ------------------------------------------------------------
# Symlink-Prüfung
# ------------------------------------------------------------
check_symlink() {
  local link="$1"
  local expected_target="$2"
  local display_name="${3:-$link}"

  if [[ -L "$link" ]]; then
    # Prüfe ob Symlink-Ziel existiert (toter Symlink?)
    if [[ ! -e "$link" ]]; then
      fail "$display_name → toter Symlink (Target existiert nicht)"
      return 1
    fi
    # Symlink-Ziel normalisieren und gegen erwartete Quelldatei vergleichen
    local actual_target resolved
    actual_target=$(readlink "$link")
    resolved="$actual_target"
    [[ "$actual_target" != /* ]] && resolved="${link:h}/${actual_target}"
    if [[ "${resolved:a}" == "${DOTFILES_DIR}/${expected_target}" ]]; then
      pass "$display_name → korrekt verlinkt"
    else
      fail "$display_name → falsches Ziel: $actual_target"
    fi
  elif [[ -e "$link" ]]; then
    fail "$display_name → existiert, ist aber kein Symlink"
  else
    fail "$display_name → fehlt"
  fi
}

# ------------------------------------------------------------
# Tool-Prüfung
# ------------------------------------------------------------
check_tool() {
  local tool="$1"
  local description="${2:-$tool}"

  if command -v "$tool" >/dev/null 2>&1; then
    pass "$description"
  else
    fail "$description → nicht installiert"
  fi
}

# ------------------------------------------------------------
# Brewfile-Parser: Extrahiert Tool-Namen
# ------------------------------------------------------------
# Liest brew-Formulae aus Brewfile und gibt Tool-Namen zurück
# Filtert ZSH-Plugins (haben kein Binary) und mappt abweichende Namen
get_tools_from_brewfile() {
  local brewfile="$1"
  [[ -f "$brewfile" ]] || return 1

  # Mapping: Formula-Name → Binary-Name (falls unterschiedlich)
  typeset -A tool_mapping=(
    [ripgrep]=rg
    [tealdeer]=tldr
    [sevenzip]=7zz
    [poppler]=pdftotext
    [imagemagick]=magick
  )

  # Formulae die kein eigenständiges Binary haben (werden separat geprüft)
  # mas ist macOS-exklusiv (Mac App Store CLI)
  typeset -a skip_formulae=(
    zsh-syntax-highlighting
    zsh-autosuggestions
    mas
  )

  # Extrahiere brew-Formulae (keine casks, keine mas)
  grep -E '^brew "[^"]+"' "$brewfile" | \
    sed 's/brew "\([^"]*\)".*/\1/' | \
    while read -r formula; do
      # Überspringe Formulae ohne Binary
      if (( ${skip_formulae[(Ie)$formula]} )); then
        continue
      fi
      # Verwende Mapping falls vorhanden, sonst Formula-Name
      print "${tool_mapping[$formula]:-$formula}"
    done
}

# ------------------------------------------------------------
# Hauptprüfungen
# ------------------------------------------------------------
print ""
print "${C_OVERLAY0}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
print "${C_MAUVE}🔍 ${C_BOLD}dotfiles Health Check${C_RESET}"
print "${C_OVERLAY0}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
print ""
print "   ${C_DIM}Prüft ob alle Komponenten korrekt installiert sind${C_RESET}"
print "   ${C_DIM}ℹ SOLL-IST-Vergleich: Alle Dateien in terminal/ und editor/${C_RESET}"

# --- Symlinks: Bidirektionaler SOLL-IST-Vergleich ---
section "Symlinks (bidirektional)"

# VOLLSTÄNDIG DYNAMISCH: Scannt ALLE Dateien in terminal/
# und prüft ob entsprechende Symlinks im Home-Verzeichnis existieren
#
# Richtung 1: SOLL → IST
#   SOLL = Alle Dateien in terminal/ (außer .DS_Store, *.patch.md)
#   IST  = Entsprechende Symlinks in ~/ bzw. ~/.config/
#
# Richtung 2: IST → SOLL
#   IST  = Alle Symlinks in ~/.config/ die auf dotfiles zeigen
#   SOLL = Entsprechende Dateien in terminal/ oder editor/
#
# Bei neuen Dateien in terminal/ oder editor/ wird der Check automatisch erweitert!

typeset -i symlink_count=0
typeset -a missing_symlinks=()
typeset -a expected_symlinks=()  # Für bidirektionale Prüfung

# ━━━ Richtung 1: SOLL → IST ━━━
# Prüfe terminal/ und editor/ Verzeichnisse
for stow_dir in "$TERMINAL_DIR" "$EDITOR_DIR"; do
  [[ -d "$stow_dir" ]] || continue
  typeset dir_name="${stow_dir:t}"

  while IFS= read -r source_file; do
    [[ -z "$source_file" ]] && continue

    # Relativen Pfad berechnen (ab terminal/ oder editor/)
    typeset rel_path="${source_file#$stow_dir/}"

    # Ziel-Pfad im Home-Verzeichnis
    typeset target_path="$HOME/$rel_path"
    typeset display_path="~/$rel_path"

    # Für bidirektionale Prüfung merken
    expected_symlinks+=("$target_path")

    (( symlink_count++ )) || true

    if [[ -L "$target_path" ]]; then
      # Symlink-Ziel normalisieren und gegen erwartete Quelldatei vergleichen
      typeset link_target=""
      link_target=$(readlink "$target_path" 2>/dev/null)
      typeset resolved_link="$link_target"
      [[ "$link_target" != /* ]] && resolved_link="${target_path:h}/${link_target}"
      if [[ "${resolved_link:a}" == "$source_file" ]]; then
        pass "$display_path"
      else
        fail "$display_path → falsches Ziel: $link_target"
      fi
    elif [[ -e "$target_path" ]]; then
      fail "$display_path → existiert, ist aber kein Symlink"
    else
      fail "$display_path → fehlt"
      missing_symlinks+=("$rel_path")
    fi
  done < <(find "$stow_dir" -type f ! -name '.DS_Store' 2>/dev/null | sort)
done

# Hinweis bei fehlenden Symlinks
if (( ${#missing_symlinks[@]} > 0 )); then
  print "\n  ${C_DIM}💡 Fehlende Symlinks erstellen mit:${C_RESET}"
  print "     ${C_BOLD}cd $DOTFILES_DIR && stow -R terminal editor${C_RESET}"
fi

print "\n  ${C_DIM}📊 Richtung 1: $symlink_count Dateien aus terminal/ und editor/${C_RESET}"

# ━━━ Richtung 2: IST → SOLL ━━━
# Finde Orphan-Symlinks in ~/.config/ die auf dotfiles zeigen aber nicht mehr im Repo sind
typeset -i orphan_count=0
typeset -a orphan_symlinks=()

# Prüfe alle Symlinks in ~/.config/ die auf dotfiles zeigen
while IFS= read -r symlink; do
  [[ -z "$symlink" ]] && continue

  # Ziel-Pfad normalisieren (funktioniert für abs. UND rel. Pfade, auch tote Symlinks)
  # :a löst ../ auf ohne Dateisystem-Zugriff (im Gegensatz zu :A/realpath)
  typeset link_target=""
  link_target=$(readlink "$symlink" 2>/dev/null) || continue
  typeset resolved_target="$link_target"
  [[ "$link_target" != /* ]] && resolved_target="${symlink:h}/${link_target}"
  resolved_target="${resolved_target:a}"
  [[ "$resolved_target" == "${DOTFILES_DIR}/"* ]] || continue

  # Wenn Quelle existiert → kein Orphan
  [[ -f "$resolved_target" ]] && continue

  # Orphan gefunden - Symlink zeigt auf dotfiles aber Quelle fehlt
  typeset display_path="${symlink/#$HOME/~}"
  orphan_symlinks+=("$display_path")
  (( orphan_count++ )) || true
done < <(find "$HOME/.config" -maxdepth 3 -type l 2>/dev/null | sort)

# Prüfe auch Root-Level Dotfiles (~/.zshrc, ~/.zshenv, etc.)
for dotfile in ~/.zshrc ~/.zshenv ~/.zprofile ~/.zlogin ~/.editorconfig; do
  [[ -L "$dotfile" ]] || continue

  # Ziel-Pfad normalisieren (wie oben)
  typeset link_target2=""
  link_target2=$(readlink "$dotfile" 2>/dev/null) || continue
  typeset resolved_dotfile="$link_target2"
  [[ "$link_target2" != /* ]] && resolved_dotfile="${dotfile:h}/${link_target2}"
  resolved_dotfile="${resolved_dotfile:a}"
  [[ "$resolved_dotfile" == "${DOTFILES_DIR}/"* ]] || continue

  # Wenn Quelle existiert → kein Orphan
  [[ -f "$resolved_dotfile" ]] && continue

  typeset display_path="${dotfile/#$HOME/~}"
  orphan_symlinks+=("$display_path")
  (( orphan_count++ )) || true
done

if (( ${#orphan_symlinks[@]} > 0 )); then
  fail "Orphan-Symlinks (zeigen auf dotfiles, aber Quelle fehlt im Repo):"
  for orphan in "${orphan_symlinks[@]}"; do
    print "       → $orphan"
  done
  print "\n  ${C_DIM}💡 Entfernen mit: rm <symlink> oder Quelle wiederherstellen${C_RESET}"
else
  print "  ${C_DIM}📊 Richtung 2: Keine Orphan-Symlinks gefunden${C_RESET}"
fi

# --- Homebrew & Tools ---
section "Homebrew & CLI-Tools"

if command -v brew >/dev/null 2>&1; then
  pass "Homebrew installiert ($(brew --version | head -1))"

  # DYNAMISCH: Tools aus Brewfile extrahieren
  if [[ -f "$BREWFILE" ]]; then
    typeset -a tools=($(get_tools_from_brewfile "$BREWFILE"))
    for tool in "${tools[@]}"; do
      check_tool "$tool" "$tool"
    done
  else
    warn "Brewfile nicht gefunden: $BREWFILE"
  fi
elif [[ "$_hc_os" == "linux" && "$_hc_arch" == armv* ]]; then
  # 32-bit ARM: Kein Homebrew verfügbar, Tools wurden via apt/cargo/gh installiert
  # Prüfe trotzdem alle erwarteten Binaries aus dem Brewfile
  warn "Homebrew nicht verfügbar (32-bit ARM) – prüfe Binaries direkt"
  if [[ -f "$BREWFILE" ]]; then
    typeset -a tools=($(get_tools_from_brewfile "$BREWFILE"))
    for tool in "${tools[@]}"; do
      check_tool "$tool" "$tool"
    done
  fi
else
  fail "Homebrew nicht installiert"
fi

# ZSH-Plugins (DYNAMISCH aus Brewfile extrahiert)
section "ZSH-Plugins"

# DYNAMISCH: Extrahiere zsh-* Formulae aus Brewfile
typeset -a zsh_plugins=($(grep -E '^brew "zsh-' "$BREWFILE" 2>/dev/null | sed 's/brew "\([^"]*\)".*/\1/'))

if (( ${#zsh_plugins[@]} > 0 )); then
  for plugin in "${zsh_plugins[@]}"; do
    # Prüfe Homebrew-Pfad, dann apt-Pfad (/usr/share/)
    if command -v brew >/dev/null 2>&1 && [[ -d "$(brew --prefix)/share/$plugin" ]]; then
      pass "$plugin (Homebrew)"
    elif [[ -d "/usr/share/$plugin" ]]; then
      pass "$plugin (/usr/share)"
    else
      if command -v brew >/dev/null 2>&1; then
        warn "$plugin nicht installiert (brew install $plugin)"
      else
        warn "$plugin nicht installiert (sudo apt-get install $plugin)"
      fi
    fi
  done
else
  warn "Keine ZSH-Plugins in Brewfile gefunden"
fi

# --- Font (DYNAMISCH aus Brewfile, nur macOS) ---
# Auf Linux/SSH werden Fonts vom Client-Terminal gerendert,
# der Pi sendet nur Unicode-Codepoints über SSH.
if [[ "$_hc_os" == "macos" ]]; then
section "Nerd Font"

# DYNAMISCH: Extrahiere Font-Casks aus Brewfile
typeset -a font_casks=($(grep -E '^cask "font-' "$BREWFILE" 2>/dev/null | sed 's/cask "\([^"]*\)".*/\1/'))

if (( ${#font_casks[@]} > 0 )); then
  typeset font_pattern
  for font_cask in "${font_casks[@]}"; do
    # Konvertiere cask-name zu Font-Dateiname-Pattern
    # z.B. font-meslo-lg-nerd-font → MesloLG*NerdFont*
    case "$font_cask" in
      font-meslo-lg-nerd-font)
        font_pattern="MesloLG*NerdFont*"
        ;;
      font-jetbrains-mono-nerd-font)
        font_pattern="JetBrainsMono*NerdFont*"
        ;;
      font-*)
        # Generischer Fallback: Entferne font- Prefix, CamelCase
        font_pattern="${font_cask#font-}"
        font_pattern="${font_pattern//-/}*"
        ;;
    esac

    typeset -a font_files=(~/Library/Fonts/${~font_pattern}(N) /Library/Fonts/${~font_pattern}(N))
    if (( ${#font_files} > 0 )); then
      pass "$font_cask installiert (${#font_files} Dateien)"
    else
      fail "$font_cask nicht gefunden"
    fi
  done
else
  warn "Keine Font-Casks in Brewfile gefunden"
fi
else
  # Linux: Font-Check übersprungen (SSH = Font kommt vom Client)
  print "\n  ${C_DIM}ℹ Nerd Font: Wird vom SSH-Client gerendert (kein lokaler Check nötig)${C_RESET}"
fi  # macOS Font-Guard

# --- Plattform-Abstraktionen ---
section "Plattform-Abstraktionen (platform.zsh)"

# platform.zsh wird früh in .zshrc geladen – hier manuell laden für isolierten Test
typeset platform_file="$DOTFILES_DIR/terminal/.config/platform.zsh"
if [[ -f "$platform_file" ]]; then
  # Guard- und Detection-Variablen zurücksetzen, damit die Erkennung isoliert neu läuft
  unset _PLATFORM_LOADED _PLATFORM_OS _PLATFORM_DISTRO _PLATFORM_HAS_DISPLAY
  source "$platform_file"
else
  fail "platform.zsh nicht gefunden: $platform_file"
fi

# platform.zsh wird früh in .zshrc geladen und definiert clip/clippaste/xopen/sedi
if [[ -n "${_PLATFORM_OS:-}" ]]; then
  pass "Plattform erkannt: $_PLATFORM_OS"
else
  fail "_PLATFORM_OS nicht gesetzt (platform.zsh nicht geladen?)"
fi

# Prüfe ob alle 4 Funktionen definiert sind
for func in clip clippaste xopen sedi; do
  if (( $+functions[$func] )); then
    pass "$func() definiert"
  else
    fail "$func() nicht definiert"
  fi
done

# sedi: In-place sed Test (plattformunabhängig – sedi abstrahiert BSD/GNU)
typeset test_file=$(mktemp)
echo "foo" > "$test_file"
sedi 's/foo/bar/' "$test_file"
if [[ "$(cat "$test_file")" == "bar" ]]; then
  pass "sedi() funktioniert korrekt"
else
  fail "sedi() hat Datei nicht korrekt bearbeitet"
fi
rm -f "$test_file"

# clip/clippaste: Roundtrip-Test (nur wenn Display vorhanden)
# HINWEIS: Überschreibt den aktuellen Clipboard-Inhalt – unvermeidbar für einen echten Roundtrip-Test.
if [[ "$_PLATFORM_OS" == "macos" ]]; then
  typeset test_str="health-check-$$"
  if echo "$test_str" | clip && [[ "$(clippaste)" == "$test_str" ]]; then
    pass "clip/clippaste Roundtrip erfolgreich"
  else
    warn "clip/clippaste Roundtrip fehlgeschlagen"
  fi
fi

# --- Terminal-Profil (nur macOS) ---
if [[ "$_hc_os" == "macos" ]]; then
section "Terminal.app Profil"

# Profilname dynamisch aus .terminal-Datei ableiten
typeset terminal_file profile_name default_profile startup_profile
terminal_file=$(find "$DOTFILES_DIR/setup" -maxdepth 1 -name "*.terminal" | sort | head -1)
profile_name="${${terminal_file:t}%.terminal}"
[[ -z "$profile_name" ]] && profile_name="catppuccin-mocha"
default_profile=$(defaults read com.apple.Terminal "Default Window Settings" 2>/dev/null || echo "")
startup_profile=$(defaults read com.apple.Terminal "Startup Window Settings" 2>/dev/null || echo "")

if [[ "$default_profile" == "$profile_name" ]]; then
  pass "Standard-Profil: $profile_name"
else
  warn "Standard-Profil ist '$default_profile' (erwartet: $profile_name)"
fi

if [[ "$startup_profile" == "$profile_name" ]]; then
  pass "Startup-Profil: $profile_name"
else
  warn "Startup-Profil ist '$startup_profile' (erwartet: $profile_name)"
fi
fi  # macOS Terminal.app Guard

# --- Starship ---
section "Starship Konfiguration"

# Prüft Symlink (nicht nur Datei!) – erkennt tote Symlinks
# Muster ohne "dotfiles/" → funktioniert unabhängig vom Checkout-Verzeichnis
check_symlink "$HOME/.config/starship/starship.toml" \
  "terminal/.config/starship/starship.toml" \
  "~/.config/starship/starship.toml"

# --- ZSH-Sessions (nur macOS) ---
if [[ "$_hc_os" == "macos" ]]; then
section "ZSH-Sessions"

if [[ -f "$HOME/.zshenv" ]] && grep -q "SHELL_SESSIONS_DISABLE=1" "$HOME/.zshenv" 2>/dev/null; then
  pass "macOS zsh_sessions deaktiviert (SHELL_SESSIONS_DISABLE=1 in ~/.zshenv)"
else
  warn "SHELL_SESSIONS_DISABLE=1 nicht in ~/.zshenv (macOS Session-History aktiv)"
  warn "  → stow -R terminal editor ausführen oder ~/.zshenv manuell erstellen"
fi
fi  # macOS ZSH-Sessions Guard

# --- Catppuccin Theme-Registry ---
section "Catppuccin Theme-Registry"

# Bidirektionale Prüfung der Theme-Registry:
# 1. IST → SOLL: Jede Config mit "catppuccin" muss in theme-style dokumentiert sein
# 2. SOLL → IST: Jeder Eintrag in theme-style muss existierende Config haben
check_theme_registry() {
  local theme_style="$DOTFILES_DIR/terminal/.config/theme-style"
  [[ -f "$theme_style" ]] || { warn "theme-style nicht gefunden"; return 1; }

  # Extrahiere dokumentierte Tools + Pfade aus theme-style
  # Format: #   tool   | config-path | upstream | status
  # Tool-Zeilen: beginnen mit "#   " UND enthalten "|"
  typeset -A documented_paths=()
  local -a documented_tools=()
  while IFS= read -r line; do
    # Nur Zeilen die mit "#   " beginnen UND Pipes enthalten
    [[ "$line" != "#   "*"|"* ]] && continue

    local tool_name="${line##\#}"
    tool_name="${tool_name%%|*}"
    tool_name="${tool_name// /}"
    [[ -z "$tool_name" ]] && continue

    # Extrahiere config-path (zweite Spalte)
    local cfg_path="${line#*|}"
    cfg_path="${cfg_path%%|*}"
    cfg_path="${cfg_path// /}"

    documented_tools+=("$tool_name")
    documented_paths[$tool_name]="$cfg_path"
  done < "$theme_style"

  local has_errors=0

  # ━━━ Richtung 1: IST → SOLL ━━━
  # Prüfe ob alle Config-Dateien mit "catppuccin" dokumentiert sind
  local -a undocumented=()
  while IFS= read -r file; do
    [[ -z "$file" ]] && continue

    local tool=""
    case "$file" in
      */bat/themes/*|*/bat/config)     tool="bat" ;;
      */zsh/*syntax*)                  tool="zsh-syntax" ;;
      *.terminal)                      tool="Terminal.app" ;;
      *.xccolortheme)                  tool="Xcode" ;;
      */theme-style)                  tool="theme-style" ;;
      */docs/*|*/tests/*|*.page.md|*.sh|*.alias) continue ;;
      */.config/*/*)
        tool="${file#*/.config/}"
        tool="${tool%%/*}"
        ;;
    esac

    [[ -z "$tool" ]] && continue

    if ! (( ${documented_tools[(Ie)$tool]} )); then
      undocumented+=("$tool")
      has_errors=1
    fi
  done < <(grep -rlI -E "catppuccin|Catppuccin" "$DOTFILES_DIR" --include="*.yml" --include="*.yaml" --include="*.toml" --include="*.json" --include="*.jsonc" --include="*.theme" --include="*.tmTheme" --include="*.terminal" --include="*.xccolortheme" --include="config" --include="theme-style" 2>/dev/null | grep -v ".git" | grep -v "node_modules")

  # ━━━ Richtung 2: SOLL → IST ━━━
  # Prüfe ob alle dokumentierten Tools auch existieren
  local -a missing_configs=()
  for tool in "${documented_tools[@]}"; do
    local config_path="${documented_paths[$tool]}"
    [[ -z "$config_path" ]] && continue

    # Expandiere Pfad (~ → $HOME, ~/dotfiles → $DOTFILES_DIR)
    local expanded_path="${config_path/#\~\/dotfiles/$DOTFILES_DIR}"
    expanded_path="${expanded_path/#\~/$HOME}"

    # Prüfe ob Pfad existiert (Datei oder Verzeichnis)
    if [[ ! -e "$expanded_path" ]] && [[ ! -d "$expanded_path" ]]; then
      # Bei Glob-Pattern (*) prüfe ob mindestens eine Datei existiert
      if [[ "$expanded_path" == *\** ]]; then
        # Aktiviere Glob-Expansion und prüfe
        setopt local_options nullglob
        local -a glob_matches=($~expanded_path)
        (( ${#glob_matches[@]} == 0 )) && missing_configs+=("$tool → $config_path") && has_errors=1
      else
        missing_configs+=("$tool → $config_path")
        has_errors=1
      fi
    fi
  done

  # ━━━ Ergebnis ausgeben ━━━
  if (( ${#undocumented[@]} > 0 )); then
    fail "Config mit Catppuccin aber nicht in theme-style:"
    for item in "${(@u)undocumented[@]}"; do  # (@u) = unique
      print "       → $item"
    done
    print "       💡 Füge das Tool zu terminal/.config/theme-style hinzu"
  fi

  if (( ${#missing_configs[@]} > 0 )); then
    fail "In theme-style dokumentiert aber Config fehlt:"
    for item in "${missing_configs[@]}"; do
      print "       → $item"
    done
    print "       💡 Entferne veraltete Einträge aus theme-style"
  fi

  if (( has_errors == 0 )); then
    pass "Theme-Registry konsistent (${#documented_tools[@]} Tools, bidirektional geprüft)"
  fi
}

check_theme_registry

# --- Brewfile Status (nur mit Homebrew) ---
if command -v brew >/dev/null 2>&1; then
section "Brewfile Status"

if [[ -n "${HOMEBREW_BUNDLE_FILE:-}" ]] && [[ -f "$HOMEBREW_BUNDLE_FILE" ]]; then
  typeset check_output
  check_output=$(brew bundle check --file="$HOMEBREW_BUNDLE_FILE" --verbose 2>&1)
  typeset check_exit=$?

  if (( check_exit == 0 )); then
    pass "Alle Brewfile-Abhängigkeiten erfüllt"
  elif echo "$check_output" | grep -qE "needs to be installed"; then
    # Unterscheide: "installed or updated" = Update, nur "installed" = fehlend
    typeset missing updated
    # Updates: Zeilen mit "or updated"
    updated=$(echo "$check_output" | grep "or updated" | grep -oE "(Formula|Cask) [^ ]+" | sed 's/Formula //' | sed 's/Cask //' | tr '\n' ' ')
    # Fehlend: Zeilen mit "installed" aber OHNE "or updated"
    missing=$(echo "$check_output" | grep "needs to be installed" | grep -v "or updated" | grep -oE "(Formula|Cask) [^ ]+" | sed 's/Formula //' | sed 's/Cask //' | tr '\n' ' ')

    if [[ -n "$missing" ]]; then
      warn "Brewfile-Pakete fehlen: ${missing}"
      warn "  → brew bundle --file=$HOMEBREW_BUNDLE_FILE"
    fi
    if [[ -n "$updated" ]]; then
      # Updates sind informativ, kein echtes Problem
      pass "Brewfile-Updates verfügbar: ${updated}"
      print "     ${C_DIM}Optional: brew bundle --file=$HOMEBREW_BUNDLE_FILE${C_RESET}"
    fi
  else
    # Echte fehlende Pakete
    warn "Nicht alle Brewfile-Abhängigkeiten installiert"
    warn "  → brew bundle --file=$HOMEBREW_BUNDLE_FILE"
  fi
else
  warn "HOMEBREW_BUNDLE_FILE nicht gesetzt (neu einloggen nach stow)"
fi
fi  # Homebrew Brewfile-Status Guard

# ------------------------------------------------------------
# Zusammenfassung
# ------------------------------------------------------------
print ""
print "${C_OVERLAY0}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
print "${C_MAUVE}📊 ${C_BOLD}Zusammenfassung${C_RESET}"
print "${C_OVERLAY0}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
print ""
print "   ${C_GREEN}✔${C_RESET} Bestanden: ${C_BOLD}$passed${C_RESET}"
print "   ${C_YELLOW}⚠${C_RESET} Warnungen: ${C_BOLD}$warnings${C_RESET}"
print "   ${C_RED}✖${C_RESET} Fehler:    ${C_BOLD}$failed${C_RESET}"

if (( failed > 0 )); then
  print ""
  print "${C_RED}✖ ${C_BOLD}Health Check fehlgeschlagen${C_RESET}"
  print "   ${C_DIM}Behebe die Fehler und führe den Check erneut aus.${C_RESET}"
  exit 1
elif (( warnings > 0 )); then
  print ""
  print "${C_YELLOW}⚠ ${C_BOLD}Health Check mit Warnungen${C_RESET}"
  print "   ${C_DIM}Das Setup funktioniert, aber einige optionale Komponenten fehlen.${C_RESET}"
  exit 0
else
  print ""
  print "${C_GREEN}✔ ${C_BOLD}Health Check erfolgreich${C_RESET}"
  print "   ${C_DIM}Alle Komponenten korrekt installiert.${C_RESET}"
  exit 0
fi
