#
# Kinto.nix - A Declarative Kinto Replacement for NixOS
#
# ## What is this?
# This file is a NixOS module that replicates the core functionality of Kinto
# (https://github.com/rbreaves/kinto) using the `keyd` daemon. It provides
# a macOS-like keyboard experience on NixOS.
#
# ## How was it created?
# This module was created by translating the logic from the original Kinto
# source code (`linux/kinto.py`, `xkeysnail_service.sh`, etc.) into a `keyd`
# configuration and a NixOS module. The source code references have been
# verified against the original files.
#
# ## Why was it created?
# The original Kinto project uses imperative installation scripts. This module
# provides a declarative alternative for NixOS users.
#
# References:
# - https://github.com/NixOS/nixpkgs/issues/137698
# - https://github.com/rbreaves/kinto/issues/566
# - https://github.com/rbreaves/kinto/tree/4a3bfe79e2578dd85cb6ff2ebc5505f758c64ab6
#                                          (exact commit used for conversion)

# ========== USAGE INSTRUCTIONS ==========
# 
# This configuration provides Mac-style keyboard shortcuts on Linux similar to Kinto:
# 
# Core Features:
# • Cmd+C/V/X for copy/paste/cut
# • Cmd+Tab for app switching
# • Cmd+Left/Right for home/end navigation
# • Cmd+Up/Down for document start/end
# • Terminal-specific overrides (Cmd+C becomes Ctrl+Shift+C in terminals)
# • Browser tab navigation with Cmd+1-9
# • File manager shortcuts
# • VS Code integration with Alt+F19 workaround
# • Emacs-style bindings on Ctrl key
# • Apple keyboard hardware support
#
# Configuration Options (modify at the top of this file):
# • enableAppleKeyboard = true/false   - Apple keyboard driver support
# • enableVSCodeFixes = true/false     - VS Code keybinding fixes  
# • appleKeyboardSwapKeys = true/false - Hardware-level Alt/Cmd swapping
#
# To use:
# 1. Add this module to your NixOS configuration
# 2. Customize the options at the top if needed
# 3. Run `sudo nixos-rebuild switch`
# 4. Reboot to ensure kernel modules load properly
#
# To customize further:
# • Modify the keyd extraConfig section above
# • Adjust the configuration options at the top
# • Add application-specific window rules to the keyd config

{ config, pkgs, lib, ... }:

let
  # Configuration options - modify these to customize behavior
  enableAppleKeyboard = false;   # Set to false if not using Apple keyboards
  enableVSCodeFixes = true;      # Set to false to manage VS Code settings manually
  appleKeyboardSwapKeys = false; # Set to false to keep Alt/Cmd in original positions
in

