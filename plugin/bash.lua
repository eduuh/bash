-- Bash Runner Plugin for Neovim - Auto-initialization for Lazy.nvim compatibility
-- This file is loaded automatically when the plugin is loaded by Lazy.nvim
-- See README.md for full feature list and documentation

-- Prevent loading if already loaded
if vim.g.loaded_bash_runner then
  return
end
vim.g.loaded_bash_runner = 1

-- The actual setup will be called from the user's Lazy.nvim config,
-- but we'll use default settings if the user hasn't called setup()
local bash = require("bash")

-- Add a vim.defer to ensure keymaps are set up after Neovim is fully loaded
vim.defer_fn(function()
  -- If the user hasn't explicitly called setup, use the defaults
  if not bash.is_setup then
    bash.setup({})
  end
  
  -- Also load the simple version with no args if the user hasn't explicitly done so
  if not bash.simple.is_setup then
    -- We don't auto-setup the simple version to avoid keymap conflicts
    -- User must explicitly call require("bash.simple").setup() if they want it
  end
end, 0)

