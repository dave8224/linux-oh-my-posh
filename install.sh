#!/usr/bin/env bash
set -euo pipefail

THEME_SRC="$PWD/themes/dave-tokyonight.omp.json"
THEME_DIR="$HOME/.config/oh-my-posh"
THEME_DST="$THEME_DIR/dave-tokyonight.omp.json"

FONT_DIR="$HOME/.local/share/fonts/JetBrainsMonoNerd"
FONT_ZIP="/tmp/JetBrainsMono.zip"

ALACRITTY_DIR="$HOME/.config/alacritty"
ALACRITTY_CFG="$ALACRITTY_DIR/alacritty.toml"

echo "===== Oh My Posh + Nerd Font Bootstrap ====="
echo

# ------------------------------------------------------------
# 1. Basic prerequisites
# ------------------------------------------------------------

need_cmd() {
    command -v "$1" >/dev/null 2>&1
}

install_prereqs() {
    local missing=()

    need_cmd curl || missing+=("curl")
    need_cmd unzip || missing+=("unzip")
    need_cmd fc-cache || missing+=("fontconfig")

    if [ "${#missing[@]}" -eq 0 ]; then
        echo "✓ Prerequisites present"
        return
    fi

    echo "Installing prerequisites: ${missing[*]}"

    if need_cmd zypper; then
        sudo zypper install -y curl unzip fontconfig
    elif need_cmd pacman; then
        sudo pacman -S --needed --noconfirm curl unzip fontconfig
    elif need_cmd dnf; then
        sudo dnf install -y curl unzip fontconfig
    elif need_cmd apt; then
        sudo apt update
        sudo apt install -y curl unzip fontconfig
    else
        echo "ERROR: unsupported package manager."
        exit 1
    fi
}

install_prereqs

# ------------------------------------------------------------
# 2. Install Oh My Posh
# ------------------------------------------------------------

if need_cmd oh-my-posh; then
    echo "✓ Oh My Posh already installed: $(oh-my-posh version)"
else
    echo "Installing Oh My Posh..."
    curl -s https://ohmyposh.dev/install.sh | bash -s

    export PATH="$HOME/.local/bin:$PATH"

    if ! need_cmd oh-my-posh; then
        echo "ERROR: Oh My Posh install completed but binary not found."
        exit 1
    fi

    echo "✓ Oh My Posh installed: $(oh-my-posh version)"
fi

# ------------------------------------------------------------
# 3. Install exact theme from this repo
# ------------------------------------------------------------

if [ ! -f "$THEME_SRC" ]; then
    echo "ERROR: theme missing:"
    echo "  $THEME_SRC"
    exit 1
fi

mkdir -p "$THEME_DIR"
cp "$THEME_SRC" "$THEME_DST"

# Detect distro and set the OS icon in the installed theme.
DISTRO_ID=""
DISTRO_LIKE=""

if [ -r /etc/os-release ]; then
    . /etc/os-release
    DISTRO_ID="${ID:-}"
    DISTRO_LIKE="${ID_LIKE:-}"
fi

case "$DISTRO_ID" in
    nobara|fedora)
        OS_ICON=""
        ;;
    opensuse*|suse|sles)
        OS_ICON=""
        ;;
    arch|cachyos|endeavouros|garuda|manjaro)
        OS_ICON=""
        ;;
    ubuntu|pop|linuxmint)
        OS_ICON=""
        ;;
    debian)
        OS_ICON=""
        ;;
    *)
        case "$DISTRO_LIKE" in
            *fedora*|*rhel*)
                OS_ICON=""
                ;;
            *arch*)
                OS_ICON=""
                ;;
            *ubuntu*)
                OS_ICON=""
                ;;
            *debian*)
                OS_ICON=""
                ;;
            *suse*)
                OS_ICON=""
                ;;
            *)
                OS_ICON=""
                ;;
        esac
        ;;
esac

python3 - "$THEME_DST" "$OS_ICON" <<'PYICON'
import json
import sys

path, icon = sys.argv[1], sys.argv[2]

with open(path, "r", encoding="utf-8") as f:
    data = json.load(f)

for block in data.get("blocks", []):
    for segment in block.get("segments", []):
        if segment.get("type") == "os":
            segment["template"] = f" {icon} "

with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
    f.write("\n")
PYICON

