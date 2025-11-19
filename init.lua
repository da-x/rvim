-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Set to true if you have a Nerd Font installed and selected in the terminal
vim.g.have_nerd_font = true

-- [[ Setting options ]]
-- See `:help vim.o`
-- NOTE: You can change these options as you wish!
--  For more options, you can see `:help option-list`

-- Make line numbers default
vim.o.number = true
-- You can also add relative line numbers, to help with jumping.
--  Experiment for yourself to see if you like it!
-- vim.o.relativenumber = true

-- Enable mouse mode, can be useful for resizing splits for example!
vim.o.mouse = 'a'

-- Don't show the mode, since it's already in the status line
vim.o.showmode = false

-- Sync clipboard between OS and Neovim.
--  Schedule the setting after `UiEnter` because it can increase startup-time.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.schedule(function()
  vim.o.clipboard = 'unnamedplus'
end)

-- Enable break indent
vim.o.breakindent = true

-- Save undo history
vim.o.undofile = true

-- Disable swap files
vim.o.swapfile = false

-- Remember cursor position, search history, etc.
vim.o.shada = "'100,<50,s10,h,f1"

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.o.ignorecase = true
vim.o.smartcase = true

-- Keep signcolumn on by default
vim.o.signcolumn = 'auto:2'

-- Decrease update time
vim.o.updatetime = 250

-- Decrease mapped sequence wait time
vim.o.timeout = false
vim.o.ttimeout = false

-- Configure how new splits should be opened
vim.o.splitright = true
vim.o.splitbelow = true

-- Avoid breakding words
vim.o.linebreak = true

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
--
--  Notice listchars is set using `vim.opt` instead of `vim.o`.
--  It is very similar to `vim.o` but offers an interface for conveniently interacting with tables.
--   See `:help lua-options`
--   and `:help lua-options-guide`
vim.o.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

-- Preview substitutions live, as you type!
vim.o.inccommand = 'split'

-- Show which line your cursor is on
vim.o.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.o.scrolloff = 10

-- if performing an operation that would fail due to unsaved changes in the buffer (like `:q`),
-- instead raise a dialog asking if you wish to save the current file(s)
-- See `:help 'confirm'`
vim.o.confirm = true

-- Allow cursor to go after one last character of the line, like in modern editing environments
vim.o.virtualedit = 'onemore,block'

-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
-- Location list configuration
local function smart_setloclist()
  vim.diagnostic.setloclist()
  -- Auto-resize location list window to be minimal but max 1/3 of screen
  local loc_items = #vim.fn.getloclist(0)
  if loc_items > 0 then
    local max_height = math.floor(vim.o.lines / 3)
    local height = math.min(loc_items, max_height)
    vim.cmd('lopen ' .. height)
  end
end

local function is_loclist_open()
  for _, win in ipairs(vim.fn.getwininfo()) do
    if win.loclist == 1 then
      return true
    end
  end
  return false
end

local function save_and_refresh_loclist()
  vim.cmd 'write'
  -- Wait a bit for linters to run, then refresh location list
  vim.defer_fn(function()
    smart_setloclist()
  end, 100)
end

vim.keymap.set('n', '<leader>q', smart_setloclist, { desc = 'Open diagnostic [Q]uickfix list' })
vim.keymap.set('n', '<leader>Q', '<cmd>lclose<cr>', { desc = 'Close location list' })
vim.keymap.set('n', '<leader>w', save_and_refresh_loclist, { desc = 'Save and refresh location list' })

-- Treesitter incremental selection
vim.keymap.set('n', '+', function()
  -- TODO: do viw in normal mode and use that if it selects less.
  vim.cmd 'normal! viw'
  -- local iss = require 'nvim-treesitter.incremental_selection'
  -- iss.node_incremental()
end, { desc = 'Expand treesitter selection' })

vim.keymap.set('v', '+', function()
  local start_pos = vim.fn.getpos "'<"
  local end_pos = vim.fn.getpos "'>"

  local iss = require 'nvim-treesitter.incremental_selection'
  iss.node_incremental()

  local new_start = vim.fn.getpos "'<"
  local new_end = vim.fn.getpos "'>"

  -- If selection hasn't changed, try again
  if start_pos[2] == new_start[2] and start_pos[3] == new_start[3] and end_pos[2] == new_end[2] and end_pos[3] == new_end[3] then
    iss.node_incremental()
  end
end, { desc = 'Expand treesitter selection' })

vim.keymap.set('v', '-', function()
  local iss = require 'nvim-treesitter.incremental_selection'
  iss.node_decremental()
end, { desc = 'Contract treesitter selection' })

-- Navigate diagnostics
vim.keymap.set('n', '<F4>', vim.diagnostic.goto_next, { desc = 'Goto next diagnostic message' })
vim.keymap.set('n', '<F16>', vim.diagnostic.goto_prev, { desc = 'Goto prev diagnostic message' }) -- Shift-F4
vim.keymap.set('n', '<F5>', function()
  local diagnostics = vim.diagnostic.get(0) -- Get diagnostics for current buffer
  if #diagnostics > 0 then
    vim.api.nvim_win_set_cursor(0, { diagnostics[1].lnum + 1, diagnostics[1].col })
  end
end, { desc = 'Goto first diagnostic message' })
-- vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous [D]iagnostic message' })

-- Navigate quickfix list
vim.keymap.set('n', '<F7>', '<cmd>cnext<CR>', { desc = 'Goto next quickfix location' }) --
vim.keymap.set('n', '<C-F7>', '<cmd>cfirst<CR>', { desc = 'Goto first quickfix location' }) -- Also: ]q

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- TIP: Disable arrow keys in normal mode
-- vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
-- vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
-- vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
-- vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Delete current line with Ctrl-D
vim.keymap.set('n', '<C-d>', 'dd', { desc = 'Delete current line' })
vim.keymap.set('i', '<C-d>', '<C-o>dd', { desc = 'Delete current line' })

-- Undo with Ctrl-Z
vim.keymap.set('n', '<C-z>', ':undo<CR>', { desc = 'Undo' })
vim.keymap.set('i', '<C-z>', '<ESC>:undo<CR>i', { desc = 'Undo' })

-- Redo with Alt-Ctrl-U
vim.keymap.set('n', '<M-C-U>', ':redo<CR>', { desc = 'Redo' })
vim.keymap.set('i', '<M-C-U>', '<ESC>:redo<CR>i', { desc = 'Redo' })

-- Duplicate current line with <leader>d (without affecting registers)
vim.keymap.set('n', '<leader>d', function()
  local line = vim.api.nvim_get_current_line()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_lines(0, row, row, false, { line })
end, { desc = 'Duplicate current line' })

-- Delete without affecting any clipboard
local function delete_no_clipboard()
  vim.g.no_clipboard_affect = 1
  vim.cmd 'normal! "_x'
  vim.g.no_clipboard_affect = 0
end

local function delete_to_end_no_system_clipboard()
  vim.g.no_clipboard_affect = 1
  vim.cmd 'normal! D'
  vim.g.no_clipboard_affect = 0
end

vim.keymap.set('n', '<Del>', delete_no_clipboard, { desc = 'Delete selection without affecting register', noremap = true })
vim.keymap.set('v', '<Del>', delete_no_clipboard, { desc = 'Delete selection without affecting register', noremap = true })
vim.keymap.set('n', 'D', delete_to_end_no_system_clipboard, { desc = 'Delete to end of line without affecting register', noremap = true })

-- Save current file with Ctrl-X s
vim.keymap.set('n', '<C-x>s', '<cmd>w<CR>', { desc = 'Save current file' })
vim.keymap.set('n', '<C-x><C-s>', '<cmd>w<CR>', { desc = 'Save current file' })

-- Git bindings (C-g prefix) - comprehensive git workflow shortcuts
vim.keymap.set('n', '<C-g>s', '<cmd>Git<CR>', { desc = 'Git status (stage with s, unstage with u)' })
vim.keymap.set('n', '<C-g>f', '<cmd>call GFilesWithPreview()<CR>', { desc = 'Git status (stage with s, unstage with u)' })
vim.keymap.set('n', '<C-g>L', '<cmd>BCommits<CR>', { desc = 'File history (commits affecting current buffer)' })
vim.keymap.set('n', '<C-g>AA', function()
  vim.fn.MyGitAddAllAmend()
end, { desc = 'Add all changes and amend last commit' })
vim.keymap.set('n', '<C-g>PP', function()
  vim.fn.MyGitPush()
end, { desc = 'Push changes' })

-- Git hunk operations
vim.keymap.set('n', '<C-g><Insert>', function()
  require('gitsigns').stage_hunk()
end, { desc = 'Stage Git hunk under cursor' })
vim.keymap.set('n', '<C-g><Del>', function()
  require('gitsigns').reset_hunk()
end, { desc = 'Reset Git hunk under cursor' })
vim.keymap.set('n', '<C-g><Up>', function()
  require('gitsigns').nav_hunk 'prev'
end, { desc = 'Go to previous Git hunk' })
vim.keymap.set('n', '<C-g><Down>', function()
  require('gitsigns').nav_hunk 'next'
end, { desc = 'Go to next Git hunk' })

-- Git conflict marker navigation and resolution
vim.keymap.set('n', '<C-g>b', '<Plug>(conflict-marker-next-hunk)', { desc = 'Next conflict marker' })
vim.keymap.set('n', '<C-g>t', '<Plug>(conflict-marker-prev-hunk)', { desc = 'Previous conflict marker' })
vim.keymap.set('n', '<C-g>q<Del>', '<Plug>(conflict-marker-none)', { desc = 'Choose none (remove conflict)' })
vim.keymap.set('n', '<C-g>q<Down>', '<Plug>(conflict-marker-themselves)', { desc = 'Choose theirs' })
vim.keymap.set('n', '<C-g>q<Up>', '<Plug>(conflict-marker-ourselves)', { desc = 'Choose ours' })
vim.keymap.set('n', '<C-g>q<CR>', '<Plug>(conflict-marker-both)', { desc = 'Choose both' })

