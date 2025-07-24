-- WezTerm Configuration
-- ===================
-- This configuration aims to replicate iTerm2 behavior and keybindings for a seamless
-- transition between terminals. It's designed to work cross-platform (macOS and Linux)
-- while maintaining the muscle memory and workflows from iTerm2.
--
-- Key Features:
-- - iTerm2-style keyboard shortcuts for tabs and panes
-- - Command+Click to open files in VS Code (with line number support)
-- - Gruvbox dark theme
-- - FiraMono Nerd Font
-- - Cross-platform compatibility

local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- Environment Setup
-- =================
-- Fix PATH for GUI applications on macOS
-- When WezTerm is launched from Spotlight/Dock, it doesn't inherit the shell's PATH,
-- which causes issues with commands like 'code' for VS Code
if wezterm.target_triple:find('darwin') then
  config.set_environment_variables = {
    PATH = '/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:' .. (os.getenv('PATH') or ''),
  }
end

-- Appearance
-- ==========
-- Font configuration to match iTerm2 setup
config.font = wezterm.font('FiraMono Nerd Font Mono', { weight = 'Regular' })
config.font_size = 16.0

-- Enable unlimited scrollback like iTerm2
config.scrollback_lines = 999999

-- Colors and theme - using Gruvbox dark theme
config.color_scheme = 'Gruvbox dark, hard (base16)'

-- Tab bar settings
config.use_fancy_tab_bar = true
config.enable_tab_bar = true
config.tab_bar_at_bottom = false
config.window_decorations = "RESIZE"

-- Enable native macOS fullscreen
config.native_macos_fullscreen_mode = true

-- Key Bindings
-- ============
-- Replicate iTerm2's keyboard shortcuts for seamless transition
config.keys = {
  -- Tab Management
  -- --------------
  
  -- New tab: Command + T (same as iTerm2)
  {
    key = 't',
    mods = 'CMD',
    action = wezterm.action.SpawnTab 'CurrentPaneDomain',
  },
  
  -- Cycle to next tab: Command + Right Arrow (same as iTerm2)
  {
    key = 'RightArrow',
    mods = 'CMD',
    action = wezterm.action.ActivateTabRelative(1),
  },
  
  -- Cycle to previous tab: Command + Left Arrow (same as iTerm2)
  {
    key = 'LeftArrow',
    mods = 'CMD',
    action = wezterm.action.ActivateTabRelative(-1),
  },
  
  -- Pane Management
  -- ---------------
  
  -- Split pane vertically (new pane on right): Command + D (same as iTerm2)
  {
    key = 'd',
    mods = 'CMD',
    action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' },
  },
  
  -- Navigate to pane on the right: Command + ] (same as iTerm2)
  {
    key = ']',
    mods = 'CMD',
    action = wezterm.action.ActivatePaneDirection 'Right',
  },
  
  -- Navigate to pane on the left: Command + [ (same as iTerm2)
  {
    key = '[',
    mods = 'CMD',
    action = wezterm.action.ActivatePaneDirection 'Left',
  },
  
  -- Close current pane/tab: Command + W (same as iTerm2)
  -- Closes the current pane. If it's the last pane in a tab, closes the tab.
  {
    key = 'w',
    mods = 'CMD',
    action = wezterm.action.CloseCurrentPane { confirm = false },
  },
}

-- Mouse Behavior
-- ==============
-- Configure mouse behavior to match iTerm2
config.mouse_bindings = {
  -- Regular left click selects text (default behavior)
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'NONE',
    action = wezterm.action.CompleteSelectionOrOpenLinkAtMouseCursor('ClipboardAndPrimarySelection'),
  },
  
  -- Command+Click opens links (same as iTerm2)
  -- This is essential for opening files in VS Code
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'SUPER',  -- SUPER is Command key on macOS
    action = wezterm.action.OpenLinkAtMouseCursor,
  },
}

-- Hyperlink Detection
-- ===================
-- Configure what text patterns should be clickable links
-- Start with WezTerm's default rules (HTTP/HTTPS URLs, etc.)
config.hyperlink_rules = wezterm.default_hyperlink_rules()

-- Additional custom rules for development workflows:

