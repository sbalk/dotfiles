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
  
  -- Text Navigation
  -- ---------------
  
  -- Move by word: Alt + Left/Right Arrow (same as iTerm2)
  {
    key = 'LeftArrow',
    mods = 'ALT',
    action = wezterm.action.SendString '\x1bb',  -- Move backward one word
  },
  {
    key = 'RightArrow',
    mods = 'ALT',
    action = wezterm.action.SendString '\x1bf',  -- Move forward one word
  },
}

-- Mouse Behavior
-- ==============
-- Configure mouse behavior to match iTerm2
-- Note: We're only overriding Command+Click behavior; regular clicks use defaults
config.mouse_bindings = {
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
    return  -- Let WezTerm handle non-file URLs
  end
  
  -- Extract the file path from the file:// URI
  local file_path = uri:gsub('^file://', '')
  
  -- Parse file path with optional line:column notation
  local path, line, col = file_path:match('^([^:]+):?(%d*):?(%d*)$')
  path = path or file_path
  
  -- Resolve the full path
  if path:match('^~') then
    -- Expand ~ to home directory
    path = os.getenv('HOME') .. path:sub(2)
  elseif not path:match('^/') then
    -- Resolve relative paths using current working directory
    local cwd = pane:get_current_working_dir()
    if cwd and cwd.path then
      path = cwd.path .. '/' .. path
    end
  end
  
  -- Build VS Code command
  local cmd = 'code -r'
  if line and line ~= '' then
    -- Add line:column if present
    cmd = cmd .. string.format(' -g "%s:%s%s"', path, line, col ~= '' and ':' .. col or '')
  else
    cmd = cmd .. string.format(' "%s"', path)
  end
  
  -- Execute through login shell to ensure VS Code is in PATH
  os.execute('/bin/sh -l -c \'' .. cmd .. '\'')
  
  return false  -- Prevent default action
end)

return config