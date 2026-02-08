#!/usr/bin/env zsh
# ============================================================
# apt-packages.sh - Brewfile-gesteuerte Paketinstallation (32-bit ARM)
# ============================================================
# Zweck       : Installiert CLI-Tools via apt/cargo auf Systemen ohne Homebrew
# Pfad        : setup/modules/apt-packages.sh
# Benötigt    : _core.sh, validation.sh
# Plattform   : Linux (Debian/Raspbian, armv6/armv7)
#
# STEP        : APT-Pakete | Installiert verfügbare CLI-Tools via apt | ⚠️ Warnung
# STEP        : Cargo-Tools | Installiert fehlende Tools via cargo | ⚠️ Warnung
# STEP        : NPM-Tools | Installiert npm-Pakete (falls Node vorhanden) | ⚠️ Warnung
# STEP        : Binary-Symlinks | Erstellt Symlinks für abweichende Binary-Namen | ⚠️ Warnung
# ============================================================
# Architektur:
#   Homebrew/Linuxbrew unterstützt kein 32-bit ARM (armv6/armv7).
#   Dieses Modul ersetzt homebrew.sh auf alten Raspberry Pis.
#
#   SINGLE SOURCE OF TRUTH: setup/Brewfile
#   Das Brewfile wird dynamisch geparst. Die Mapping-Tabelle
#   BREW_TO_ALT ordnet jeder Formula eine Installationsmethode zu.
#   Neue Formulae im Brewfile ohne Mapping → automatische Warnung.
#
# Installationsmethoden (BREW_TO_ALT Werte):
#   apt:NAME         → sudo apt-get install NAME
#   cargo:CRATE      → cargo install CRATE
#   npm:PACKAGE      → npm install -g PACKAGE
#   skip             → macOS-exklusiv oder ZSH-Plugin (separat behandelt)
#
# Binary-Namen-Konflikte:
#   apt: fd-find → Binary heißt "fdfind" → Symlink in ~/.local/bin
# ============================================================

# Guard: Core muss geladen sein
[[ -z "${_BOOTSTRAP_CORE_LOADED:-}" ]] && {
    echo "FEHLER: _core.sh muss vor apt-packages.sh geladen werden" >&2
    return 1
}

# Guard: Nur auf Debian-basierten Systemen mit 32-bit ARM
if ! is_debian || [[ "$PLATFORM_ARCH" != armv* ]]; then
    return 0
fi

# ------------------------------------------------------------
# Mapping: Brew-Formula → Installationsmethode
# ------------------------------------------------------------
# SYNC-CHECK: Bei neuer Formula im Brewfile hier Eintrag ergänzen.
#             Fehlende Einträge werden beim Bootstrap als Warnung angezeigt.
typeset -A BREW_TO_ALT=(
    # apt-Pakete (Debian Trixie armhf)
    [bat]=apt:bat
    [btop]=apt:btop
    [eza]=apt:eza
    [fastfetch]=apt:fastfetch
    [fd]=apt:fd-find
    [ffmpeg]=apt:ffmpeg
    [fzf]=apt:fzf
    [gh]=apt:gh               # Erst ab Debian Trixie in offiziellen Repos
    [imagemagick]=apt:imagemagick
    [jq]=apt:jq
    [lazygit]=apt:lazygit
    [poppler]=apt:poppler-utils
    [ripgrep]=apt:ripgrep
    [sevenzip]=apt:7zip
    [shellcheck]=apt:shellcheck
    [starship]=apt:starship
    [stow]=apt:stow
    [tealdeer]=apt:tealdeer
    [zoxide]=apt:zoxide

    # ZSH-Plugins (apt, werden separat vom Plugin-Pfad-Fallback genutzt)
    [zsh-autosuggestions]=apt:zsh-autosuggestions
    [zsh-syntax-highlighting]=apt:zsh-syntax-highlighting

    # Cargo (kein apt für armhf)
    [resvg]=cargo:resvg
    [yazi]=cargo:yazi-fm

    # npm
    [markdownlint-cli2]=npm:markdownlint-cli2

    # macOS-exklusiv (auf Linux überspringen)
    [mas]=skip
)

# Zusätzliche Cargo-Crates die neben dem Haupt-Crate installiert werden
# yazi braucht zwei Crates: yazi-fm (Hauptprogramm) und yazi-cli (ya Helper)
typeset -A CARGO_EXTRA_CRATES=(
    [yazi-fm]=yazi-cli
)

# Binary-Name-Korrekturen: apt-Paketname → erwarteter Binary-Name
# Wenn der apt-Binary-Name vom erwarteten Namen abweicht
typeset -A BINARY_SYMLINKS=(
    [fd-find]=fd
)

