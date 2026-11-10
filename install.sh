#!/bin/bash
# Sets up this Mac from scratch: apps, tools and every config in ~/.config.
#
#   git clone https://github.com/Uzalov-Gamid/houston.git ~/.config
#   ~/.config/install.sh
#
# Safe to re-run: every step skips what is already done.
set -euo pipefail

CONFIG="$HOME/.config"
log() { printf '\033[36m==>\033[0m %s\n' "$1"; }

# 1. Apple's command line tools (git, clang, make — SketchyBar builds a helper)
if ! xcode-select -p >/dev/null 2>&1; then
  log "Installing Command Line Tools (a system dialog will open)..."
  xcode-select --install
  read -rp "Press Enter when the Command Line Tools installation has finished..."
fi

# 2. Homebrew
if ! command -v brew >/dev/null 2>&1; then
  log "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv)"

# 3. Everything from the Brewfile (App Store apps need you signed in to the App Store)
log "Installing apps and tools from Brewfile..."
brew bundle --file="$CONFIG/Brewfile" || log "Some Brewfile items failed — re-run later: brew bundle --file=$CONFIG/Brewfile"

# 4. npm tools
log "Installing npm tools..."
npm install -g @ticktick/ticktick-cli @sqltools/formatter \
  @microsoft/compose-language-service @postgrestools/postgrestools @ansible/ansible-language-server

# 4b. uv tools: SQL client and the nginx language server
log "Installing uv tools..."
uv tool install 'harlequin[postgres]'
uv tool install nginx-language-server

# 4c. Postgres: start it at login, a database named after you (psql with no flags)
log "Starting PostgreSQL..."
brew services start postgresql@18
sleep 3
createdb "$USER" 2>/dev/null || true

# 5. Personal Python libraries, into Homebrew's python3 (user site)
log "Installing Python libraries..."
/opt/homebrew/bin/python3 -m pip install --user --break-system-packages -q -r "$CONFIG/python/requirements.txt"

# 6. SbarLua — the Lua module SketchyBar's config is written with
if [ ! -f "$HOME/.local/share/sketchybar_lua/sketchybar.so" ]; then
  log "Building SbarLua..."
  tmp=$(mktemp -d)
  git clone --depth 1 https://github.com/FelixKratz/SbarLua.git "$tmp/SbarLua"
  (cd "$tmp/SbarLua" && make install)
  rm -rf "$tmp"
fi

# 6b. input-source: switches the keyboard to English when Ghostty gets focus
#     (called by aerospace/ghostty-en.sh)
mkdir -p "$HOME/.local/bin"
swiftc -O "$CONFIG/aerospace/input-source.swift" -o "$HOME/.local/bin/input-source"

# 6c. git name and e-mail are kept out of the repo (git/identity, not tracked)
if [ ! -f "$CONFIG/git/identity" ]; then
  read -rp "Git name: " git_name
  read -rp "Git e-mail: " git_email
  printf '[user]\n\tname = %s\n\temail = %s\n' "$git_name" "$git_email" >"$CONFIG/git/identity"
fi

# 7. zsh reads its config from ~/.config/zsh
if [ ! -f "$HOME/.zshenv" ]; then
  echo 'export ZDOTDIR="$HOME/.config/zsh"' >"$HOME/.zshenv"
fi

# 8. fish as the login shell + its plugins (Tide prompt)
FISH=/opt/homebrew/bin/fish
if ! grep -qx "$FISH" /etc/shells; then
  log "Allowing fish as a login shell (asks for your password)..."
  echo "$FISH" | sudo tee -a /etc/shells >/dev/null
fi
if [ "$(dscl . -read "$HOME" UserShell | awk '{print $2}')" != "$FISH" ]; then
  chsh -s "$FISH"
fi
log "Installing fish plugins..."
"$FISH" -c 'type -q fisher; or begin; curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source; end; fisher update'

# 9. tmux plugins
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  git clone --depth 1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi
"$HOME/.tmux/plugins/tpm/bin/install_plugins" >/dev/null || true

# 10. Start the desktop: bar, then AeroSpace (it starts borders itself)
log "Starting SketchyBar and AeroSpace..."
brew services start sketchybar
open -a AeroSpace

log "Done. Grant Accessibility access to AeroSpace and Karabiner when macOS asks,"
log "then open Ghostty."
log "By hand: Jazz (SberJazz), My Words — see the end of Brewfile."
