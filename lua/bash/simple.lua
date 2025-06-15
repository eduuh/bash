-- Bash Simple Runner - A variant without argument support
local simple_runner = require("bash.simple_runner")

---@class BashSimpleConfig
---@field shell string Shell to use for execution (default: /bin/bash)
---@field output_buffer_reuse boolean Whether to reuse output buffer (default: false)
---@field enable_keymaps boolean Whether to enable default keymaps (default: true)
---@field keymaps table Custom keymap configuration
---@field supported_filetypes table List of filetypes for which automatic bash detection is enabled
---@field allow_any_filetype boolean Whether to allow running line mode in any filetype
local default_config = {
  shell = "/bin/bash",
  output_buffer_reuse = false,
  supported_filetypes = { "bash", "sh", "zsh", "txt", "markdown", "md" },
  allow_any_filetype = true,
  enable_keymaps = true,
  keymaps = {
    prefix = "<leader>s"  -- Single prefix for simple runner
  }
}

---@class BashSimpleRunner
local M = {}

---@type BashSimpleConfig
M.config = default_config
M.is_setup = false

---@param opts BashSimpleConfig?
-- Setup function to configure the bash simple runner plugin
M.setup = function(opts)
  -- Mark as set up so we don't run twice
  M.is_setup = true
  
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
  
  -- Configure the runner module
  simple_runner.setup({
    shell = M.config.shell,
    output_buffer_reuse = M.config.output_buffer_reuse,
    supported_filetypes = M.config.supported_filetypes,
    allow_any_filetype = M.config.allow_any_filetype
  })
  
  -- Create user commands
  simple_runner.create_commands()
  
  -- Setup keymaps if enabled
  if M.config.enable_keymaps then
    simple_runner.setup_keymaps(M.config.keymaps)
    vim.notify("Bash Simple Runner: Default keymaps enabled", vim.log.levels.INFO)
  end
end

-- Expose runner functions for direct API access
M.run_current_line = simple_runner.run_current_line
M.run_visual_selection = simple_runner.run_visual_selection
M.run_entire_buffer = simple_runner.run_entire_buffer

return M