# Mapping: Brew-Formula → Binary-Name (falls abweichend)
# Wie in health-check.sh get_tools_from_brewfile()
typeset -A BREW_TO_BINARY=(
    [ripgrep]=rg
    [tealdeer]=tldr
    [sevenzip]=7zz
    [poppler]=pdftotext
    [imagemagick]=magick
)

# ------------------------------------------------------------
# Brewfile-Parser
# ------------------------------------------------------------
# Liest brew-Formulae aus Brewfile (identisch mit health-check.sh)
_parse_brewfile() {
    local brewfile="${SCRIPT_DIR}/Brewfile"
    [[ -f "$brewfile" ]] || {
        err "Brewfile nicht gefunden: $brewfile"
        return 1
    }

    grep -E '^brew "[^"]+"' "$brewfile" | sed 's/brew "\([^"]*\)".*/\1/'
}

# ------------------------------------------------------------
# APT-Installation
# ------------------------------------------------------------
_install_apt_packages() {
    CURRENT_STEP="APT-Pakete"
    local -a apt_packages=()

    # Aus Mapping alle apt:-Einträge sammeln
    for formula in "${(@k)BREW_TO_ALT}"; do
        local method="${BREW_TO_ALT[$formula]}"
        [[ "$method" == apt:* ]] || continue
        local pkg="${method#apt:}"
        if ! dpkg -s "$pkg" &>/dev/null; then
            apt_packages+=("$pkg")
        fi
    done

    if (( ${#apt_packages[@]} == 0 )); then
        ok "Alle APT-Pakete bereits installiert"
        return 0
    fi

    log "Aktualisiere Paketlisten..."
    sudo apt-get update -qq || {
        warn "apt-get update fehlgeschlagen – versuche trotzdem zu installieren"
    }

    log "Installiere ${#apt_packages[@]} Pakete via apt..."
    if sudo apt-get install -y "${apt_packages[@]}"; then
        ok "${#apt_packages[@]} APT-Pakete installiert"
    else
        warn "Einige APT-Pakete konnten nicht installiert werden"
        warn "Manuell prüfen: sudo apt-get install ${apt_packages[*]}"
    fi

    return 0
}

# ------------------------------------------------------------
# Cargo-Installation
# ------------------------------------------------------------
_install_cargo_tools() {
    CURRENT_STEP="Cargo-Tools"

    # Sammle fehlende Cargo-Tools aus Mapping
    local -a missing_crates=()
    for formula in "${(@k)BREW_TO_ALT}"; do
        local method="${BREW_TO_ALT[$formula]}"
        [[ "$method" == cargo:* ]] || continue
        local crate="${method#cargo:}"
        local binary="${BREW_TO_BINARY[$formula]:-$formula}"

        if ! command -v "$binary" >/dev/null 2>&1; then
            missing_crates+=("$crate")
            # Zusätzliche Crates (z.B. yazi-cli neben yazi-fm)
            [[ -n "${CARGO_EXTRA_CRATES[$crate]:-}" ]] && \
                missing_crates+=("${CARGO_EXTRA_CRATES[$crate]}")
        fi
    done

    if (( ${#missing_crates[@]} == 0 )); then
        ok "Alle Cargo-Tools bereits installiert"
        return 0
    fi

    # Rust/Cargo prüfen oder installieren
    if ! command -v cargo >/dev/null 2>&1; then
        log "Rust-Toolchain nicht gefunden – installiere via rustup..."
        if curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path; then
            source "$HOME/.cargo/env"
            ok "Rust-Toolchain installiert"
        else
            warn "Rust-Installation fehlgeschlagen"
            warn "Manuell: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
            for crate in "${missing_crates[@]}"; do
                warn "  Dann: cargo install $crate"
            done
            return 0
        fi
    else
        ok "Rust-Toolchain vorhanden: $(rustc --version 2>/dev/null | head -1)"
    fi

    # Speicher-basierte Cargo-Limits für schwache Hardware
    # RPi Zero/1: 512 MB RAM → OOM bei paralleler Kompilierung
    # RPi 2/3 (32-bit OS): 1 GB RAM → knapp bei großen Crates
    local total_mem_mb=0
    if [[ -r /proc/meminfo ]]; then
        local mem_kb
        mem_kb=$(awk '/^MemTotal:/ { print $2 }' /proc/meminfo)
        total_mem_mb=$(( mem_kb / 1024 ))
    fi

    local cargo_jobs=""
    local cargo_rustflags=""
    if (( total_mem_mb > 0 && total_mem_mb <= 1024 )); then
        # Sequenzielle Kompilierung: ein Job, eine Codegen-Unit
        cargo_jobs=1
        cargo_rustflags="-C codegen-units=1"
        warn "RAM: ${total_mem_mb} MB → setze CARGO_BUILD_JOBS=1, codegen-units=1"

        # Swap-Prüfung: ohne Swap schlägt starship/yazi auf ≤512 MB fehl
        local swap_kb
        swap_kb=$(awk '/^SwapTotal:/ { print $2 }' /proc/meminfo)
        if (( swap_kb < 524288 )); then
            warn "Swap: $(( swap_kb / 1024 )) MB – empfohlen: mindestens 512 MB"
            warn "  sudo fallocate -l 512M /swapfile && sudo chmod 600 /swapfile"
            warn "  sudo mkswap /swapfile && sudo swapon /swapfile"
        fi
    fi

    warn "Cargo-Kompilierung auf 32-bit ARM ist langsam (je Tool 5-30 Min)"
    for crate in "${missing_crates[@]}"; do
        log "Installiere $crate via cargo..."
        if ${cargo_jobs:+CARGO_BUILD_JOBS=$cargo_jobs} \
           RUSTFLAGS="${cargo_rustflags:+$cargo_rustflags }${RUSTFLAGS:-}" \
           cargo install "$crate"; then
            ok "$crate installiert via cargo"
        else
            warn "$crate: cargo install fehlgeschlagen"
        fi
    done

    return 0
}

# ------------------------------------------------------------
# NPM-Installation
# ------------------------------------------------------------
_install_npm_tools() {
    CURRENT_STEP="NPM-Tools"

    local -a missing_npms=()
    for formula in "${(@k)BREW_TO_ALT}"; do
        local method="${BREW_TO_ALT[$formula]}"
        [[ "$method" == npm:* ]] || continue
        local pkg="${method#npm:}"

        command -v "$pkg" >/dev/null 2>&1 && continue
        missing_npms+=("$pkg")
    done

    if (( ${#missing_npms[@]} == 0 )); then
        return 0
    fi

    if ! command -v npm >/dev/null 2>&1; then
        warn "npm nicht verfügbar – folgende Pakete manuell installieren:"
        warn "  sudo apt-get install nodejs npm"
        for pkg in "${missing_npms[@]}"; do
            warn "  npm install -g $pkg"
        done
        return 0
    fi

    # npm-Prefix auf ~/.local setzen, damit globale Pakete ohne sudo
    # in ~/.local/bin landen (bereits im PATH)
    npm config set prefix "$HOME/.local" 2>/dev/null

    for pkg in "${missing_npms[@]}"; do
        log "Installiere $pkg via npm..."
        if npm install -g "$pkg" 2>&1; then
            ok "$pkg installiert via npm"
        else
            warn "$pkg: npm install fehlgeschlagen"
        fi
    done

    return 0
}

# ------------------------------------------------------------
# Binary-Symlinks (apt-Namen → erwartete Namen)
# ------------------------------------------------------------
_create_binary_symlinks() {
    CURRENT_STEP="Binary-Symlinks"

    local bin_dir="$HOME/.local/bin"
    mkdir -p "$bin_dir"

    for apt_pkg expected_name in "${(@kv)BINARY_SYMLINKS}"; do
        # apt-Binary-Name: für fd-find ist es "fdfind"
        local apt_binary="${apt_pkg//-/}"  # fd-find → fdfind
        if command -v "$apt_binary" >/dev/null 2>&1 && ! command -v "$expected_name" >/dev/null 2>&1; then
            ln -sf "$(command -v "$apt_binary")" "$bin_dir/$expected_name"
            ok "Symlink: $expected_name → $apt_binary"
        fi
    done

    # Sicherstellen dass ~/.local/bin im PATH ist
    if [[ ":$PATH:" != *":$bin_dir:"* ]]; then
        export PATH="$bin_dir:$PATH"
        warn "$bin_dir zum PATH hinzugefügt (nur diese Session)"
    fi

    return 0
}

# ------------------------------------------------------------
# Drift-Erkennung: Brewfile vs. Mapping
# ------------------------------------------------------------
_check_mapping_coverage() {
    CURRENT_STEP="Mapping-Prüfung"

    local -a unmapped=()
    while IFS= read -r formula; do
        [[ -z "$formula" ]] && continue
        if [[ -z "${BREW_TO_ALT[$formula]+x}" ]]; then
            unmapped+=("$formula")
        fi
    done < <(_parse_brewfile)

    if (( ${#unmapped[@]} > 0 )); then
        warn "Brewfile enthält ${#unmapped[@]} Formula(e) ohne Mapping in apt-packages.sh:"
        for f in "${unmapped[@]}"; do
            warn "  $f → Eintrag in BREW_TO_ALT ergänzen"
        done
    fi
}

# ------------------------------------------------------------
# Haupt-Setup-Funktion
# ------------------------------------------------------------
setup_apt_packages() {
    section "APT-Pakete (32-bit ARM)"

    # Drift-Erkennung zuerst (warnt bei neuen Formulae ohne Mapping)
    _check_mapping_coverage

    _install_apt_packages
    _create_binary_symlinks
    _install_cargo_tools
    _install_npm_tools

    return 0
}
