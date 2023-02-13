local log = require('omnisharp.log')
local M = {}

-- NOTE: this only works if your lsp client is called "omnisharp" or "omnisharp_mono"
M.get_current_omnisharp_client = function()
  local bufnr = vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_active_clients({
    bufnr = bufnr,
  })

  for _, client in pairs(clients) do
    if client.name == 'omnisharp' or client.name == 'omnisharp_mono' then
      return client
    end
  end

  log.error('Could not find a valid OmniSharp client attached to this buffer')
  return nil
end

M.make_current_file_params = function()
  return {
    fileName = vim.fn.expand('%:p')
  }
end

return M
