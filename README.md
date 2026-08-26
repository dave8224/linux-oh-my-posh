# linux-oh-my-posh

Portable setup for my Linux Oh My Posh environment.

## What this installs

- Oh My Posh
- JetBrainsMono Nerd Font
- Exact `dave-tokyonight.omp.json` theme
- Bash initialization
- Alacritty Nerd Font integration
- Alacritty opacity and padding on fresh configs

## Supported package managers

- zypper
- pacman
- dnf
- apt

## Install

```bash
git clone https://github.com/dave8224/linux-oh-my-posh.git
cd linux-oh-my-posh
./install.sh
```

## What the installer checks

It verifies:

- curl
- unzip
- fontconfig
- Oh My Posh
- JetBrainsMono Nerd Font
- dave-tokyonight theme
- Bash integration
- Alacritty Nerd Font integration

If the Nerd Font is missing, it is downloaded and installed automatically.

If Oh My Posh is missing, the official installer is used.

## Theme

The installer uses:

`themes/dave-tokyonight.omp.json`

The theme is never recreated or approximated.

## Troubleshooting

If the icons look wrong, check the Nerd Font first:

```bash
fc-match "JetBrainsMono Nerd Font"
```