-- Git grep bindings (F9 family)
vim.keymap.set('n', '<F9>', function()
  vim.fn.MyGitGrep(vim.fn.expand '<cword>')
end, { desc = 'Git grep current word' })
vim.keymap.set('n', '<C-F9>', ':Gg ', { desc = 'Git grep prompt' })
vim.keymap.set('n', '<Tab>', '<C-w>', { desc = 'Shorter <C-w>', remap = true })
vim.keymap.set('n', '<S-F9>', function()
  require('telescope.builtin').live_grep { default_text = vim.fn.expand '<cword>' }
end, { desc = 'Ripgrep current word' })
vim.keymap.set('n', '<M-F9>', function()
  require('telescope.builtin').live_grep()
end, { desc = 'Ripgrep prompt' })

-- Git diff views
vim.keymap.set('n', '<C-g>d', function()
  vim.fn.MyFZFDiffHunks ''
end, { desc = 'Working directory changes (unstaged)' })
vim.keymap.set('n', '<C-g><C-d>', function()
  vim.fn.MyFZFDiffHunks ''
end, { desc = 'Working directory changes (unstaged)' })
vim.keymap.set('n', '<C-g>D', function()
  vim.fn.MyFZFDiffHunks 'HEAD'
end, { desc = 'Changes vs HEAD (all changes)' })
vim.keymap.set('n', '<C-g>C', function()
  vim.fn.MyFZFDiffHunks '--cached'
end, { desc = 'Staged changes (--cached)' })
vim.keymap.set('n', '<C-g>j', function()
  vim.fn.MyFZFDiffHunks 'HEAD~1'
end, { desc = 'Changes vs previous commit (HEAD~1)' })
vim.keymap.set('n', '<C-g><C-j>', function()
  vim.fn.MyFZFDiffHunks 'HEAD~1'
end, { desc = 'Changes vs previous commit (HEAD~1)' })
vim.keymap.set('n', '<C-g>i', function()
  vim.fn.MyFZFChooseRebaseInteractive()
end, { desc = 'Interactive rebase (choose commit via FZF)' })

-- Toggle comments with Ctrl-r
vim.keymap.set('n', '<C-r>', 'gcc', { desc = 'Toggle comment on current line', remap = true })
vim.keymap.set('v', '<C-r>', 'gc', { desc = 'Toggle comment on selection', remap = true })

-- Toggle visual line selection with Ctrl-Space
vim.keymap.set('n', '<C-Space>', 'V', { desc = 'Enter visual line mode' })
vim.keymap.set('v', '<C-Space>', '<Esc>', { desc = 'Exit visual mode' })

-- Yank with Enter in visual mode and move to end of selection
vim.keymap.set('v', '<CR>', 'y`>', { desc = 'Yank selection and move to end' })

-- Surround visual selection quick surround actions
vim.keymap.set('v', ')', '<Esc>`>a)<Esc>`<i(<Esc>', { desc = 'Surround selection with parentheses' })
vim.keymap.set('v', ']', '<Esc>`>a]<Esc>`<i[<Esc>', { desc = 'Surround selection with parentheses' })
vim.keymap.set('v', '}', '<Esc>`>a}<Esc>`<i{<Esc>', { desc = 'Surround selection with parentheses' })
vim.keymap.set('v', '""', '<Esc>`>a"<Esc>`<i"<Esc>', { desc = 'Surround selection with double quotes' })
vim.keymap.set('v', "''", "<Esc>`>a'<Esc>`<i'<Esc>", { desc = 'Surround selection with single quotes' })

-- System clipboard yank operations
vim.keymap.set('n', '<leader>yf', function()
  vim.fn.YankCurrentFilename()
end, { desc = 'Yank current filename to system clipboard' })
vim.keymap.set('n', '<leader>yd', function()
  vim.fn.YankCurrentDirAbs()
end, { desc = 'Yank current directory to system clipboard' })

-- Search and select current word/selection (like * but without moving cursor)
vim.keymap.set('n', '<A-t>', '*``', { desc = 'Search current word without moving cursor', remap = true })
vim.keymap.set('v', '<A-t>', '<leader><C-space>*``', { desc = 'Search selection without moving cursor', remap = true })
vim.keymap.set('i', '<A-t>', '<C-c><leader><C-space>*``', { desc = 'Search current word without moving cursor', remap = true })

-- Make Backspace behave like it normally does in normal mode (delete char before cursor)
vim.keymap.set('n', '<BS>', '"_X', { desc = 'Delete character before cursor' })

-- Smart Tab behavior in insert mode - respects current indentation settings
vim.keymap.set('i', '<Tab>', function()
  if vim.bo.expandtab then
    -- Use spaces based on softtabstop or shiftwidth
    local spaces = vim.bo.softtabstop > 0 and vim.bo.softtabstop or vim.bo.shiftwidth
    return string.rep(' ', spaces)
  else
    -- Use actual tab character
    return '\t'
  end
end, { desc = 'Insert tab/spaces based on current indentation mode', expr = true })

-- UltiSnips configuration
vim.g.UltiSnipsExpandTrigger = '<C-q>'
vim.g.UltiSnipsListSnippets = '<C-j>'
vim.g.UltiSnipsJumpForwardTrigger = '<C-e>'
vim.g.UltiSnipsJumpBackwardTrigger = '<C-f>'
vim.g.UltiSnipsRemoveSelectModeMappings = 0

-- FZF spell suggestions (replaces default z= spell menu)
vim.keymap.set('n', 'z=', function()
  vim.fn.FzfSpell()
end, { desc = 'FZF spell suggestions for word under cursor' })

-- Substitute delimiter rotation
vim.keymap.set('n', '<A-d>', function()
  vim.fn.RotateSubstituteDelimiter()
end, { desc = 'Rotate substitute delimiter' })

-- Advanced search and replace with current search pattern
vim.keymap.set('n', '<A-r>', function()
  local delim = vim.fn.GetSubstituteDelimiter()
  local pattern = vim.fn.getreg '/'
  local replacement = vim.fn.InsertSelectionMatch()
  return ':%s' .. delim .. pattern .. delim .. replacement .. delim .. 'g' .. string.rep('<Left>', 2)
end, { desc = 'Search/replace with matched text as replacement', expr = true })
vim.keymap.set('v', '<A-r>', function()
  local delim = vim.fn.GetSubstituteDelimiter()
  local pattern = vim.fn.getreg '/'
  local replacement = vim.fn.InsertSelectionMatch()
  return ':s' .. delim .. pattern .. delim .. replacement .. delim .. 'g' .. string.rep('<Left>', 2)
end, { desc = 'Search/replace with matched text as replacement', expr = true })

-- Search and replace with empty replacement
vim.keymap.set('n', '<A-n>', function()
  local delim = vim.fn.GetSubstituteDelimiter()
  local pattern = vim.fn.getreg '/'
  return ':%s' .. delim .. pattern .. delim .. delim .. 'g' .. string.rep('<Left>', 2)
end, { desc = 'Search/replace with empty replacement', expr = true })
vim.keymap.set('v', '<A-n>', function()
  local delim = vim.fn.GetSubstituteDelimiter()
  local pattern = vim.fn.getreg '/'
  return ':s' .. delim .. pattern .. delim .. delim .. 'g' .. string.rep('<Left>', 2)
end, { desc = 'Search/replace with empty replacement', expr = true })

-- Buffer switcher with F2
vim.keymap.set('n', '<F2>', function()
  require('telescope.builtin').buffers { sort_mru = true, sort_lastused = true }
end, { desc = 'Switch buffers' })

-- Recent files (MRU) with Ctrl-F2
vim.keymap.set('n', '<C-F2>', function()
  require('telescope.builtin').oldfiles()
end, { desc = 'Recent files (MRU)' })

-- Close buffer with Ctrl-Delete
vim.keymap.set('n', '<C-Del>', '<cmd>bd<CR>', { desc = 'Close current buffer' })

-- Make End key go after the last character (only in normal mode)
vim.keymap.set('n', '<End>', function()
  if vim.fn.col '$' > 1 then
    vim.fn.cursor(vim.fn.line '.', vim.fn.col '$')
  end
end, { desc = 'Go after last character' })

-- Edit shortcuts for configuration files
vim.keymap.set('n', '<leader>el', '<cmd>EditLocalVimrc<cr>', { desc = 'Edit local vimrc' })
vim.keymap.set('n', '<leader>ea', '<cmd>e! ~/.config/alacritty/alacritty.yml<cr>', { desc = 'Edit alacritty config' })
vim.keymap.set('n', '<leader>ee', '<cmd>e! ~/.config/rvim/init.lua<cr>', { desc = 'Edit rvim init.lua' })
vim.keymap.set('n', '<leader>eg', '<cmd>e! ~/.files/gitconfig<cr>', { desc = 'Edit gitconfig' })
vim.keymap.set('n', '<leader>et', '<cmd>e! ~/.tmux.conf<cr>', { desc = 'Edit tmux config' })
vim.keymap.set('n', '<leader>ez', '<cmd>e! ~/.zsh/zshrc.sh<cr>', { desc = 'Edit zsh config' })
vim.keymap.set('n', '<leader>e_', '<cmd>e! ~/.vim_runtime/project-specific.vim<cr>', { desc = 'Edit project-specific vim config' })
vim.keymap.set('n', '<leader>ef', '<cmd>NvimTreeFindFileToggle<cr>', { desc = 'Toggle file explorer' })

-- Eat plugin key bindings (F8 family and leader+o combinations)
vim.keymap.set('n', '<F8>', function()
  vim.fn.EatNext()
end, { desc = 'Eat: Run next command' })
vim.keymap.set('n', '<M-F8>', function()
  vim.fn.SaveAllAndEatRedo()
end, { desc = 'Eat: Save all and redo' })
vim.keymap.set('n', '<C-F8>', function()
  vim.fn.EatFirst()
end, { desc = 'Eat: Run first command' })