echo "✓ Theme installed:"
echo "  $THEME_DST"
echo "✓ Distro icon: $OS_ICON (${DISTRO_ID:-unknown})"

# ------------------------------------------------------------
# 4. Install JetBrainsMono Nerd Font if missing
# ------------------------------------------------------------

if grep -qi 'JetBrainsMono Nerd Font' < <(fc-list); then
    echo "✓ JetBrainsMono Nerd Font already installed"
else
    echo "Installing JetBrainsMono Nerd Font..."

    rm -rf "$FONT_DIR"
    mkdir -p "$FONT_DIR"

    curl -fL \
      https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip \
      -o "$FONT_ZIP"

    unzip -oq "$FONT_ZIP" -d "$FONT_DIR"

    fc-cache -f

    if ! grep -qi 'JetBrainsMono Nerd Font' < <(fc-list); then
        echo "ERROR: Nerd Font files were installed but Fontconfig cannot see them."
        exit 1
    fi

    echo "✓ JetBrainsMono Nerd Font installed"
fi

# ------------------------------------------------------------
# 5. Bash integration
# ------------------------------------------------------------

BASHRC="$HOME/.bashrc"
POSH_LINE='eval "$(oh-my-posh init bash --config ~/.config/oh-my-posh/dave-tokyonight.omp.json)"'

touch "$BASHRC"

if grep -Fqx "$POSH_LINE" "$BASHRC"; then
    echo "✓ Bash integration already present"
else
    {
        echo
        echo "# Oh My Posh"
        echo "$POSH_LINE"
    } >> "$BASHRC"

    echo "✓ Bash integration added"
fi

# ------------------------------------------------------------
# 6. Alacritty integration
# ------------------------------------------------------------

if need_cmd alacritty; then
    mkdir -p "$ALACRITTY_DIR"

    if [ ! -f "$ALACRITTY_CFG" ]; then
        cat > "$ALACRITTY_CFG" <<'ALACRITTY'
[window]
opacity = 0.90
padding = { x = 10, y = 10 }

[font]
normal = { family = "JetBrainsMono Nerd Font", style = "Regular" }
bold = { family = "JetBrainsMono Nerd Font", style = "Bold" }
italic = { family = "JetBrainsMono Nerd Font", style = "Italic" }
bold_italic = { family = "JetBrainsMono Nerd Font", style = "Bold Italic" }
size = 10.0
ALACRITTY

        echo "✓ Created Alacritty config"
    else
        python3 <<'PY'
from pathlib import Path

p = Path.home() / ".config/alacritty/alacritty.toml"
s = p.read_text()

if "[font]" not in s:
    s += '''

[font]
normal = { family = "JetBrainsMono Nerd Font", style = "Regular" }
bold = { family = "JetBrainsMono Nerd Font", style = "Bold" }
italic = { family = "JetBrainsMono Nerd Font", style = "Italic" }
bold_italic = { family = "JetBrainsMono Nerd Font", style = "Bold Italic" }
size = 10.0
'''

if "[window]" not in s:
    s = '''[window]
opacity = 0.90
padding = { x = 10, y = 10 }

''' + s

p.write_text(s)
PY

        echo "✓ Existing Alacritty config preserved"
        echo "  Added missing font/window sections only"
    fi
else
    echo "ℹ Alacritty not installed; skipping terminal config"
fi

# ------------------------------------------------------------
# 7. Verification
# ------------------------------------------------------------

echo
echo "===== Verification ====="

echo -n "Oh My Posh: "
oh-my-posh version

echo -n "Theme: "
test -f "$THEME_DST" && echo "OK"

echo -n "Nerd Font: "
if grep -qi 'JetBrainsMono Nerd Font' < <(fc-list); then
    echo "OK"
else
    echo "FAILED"
    exit 1
fi

echo -n "Font match: "
fc-match "JetBrainsMono Nerd Font" | head -1

echo -n "Bash init: "
grep -Fqx "$POSH_LINE" "$BASHRC" && echo "OK" || echo "FAILED"

if need_cmd alacritty; then
    echo -n "Alacritty config: "
    grep -q 'JetBrainsMono Nerd Font' "$ALACRITTY_CFG" && echo "OK" || echo "CHECK MANUALLY"
fi

echo
echo "===== Done ====="
echo "Close and reopen your terminal, or run:"
echo
echo "  source ~/.bashrc"
