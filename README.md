# Bash Runner for Neovim

Run bash scripts directly from Neovim. Execute a line, selection, or entire file and see results in a separate buffer.

## Features

- **Async Execution**: Scripts run asynchronously without blocking the UI
- **Multiple Execution Modes**:
  - Run current line (works in any filetype)
  - Run visual selection
  - Run entire buffer
- **Supported Filetypes**: bash, sh, zsh, txt, markdown, md
- **Bash Shebang Detection**: Automatically detects bash scripts by shebang (`#!`)
- **Argument Support**: Prompt for script arguments before execution
- **Output Management**: Results displayed in a dedicated output buffer
- **Error Handling**: Clear display of stdout and stderr

## Installation

### Using [Lazy.nvim](https://github.com/folke/lazy.nvim) (Recommended)

```lua
{
  "eduuh/bash.nvim",
  cmd = { "BashRunLine", "BashRunBlock", "BashRunFile" },
  ft = { "bash", "sh", "zsh", "txt", "markdown", "md" },
  keys = {
    { "<leader>bl", "<cmd>BashRunLine<cr>", desc = "Run current line as bash" },
    { "<leader>bb", "<cmd>BashRunBlock<cr>", mode = "v", desc = "Run selection as bash" },
    { "<leader>bf", "<cmd>BashRunFile<cr>", desc = "Run entire buffer as bash" },
    -- With arguments variants
    { "<leader>bla", function() vim.ui.input({prompt="Arguments: "}, function(args) if args then vim.cmd("BashRunLineArgs " .. args) end end) end, desc = "Run line with args" },
    { "<leader>bba", "<cmd>lua require('bash.runner').prompt_for_visual_args()<cr>", mode = "v", desc = "Run selection with args" },
    { "<leader>bfa", function() vim.ui.input({prompt="Arguments: "}, function(args) if args then vim.cmd("BashRunFileArgs " .. args) end end) end, desc = "Run buffer with args" },
  },
}
```

### Manual

```bash
git clone https://github.com/eduuh/bash-runner.nvim ~/.config/nvim/pack/plugins/start/bash-runner.nvim
```

## Usage

### Commands

#### Standard Commands (with argument prompt)
- `:BashRunLine` - Run current line
- `:BashRunBlock` - Run visual selection
- `:BashRunFile` - Run entire buffer

#### Direct Argument Commands
- `:BashRunLineArgs [args]` - Run current line with arguments
- `:BashRunBlockArgs [args]` - Run visual selection with arguments
- `:BashRunFileArgs [args]` - Run entire buffer with arguments

#### Simplified Commands (No Arguments)
- `:BashRunLineSimple` - Run current line (no args)
- `:BashRunBlockSimple` - Run visual selection (no args)
- `:BashRunFileSimple` - Run entire buffer (no args)

### Keymaps

Default keymaps (enabled by default):

- `<leader>b` - Run current line or visual selection (context-aware)
- `<leader>B` - Run entire buffer

With arguments:
- `<leader>a` - Run current line or visual selection with arguments (will prompt)
- `<leader>A` - Run entire buffer with arguments (will prompt)

#### Simplified Variant Keymaps

Default keymaps for the simplified variant:

- `<leader>s` - Run current line or visual selection (context-aware, no args)
- `<leader>S` - Run entire buffer (no args)

### Keymap Usage Examples

#### Main Plugin
1. Position cursor on a bash command and press `<leader>b` to run it
2. Select multiple lines in visual mode and press `<leader>b` to run the selection
3. Press `<leader>B` to run the entire buffer as a script
4. Use `<leader>a` instead to be prompted for arguments

#### Simple Variant
1. Position cursor on a bash command and press `<leader>s` to run it without arguments
2. Select multiple lines in visual mode and press `<leader>s` to run the selection
3. Press `<leader>S` to run the entire buffer as a script

## Configuration

```lua
require("bash").setup({
  -- Shell to use
  shell = "/bin/bash",

  -- Reuse output buffer
  output_buffer_reuse = false,

  -- Default arguments
  default_args = {
    line = "",
    block = "",
    file = ""
  },

  -- Supported filetypes
  supported_filetypes = { "bash", "sh", "zsh", "txt", "markdown", "md" },

  -- Allow line mode in any file
  allow_any_filetype = true,

  -- Enable default keymaps
  enable_keymaps = true, -- Default keymaps are enabled by default

  -- Custom keymaps
  keymaps = {
    prefix = "<leader>b",     -- Single prefix for bash commands
    args_prefix = "<leader>a" -- Single prefix for commands with args
  }
})
```

### Simplified Variant (No Arguments)

If you prefer a simpler version without argument support, you can use the simplified variant:

```lua
-- Use the simple variant without argument support
require("bash.simple").setup({
  -- Configuration options (same as main plugin)
  shell = "/bin/bash",
  output_buffer_reuse = false,
  enable_keymaps = true,
  keymaps = {
    prefix = "<leader>s"   -- Single prefix for simple bash commands
  }
})
```

## License

docker ps

MIT License
