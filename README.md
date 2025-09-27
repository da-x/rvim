# rvim

My highly customized Neovim configuration, built on top of Kickstart.nvim.

## About

This is "rvim" (named for lack of a better term) - a personalized Neovim setup that extends Kickstart.nvim with extensive customizations for my development workflow.

Key additions include a lockfile for configuration stability and numerous enhancements tailored to my specific needs.

## Installation

1. Clone this repository to a separate config directory:
   ```bash
   git clone <repo-url> ~/.config/rvim
   ```

2. Create a handy script to run rvim alongside regular nvim:
   ```bash
   cat > ~/.local/bin/rvim << 'EOF'
   #!/bin/bash
   NVIM_APPNAME=rvim nvim "$@"
   EOF
   chmod +x ~/.local/bin/rvim
   ```

3. Start rvim - plugins will auto-install on first run:
   ```bash
   rvim
   ```

This allows you to use both `nvim` (your regular config) and `rvim` (this config) during migration.

## Original

Based on [Kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) - see [ORIG_README.md](ORIG_README.md) for original documentation.
