local M = {}

-- Default configuration
local default_config = {
  shell = "/bin/bash",
  output_buffer_reuse = false,
  default_args = {
    line = "",
    block = "",
    file = "",
  },
  supported_filetypes = { "bash", "sh", "zsh", "txt", "markdown", "md" },
  allow_any_filetype = true,
}

local config = default_config

-- Set configuration
function M.setup(opts)
  config = vim.tbl_deep_extend("force", config, opts or {})
end

-- Helper: Check if the current buffer is a supported file type
local function is_supported_filetype()
  local ft = vim.bo.filetype

  -- If any filetype is allowed, return true
  if config.allow_any_filetype then
    return true
  end

  -- Check if current filetype is in supported list
  for _, supported_ft in ipairs(config.supported_filetypes) do
    if ft == supported_ft then
      return true
    end
  end

  return false
end

-- Helper: Check if script is a bash script by checking for shebang
local function has_bash_shebang(code)
  local first_line = code:match("^([^\n]*)")
  if first_line and first_line:match("^#!.*bash") then
    return true
  end
  return false
end

-- Helper: get current line content
local function get_current_line()
  local line_num = vim.fn.line(".")
  local lines = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)
  return lines[1] or ""
end

-- Helper: get visual selection or block
local function get_visual_selection()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  local start_line = start_pos[2] - 1
  local end_line = end_pos[2]

  local lines = vim.api.nvim_buf_get_lines(0, start_line, end_line, false)
  return table.concat(lines, "\n")
end

-- Helper: get entire buffer content
local function get_entire_buffer()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  return table.concat(lines, "\n")
end

-- Helper: create or reuse output buffer
local function get_output_buffer()
  local buf_name = "bash-output"

  if config.output_buffer_reuse then
    -- Try to find existing buffer
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_get_name(buf):match(buf_name) then
        return buf
      end
    end
  end

  -- Create new buffer
  vim.cmd("vnew")
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_name(buf, buf_name .. "-" .. os.time())
  vim.bo[buf].filetype = "bash-output"
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].swapfile = false

  return buf
end

-- Helper: write output to buffer
local function write_to_output_buffer(output, error_output)
  local buf = get_output_buffer()
  local content = {}

  if output and output ~= "" then
    table.insert(content, "=== STDOUT ===")
    vim.list_extend(content, vim.split(output, "\n"))
  end

  if error_output and error_output ~= "" then
    if #content > 0 then
      table.insert(content, "")
    end
    table.insert(content, "=== STDERR ===")
    vim.list_extend(content, vim.split(error_output, "\n"))
  end

  if #content == 0 then
    content = { "No output" }
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
end

-- Helper: prompt for arguments
local function prompt_for_args(mode, callback)
  local default_arg = config.default_args[mode] or ""

  vim.ui.input({
    prompt = string.format("Arguments for %s execution: ", mode),
    default = default_arg,
  }, function(args)
    callback(args or "")
  end)
end

-- Core function: execute script asynchronously
local function execute_script_async(script, args)
  if not script or script:match("^%s*$") then
    vim.notify("No script content to execute", vim.log.levels.WARN)
    return
  end

  local cmd = { config.shell, "-c", script }
  if args and args ~= "" then
    -- Append arguments to the script
    cmd = { config.shell, "-c", script .. " " .. args }
  end

  vim.system(cmd, {
    text = true,
    timeout = 30000, -- 30 second timeout
  }, function(obj)
    vim.schedule(function()
      if obj.code == 0 then
        write_to_output_buffer(obj.stdout, obj.stderr)
        vim.notify("Script executed successfully", vim.log.levels.INFO)
      else
        write_to_output_buffer(obj.stdout, obj.stderr or ("Process exited with code: " .. obj.code))
        vim.notify("Script execution failed", vim.log.levels.ERROR)
      end
    end)
  end)
end

-- Public functions
function M.run_current_line()
  -- Line mode is allowed in any filetype if configured
  local script = get_current_line()

  prompt_for_args("line", function(args)
    execute_script_async(script, args)
  end)
end

function M.run_visual_selection()
  -- Check if this is a supported filetype for block execution
  if not is_supported_filetype() and not has_bash_shebang(get_visual_selection()) then
    vim.notify(
      "Block execution is only available for supported filetypes: " .. table.concat(config.supported_filetypes, ", "),
      vim.log.levels.WARN
    )
    return
  end

  local script = get_visual_selection()

  prompt_for_args("block", function(args)
    execute_script_async(script, args)
  end)
end