-- Leader+o family for Eat plugin
vim.keymap.set('n', '<leader>o<Insert>', function()
  vim.fn.EatScan()
end, { desc = 'Eat: Scan for commands' })
vim.keymap.set('n', '<leader>o<Home>', function()
  vim.fn.EatFirst()
end, { desc = 'Eat: Run first command' })
vim.keymap.set('n', '<leader>ol', function()
  vim.fn.EatScan()
end, { desc = 'Eat: Scan for commands' })
vim.keymap.set('n', '<leader>oo', function()
  vim.fn.SaveAllAndEatRedo()
end, { desc = 'Eat: Save all and redo' })
vim.keymap.set('n', '<leader>o<BS>', function()
  vim.fn.EatPrev()
end, { desc = 'Eat: Run previous command' })
vim.keymap.set('n', '<leader>o<CR>', function()
  vim.fn.EatNext()
end, { desc = 'Eat: Run next command' })
vim.keymap.set('n', '<leader>o<Space>', function()
  vim.fn.EatFirst()
end, { desc = 'Eat: Run first command' })
vim.keymap.set('n', '<leader>o[', function()
  vim.fn.EatPrev()
end, { desc = 'Eat: Run previous command' })
vim.keymap.set('n', '<leader>o]', function()
  vim.fn.EatNext()
end, { desc = 'Eat: Run next command' })

-- Faster moving of the cursor using Ctrl and arrows
vim.keymap.set('n', '<C-Up>', '{', { silent = true, desc = 'Move to previous paragraph' })
vim.keymap.set('n', '<C-Down>', '}', { silent = true, desc = 'Move to next paragraph' })
vim.keymap.set('i', '<C-Up>', '<C-c>{i', { silent = true, desc = 'Move to previous paragraph' })
vim.keymap.set('i', '<C-Down>', '<C-c>}i', { silent = true, desc = 'Move to next paragraph' })
vim.keymap.set('v', '<C-Up>', '{', { silent = true, desc = 'Move to previous paragraph' })
vim.keymap.set('v', '<C-Down>', '}', { silent = true, desc = 'Move to next paragraph' })

vim.keymap.set('n', '<Down>', 'gj', { desc = 'Move down by visual line' })
vim.keymap.set('n', '<Up>', 'gk', { desc = 'Move up by visual line' })

-- Bind M-T-PageUp to nop by default (can be overridden in specific contexts)
vim.keymap.set('n', '<M-T-PageUp>', '<Nop>', { desc = 'No operation (disabled by default)' })
vim.keymap.set('i', '<M-T-PageUp>', '<Nop>', { desc = 'No operation (disabled by default)' })
vim.keymap.set('i', '<T-PageUp>', '<Return>') -- Because I accidentally do shirt-enter when I want enter
vim.keymap.set('n', '<T-PageUp>', '<Return>') -- Because I accidentally do shirt-enter when I want enter

-- Disabled until further notice:
vim.keymap.set('n', '<C-a>', '<Nop>', { desc = 'No operation (disabled by default)' })
vim.keymap.set('n', '<C-x>', '<Nop>', { desc = 'No operation (disabled by default)' })
vim.keymap.set('v', '<C-a>', '<Nop>', { desc = 'No operation (disabled by default)' })
vim.keymap.set('v', '<C-x>', '<Nop>', { desc = 'No operation (disabled by default)' })

-- local_vimrc

vim.g.local_vimrc = { 'vimrc_local.vim' }
vim.g.local_vimrc_look_only_in_dot_git = true
vim.g.local_vimrc_options = {
  whitelist = { vim.fn.expand '$HOME' }, -- Because of local_vimrc_look_only_in_dot_git, all is vetted
  blacklist = {},
  asklist = {},
  sandboxlist = {},
}

-- Load utility functions
local utils = require 'utils'

-- Configure Python plugin loading from rplugin directory
vim.g.python3_host_prog = vim.fn.exepath 'python3'
local rplugin_path = vim.fn.stdpath 'config' .. '/rplugin'
if vim.fn.isdirectory(rplugin_path) == 1 then
  vim.opt.runtimepath:append(rplugin_path)
end

-- Keybinds to make split navigation easier.
vim.keymap.set('n', '<leader>hi', utils.show_highlight_groups, { desc = 'Show [H]ighlight [I]nfo under cursor' })
vim.keymap.set('n', '<leader>hk', utils.show_key_notation, { desc = 'Show [K]ey notation for next key pressed' })

--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- NOTE: Some terminals have colliding keymaps or are not able to send distinct keycodes
-- vim.keymap.set("n", "<C-S-h>", "<C-w>H", { desc = "Move window to the left" })
-- vim.keymap.set("n", "<C-S-l>", "<C-w>L", { desc = "Move window to the right" })
-- vim.keymap.set("n", "<C-S-j>", "<C-w>J", { desc = "Move window to the lower" })
-- vim.keymap.set("n", "<C-S-k>", "<C-w>K", { desc = "Move window to the upper" })

-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.hl.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- Remember cursor position
vim.api.nvim_create_autocmd('BufReadPost', {
  desc = 'Restore cursor position',
  group = vim.api.nvim_create_augroup('restore-cursor', { clear = true }),
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- VimScript files: 2-space indentation
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'vim',
  desc = 'Set 2-space indentation for VimScript files',
  group = vim.api.nvim_create_augroup('vim-indent', { clear = true }),
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.expandtab = true
  end,
})

-- Git commit buffer mappings
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'gitcommit',
  desc = 'Setup git commit key bindings',
  group = vim.api.nvim_create_augroup('git-commit-bindings', { clear = true }),
  callback = function(ev)
    local opts = { buffer = ev.buf }

    -- Quick save commit message and return
    vim.keymap.set('n', '<C-g><CR>', '<cmd>w | bd<cr>', vim.tbl_extend('force', opts, { desc = 'Save commit and close' }))
    vim.keymap.set('i', '<C-g><CR>', '<C-c><C-g><CR>', vim.tbl_extend('force', opts, { desc = 'Save commit and close' }))

    -- Abort commit (delete commit message file)
    vim.keymap.set(
      'n',
      '<C-Del>',
      '<cmd>%delete | w | bd | echo "Commit aborted - all files remain staged"<cr>',
      vim.tbl_extend('force', opts, { desc = 'Abort commit' })
    )
    vim.keymap.set(
      'i',
      '<C-Del>',
      '<C-c>:%delete | w | bd | echo "Commit aborted - all files remain staged"<cr>',
      vim.tbl_extend('force', opts, { desc = 'Abort commit' })
    )

    -- Alternative save and close
    vim.keymap.set('n', '<M-T-PageUp>', function()
      vim.fn.EndCommitMessageEdit()
    end, vim.tbl_extend('force', opts, { desc = 'End commit message edit' }))
    vim.keymap.set('i', '<M-T-PageUp>', '<C-c><cmd>lua vim.fn.EndCommitMessageEdit()<cr>', vim.tbl_extend('force', opts, { desc = 'End commit message edit' }))
  end,
})

-- Git rebase todo buffer mappings
vim.api.nvim_create_autocmd('BufRead', {
  pattern = 'git-rebase-todo',
  desc = 'Setup git rebase todo key bindings',
  group = vim.api.nvim_create_augroup('git-rebase-bindings', { clear = true }),
  callback = function(ev)
    local opts = { buffer = ev.buf }

    -- Rebase action shortcuts
    vim.keymap.set('n', 'p', '0ciwpick<Esc><Down>0', vim.tbl_extend('force', opts, { desc = 'Set to pick' }))
    vim.keymap.set('n', 'r', '0ciwreword<Esc><Down>0', vim.tbl_extend('force', opts, { desc = 'Set to reword' }))
    vim.keymap.set('n', 'e', '0ciwedit<Esc><Down>0', vim.tbl_extend('force', opts, { desc = 'Set to edit' }))
    vim.keymap.set('n', 's', '0ciwsquash<Esc><Down>0', vim.tbl_extend('force', opts, { desc = 'Set to squash' }))
    vim.keymap.set('n', 'f', '0ciwfixup<Esc><Down>0', vim.tbl_extend('force', opts, { desc = 'Set to fixup' }))
    vim.keymap.set('n', 'x', '0ciwexec<Esc><Down>0', vim.tbl_extend('force', opts, { desc = 'Set to exec' }))
    vim.keymap.set('n', 'd', '0ciwdrop<Esc><Down>0', vim.tbl_extend('force', opts, { desc = 'Set to drop' }))
    vim.keymap.set('n', 'k', '0ciwdrop<Esc><Down>0', vim.tbl_extend('force', opts, { desc = 'Set to drop' }))

    -- Movement shortcuts - use vim-move plugin directly
    vim.keymap.set('n', '<C-Up>', '<Plug>MoveLineUp', vim.tbl_extend('force', opts, { desc = 'Move line up' }))
    vim.keymap.set('n', '<C-Down>', '<Plug>MoveLineDown', vim.tbl_extend('force', opts, { desc = 'Move line down' }))
    vim.keymap.set('n', '<M-PageUp>', '<M-k>', vim.tbl_extend('force', opts, { desc = 'Move line up' }))
    vim.keymap.set('n', '<M-PageDown>', '<M-j>', vim.tbl_extend('force', opts, { desc = 'Move line down' }))

    -- Set cursor to first line
    vim.fn.setpos('.', { 0, 1, 1, 0 })
  end,
})

-- blink.cmp accept

local function blink_cmp_enter(cmp)
  if not require('blink.cmp').is_visible() or vim.bo.filetype == 'markdown' then
    cmp.cancel()
    vim.api.nvim_feedkeys('\r', 'n', true)
  else
    cmp.accept()
  end
end

local function accept_blink_cmcp(cmp)
  if not require('blink.cmp').is_visible() and vim.bo.filetype == 'gitcommit' then
    vim.schedule(function()
      vim.fn.EndCommitMessageEdit()
    end)
  else
    cmp.accept()
  end
end