{
  # Enable keyd service for key remapping
  # Source: `linux/xkeysnail.service` - Kinto uses xkeysnail as a systemd service.
  services.keyd = {
    enable = true;
    keyboards = {
      default = {
        ids = [ "*" ];
        extraConfig = ''
          # This configuration is a translation of the rules found in
          # Kinto's xkeysnail configuration at linux/kinto.py

          [main]
          # ----------------------------------------------------------------------
          # Core functionality: Map Command keys to a 'meta_mac' layer.
          # This layer sends 'control' by default for all keys not explicitly
          # remapped within the layer. This mimics macOS's Cmd key.
          # Source: linux/kinto.py, lines 151-155 (Mac Only modmap)
          # ----------------------------------------------------------------------
          leftmeta = layer(meta_mac)
          rightmeta = layer(meta_mac)

          # ----------------------------------------------------------------------
          # Emacs-style bindings, typically using Ctrl on Linux.
          # This module adds them to the Ctrl key for consistency with Linux apps.
          # Source: Inspired by linux/kinto.py, lines 586-594 (which maps them to the Super key).
          # ----------------------------------------------------------------------
          leftcontrol = layer(emacs)

          [emacs]
          a = home          # Beginning of Line (C-a)
          e = end           # End of Line (C-e)
          b = left          # Back one character (C-b)
          f = right         # Forward one character (C-f)
          n = down          # Next line (C-n)
          p = up            # Previous line (C-p)
          k = S-end, delete # Kill line (C-k)
          d = delete        # Delete character (C-d)

          # ----------------------------------------------------------------------
          # The meta_mac layer. The ':C' means "send Control plus the key".
          # For example, pressing Cmd+A will send Ctrl+A.
          # Mappings below this line are exceptions to that rule.
          # ----------------------------------------------------------------------
          [meta_mac:C]

          # ----------------------------------------------------------------------
          # Word-wise navigation and selection (macOS style).
          # Source: linux/kinto.py, "Wordwise" section, lines 598-617
          # ----------------------------------------------------------------------
          left = home
          right = end
          up = C-home
          down = C-end
          S-left = S-home
          S-right = S-end
          S-up = C-S-home
          S-down = C-S-end
          backspace = C-backspace # Delete word left (from Alt-Backspace on line 615)
          delete = C-delete       # Delete word right (from Alt-Delete on line 617)

          # ----------------------------------------------------------------------
          # App and tab switching.
          # Source: linux/kinto.py, "General GUI" section, lines 554-558
          # ----------------------------------------------------------------------
          tab = A-tab          # Switch applications
          S-tab = A-S-tab      # Switch applications (reverse)
          grave = A-grave      # Switch windows of the same application
          S-grave = A-S-grave  # Switch windows of the same application (reverse)

          # ----------------------------------------------------------------------
          # Standard shortcuts.
          # Source: linux/kinto.py, "General GUI" section, lines 546, 547, 548, 552, 553
          # ----------------------------------------------------------------------
          h = super(h)         # Hide window
          q = A-f4             # Quit application
          space = A-f1         # Application launcher (like Spotlight)
          f3 = super(d)        # Show desktop
          super(f) = A-f10     # Maximize window

          # ----------------------------------------------------------------------
          # Tab navigation in applications like browsers, file managers, etc.
          # Source: linux/kinto.py, "General GUI" section, lines 544-545
          # ----------------------------------------------------------------------
          S-leftbrace = C-pageup
          S-rightbrace = C-pagedown

          # ----------------------------------------------------------------------
          # Browser-specific shortcuts.
          # Source: linux/kinto.py, "General Web Browsers" keymap, lines 471-479
          # ----------------------------------------------------------------------
          1 = A-1
          2 = A-2
          3 = A-3
          4 = A-4
          5 = A-5
          6 = A-6
          7 = A-7
          8 = A-8
          9 = A-9 # Last tab

          # ----------------------------------------------------------------------
          # Terminal overrides.
          # Source: linux/kinto.py, "terminals" list (line 10) and keymap (lines 785-846)
          # ----------------------------------------------------------------------
          [window=^(alacritty|kitty|konsole|gnome-terminal|terminator|xterm|io.elementary.terminal)$]
          # In terminals, Cmd+C should be copy, not interrupt.
          # We map Cmd+C to Ctrl+Shift+C, which is the standard "copy" shortcut in many terminals.
          # Source: linux/kinto.py, line 837
          c = C-S-c
          v = C-S-v
          f = C-S-f
          # Remap other keys to use Ctrl+Shift instead of just Ctrl.
          w = C-S-w
          t = C-S-t
          n = C-S-n
          # Prevent Cmd+Q from closing the terminal window.
          q = overload(q, q)

          # ----------------------------------------------------------------------
          # File manager overrides.
          # Source: linux/kinto.py, "General File Managers" keymap, lines 405-440
          # ----------------------------------------------------------------------
          [window=^(nautilus|dolphin|nemo|caja|thunar)$]
          # Get Info / Properties
          i = A-enter
          # Go up a directory
          up = A-up
          # Go back/forward in history
          left = A-left
          right = A-right
          # Open selected item
          down = enter
          # Move to trash
          backspace = delete
          # Show/hide hidden files
          S-dot = C-h

          # ----------------------------------------------------------------------
          # VS Code overrides.
          # Source: linux/kinto.py, "Code" keymap, lines 646-686
          # ----------------------------------------------------------------------
          [window=^(code|vscodium)$]
          # Word-wise navigation with Alt, avoiding the menu bar focus issue.
          # Source: linux/kinto.py, line 652
          A-left = A-f19, C-left
          A-right = A-f19, C-right
          A-S-left = A-f19, C-S-left
          A-S-right = A-f19, C-S-right
          # Go to Line... (Cmd+G -> Ctrl+G)
          # Source: linux/kinto.py, line 666 (adapted from Super+g)
          g = C-g
          # QuickFix (Cmd+. -> Ctrl+.)
          # Source: linux/kinto.py, line 649 (adapted from RC-Dot)
          dot = C-dot

          # ----------------------------------------------------------------------
          # Browser Overrides for Firefox and Chrome-based browsers (Brave)
          # Source: linux/kinto.py, lines 447-463
          # ----------------------------------------------------------------------
          [window=^firefox$]
          # Open private window with Cmd+Shift+N like Chrome
          S-n = C-S-p

          [window=^(brave-browser|google-chrome)$]
          # Quit with Cmd+Q
          q = A-f4

          # ----------------------------------------------------------------------
          # Terminal-Specific Overrides for Kitty and Alacritty
          # ----------------------------------------------------------------------
          [window=^kitty$]
          # Source: linux/kinto.py, lines 766-772
          # Tab switching with Ctrl+Tab instead of Ctrl+PageUp/Down
          C-tab = C-S-right
          C-S-tab = C-S-left
          C-grave = C-S-left

          [window=^alacritty$]
          # Source: linux/kinto.py, lines 781-783
          # Clear screen with Cmd+K
          k = C-l
        '';
      };
    };
  };

  # keyd package is automatically installed by the service
  # No additional packages required for basic functionality

  # ========== DESKTOP ENVIRONMENT SPECIFIC SHORTCUTS ==========
  # Source: xkeysnail_service.sh, lines 254-259 (GNOME configuration)
  services.xserver.desktopManager.gnome = lib.mkIf (config.services.desktopManager.gnome.enable or false) {
    extraGSettingsOverrides = ''
      # Disable overlay key so Super+Space can be used for app launcher
      # Source: xkeysnail_service.sh, line 258
      [org.gnome.mutter]
      overlay-key='''
      
      # Set up Mac-style shortcuts
      # Source: xkeysnail_service.sh, lines 295, 326, 335
      [org.gnome.desktop.wm.keybindings]
      minimize=['<Super>h', '<Alt>F9']
      show-desktop=['<Super>d']
      close=['<Alt>F4']
      
      [org.gnome.shell.keybindings]
      toggle-application-view=['<Super>space']
    '';
  };
  
  # ========== APPLE KEYBOARD HARDWARE SUPPORT ==========
  # Source: xkeysnail_service.sh, lines 100-112 (Apple keyboard driver options)
  boot.kernelModules = lib.mkIf enableAppleKeyboard [ "hid_apple" ];
  boot.extraModprobeConfig = lib.mkIf enableAppleKeyboard ''
    # Swap Alt and Cmd keys on Apple keyboards at hardware level
    # Source: removeAppleKB function in xkeysnail_service.sh, line 104
    options hid_apple swap_opt_cmd=${if appleKeyboardSwapKeys then "1" else "0"}
    
    # Additional Apple keyboard options
    options hid_apple fnmode=2      # Function keys work as F1-F12 by default
    options hid_apple iso_layout=0  # Use ANSI layout
  '';
  
  # ========== VS CODE INTEGRATION ==========
  # Source: linux/vscode_keybindings.json - VS Code specific fixes
  # The Alt+F19 workaround and word navigation fixes are essential for VS Code
  environment.etc."vscode-keybindings.json" = lib.mkIf enableVSCodeFixes {
    text = builtins.toJSON [
      {
        key = "alt+left";
        command = "-workbench.action.terminal.focusPreviousPane";
        when = "terminalFocus";
      }
      {
        key = "alt+right"; 
        command = "-workbench.action.terminal.focusNextPane";
        when = "terminalFocus";
      }
      {
        key = "alt+right";
        command = "cursorWordRight";
      }
      {
        key = "alt+left";
        command = "cursorWordLeft";
      }
      {
        key = "shift+alt+left";
        command = "cursorWordStartLeftSelect";
        when = "textInputFocus";
      }
      {
        key = "shift+alt+right";
        command = "cursorWordEndRightSelect";
        when = "textInputFocus";
      }
    ];
  };

}
