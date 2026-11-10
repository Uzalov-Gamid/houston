# Everything this Mac needs — apps, CLI tools, fonts — in one file.
#
#   install / update everything:  brew bundle --file=~/.config/Brewfile
#   what is missing:              brew bundle check --file=~/.config/Brewfile --verbose
#   what is installed but NOT here (candidates to remove):
#                                 brew bundle cleanup --file=~/.config/Brewfile
#
# On a fresh Mac run ~/.config/install.sh instead: it also does the steps
# Homebrew cannot (SbarLua, fish plugins, tmux plugins, default shell).

tap "nikitabobko/tap"     # AeroSpace
tap "felixkratz/formulae" # SketchyBar, JankyBorders
tap "writronic/tap"       # MaCursor

# ── Window manager, menu bar, keyboard ────────────────────────────────
cask "aerospace"                 # tiling window manager
brew "sketchybar"                # top bar
brew "borders"                   # glow around the focused window
brew "lua"                       # SketchyBar config is written in Lua
brew "jq"                        # bar scripts parse JSON
cask "karabiner-elements"        # Caps→Ctrl, Fn+HJKL arrows
cask "font-sketchybar-app-font"  # app icons in the bar
cask "font-sf-pro"               # bar text + SF Symbols glyphs
cask "font-sf-mono"
cask "sf-symbols"                # look up icon codes for the bar
cask "macursor"                  # custom mouse cursor theme (cursor/)

# ── Terminal & shell ──────────────────────────────────────────────────
cask "ghostty"
cask "font-0xproto-nerd-font"    # terminal font
brew "fish"                      # main shell
brew "tmux"
brew "atuin"                     # Ctrl-R history
brew "zoxide"                    # `cd` that remembers folders
brew "fzf"
brew "lsd"                       # `ls`
brew "yazi"                      # file manager (`yz`)
brew "ffmpegthumbnailer"         #   yazi: video previews
brew "poppler"                   #   yazi: PDF previews
brew "sevenzip"                  #   yazi: archive previews
brew "imagemagick"               #   yazi: image previews
brew "ghostscript"               #   imagemagick: PDF/EPS
brew "fastfetch"                 # `ff`
brew "btop"
brew "tree"
brew "wget"
brew "starship"                  # prompt for zsh (fish uses Tide)
brew "zsh-autosuggestions"
brew "zsh-syntax-highlighting"

# ── Editors ───────────────────────────────────────────────────────────
brew "neovim"                    # editor, minimal config in nvim/
brew "ripgrep"                   # `rg`, fast search
brew "fd"                        # fast file finder
brew "glow"                      # Markdown in the terminal (nvim draws its own reading view)
brew "node"                      # npm tools (TickTick CLI, SQL formatter)
cask "visual-studio-code"

# ── Language servers for nvim (nvim/lsp/) ─────────────────────────────
brew "pyright"                   # Python
brew "bash-language-server"      # Bash / sh
brew "shellcheck"                # Bash: the checks behind bash-language-server
brew "shfmt"                     # Bash: formatting
brew "yaml-language-server"      # YAML: k8s, GitHub Actions, compose schemas
brew "vscode-langservers-extracted" # JSON, HTML, CSS
brew "dockerfile-language-server" # Dockerfile
brew "lua-language-server"       # Lua
brew "terraform-ls"              # Terraform
brew "helm-ls"                   # Helm templates
brew "taplo"                     # TOML
brew "uv"                        # Python tools: harlequin, nginx-language-server

# ── Git ───────────────────────────────────────────────────────────────
brew "git"
brew "git-delta"                 # diff pager
brew "git-lfs"
brew "gh"
brew "lazygit"                   # `lg`

# ── Docker (School 21 container, DevOps) ──────────────────────────────
brew "colima"                    # Docker VM without Docker Desktop
brew "docker"
brew "docker-buildx"
brew "docker-compose"
brew "docker-credential-helper"
brew "lazydocker"                # containers TUI (nvim: <leader>c)

# ── Databases & SQL ───────────────────────────────────────────────────
brew "postgresql@18"
brew "pgcli"
brew "vi-sql"
brew "sqlfluff"
brew "sql-formatter"
cask "db-browser-for-sqlite"

# ── Python ────────────────────────────────────────────────────────────
brew "python@3.14"
brew "python-tk@3.14"

# ── AI ────────────────────────────────────────────────────────────────
cask "claude"
cask "claude-code"
cask "chatgpt"
cask "codex"
cask "copilot-cli"
brew "opencode"

# ── Apps ──────────────────────────────────────────────────────────────
cask "arc"
cask "obsidian"
cask "homerow"
cask "handy"                     # speech to text
cask "appcleaner"
cask "telegram"
cask "ticktick"
cask "utm"
cask "steam"

# ── App Store ─────────────────────────────────────────────────────────
brew "mas"
mas "Happ", id: 6788279553

# Not available via Homebrew / App Store, install by hand:
#   Liftoff (app launcher on ⌘Space) — ~/Documents/liftoff, ./make-app.sh
#   Jazz (SberJazz) — https://salutejazz.ru
#   My Words