-- Markdown buffer mappings
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'markdown',
  desc = 'Setup markdown key bindings',
  group = vim.api.nvim_create_augroup('my-markdown-bindings', { clear = true }),
  callback = function(ev)
    local opts = { buffer = ev.buf }

    -- Enable proper list formatting and auto-indent
    vim.opt_local.formatoptions:append 'ro' -- Auto-insert comment leader on <CR> and 'o'
    vim.opt_local.comments = 'b:-,b:*,b:+,b:1.' -- Define list markers as comments
    vim.opt_local.autoindent = true
    vim.opt_local.smartindent = false -- Disable smart indent for markdown

    -- Markdown-specific shortcuts
    vim.keymap.set('i', '<A-e>d', '<C-c><A-e>d', vim.tbl_extend('force', opts, { desc = 'Insert markdown date' }))

    -- Link handling
    vim.keymap.set('n', '<CR>', function()
      require('utils').open_markdown_link()
    end, vim.tbl_extend('force', opts, { desc = 'Open markdown link under cursor' }))

    -- Date and timestamp insertions
    vim.keymap.set(
      'i',
      '<A-e><Down>',
      'Go<CR><CR><C-R>=MyVimEditInsertDateLine()<CR><CR> <Backspace>',
      vim.tbl_extend('force', opts, { desc = 'Insert date line at end' })
    )
    vim.keymap.set('i', '<A-e><CR>', '<C-c>i<C-R>=MyVimEditTimestamp()<CR>', vim.tbl_extend('force', opts, { desc = 'Insert timestamp' }))
    vim.keymap.set(
      'i',
      '<A-e>d',
      'Go<CR><CR><C-R>=MyVimEditInsertDateLine()<CR><CR> <Backspace>',
      vim.tbl_extend('force', opts, { desc = 'Insert date line at end' })
    )
    vim.keymap.set(
      'n',
      '<A-e>d',
      'Go<CR><CR><C-R>=MyVimEditInsertDateLine()<CR><CR> <Backspace>',
      vim.tbl_extend('force', opts, { desc = 'Insert date line at end' })
    )
    vim.keymap.set('n', '<A-e><CR>', 'Go<C-R>=MyVimEditTimestamp()<CR>', vim.tbl_extend('force', opts, { desc = 'Insert timestamp at end' }))

    -- Drag markdown bullets up/down
    vim.keymap.set('n', '<M-k>', function()
      vim.fn.MyMarkdownDragUp()
    end, vim.tbl_extend('force', opts, { desc = 'Move line up' }))
    vim.keymap.set('n', '<M-j>', function()
      vim.fn.MyMarkdownDragDown()
    end, vim.tbl_extend('force', opts, { desc = 'Move line down' }))
    vim.keymap.set('v', '<M-k>', function()
      vim.fn.MyMarkdownDragUp()
    end, vim.tbl_extend('force', opts, { desc = 'Move selection up' }))
    vim.keymap.set('v', '<M-j>', function()
      vim.fn.MyMarkdownDragDown()
    end, vim.tbl_extend('force', opts, { desc = 'Move selection down' }))
    vim.keymap.set('n', '<S-Up>', function()
      vim.fn.MyMarkdownDragUp()
    end, vim.tbl_extend('force', opts, { desc = 'Move line up' }))
    vim.keymap.set('n', '<S-Down>', function()
      vim.fn.MyMarkdownDragDown()
    end, vim.tbl_extend('force', opts, { desc = 'Move line down' }))
    vim.keymap.set('v', '<S-Up>', function()
      vim.fn.MyMarkdownDragUp()
    end, vim.tbl_extend('force', opts, { desc = 'Move selection up' }))
    vim.keymap.set('v', '<S-Down>', function()
      vim.fn.MyMarkdownDragDown()
    end, vim.tbl_extend('force', opts, { desc = 'Move selection down' }))
  end,
})

-- Knots buffer mappings (when InKnotBuffer is called)
-- This will be triggered by the InKnotBuffer function
vim.api.nvim_create_user_command('SetupKnotBindings', function()
  local opts = { buffer = 0 }

  -- Knot manipulation
  vim.keymap.set('n', '<C-n>m', function()
    vim.fn['knot#MoveCurrentInteractive']()
  end, vim.tbl_extend('force', opts, { desc = 'Move current knot' }))
  vim.keymap.set('n', '<C-n><Del>', function()
    vim.fn['knot#DeleteCurrent']()
  end, vim.tbl_extend('force', opts, { desc = 'Delete current knot' }))

  -- URL operations
  vim.keymap.set('n', '<C-PageUp>', function()
    vim.fn['knot#pickUrl']()
  end, vim.tbl_extend('force', opts, { desc = 'Pick URL from current knot' }))

  -- Navigation
  vim.keymap.set('n', '<C-n><Backspace>', function()
    vim.fn['knot#goToBacklinks']()
  end, vim.tbl_extend('force', opts, { desc = 'Go to backlinks' }))
  vim.keymap.set('n', '<C-h>', function()
    vim.fn['knot#goToBacklinks']()
  end, vim.tbl_extend('force', opts, { desc = 'Go to backlinks' }))
  vim.keymap.set('n', '<C-n><PageDown>', function()
    vim.fn['knot#Pick']()
  end, vim.tbl_extend('force', opts, { desc = 'Pick knot' }))
  vim.keymap.set('n', '<F3>', function()
    vim.fn['knot#Pick']()
  end, vim.tbl_extend('force', opts, { desc = 'Pick knot' }))
  vim.keymap.set('n', '<C-F1>', function()
    vim.fn['knot#openReminder']()
  end, vim.tbl_extend('force', opts, { desc = 'Open reminder' }))

  -- Insertions and extractions
  vim.keymap.set('i', '<C-t>', '<C-c>i<C-R>=MyVimEditTimestamp()<CR>', vim.tbl_extend('force', opts, { desc = 'Insert timestamp' }))
  vim.keymap.set('n', '<C-t>', 'G<cmd>lua MarkdownInsertTimestamp()<cr>A', vim.tbl_extend('force', opts, { desc = 'Insert timestamp at end' }))
  vim.keymap.set('n', '<C-n>u', function()
    vim.fn['knot#insertOpenedTabURL']()
  end, vim.tbl_extend('force', opts, { desc = 'Insert opened tab URL' }))
  vim.keymap.set('n', '<C-n><Up>', 'i<C-R>=knot#DateLink()<CR>', vim.tbl_extend('force', opts, { desc = 'Insert date link' }))
  vim.keymap.set('n', '<leader>]', function()
    vim.fn['knot#InsertReminder']()
  end, vim.tbl_extend('force', opts, { desc = 'Insert reminder' }))

  -- Carve operation
  vim.keymap.set('x', '<C-n><Insert>', ':<c-u>call knot#CarveCurrentInteractive()<CR>', vim.tbl_extend('force', opts, { desc = 'Carve current selection' }))
end, { desc = 'Setup Knot buffer bindings' })

-- Format on save toggle command
vim.api.nvim_create_user_command('ToggleFormatOnSave', function()
  vim.g.disable_format_on_save = not vim.g.disable_format_on_save
  local status = vim.g.disable_format_on_save and 'disabled' or 'enabled'
  print('Format on save: ' .. status)
end, { desc = 'Toggle format on save globally' })

-- [[ Install `lazy.nvim` plugin manager ]]
--    See `:help lazy.nvim.txt` or https://github.com/folke/lazy.nvim for more info
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then
    error('Error cloning lazy.nvim:\n' .. out)
  end
end

local function apply_custom_colors()
  vim.api.nvim_set_hl(0, 'Normal', { bg = '#000013' }) -- Customize background color
  vim.api.nvim_set_hl(0, 'Visual', { bg = utils.adjust_brightness('#a6caf0', 0.45) }) -- Darker selection background
  -- Glowing red end-of-line whitespace
  vim.api.nvim_set_hl(0, 'ExtraWhitespace', { bg = '#ff0000', fg = '#ff4444', underline = true, bold = true })

  -- Orange markdown titles
  vim.api.nvim_set_hl(0, '@markup.heading.1.markdown', { fg = '#ffa850', bold = true })
  vim.api.nvim_set_hl(0, '@markup.heading.2.markdown', { fg = '#ffb850', bold = true })
  vim.api.nvim_set_hl(0, '@markup.heading.3.markdown', { fg = '#ffc850', bold = true })
  vim.api.nvim_set_hl(0, '@markup.heading.4.markdown', { fg = '#ffd850', bold = true })
  vim.api.nvim_set_hl(0, '@markup.heading.5.markdown', { fg = '#ffe850', bold = true })
  vim.api.nvim_set_hl(0, '@markup.heading.6.markdown', { fg = '#fff850', bold = true })

  -- Dark markdown link URLs (visible but very dark)
  vim.api.nvim_set_hl(0, '@markup.link.url.markdown_inline', { fg = '#006622' })

  -- vim.api.nvim_set_hl(0, 'Comment', { fg = '#6aa2f7' }) -- Example: customize comment color
  -- vim.api.nvim_set_hl(0, 'LineNr', { fg = '#565f89' }) -- Example: customize line numbers
end

---@type vim.Option
local rtp = vim.opt.rtp
rtp:prepend(lazypath)