function M.run_entire_buffer()
  -- Check if this is a supported filetype for file execution
  if not is_supported_filetype() and not has_bash_shebang(get_entire_buffer()) then
    vim.notify(
      "File execution is only available for supported filetypes: " .. table.concat(config.supported_filetypes, ", "),
      vim.log.levels.WARN
    )
    return
  end

  local script = get_entire_buffer()

  prompt_for_args("file", function(args)
    execute_script_async(script, args)
  end)
end

-- Run functions with direct arguments
function M.run_current_line_with_args(args)
  local script = get_current_line()
  execute_script_async(script, args)
end

function M.run_visual_selection_with_args(args)
  if not is_supported_filetype() and not has_bash_shebang(get_visual_selection()) then
    vim.notify(
      "Block execution is only available for supported filetypes: " .. table.concat(config.supported_filetypes, ", "),
      vim.log.levels.WARN
    )
    return
  end
  
  local script = get_visual_selection()
  execute_script_async(script, args)
end

function M.run_entire_buffer_with_args(args)
  if not is_supported_filetype() and not has_bash_shebang(get_entire_buffer()) then
    vim.notify(
      "File execution is only available for supported filetypes: " .. table.concat(config.supported_filetypes, ", "),
      vim.log.levels.WARN
    )
    return
  end
  
  local script = get_entire_buffer()
  execute_script_async(script, args)
end

-- Command creation
function M.create_commands()
  -- Standard commands with prompts
  vim.api.nvim_create_user_command("BashRunLine", function()
    M.run_current_line()
  end, { desc = "Run current line as bash script" })

  vim.api.nvim_create_user_command("BashRunBlock", function()
    M.run_visual_selection()
  end, { desc = "Run visual selection as bash script", range = true })

  vim.api.nvim_create_user_command("BashRunFile", function()
    M.run_entire_buffer()
  end, { desc = "Run entire buffer as bash script" })
  
  -- Commands with direct arguments
  vim.api.nvim_create_user_command("BashRunLineArgs", function(opts)
    M.run_current_line_with_args(opts.args)
  end, { desc = "Run current line as bash script with arguments", nargs = "*" })

  vim.api.nvim_create_user_command("BashRunBlockArgs", function(opts)
    M.run_visual_selection_with_args(opts.args)
  end, { desc = "Run visual selection as bash script with arguments", range = true, nargs = "*" })

  vim.api.nvim_create_user_command("BashRunFileArgs", function(opts)
    M.run_entire_buffer_with_args(opts.args)
  end, { desc = "Run entire buffer as bash script with arguments", nargs = "*" })
end

-- Optional keymaps
function M.setup_keymaps(opts)
  opts = opts or {}
  local keymap_config = vim.tbl_deep_extend("force", {
    prefix = "<leader>b",  -- Single prefix for all bash commands
    args_prefix = "<leader>a"  -- Single prefix for commands with args
  }, opts)

  -- Normal mode - run current line
  vim.keymap.set("n", keymap_config.prefix, M.run_current_line, 
    { desc = "Run current line as bash" })
  
  -- Visual mode - run selection
  vim.keymap.set("v", keymap_config.prefix, "<Cmd>BashRunBlock<CR>", 
    { desc = "Run selection as bash", silent = true })
  
  -- Normal mode with Shift - run entire file
  vim.keymap.set("n", keymap_config.prefix:upper(), M.run_entire_buffer, 
    { desc = "Run buffer as bash" })
  
  -- With arguments - current line
  vim.keymap.set("n", keymap_config.args_prefix, function()
    vim.ui.input({ prompt = "Arguments: " }, function(args)
      if args then M.run_current_line_with_args(args) end
    end)
  end, { desc = "Run current line as bash with args" })
  
  -- With arguments - visual selection
  vim.keymap.set("v", keymap_config.args_prefix, 
    "<Cmd>lua require('bash.runner').prompt_for_visual_args()<CR>", 
    { desc = "Run selection as bash with args", silent = true })
  
  -- With arguments - entire file
  vim.keymap.set("n", keymap_config.args_prefix:upper(), function()
    vim.ui.input({ prompt = "Arguments: " }, function(args)
      if args then M.run_entire_buffer_with_args(args) end
    end)
  end, { desc = "Run buffer as bash with args" })
end

-- Helper function for visual mode argument prompt
function M.prompt_for_visual_args()
  -- Store the current visual selection positions
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  local start_line = start_pos[2] - 1
  local end_line = end_pos[2]
  
  -- Exit visual mode first
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<ESC>", true, false, true), "n", true)
  
  -- Ask for arguments
  vim.ui.input({ prompt = "Arguments: " }, function(args)
    if args then
      -- Get the previously selected text
      local lines = vim.api.nvim_buf_get_lines(0, start_line, end_line, false)
      local script = table.concat(lines, "\n")
      
      -- Run the script with the provided arguments
      execute_script_async(script, args)
    end
  end)
end

return M