-- Make GitHub-style username/project paths clickable
-- Examples: "nvim-treesitter/nvim-treesitter", wbthomason/packer.nvim, "wez/wezterm.git"
table.insert(config.hyperlink_rules, {
  regex = [[["]?([\w\d]{1}[-\w\d]+)(/){1}([-\w\d\.]+)["]?]],
  format = 'https://www.github.com/$1/$3',
})

-- Make URLs with IP addresses clickable
-- Examples: http://127.0.0.1:8000, http://192.168.1.1
table.insert(config.hyperlink_rules, {
  regex = [[\b\w+://(?:[\d]{1,3}\.){3}[\d]{1,3}\S*\b]],
  format = '$0',
})

-- File paths with line and column numbers (for error messages and logs)
-- Examples: file.py:123:45, main.rs:42, src/app.js:100:5
table.insert(config.hyperlink_rules, {
  regex = [[\b([A-Za-z0-9._\-/~]+[A-Za-z0-9._\-]+):(\d+)(?::(\d+))?\b]],
  format = 'file://$0',
  highlight = 0,
})

-- Plain file names with extensions (for ls output)
-- Examples: config.lua, main.py, README.md
table.insert(config.hyperlink_rules, {
  regex = [[\b[A-Za-z0-9._\-]+\.[A-Za-z0-9]+\b]],
  format = 'file://$0',
  highlight = 0,
})

-- File paths (absolute and relative, including home directory)
-- Examples: /usr/bin/bash, ./scripts/test.sh, ~/dotfiles/config
table.insert(config.hyperlink_rules, {
  regex = [[~?(?:/[A-Za-z0-9._\-]+)+/?]],
  format = 'file://$0',
  highlight = 0,
})

-- Custom Link Handling
-- ====================
-- Override how file:// links are opened to use VS Code instead of the default handler
-- This enables the iTerm2-like behavior of Command+Click to open files in your editor
wezterm.on('open-uri', function(window, pane, uri)
  -- Only handle file:// URLs, let others (http://, https://, etc.) open normally
  if not uri:match('^file://') then
    return false  -- Let default handler open it
  end
  
  -- Extract the file path from the file:// URI
  local file_path = uri:gsub('^file://', '')
  
  -- Get the current working directory to resolve relative paths
  local cwd_uri = pane:get_current_working_dir()
  local cwd = ''
  
  if cwd_uri and cwd_uri.path then
    cwd = cwd_uri.path
  end
  
  -- Check if this is a file path with line:column notation
  -- Format: filename:line:column or filename:line
  local path, line, col = file_path:match('^([^:]+):(%d+):?(%d*)$')
  
  if path and line then
    -- Handle file paths with line numbers (from error messages, grep output, etc.)
    local full_path = path
    
    -- Expand ~ to home directory
    if full_path:match('^~') then
      full_path = os.getenv('HOME') .. full_path:sub(2)
    elseif not full_path:match('^/') then
      -- Resolve relative paths using current working directory
      full_path = cwd .. '/' .. full_path
    end
    
    -- Build VS Code command with line number (and optional column)
    local cmd
    if col and col ~= '' then
      cmd = string.format('code -r -g "%s:%s:%s"', full_path, line, col)
    else
      cmd = string.format('code -r -g "%s:%s"', full_path, line)
    end
    
    -- Execute through login shell to ensure VS Code is in PATH
    -- This fixes the issue where WezTerm launched from Spotlight doesn't have PATH set
    local shell_cmd = '/bin/sh -l -c \'' .. cmd .. '\''
    os.execute(shell_cmd)
    
    return false  -- Prevent default action
  else
    -- Handle plain file paths (from ls output, etc.)
    local full_path = file_path
    
    -- Expand ~ to home directory
    if full_path:match('^~') then
      full_path = os.getenv('HOME') .. full_path:sub(2)
    elseif not full_path:match('^/') then
      -- Resolve relative paths using current working directory
      full_path = cwd .. '/' .. full_path
    end
    
    -- Open file in VS Code
    local cmd = string.format('code -r "%s"', full_path)
    
    -- Execute through login shell to ensure VS Code is in PATH
    local shell_cmd = '/bin/sh -l -c \'' .. cmd .. '\''
    os.execute(shell_cmd)
    
    return false  -- Prevent default action
  end
end)

return config