-- [[ Configure and install plugins ]]
--
--  To check the current status of your plugins, run
--    :Lazy
--
--  You can press `?` in this menu for help. Use `:q` to close the window
--
--  To update plugins you can run
--    :Lazy update
--
-- NOTE: Here is where you install your plugins.
require('lazy').setup({
  -- NOTE: Plugins can be added with a link (or for a github repo: 'owner/repo' link).
  'NMAC427/guess-indent.nvim', -- Detect tabstop and shiftwidth automatically

  -- NOTE: Plugins can also be added by using a table,
  -- with the first argument being the link and the following
  -- keys can be used to configure plugin behavior/loading/etc.
  --
  -- Use `opts = {}` to automatically pass options to a plugin's `setup()` function, forcing the plugin to be loaded.
  --

  -- Alternatively, use `config = function() ... end` for full control over the configuration.
  -- If you prefer to call `setup` explicitly, use:
  --    {
  --        'lewis6991/gitsigns.nvim',
  --        config = function()
  --            require('gitsigns').setup({
  --                -- Your gitsigns configuration here
  --            })
  --        end,
  --    }
  --
  -- Here is a more advanced example where we pass configuration
  -- options to `gitsigns.nvim`.
  --
  -- See `:help gitsigns` to understand what the configuration keys do
  { -- Adds git related signs to the gutter, as well as utilities for managing changes
    'lewis6991/gitsigns.nvim',
    opts = {
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
    },
  },

  -- NOTE: Plugins can also be configured to run Lua code when they are loaded.
  --
  -- This is often very useful to both group configuration, as well as handle
  -- lazy loading plugins that don't need to be loaded immediately at startup.
  --
  -- For example, in the following configuration, we use:
  --  event = 'VimEnter'
  --
  -- which loads which-key before all the UI elements are loaded. Events can be
  -- normal autocommands events (`:help autocmd-events`).
  --
  -- Then, because we use the `opts` key (recommended), the configuration runs
  -- after the plugin has been loaded as `require(MODULE).setup(opts)`.

  { -- Useful plugin to show you pending keybinds.
    'folke/which-key.nvim',
    event = 'VimEnter', -- Sets the loading event to 'VimEnter'
    opts = {
      -- delay between pressing a key and opening which-key (milliseconds)
      -- this setting is independent of vim.o.timeoutlen
      delay = 0,
      icons = {
        -- set icon mappings to true if you have a Nerd Font
        mappings = vim.g.have_nerd_font,
        -- If you are using a Nerd Font: set icons.keys to an empty table which will use the
        -- default which-key.nvim defined Nerd Font icons, otherwise define a string table
        keys = vim.g.have_nerd_font and {} or {
          Up = '<Up> ',
          Down = '<Down> ',
          Left = '<Left> ',
          Right = '<Right> ',
          C = '<C-…> ',
          M = '<M-…> ',
          D = '<D-…> ',
          S = '<S-…> ',
          CR = '<CR> ',
          Esc = '<Esc> ',
          ScrollWheelDown = '<ScrollWheelDown> ',
          ScrollWheelUp = '<ScrollWheelUp> ',
          NL = '<NL> ',
          BS = '<BS> ',
          Space = '<Space> ',
          Tab = '<Tab> ',
          F1 = '<F1>',
          F2 = '<F2>',
          F3 = '<F3>',
          F4 = '<F4>',
          F5 = '<F5>',
          F6 = '<F6>',
          F7 = '<F7>',
          F8 = '<F8>',
          F9 = '<F9>',
          F10 = '<F10>',
          F11 = '<F11>',
          F12 = '<F12>',
        },
      },

      -- Document existing key chains
      spec = {
        { '<leader>s', group = '[S]earch' },
        { '<leader>t', group = '[T]oggle' },
        { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
      },
    },
  },

  -- NOTE: Plugins can specify dependencies.
  --
  -- The dependencies are proper plugin specifications as well - anything
  -- you do for a plugin at the top level, you can do for a dependency.
  --
  -- Use the `dependencies` key to specify the dependencies of a particular plugin

  { -- Fuzzy Finder (files, lsp, etc)
    'nvim-telescope/telescope.nvim',
    event = 'VimEnter',
    dependencies = {
      'nvim-lua/plenary.nvim',
      { -- If encountering errors, see telescope-fzf-native README for installation instructions
        'nvim-telescope/telescope-fzf-native.nvim',

        -- `build` is used to run some command when the plugin is installed/updated.
        -- This is only run then, not every time Neovim starts up.
        build = 'make',

        -- `cond` is a condition used to determine whether this plugin should be
        -- installed and loaded.
        cond = function()
          return vim.fn.executable 'make' == 1
        end,
      },
      { 'nvim-telescope/telescope-ui-select.nvim' },

      -- Useful for getting pretty icons, but requires a Nerd Font.
      { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
    },
    config = function()
      -- Telescope is a fuzzy finder that comes with a lot of different things that
      -- it can fuzzy find! It's more than just a "file finder", it can search
      -- many different aspects of Neovim, your workspace, LSP, and more!
      --
      -- The easiest way to use Telescope, is to start by doing something like:
      --  :Telescope help_tags
      --
      -- After running this command, a window will open up and you're able to
      -- type in the prompt window. You'll see a list of `help_tags` options and
      -- a corresponding preview of the help.
      --
      -- Two important keymaps to use while in Telescope are:
      --  - Insert mode: <c-/>
      --  - Normal mode: ?
      --
      -- This opens a window that shows you all of the keymaps for the current
      -- Telescope picker. This is really useful to discover what Telescope can
      -- do as well as how to actually do it!

      -- [[ Configure Telescope ]]
      -- See `:help telescope` and `:help telescope.setup()`
      require('telescope').setup {
        -- You can put your default mappings / updates / etc. in here
        --  All the info you're looking for is in `:help telescope.setup()`
        --
        -- defaults = {
        --   mappings = {
        --     i = { ['<c-enter>'] = 'to_fuzzy_refine' },
        --   },
        -- },
        -- pickers = {}
        extensions = {
          ['ui-select'] = {
            require('telescope.themes').get_dropdown(),
          },
        },
      }

      -- Enable Telescope extensions if they are installed
      pcall(require('telescope').load_extension, 'fzf')
      pcall(require('telescope').load_extension, 'ui-select')

      -- See `:help telescope.builtin`
      local builtin = require 'telescope.builtin'
      vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
      vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
      vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
      vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
      vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
      vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
      vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
      vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
      vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
      vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

      -- Slightly advanced example of overriding default behavior and theme
      vim.keymap.set('n', '<leader>/', function()
        -- You can pass additional configuration to Telescope to change the theme, layout, etc.
        builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
          winblend = 10,
          previewer = false,
        })
      end, { desc = '[/] Fuzzily search in current buffer' })

      -- It's also possible to pass additional configuration options.
      --  See `:help telescope.builtin.live_grep()` for information about particular keys
      vim.keymap.set('n', '<leader>s/', function()
        builtin.live_grep {
          grep_open_files = true,
          prompt_title = 'Live Grep in Open Files',
        }
      end, { desc = '[S]earch [/] in Open Files' })

      -- Shortcut for searching your Neovim configuration files
      vim.keymap.set('n', '<leader>sn', function()
        builtin.find_files { cwd = vim.fn.stdpath 'config' }
      end, { desc = '[S]earch [N]eovim files' })
    end,
  },

  -- LSP Plugins
  {
    -- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
    -- used for completion, annotations and signatures of Neovim apis
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = {
        -- Load luvit types when the `vim.uv` word is found
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
      },
    },
  },
  {
    'editorconfig/editorconfig-vim',
    lazy = false, -- Load immediately to ensure settings are applied on startup
  },
  {
    -- Main LSP Configuration
    'neovim/nvim-lspconfig',
    dependencies = {
      -- Automatically install LSPs and related tools to stdpath for Neovim
      -- Mason must be loaded before its dependents so we need to set it up here.
      -- NOTE: `opts = {}` is the same as calling `require('mason').setup({})`
      { 'mason-org/mason.nvim', opts = {} },
      'mason-org/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',

      -- Useful status updates for LSP.
      { 'j-hui/fidget.nvim', opts = {} },

      -- Allows extra capabilities provided by blink.cmp
      'saghen/blink.cmp',
    },
    config = function()
      -- Brief aside: **What is LSP?**
      --
      -- LSP is an initialism you've probably heard, but might not understand what it is.
      --
      -- LSP stands for Language Server Protocol. It's a protocol that helps editors
      -- and language tooling communicate in a standardized fashion.
      --
      -- In general, you have a "server" which is some tool built to understand a particular
      -- language (such as `gopls`, `lua_ls`, `rust_analyzer`, etc.). These Language Servers
      -- (sometimes called LSP servers, but that's kind of like ATM Machine) are standalone
      -- processes that communicate with some "client" - in this case, Neovim!
      --
      -- LSP provides Neovim with features like:
      --  - Go to definition
      --  - Find references
      --  - Autocompletion
      --  - Symbol Search
      --  - and more!
      --
      -- Thus, Language Servers are external tools that must be installed separately from
      -- Neovim. This is where `mason` and related plugins come into play.
      --
      -- If you're wondering about lsp vs treesitter, you can check out the wonderfully
      -- and elegantly composed help section, `:help lsp-vs-treesitter`

      --  This function gets run when an LSP attaches to a particular buffer.
      --    That is to say, every time a new file is opened that is associated with
      --    an lsp (for example, opening `main.rs` is associated with `rust_analyzer`) this
      --    function will be executed to configure the current buffer
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
        callback = function(event)
          -- NOTE: Remember that Lua is a real programming language, and as such it is possible
          -- to define small helper and utility functions so you don't have to repeat yourself.
          --
          -- In this case, we create a function that lets us more easily define mappings specific
          -- for LSP related items. It sets the mode, buffer and description for us each time.
          local map = function(keys, func, desc, mode)
            mode = mode or 'n'
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end

          -- Rename the variable under your cursor.
          --  Most Language Servers support renaming across files, etc.
          map('grn', vim.lsp.buf.rename, '[R]e[n]ame')
          map('<C-a>r', vim.lsp.buf.rename, '[R]e[n]ame')
          map('<F6>', vim.lsp.buf.rename, '[R]e[n]ame')

          -- Execute a code action, usually your cursor needs to be on top of an error
          -- or a suggestion from your LSP for this to activate.
          map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })
          map('<C-a>a', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })
          map('<C-a><C-a>', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })

          -- Find references for the word under your cursor.
          map('grr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
          map('<C-a>R', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')

          -- Jump to the implementation of the word under your cursor.
          --  Useful when your language has ways of declaring types without an actual implementation.
          map('gri', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
          map('<C-a>i', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')

          -- Jump to the definition of the word under your cursor.
          --  This is where a variable was first declared, or where a function is defined, etc.
          --  To jump back, press <C-t>.
          map('grd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
          map('<C-a>d', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
          map('<leader><C-d>', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')

          -- WARN: This is not Goto Definition, this is Goto Declaration.
          --  For example, in C this would take you to the header.
          map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
          map('<C-a>D', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
          -- Fuzzy find all the symbols in your current document.
          --  Symbols are things like variables, functions, types, etc.
          map('gO', require('telescope.builtin').lsp_document_symbols, 'Open Document Symbols')

          -- Fuzzy find all the symbols in your current workspace.
          --  Similar to document symbols, except searches over your entire project.
          map('gW', require('telescope.builtin').lsp_dynamic_workspace_symbols, 'Open Workspace Symbols')

          -- Jump to the type of the word under your cursor.
          --  Useful when you're not sure what type a variable is and you want to see
          --  the definition of its *type*, not where it was *defined*.
          map('grt', require('telescope.builtin').lsp_type_definitions, '[G]oto [T]ype Definition')

          -- This function resolves a difference between neovim nightly (version 0.11) and stable (version 0.10)
          ---@param client vim.lsp.Client
          ---@param method vim.lsp.protocol.Method
          ---@param bufnr? integer some lsp support methods only in specific files
          ---@return boolean
          local function client_supports_method(client, method, bufnr)
            if vim.fn.has 'nvim-0.11' == 1 then
              return client:supports_method(method, bufnr)
            else
              return client.supports_method(method, { bufnr = bufnr })
            end
          end

          -- The following two autocommands are used to highlight references of the
          -- word under your cursor when your cursor rests there for a little while.
          --    See `:help CursorHold` for information about when this is executed
          --
          -- When you move your cursor, the highlights will be cleared (the second autocommand).
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
            local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.document_highlight,
            })

            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.clear_references,
            })

            vim.api.nvim_create_autocmd('LspDetach', {
              group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
              callback = function(event2)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
              end,
            })
          end

          -- The following code creates a keymap to toggle inlay hints in your
          -- code, if the language server you are using supports them
          --
          -- This may be unwanted, since they displace some of your code
          if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
            map('<leader>th', function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
            end, '[T]oggle Inlay [H]ints')
          end
        end,
      })

      -- Diagnostic Config
      -- See :help vim.diagnostic.Opts
      vim.diagnostic.config {
        severity_sort = true,
        float = { border = 'rounded', source = 'if_many' },
        underline = { severity = vim.diagnostic.severity.ERROR },
        signs = vim.g.have_nerd_font and {
          text = {
            [vim.diagnostic.severity.ERROR] = '󰅚 ',
            [vim.diagnostic.severity.WARN] = '󰀪 ',
            [vim.diagnostic.severity.INFO] = '󰋽 ',
            [vim.diagnostic.severity.HINT] = '󰌶 ',
          },
        } or {},
        virtual_text = {
          source = 'if_many',
          spacing = 2,
          format = function(diagnostic)
            local diagnostic_message = {
              [vim.diagnostic.severity.ERROR] = diagnostic.message,
              [vim.diagnostic.severity.WARN] = diagnostic.message,
              [vim.diagnostic.severity.INFO] = diagnostic.message,
              [vim.diagnostic.severity.HINT] = diagnostic.message,
            }
            return diagnostic_message[diagnostic.severity]
          end,
        },
      }

      -- LSP servers and clients are able to communicate to each other what features they support.
      --  By default, Neovim doesn't support everything that is in the LSP specification.
      --  When you add blink.cmp, luasnip, etc. Neovim now has *more* capabilities.
      --  So, we create new capabilities with blink.cmp, and then broadcast that to the servers.
      local capabilities = require('blink.cmp').get_lsp_capabilities()

      -- Enable the following language servers
      --  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
      --
      --  Add any additional override configuration in the following tables. Available keys are:
      --  - cmd (table): Override the default command used to start the server
      --  - filetypes (table): Override the default list of associated filetypes for the server
      --  - capabilities (table): Override fields in capabilities. Can be used to disable certain LSP features.
      --  - settings (table): Override the default settings passed when initializing the server.
      --        For example, to see the options for `lua_ls`, you could go to: https://luals.github.io/wiki/settings/
      local servers = {
        -- clangd = {},
        -- gopls = {},
        -- pyright = {},
        rust_analyzer = {
          settings = {
            server = {
              path = vim.fn.expand '$HOME/.rustup/toolchains/nightly-x86_64-unknown-linux-gnu/bin/rust-analyzer',
            },
          },
        },
        -- ... etc. See `:help lspconfig-all` for a list of all the pre-configured LSPs
        --
        -- Some languages (like typescript) have entire language plugins that can be useful:
        --    https://github.com/pmizio/typescript-tools.nvim
        --
        -- But for many setups, the LSP (`ts_ls`) will work just fine
        ts_ls = {
          settings = {
            typescript = {
              inlayHints = {
                includeInlayParameterNameHints = 'all',
                includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                includeInlayFunctionParameterTypeHints = true,
                includeInlayVariableTypeHints = true,
                includeInlayPropertyDeclarationTypeHints = true,
                includeInlayFunctionLikeReturnTypeHints = true,
                includeInlayEnumMemberValueHints = true,
              },
            },
            javascript = {
              inlayHints = {
                includeInlayParameterNameHints = 'all',
                includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                includeInlayFunctionParameterTypeHints = true,
                includeInlayVariableTypeHints = true,
                includeInlayPropertyDeclarationTypeHints = true,
                includeInlayFunctionLikeReturnTypeHints = true,
                includeInlayEnumMemberValueHints = true,
              },
            },
          },
        },

        lua_ls = {
          -- cmd = { ... },
          -- filetypes = { ... },
          -- capabilities = {},
          settings = {
            Lua = {
              completion = {
                callSnippet = 'Replace',
              },
              -- You can toggle below to ignore Lua_LS's noisy `missing-fields` warnings
              -- diagnostics = { disable = { 'missing-fields' } },
            },
          },
        },
      }

      -- Ensure the servers and tools above are installed
      --
      -- To check the current status of installed tools and/or manually install
      -- other tools, you can run
      --    :Mason
      --
      -- You can press `g?` for help in this menu.
      --
      -- `mason` had to be setup earlier: to configure its options see the
      -- `dependencies` table for `nvim-lspconfig` above.
      --
      -- You can add other tools here that you want Mason to install
      -- for you, so that they are available from within Neovim.
      local ensure_installed = vim.tbl_keys(servers or {})
      vim.list_extend(ensure_installed, {
        'stylua', -- Used to format Lua code
        'prettierd', -- Fast prettier daemon for TypeScript/JavaScript formatting
        'prettier', -- Fallback formatter for TypeScript/JavaScript
      })
      require('mason-tool-installer').setup { ensure_installed = ensure_installed }

      require('mason-lspconfig').setup {
        ensure_installed = {}, -- explicitly set to an empty table (Kickstart populates installs via mason-tool-installer)
        automatic_installation = false,
        handlers = {
          function(server_name)
            local server = servers[server_name] or {}
            -- This handles overriding only values explicitly passed
            -- by the server configuration above. Useful when disabling
            -- certain features of an LSP (for example, turning off formatting for ts_ls)
            server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
            require('lspconfig')[server_name].setup(server)
          end,
        },
      }
    end,
  },

  { -- Autoformat
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<leader>f',
        function()
          require('conform').format { async = true, lsp_format = 'fallback' }
        end,
        mode = '',
        desc = '[F]ormat buffer',
      },
    },
    opts = {
      notify_on_error = false,
      format_on_save = function(bufnr)
        -- Check global disable flag first
        if vim.g.disable_format_on_save then
          return nil
        end
        -- Disable "format_on_save lsp_fallback" for languages that don't
        -- have a well standardized coding style. You can add additional
        -- languages here or re-enable it for the disabled ones.
        local disable_filetypes = { c = true, cpp = true }
        if disable_filetypes[vim.bo[bufnr].filetype] then
          return nil
        else
          return {
            timeout_ms = 500,
            lsp_format = 'fallback',
          }
        end
      end,
      formatters_by_ft = {
        lua = { 'stylua' },
        -- Conform can also run multiple formatters sequentially
        -- python = { "isort", "black" },
        --
        -- You can use 'stop_after_first' to run the first available formatter from the list
        javascript = { 'prettierd', 'prettier', stop_after_first = true },
        typescript = { 'prettierd', 'prettier', stop_after_first = true },
        javascriptreact = { 'prettierd', 'prettier', stop_after_first = true },
        typescriptreact = { 'prettierd', 'prettier', stop_after_first = true },
        json = { 'prettierd', 'prettier', stop_after_first = true },
        jsonc = { 'prettierd', 'prettier', stop_after_first = true },
      },
    },
  },

  {
    'matze/vim-move',
    config = function() end,
  },

  { -- Autocompletion
    'saghen/blink.cmp',
    event = 'VimEnter',
    version = '1.*',
    dependencies = {
      -- UltiSnips support
      'SirVer/ultisnips',
      -- Snippet Engine
      {
        'L3MON4D3/LuaSnip',
        version = '2.*',
        build = (function()
          -- Build Step is needed for regex support in snippets.
          -- This step is not supported in many windows environments.
          -- Remove the below condition to re-enable on windows.
          if vim.fn.has 'win32' == 1 or vim.fn.executable 'make' == 0 then
            return
          end
          return 'make install_jsregexp'
        end)(),
        dependencies = {
          -- `friendly-snippets` contains a variety of premade snippets.
          --    See the README about individual language/framework/plugin snippets:
          --    https://github.com/rafamadriz/friendly-snippets
          -- {
          --   'rafamadriz/friendly-snippets',
          --   config = function()
          --     require('luasnip.loaders.from_vscode').lazy_load()
          --   end,
          -- },
        },
        opts = {},
      },
      'folke/lazydev.nvim',
    },
    --- @module 'blink.cmp'
    --- @type blink.cmp.Config
    opts = {
      keymap = {
        -- 'default' (recommended) for mappings similar to built-in completions
        --   <c-y> to accept ([y]es) the completion.
        --    This will auto-import if your LSP supports it.
        --    This will expand snippets if the LSP sent a snippet.
        -- 'super-tab' for tab to accept
        -- 'enter' for enter to accept
        -- 'none' for no mappings
        --
        -- For an understanding of why the 'default' preset is recommended,
        -- you will need to read `:help ins-completion`
        --
        -- No, but seriously. Please read `:help ins-completion`, it is really good!
        --
        -- All presets have the following mappings:
        -- <tab>/<s-tab>: move to right/left of your snippet expansion
        -- <c-space>: Open menu or open docs if already open
        -- <c-n>/<c-p> or <up>/<down>: Select next/previous item
        -- <c-e>: Hide menu
        -- <c-k>: Toggle signature help
        --
        -- See :h blink-cmp-config-keymap for defining your own keymap
        preset = 'super-tab',
        ['<CR>'] = { blink_cmp_enter },
        ['<M-T-PageUp>'] = { accept_blink_cmcp },
        ['<C-a>'] = { accept_blink_cmcp },
        -- For more advanced Luasnip keymaps (e.g. selecting choice nodes, expansion) see:
        --    https://github.com/L3MON4D3/LuaSnip?tab=readme-ov-file#keymaps
      },

      appearance = {
        -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
        -- Adjusts spacing to ensure icons are aligned
        nerd_font_variant = 'mono',
      },

      completion = {
        -- By default, you may press `<c-space>` to show the documentation.
        -- Optionally, set `auto_show = true` to show the documentation after a delay.
        documentation = { auto_show = false, auto_show_delay_ms = 500 },
      },

      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer', 'lazydev', 'knots', 'ultisnips' },
        providers = {
          lsp = { score_offset = 110 },
          lazydev = { module = 'lazydev.integrations.blink', score_offset = 100 },
          knots = {
            name = 'Knots',
            module = 'knots',
            opts = {},
          },
          ultisnips = {
            name = 'UltiSnips',
            module = 'blink.cmp.sources.ultisnips',
            score_offset = 90,
            opts = {},
          },
          buffer = {
            name = 'Buffer',
            module = 'blink.cmp.sources.buffer',
            opts = {
              -- Get completions from all visible buffers
              get_bufnrs = function()
                local bufs = {}
                for _, win in ipairs(vim.api.nvim_list_wins()) do
                  bufs[vim.api.nvim_win_get_buf(win)] = true
                end
                return vim.tbl_keys(bufs)
              end,
            },
          },
        },
      },

      snippets = { preset = 'luasnip' },

      -- Blink.cmp includes an optional, recommended rust fuzzy matcher,
      -- which automatically downloads a prebuilt binary when enabled.
      --
      -- By default, we use the Lua implementation instead, but you may enable
      -- the rust implementation via `'prefer_rust_with_warning'`
      --
      -- See :h blink-cmp-config-fuzzy for more information
      fuzzy = { implementation = 'lua' },

      -- Shows a signature help window while you type arguments for a function
      signature = { enabled = true },
    },
  },

  { -- You can easily change to a different colorscheme.
    -- Change the name of the colorscheme plugin below, and then
    -- change the command in the config to whatever the name of that colorscheme is.
    --
    -- If you want to see what colorschemes are already installed, you can use `:Telescope colorscheme`.
    'folke/tokyonight.nvim',
    -- enabled = false,
    priority = 1000, -- Make sure to load this before all the other start plugins.
    config = function()
      ---@diagnostic disable-next-line: missing-fields
      require('tokyonight').setup {
        styles = {
          comments = { italic = false }, -- Disable italics in comments
        },
      }

      -- Load the colorscheme here.
      -- Like many other themes, this one has different styles, and you could load
      -- any other, such as 'tokyonight-storm', 'tokyonight-moon', or 'tokyonight-day'.
      vim.cmd.colorscheme 'tokyonight-night'

      -- Custom color overrides
      apply_custom_colors()
    end,
  },

  -- Highlight todo, notes, etc in comments
  { 'folke/todo-comments.nvim', event = 'VimEnter', dependencies = { 'nvim-lua/plenary.nvim' }, opts = { signs = false } },

  { -- Collection of various small independent plugins/modules
    'echasnovski/mini.nvim',
    config = function()
      -- Better Around/Inside textobjects
      --
      -- Examples:
      --  - va)  - [V]isually select [A]round [)]paren
      --  - yinq - [Y]ank [I]nside [N]ext [Q]uote
      --  - ci'  - [C]hange [I]nside [']quote
      require('mini.ai').setup { n_lines = 500 }

      -- Add/delete/replace surroundings (brackets, quotes, etc.)
      --
      -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
      -- - sd'   - [S]urround [D]elete [']quotes
      -- - sr)'  - [S]urround [R]eplace [)] [']
      require('mini.surround').setup()

      -- Simple and easy statusline.
      --  You could remove this setup call if you don't like it,
      --  and try some other statusline plugin
      local statusline = require 'mini.statusline'
      -- set use_icons to true if you have a Nerd Font
      statusline.setup { use_icons = vim.g.have_nerd_font }

      -- You can configure sections in the statusline by overriding their
      -- default behavior. For example, here we set the section for
      -- cursor location to LINE:COLUMN
      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_location = function()
        return '%2l:%-2v'
      end

      -- Custom filename section using our VimScript function
      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_filename = function()
        return '%{%MyStatuslineRelativePath()%}'
      end

      -- ... and there is more!
      --  Check out: https://github.com/echasnovski/mini.nvim
    end,
  },
  { -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    main = 'nvim-treesitter.configs', -- Sets main module to use for opts
    -- [[ Configure Treesitter ]] See `:help nvim-treesitter`
    opts = {
      ensure_installed = {
        'bash',
        'c',
        'diff',
        'html',
        'lua',
        'luadoc',
        'markdown',
        'markdown_inline',
        'query',
        'vim',
        'vimdoc',
        'rust',
        'typescript',
        'javascript',
        'tsx',
        'json',
        'jsonc',
      },
      -- Autoinstall languages that are not installed
      auto_install = true,
      highlight = {
        enable = true,
        -- Some languages depend on vim's regex highlighting system (such as Ruby) for indent rules.
        --  If you are experiencing weird indenting issues, add the language to
        --  the list of additional_vim_regex_highlighting and disabled languages for indent.
        additional_vim_regex_highlighting = { 'ruby' },
      },
      indent = { enable = true, disable = { 'ruby' } },
      incremental_selection = {
        enable = true,
        keymaps = {
          node_incremental = nil,
          init_incremental = nil,
        },
      },
    },
    -- There are additional nvim-treesitter modules that you can use to interact
    -- with nvim-treesitter. You should go explore a few and see what interests you:
    --
    --    - Incremental selection: Included, see `:help nvim-treesitter-incremental-selection-mod`
    --    - Show your current context: https://github.com/nvim-treesitter/nvim-treesitter-context
    --    - Treesitter + textobjects: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
  },

  -- The following comments only work if you have downloaded the kickstart repo, not just copy pasted the
  -- init.lua. If you want these files, they are in the repository, so you can just download them and
  -- place them in the correct locations.

  -- NOTE: Next step on your Neovim journey: Add/Configure additional plugins for Kickstart
  --
  --  Here are some example plugins that I've included in the Kickstart repository.
  --  Uncomment any of the lines below to enable them (you will need to restart nvim).
  --
  -- require 'kickstart.plugins.debug',
  -- require 'kickstart.plugins.indent_line',
  -- require 'kickstart.plugins.lint',
  -- require 'kickstart.plugins.autopairs',
  -- require 'kickstart.plugins.neo-tree',
  require 'kickstart.plugins.gitsigns', -- adds gitsigns recommend keymaps

  {
    'MeanderingProgrammer/render-markdown.nvim',
    ft = { 'markdown', 'quarto' },
    opts = {
      heading = {
        icons = false,
      },
      indent = {
        -- Mimic org-indent-mode behavior by indenting everything under a heading based on the
        -- level of the heading. Indenting starts from level 2 headings onward by default.

        -- Turn on / off org-indent-mode.
        enabled = true,
        -- Additional modes to render indents.
        render_modes = false,
        -- Amount of additional padding added for each heading level.
        per_level = 2,
        -- Heading levels <= this value will not be indented.
        -- Use 0 to begin indenting from the very first level.
        skip_level = 1,
        -- Do not indent heading titles, only the body.
        skip_heading = false,
        -- Prefix added when indenting, one per level.
        icon = '▎',
        -- Priority to assign to extmarks.
        priority = 0,
        -- Applied to icon.
        highlight = 'RenderMarkdownIndent',
      },
      win_options = {
        conceallevel = { default = vim.o.conceallevel, rendered = 0 },
        concealcursor = { default = vim.o.concealcursor, rendered = '' },
      },
    },
  },

  { -- Enhanced markdown support
    'tadmccorkle/markdown.nvim',
    ft = 'markdown',
    config = function()
      require('markdown').setup {
        mappings = {
          inline_surround_toggle = 'gs',
          inline_surround_toggle_line = 'gss',
          inline_surround_delete = 'ds',
          inline_surround_change = 'cs',
          link_add = 'gl',
          link_follow = false,
          go_curr_heading = ']c',
          go_parent_heading = ']p',
          go_next_heading = ']]',
          go_prev_heading = '[[',
        },
        on_attach = function(bufnr)
          local map = vim.keymap.set
          local opts = { buffer = bufnr }
          map({ 'n', 'i' }, '<C-\\>', '<Cmd>MDListItemBelow<CR>', opts)
          map({ 'n', 'i' }, '<M-e>\\', '<Cmd>MDListItemAbove<CR>', opts)

          -- Add sub-bullet (indented list item)
          map({ 'n', 'i' }, '<C-Insert>', function()
            -- Create a new list item below current one
            vim.cmd 'MDListItemBelow'
            -- Add indentation (4 spaces for sub-bullet)
            local line = vim.api.nvim_get_current_line()
            vim.api.nvim_set_current_line('    ' .. line)
            -- Position cursor at end and enter insert mode
            vim.cmd 'startinsert!'
            vim.api.nvim_win_set_cursor(0, { vim.api.nvim_win_get_cursor(0)[1], vim.fn.col '$' })
          end, vim.tbl_extend('force', opts, { desc = 'Add sub-bullet' }))
        end,
      }
    end,
  },

  { -- Knots plugin from local path
    dir = (function()
      local knots_path = os.getenv 'KNOTS_CONFIG_SCRIPTS_DIR'
      if not knots_path or knots_path == '' then
        knots_path = vim.fn.expand '~/.local/share/knots'
      end
      return knots_path .. '/vim'
    end)(),
    name = 'knots',
    lazy = false, -- equivalent to 'frozen': 1 - don't update
    config = function()
      vim.g.knots_config_script_path = os.getenv 'KNOTS_CONFIG_SCRIPTS_DIR'
      if not vim.g.knots_config_script_path or vim.g.knots_config_script_path == '' then
        vim.g.knots_config_script_path = vim.fn.expand '~/.local/share/knots'
      end
      require 'knots'
    end,
  },

  -- Github theme
  {
    'projekt0n/github-nvim-theme',
    name = 'github-theme',
    lazy = false,
    enabled = false,
    priority = 1001,
    config = function()
      require('github-theme').setup {}
      vim.cmd 'colorscheme github_dark'

      -- Override treesitter highlights
      -- vim.api.nvim_set_hl(0, '@type', { fg = '#00ff00' })
      -- vim.api.nvim_set_hl(0, '@type.builtin', { fg = '#00ff00' })
      vim.api.nvim_set_hl(0, '@keyword', { fg = '#ffff80' })
      vim.api.nvim_set_hl(0, '@keyword.operator', { fg = '#ffb0b0' })
      vim.api.nvim_set_hl(0, '@operator', { fg = '#ffb0b0' })
      vim.api.nvim_set_hl(0, '@operator.lua', { fg = '#ffb0b0' })
      vim.api.nvim_set_hl(0, '@operator.c', { fg = '#ffb0b0' })
      vim.api.nvim_set_hl(0, '@keyword.function', { fg = '#60ff60' })
      vim.api.nvim_set_hl(0, '@variable', { fg = '#80ff80' })
      vim.api.nvim_set_hl(0, '@variable.member', { fg = '#c0ffc0' })
      -- vim.api.nvim_set_hl(0, '@function.call', { fg = '#ffff00' })
      vim.api.nvim_set_hl(0, 'PreProc', { fg = '#ff80ff' })
      -- vim.api.nvim_set_hl(0, 'Constant', { fg = '#ffff00' })
      vim.api.nvim_set_hl(0, 'String', { fg = '#00e0ff' })
      vim.api.nvim_set_hl(0, 'Function', { fg = '#f0d080' })
      vim.api.nvim_set_hl(0, 'Comment', { fg = '#888888' })
      vim.api.nvim_set_hl(0, '@markup.list', { fg = '#ff8000' })
      apply_custom_colors()
    end,
  },

  { -- FZF fuzzy finder
    'junegunn/fzf.vim',
    dependencies = { 'junegunn/fzf' },
    keys = {
      { '<leader>ff', '<cmd>Files<CR>', desc = 'FZF Files' },
      { '<leader>fb', '<cmd>Buffers<CR>', desc = 'FZF Buffers' },
      { '<leader>fg', '<cmd>Rg<CR>', desc = 'FZF Ripgrep' },
      { '<leader>fl', '<cmd>Lines<CR>', desc = 'FZF Lines in buffers' },
      { '<leader>fh', '<cmd>History<CR>', desc = 'FZF File history' },
    },
    config = function()
      -- Use ripgrep for Files command if available
      if vim.fn.executable 'rg' == 1 then
        vim.env.FZF_DEFAULT_COMMAND = 'rg --files --hidden --follow --glob "!.git/*"'
      end

      -- Customize fzf layout
      vim.g.fzf_layout = { down = '~40%' }

      -- Preview window for files
      vim.g.fzf_preview_window = { 'right:50%', 'ctrl-/' }
    end,
  },

  { -- Automatically change to project root directory
    'airblade/vim-rooter',
    opts = {},
    config = function()
      vim.g.rooter_patterns = { '.git', '.git/', '_darcs/', '.hg/', '.bzr/', '.svn/' }
      vim.g.rooter_change_directory_for_non_project_files = 'current'
      vim.g.rooter_silent_chdir = 1
    end,
  },

  { -- Comprehensive Git integration
    'tpope/vim-fugitive',
    cmd = { 'Git', 'G', 'Gwrite', 'Gread', 'Gdiffsplit' },
    keys = {
      { '<leader>gs', '<cmd>Git<cr>', desc = 'Git status' },
      { '<leader>gb', '<cmd>Git blame<cr>', desc = 'Git blame' },
      { '<leader>gc', '<cmd>Git commit<cr>', desc = 'Git commit' },
      { '<leader>gp', '<cmd>Git push<cr>', desc = 'Git push' },
      { '<leader>gl', '<cmd>Git pull<cr>', desc = 'Git pull' },
      { '<leader>gd', '<cmd>Gdiffsplit<cr>', desc = 'Git diff split' },
    },
  },

  { -- Git commit browser
    'junegunn/gv.vim',
    dependencies = { 'tpope/vim-fugitive' },
    cmd = { 'GV' },
    keys = {
      { '<C-g>r', '<cmd>GV<cr>', desc = 'Git commit browser' },
      { '<C-g>r', ':GV<cr>', mode = 'v', desc = 'Git commit browser for selection' },
    },
  },

  { -- Enhanced diff views
    'sindrets/diffview.nvim',
    cmd = { 'DiffviewOpen', 'DiffviewFileHistory', 'DiffviewClose' },
    keys = {
      { '<leader>gv', '<cmd>DiffviewOpen<cr>', desc = 'Diff view open' },
      { '<leader>gh', '<cmd>DiffviewFileHistory<cr>', desc = 'File history' },
      { '<leader>gx', '<cmd>DiffviewClose<cr>', desc = 'Close diff view' },
    },
    config = true,
  },

  { -- Git conflict marker resolution
    'rhysd/conflict-marker.vim',
    lazy = false,
  },

  { -- Magit-like Git interface for Neovim
    'NeogitOrg/neogit',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'sindrets/diffview.nvim',
      'nvim-telescope/telescope.nvim',
    },
    config = true,
    keys = {
      { '<leader>gg', '<cmd>Neogit<cr>', desc = 'Neogit interface' },
      { '<leader>gr', '<cmd>Neogit rebase<cr>', desc = 'Neogit rebase' },
    },
  },

  { -- Local vimrc support for project-specific settings
    'da-x/local_vimrc',
    opts = {},
    dependencies = { 'LucHermitte/lh-vim-lib' },
    config = function() end,
  },

  { -- Linux kernel coding style
    'vivien/vim-linux-coding-style',
    ft = { 'c', 'cpp' },
    lazy = false,
    config = function()
      vim.g.linuxsty_patterns = { '/linux/', '/kernel/' }
    end,
  },

  { -- Highlight trailing whitespace in red
    'bronson/vim-trailing-whitespace',
    event = { 'BufReadPost', 'BufNewFile' },
    config = function()
      -- Plugin automatically highlights trailing whitespace in red
      -- Use :FixWhitespace to remove all trailing whitespace
    end,
  },

  { -- Custom linting with nvim-lint
    'mfussenegger/nvim-lint',
    event = { 'BufReadPost', 'BufNewFile', 'BufWritePost' },
    config = function()
      local lint = require 'lint'

      -- Custom Python-based GCC linter
      lint.linters.gcc_python = {
        name = 'gcc_python',
        cmd = vim.fn.stdpath 'config' .. '/bin/gcc_linter.py',
        stdin = false,
        args = {},
        append_fname = true,
        stream = 'stdout',
        ignore_exitcode = true,
        parser = function(output, bufnr)
          local diagnostics = {}

          if output == '' or output == nil then
            return diagnostics
          end

          local ok, decoded = pcall(vim.json.decode, output)
          if not ok or not decoded or type(decoded) ~= 'table' then
            return diagnostics
          end

          for _, item in ipairs(decoded) do
            local severity_map = {
              error = vim.diagnostic.severity.ERROR,
              warning = vim.diagnostic.severity.WARN,
              note = vim.diagnostic.severity.INFO,
            }

            table.insert(diagnostics, {
              lnum = (item.line or 1) - 1,
              col = (item.column or 1) - 1,
              severity = severity_map[item.severity] or vim.diagnostic.severity.ERROR,
              message = item.message or '',
              source = 'gcc_python',
            })
          end

          return diagnostics
        end,
      }

      -- Configure linters by filetype
      lint.linters_by_ft = {
        c = { 'gcc_python' },
        cpp = { 'gcc_python' },
      }

      -- Auto-lint on these events
      local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })
      vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
        group = lint_augroup,
        callback = function()
          lint.try_lint()
        end,
      })

      -- Manual command to test linting
      vim.api.nvim_create_user_command('TestLint', function()
        lint.try_lint 'gcc_python'
      end, { desc = 'Test GCC linter manually' })
    end,
  },

  { -- File explorer tree
    'nvim-tree/nvim-tree.lua',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    opts = {
      disable_netrw = true,
      hijack_netrw = true,
      view = {
        width = 30,
        side = 'right',
      },
      renderer = {
        group_empty = true,
      },
      filters = {
        dotfiles = false,
      },
      actions = {
        open_file = {
          quit_on_open = true,
        },
      },
      update_focused_file = {
        enable = true,
        update_root = true,
      },
    },
    keys = {
      { '<F3>', '<cmd>NvimTreeFindFileToggle<CR>', desc = 'Find file in tree and toggle' },
      { '<C-F3>', '<cmd>NvimTreeToggle<CR>', desc = 'Toggle file explorer' },
    },
    config = function(_, opts)
      require('nvim-tree').setup(opts)

      -- F3 keybindings for insert and command modes
      vim.keymap.set('!', '<F3>', '<Nop>')
      vim.keymap.set('i', '<F3>', '<C-c><F3>')
      vim.keymap.set('!', '<C-F3>', '<Nop>')
      vim.keymap.set('i', '<C-F3>', '<C-c><C-F3>')

      -- ESC to close nvim-tree when in nvim-tree buffer
      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'NvimTree',
        callback = function(ev)
          vim.keymap.set('n', '<Esc>', '<cmd>NvimTreeClose<CR>', { buffer = ev.buf, desc = 'Close nvim-tree' })
        end,
      })
    end,
  },

  -- NOTE: The import below can automatically add your own plugins, configuration, etc from `lua/custom/plugins/*.lua`
  --    This is the easiest way to modularize your config.
  --
  --  Uncomment the following line and add your plugins to `lua/custom/plugins/*.lua` to get going.
  -- { import = 'custom.plugins' },
  --
  -- For additional information with loading, sourcing and examples see `:help lazy.nvim-🔌-plugin-spec`
  -- Or use telescope!
  -- In normal mode type `<space>sh` then write `lazy.nvim-plugin`
  -- you can continue same window with `<space>sr` which resumes last telescope search
}, {
  ui = {
    checker = { enabled = true },
    -- If you are using a Nerd Font: set icons to an empty table which will use the
    -- default lazy.nvim defined Nerd Font icons, otherwise define a unicode icons table
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
  },
})

require('lazy').load { plugins = {
  'fzf.vim',
  'local_vimrc',
  'vim-rooter',
  'markdown.nvim',
} }

-- Function to edit UltiSnips for current filetype
function MyEditUltiSnips()
  vim.cmd 'UltiSnipsEdit'
end

-- Keymap for editing UltiSnips
vim.keymap.set('n', '<leader>sm', MyEditUltiSnips, { desc = 'Edit UltiSnips for current filetype' })

-- Source additional VimScript configuration
vim.cmd('source ' .. vim.fn.stdpath 'config' .. '/vimscript.vim')

--
-- How to inspect binds?
--
-- Example:
--
--     rvim --headless -c "verbose imap <Tab>" -c 'qa!'
--
-- Show all bindings:
--
--     rvim --headless -c "verbose nmap " -c 'qa!' 2>&1
--
--
-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
