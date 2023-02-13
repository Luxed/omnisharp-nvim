# Omnisharp-nvim

WARNING: This plugin is not really ready to be used yet.

## Features

- Semantic highlighting.
  - Custom implementation for neovim 0.7 and 0.8.
  - Fixes [semantic token naming bug](https://github.com/OmniSharp/omnisharp-roslyn/issues/2483) with neovim 0.9 and later.
- Automatic configuration with [nvim-dap](https://github.com/mfussenegger/nvim-dap)
- Support for both `omnisharp` and `omnisharp_mono` _at the same time_.  
  The "mono" version of omnisharp is enabled when the `.omnisharp_mono` file is found.

## Difference with OmniSharp-vim

While [omnisharp-vim](https://github.com/OmniSharp/omnisharp-vim) does support Neovim, it is made in vimscript and does not support Neovim's built-in language server support. Instead it implements its own communication with the OmniSharp server.  
With Omnisharp-nvim, Neovim will be the only supported editor and it will be using the built-in language server support.  

## Requirements and recommentations

- Neovim 0.7+
- [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig)
- (Optional) [mason.nvim](https://github.com/williamboman/mason.nvim) and [mason-lspconfig.nvim](https://github.com/williamboman/mason-lspconfig.nvim)  
  Those will help you install and manage `omnisharp` and the open-source `netcoredbg` debugger
- (Optional) [omnisharp-extended-lsp.nvim](https://github.com/Hoffs/omnisharp-extended-lsp.nvim)  
  Adds metadata support when using the "go to definition" feature
- (Optional) [nvim-lightbulb](https://github.com/kosayoda/nvim-lightbulb)  
  Omnisharp has a _lot_ of code actions possible. It is _very_ useful to know when there is at least one availble where the cursor is
- (Optional) [nvim-dap](https://github.com/mfussenegger/nvim-dap) and [nvim-dap-ui](https://github.com/rcarriga/nvim-dap-ui)  
  Required if you want debugging support

## LSP Configuration

~~~lua
-- 'omnisharp_mono' is also supported when using Mason.
lspconfig['omnisharp'].setup(require('omnisharp').setup({
    automatic_dap_configuration = false, -- When true, a DAP configuration will be created.
    highlight = {
      enabled = false,
      fixSemanticTokens = false, -- Fixes issue with semantic tokens for neovim 0.9. "enabled" needs to be true for this to work.
      refresh_mode = 'normal', -- 'normal' or 'insert'
      groups = nil,
    },
    is_mono = false, -- Set this to true when you want to enable omnisharp_mono. With Mason, you can use "server_name == 'omnisharp_mono'" to set this automatically.
    server = {
        -- You can put your server configuration here (like your "on_attach" function)
    }
}))
~~~

## DAP Configuration

The following example uses mason.nvim to manage the debugger version. If you do not wish to use Mason, use a custom path.

~~~lua
local mason_path = vim.fn.stdpath('data') .. '/mason'
local netcoredbg_path = mason_path .. '/bin/netcoredbg'

-- When on Windows, bypass the "cmd" created by Mason.
if vim.fn.has('win32') == 1 then
  netcoredbg_path = mason_path .. '/packages/netcoredbg/netcoredbg/netcoredbg.exe'
end

-- NOTE: Using "coreclr" as an adapter name is important because it is what this plugin is expecting
dap.adapters.coreclr = {
  type = 'executable',
  command = netcoredbg_path,
  args = { '--interpreter=vscode' },
}
~~~
