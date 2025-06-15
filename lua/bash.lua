-- Bash Runner Plugin for Neovim
local runner = require("bash.runner")

---@class BashConfig
---@field shell string Shell to use for execution (default: /bin/bash)
---@field output_buffer_reuse boolean Whether to reuse output buffer (default: false)
---@field default_args table Default arguments for each run mode
---@field enable_keymaps boolean Whether to enable default keymaps (default: false)
---@field keymaps table Custom keymap configuration
---@field supported_filetypes table List of filetypes for which automatic bash detection is enabled
---@field allow_any_filetype boolean Whether to allow running line mode in any filetype
local default_config = {
  shell = "/bin/bash",
  output_buffer_reuse = false,
  default_args = {
    line = "",
    block = "",
    file = ""
  },
  supported_filetypes = { "bash", "sh", "zsh", "txt", "markdown", "md" },
  allow_any_filetype = true,
  enable_keymaps = true,  -- Changed to true by default to enable keymaps
  keymaps = {
    prefix = "<leader>b",     -- Single key prefix for bash commands
    args_prefix = "<leader>a" -- Single key prefix for commands with args
  }
}

---@class BashRunner
local M = {}

---@type BashConfig
M.config = default_config
M.is_setup = false

---@param opts BashConfig?
-- Setup function to configure the bash runner plugin
M.setup = function(opts)
  -- Mark as set up so we don't run twice
  M.is_setup = true
  
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
  
  -- Configure the runner module
  runner.setup({
    shell = M.config.shell,
    output_buffer_reuse = M.config.output_buffer_reuse,
    default_args = M.config.default_args,
    supported_filetypes = M.config.supported_filetypes,
    allow_any_filetype = M.config.allow_any_filetype
  })
  
  -- Create user commands
  runner.create_commands()
  
  -- Setup keymaps if enabled
  if M.config.enable_keymaps then
    runner.setup_keymaps(M.config.keymaps)
    vim.notify("Bash Runner: Default keymaps enabled", vim.log.levels.INFO)
  end
end

-- Expose runner functions for direct API access
M.run_current_line = runner.run_current_line
M.run_visual_selection = runner.run_visual_selection
M.run_entire_buffer = runner.run_entire_buffer

-- Expose direct argument functions
M.run_current_line_with_args = runner.run_current_line_with_args
M.run_visual_selection_with_args = runner.run_visual_selection_with_args
M.run_entire_buffer_with_args = runner.run_entire_buffer_with_args

-- Expose the simplified variant without argument support
M.simple = require("bash.simple")

-- Expose simplified runner functions with their original names for convenience
M.run_line_simple = M.simple.run_current_line
M.run_block_simple = M.simple.run_visual_selection
M.run_file_simple = M.simple.run_entire_buffer

return M
