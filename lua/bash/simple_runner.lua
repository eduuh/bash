-- Bash Simple Runner - A variant without argument support
-- This is a simplified version of the runner module without argument handling

local M = {}

-- Default configuration
local default_config = {
  shell = "/bin/bash",
  output_buffer_reuse = false,
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
  local buf_name = "bash-simple-output"

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
  
  -- Format the output
  local content = {}
  
  table.insert(content, "=== BASH EXECUTION RESULT ===")
  table.insert(content, "")
  
  -- Add stdout if available
  if output and output ~= "" then
    table.insert(content, "=== STDOUT ===")
    table.insert(content, output)
  end
  
  -- Add stderr if available
  if error_output and error_output ~= "" then
    table.insert(content, "")
    table.insert(content, "=== STDERR ===")
    table.insert(content, error_output)
  end
  
  -- Write to buffer
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
  
  -- Set cursor to beginning of buffer
  vim.api.nvim_win_set_cursor(vim.fn.win_getid(), {1, 0})
end

-- Execute a bash script asynchronously
local function execute_script_async(script)
  -- Store the script in a temporary file
  local temp_file = os.tmpname()
  local file = io.open(temp_file, "w")
  file:write(script)
  file:close()
  
  -- Make the temporary file executable
  os.execute("chmod +x " .. temp_file)
  
  -- Execute the script asynchronously
  vim.fn.jobstart(config.shell .. " " .. temp_file, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data then
        write_to_output_buffer(table.concat(data, "\n"), nil)
      end
    end,
    on_stderr = function(_, data)
      if data then
        local stderr_output = table.concat(data, "\n")
        if stderr_output ~= "" then
          write_to_output_buffer(nil, stderr_output)
        end
      end
    end,
    on_exit = function()
      -- Clean up temp file
      os.remove(temp_file)
    end
  })
end

-- Run a block of code as bash
function M.run_current_line()
  local script = get_current_line()
  execute_script_async(script)
end

-- Run visual selection as bash
function M.run_visual_selection()
  if not is_supported_filetype() and not has_bash_shebang(get_visual_selection()) then
    vim.notify(
      "Block execution is only available for supported filetypes: " .. table.concat(config.supported_filetypes, ", "),
      vim.log.levels.WARN
    )
    return
  end
  
  local script = get_visual_selection()
  execute_script_async(script)
end

-- Run entire buffer as bash
function M.run_entire_buffer()
  if not is_supported_filetype() and not has_bash_shebang(get_entire_buffer()) then
    vim.notify(
      "File execution is only available for supported filetypes: " .. table.concat(config.supported_filetypes, ", "),
      vim.log.levels.WARN
    )
    return
  end
  
  local script = get_entire_buffer()
  execute_script_async(script)
end

-- Command creation
function M.create_commands()
  -- Simple commands without argument support
  vim.api.nvim_create_user_command("BashRunLineSimple", function()
    M.run_current_line()
  end, { desc = "Run current line as bash script (no args)" })

  vim.api.nvim_create_user_command("BashRunBlockSimple", function()
    M.run_visual_selection()
  end, { desc = "Run visual selection as bash script (no args)", range = true })

  vim.api.nvim_create_user_command("BashRunFileSimple", function()
    M.run_entire_buffer()
  end, { desc = "Run entire buffer as bash script (no args)" })
end

-- Optional keymaps
function M.setup_keymaps(opts)
  opts = opts or {}
  local keymap_config = vim.tbl_deep_extend("force", {
    prefix = "<leader>b",  -- Single prefix for all bash commands
  }, opts)

  -- Normal mode mappings - simplified with a single prefix
  vim.keymap.set("n", keymap_config.prefix, M.run_current_line, { desc = "Run current line as bash" })
  
  -- Visual mode mapping - use the same key
  vim.keymap.set("v", keymap_config.prefix, "<Cmd>BashRunBlockSimple<CR>", { desc = "Run selection as bash", silent = true })
  
  -- Add file execution with Shift modifier
  vim.keymap.set("n", keymap_config.prefix:upper(), M.run_entire_buffer, { desc = "Run buffer as bash" })
end

return M
