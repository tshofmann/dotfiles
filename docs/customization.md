# ⚙️ Konfiguration

Diese Anleitung erklärt, wie du die dotfiles an deine Bedürfnisse anpassen kannst.

---

## Catppuccin Mocha Theme

Das gesamte Setup verwendet [Catppuccin Mocha](https://catppuccin.com/) als einheitliches Farbschema. Dies gewährleistet ein konsistentes Erscheinungsbild über alle Tools hinweg.

### Konfigurierte Tools

| Tool | Theme-Datei | Status |
| ---- | ----------- | ------ |
| **bat** | `terminal/.config/bat/themes/` | Via Stow verlinkt (+ Cache-Build) |
| **btop** | `terminal/.config/btop/themes/` | Via Stow verlinkt |
| **eza** | `terminal/.config/eza/theme.yml` | Via Stow verlinkt |
| **fastfetch** | `terminal/.config/fastfetch/config.jsonc` | Via Stow verlinkt |
| **fzf** | `terminal/.config/fzf/config` | Farben in Config-Datei (via Stow) |
| **jq** | `terminal/.config/theme-style` | Via Stow verlinkt |
| **kitty** | `terminal/.config/kitty/current-theme.conf` | Via Stow verlinkt |
| **lazygit** | `terminal/.config/lazygit/config.yml` | Via Stow verlinkt |
| **starship** | `terminal/.config/starship/starship.toml` | Via Stow verlinkt |
| **tealdeer** | `terminal/.config/tealdeer/config.toml` | Via Stow verlinkt |
| **yazi** | `terminal/.config/yazi/theme.toml` | Via Stow verlinkt |
| **zsh-syntax-highlighting** | `terminal/.config/zsh/catppuccin_mocha-*` | Via Stow verlinkt |
| **Terminal.app** | `setup/catppuccin-mocha.terminal` | Via Bootstrap importiert + als Standard gesetzt |
| **Xcode** | `setup/Catppuccin Mocha.xccolortheme` | Via Bootstrap kopiert (manuelle Aktivierung) |

### Xcode Theme aktivieren

Das Catppuccin Mocha Theme für Xcode wird automatisch vom Bootstrap-Skript nach `~/Library/Developer/Xcode/UserData/FontAndColorThemes/` kopiert, muss aber einmalig manuell aktiviert werden:

1. **Xcode** öffnen
2. **Xcode** → **Settings** (⌘,)
3. Tab **Themes** auswählen
4. **Catppuccin Mocha** anklicken

> **Hinweis:** Änderungen am Original in `setup/Catppuccin Mocha.xccolortheme` werden bei erneutem Bootstrap-Lauf übernommen.

### Farbpalette (Catppuccin Mocha)

Alle verfügbaren Shell-Farbvariablen aus `~/.config/theme-style`:

| Farbe | Hex | Variable |
| ----- | --- | -------- |
| Rosewater | `#F5E0DC` | `C_ROSEWATER` |
| Flamingo | `#F2CDCD` | `C_FLAMINGO` |
| Pink | `#F5C2E7` | `C_PINK` |
| Mauve | `#CBA6F7` | `C_MAUVE` |
| Red | `#F38BA8` | `C_RED` |
| Maroon | `#EBA0AC` | `C_MAROON` |
| Peach | `#FAB387` | `C_PEACH` |
| Yellow | `#F9E2AF` | `C_YELLOW` |
| Green | `#A6E3A1` | `C_GREEN` |
| Teal | `#94E2D5` | `C_TEAL` |
| Sky | `#89DCEB` | `C_SKY` |
| Sapphire | `#74C7EC` | `C_SAPPHIRE` |
| Blue | `#89B4FA` | `C_BLUE` |
| Lavender | `#B4BEFE` | `C_LAVENDER` |
| Text | `#CDD6F4` | `C_TEXT` |
| Subtext1 | `#BAC2DE` | `C_SUBTEXT1` |
| Subtext0 | `#A6ADC8` | `C_SUBTEXT0` |
| Overlay2 | `#9399B2` | `C_OVERLAY2` |
| Overlay1 | `#7F849C` | `C_OVERLAY1` |
| Overlay0 | `#6C7086` | `C_OVERLAY0` |
| Surface2 | `#585B70` | `C_SURFACE2` |
| Surface1 | `#45475A` | `C_SURFACE1` |
| Surface0 | `#313244` | `C_SURFACE0` |
| Base | `#1E1E2E` | `C_BASE` |
| Mantle | `#181825` | `C_MANTLE` |
| Crust | `#11111B` | `C_CRUST` |

> **Text-Styles:** Zusätzlich zu den Farben stehen `C_RESET`, `C_BOLD`, `C_DIM`, `C_ITALIC` und `C_UNDERLINE` zur Verfügung.
>
> **Verwendung in Skripten:**

```zsh
source ~/.config/theme-style
echo "${C_GREEN}Erfolg${C_RESET}"
echo "${C_BOLD}Fett${C_RESET}"
```

Vollständige Palette: [catppuccin.com/palette](https://catppuccin.com/palette)

---

## Starship-Prompt

Die [Starship](https://starship.rs/) Prompt-Konfiguration ist versioniert und wird via Stow nach `~/.config/starship/starship.toml` verlinkt.

> **Hinweis:** Starship sucht standardmäßig nach `~/.config/starship.toml` (ohne Unterordner). Um die "Ein Tool = Ein Ordner"-Konvention einzuhalten, setzen wir `STARSHIP_CONFIG` in `~/.zshenv`:
>
> ```zsh
> export STARSHIP_CONFIG="$XDG_CONFIG_HOME/starship/starship.toml"
> ```

### Konfiguration

Die Datei `terminal/.config/starship/starship.toml` enthält das `catppuccin-powerline` Preset aus dem [catppuccin/starship](https://github.com/catppuccin/starship) Repository.

### Anpassungen

Du kannst die Starship-Konfiguration direkt in `terminal/.config/starship/starship.toml` bearbeiten:

```zsh
# Datei öffnen
$EDITOR ~/dotfiles/terminal/.config/starship/starship.toml
```

### Preset wechseln

Falls du ein anderes Preset verwenden möchtest:

```zsh
# Verfügbare Presets auflisten
starship preset --list

# Neues Preset generieren (überschreibt die Datei)
starship preset <preset-name> -o ~/dotfiles/terminal/.config/starship/starship.toml

# Änderung committen
cd ~/dotfiles
git add terminal/.config/starship/starship.toml
git commit -m "Starship: <preset-name> Preset"
```

Presets online: [starship.rs/presets](https://starship.rs/presets/)

---

<a name="schriftart-wechseln"></a>

## Schriftart wechseln

Das Terminal-Profil, der Nerd Font und das Starship-Prompt sind eng gekoppelt. Wenn du die Schriftart ändern möchtest, musst du alle drei Komponenten berücksichtigen.
> **⚠️ Wichtig:** Die Datei `catppuccin-mocha.terminal` enthält binäre NSArchiver-Daten. **Niemals direkt editieren** – nur über die Terminal.app GUI ändern und neu exportieren.

### Voraussetzung

Bei Starship-Konfigurationen mit Powerline-Symbolen (wie dem `catppuccin-powerline` Preset) muss die Schriftart ein **Nerd Font** sein. Nerd Fonts enthalten zusätzliche Icons und Symbole, die für Powerline-Prompts benötigt werden.

### Schritt 1: Neuen Nerd Font installieren

```zsh
# Verfügbare Nerd Fonts suchen
brew search nerd-font

# Beispiel: Nerd Font installieren (z.B. font-jetbrains-mono-nerd-font)
brew install --cask font-jetbrains-mono-nerd-font
```

### Schritt 2: Terminal.app Profil anpassen

1. Terminal.app öffnen
2. **Terminal** → **Einstellungen** → **Profile** → **catppuccin-mocha**
3. Tab **Text** → **Schrift** → **Ändern…**
4. Neuen Nerd Font auswählen (z.B. "JetBrainsMono Nerd Font Mono")
5. Größe anpassen (empfohlen: 13-14pt)
6. Profil exportieren: **Einstellungen** → **Profile** → **Zahnrad** → **"...exportieren"**

### Schritt 3: Exportiertes Profil ins Repository

```zsh
# Optional: Altes Profil sichern
mv ~/dotfiles/setup/*.terminal ~/dotfiles/setup/old-profile.terminal.bak

# Neues Profil verschieben
mv ~/Downloads/<profilname>.terminal ~/dotfiles/setup/

# Backup entfernen (wenn nicht mehr benötigt)
rm ~/dotfiles/setup/*.bak

# Änderung committen
cd ~/dotfiles
git add setup/*.terminal
git commit -m "Terminal-Profil: <Neuer Font Name>"
```

> **Hinweis:** Der Dateiname ist frei wählbar – bootstrap.sh findet automatisch die alphabetisch erste `.terminal`-Datei in `setup/`. Bei mehreren Dateien erscheint eine Warnung.

---

## Aliase anpassen

### Wie Aliase geladen werden

Die `.zshrc` lädt beim Start alle `.alias`-Dateien aus `~/.config/alias/` automatisch in **alphabetischer Reihenfolge**:

```zsh
for alias_file in "$HOME/.config/alias"/*.alias(N-.on); do
    source "$alias_file"
done
```

Jede `.alias`-Datei repräsentiert ein Tool und beginnt mit einem Guard, der prüft ob das Tool installiert ist. Fehlt das Tool, wird die Datei übersprungen.

### Eigene Aliase hinzufügen

Erstelle eine neue Datei in `terminal/.config/alias/`:

```zsh
# terminal/.config/alias/custom.alias

# Guard: Diese Datei hat keine Tool-Abhängigkeit
# Wird immer geladen

# Meine Shortcuts
alias projects='cd ~/Projects'
alias dotfiles='cd ~/dotfiles'
```

### Bestehende Aliase überschreiben

Aliase werden in alphabetischer Reihenfolge geladen. Um einen bestehenden Alias zu überschreiben, erstelle eine Datei die **nach** der Original-Datei geladen wird:

```zsh
# terminal/.config/alias/zzz-overrides.alias

# ls ohne Icons (falls eza-Icons stören)
alias ls='eza --no-icons'
```

---

## fzf anpassen

### Globale Optionen

Die fzf-Konfiguration liegt in `terminal/.config/fzf/config`:

```zsh
# Catppuccin Mocha Farben (bereits konfiguriert)
--color=bg+:#313244,spinner:#F5E0DC,hl:#F38BA8
--color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC
--color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8
--color=selected-bg:#45475A
--color=border:#6C7086,label:#CDD6F4
--color=header:italic
--color=prompt:bold

# Layout (Auszug)
--height=~50%
--layout=reverse
--border=rounded
```

### Keybindings ändern

Shell-Keybindings für fzf werden in `terminal/.config/fzf/init.zsh` definiert:

```zsh
# Ctrl+X Prefix für dotfiles-Keybindings
bindkey '^X1' fzf-history-widget         # Ctrl+X 1 = History
bindkey '^X2' fzf-file-widget            # Ctrl+X 2 = Dateien
bindkey '^X3' fzf-cd-widget              # Ctrl+X 3 = Verzeichnisse
```

---

## Weitere Anpassungen

| Was | Wo | Format |
| --- | -- | ------ |
| bat Theme | `~/.config/bat/config` | `--theme="..."` |
| btop Einstellungen | `~/.config/btop/btop.conf` | Konfig-Datei |
| fd Ignore-Patterns | `~/.config/fd/ignore` | Glob-Patterns |
| fastfetch Modules | `~/.config/fastfetch/config.jsonc` | JSONC |
| kitty Terminal | `~/.config/kitty/kitty.conf` | Konfig-Datei |
| lazygit Keybindings | `~/.config/lazygit/config.yml` | YAML |
| ripgrep Optionen | `~/.config/ripgrep/config` | CLI-Flags |
| tealdeer Farben | `~/.config/tealdeer/config.toml` | TOML |
| yazi File Manager | `~/.config/yazi/yazi.toml` | TOML |

---

## ZSH-Ladereihenfolge

```text
.zshenv        # Immer (Umgebungsvariablen)
    │
    ├── Login-Shell?
    │       │
    │       └── .zprofile (DOTFILES_DIR, Homebrew)
    │
    └── Interactive?
            │
            └── .zshrc (Aliase, Prompt, Keybindings)
                    │
                    └── .zlogin (Background-Tasks)
```

| Datei | Wann geladen | Verwendung |
| ----- | ------------ | ---------- |
| `.zshenv` | Immer | Umgebungsvariablen (XDG, EDITOR, VISUAL) |
| `.zprofile` | Login-Shell | DOTFILES_DIR, Homebrew (einmalig) |
| `.zshrc` | Interaktiv | Aliase, Prompt, Keybindings |
| `.zlogin` | Nach Login | Background-Tasks nach `.zshrc` |
