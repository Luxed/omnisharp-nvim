local log = require('omnisharp.log')
local request = require('omnisharp.request')

local function setup_highlight_autocmds(config)
  local highlight_callback = function()
    request.highlight(nil, require('omnisharp.highlight').__highlight_handler)
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local highlight_augroup = vim.api.nvim_create_augroup('omnisharp_highlight_' .. tostring(bufnr), {clear = true})
  vim.api.nvim_create_autocmd('BufEnter', {
    group = highlight_augroup,
    buffer = bufnr,
    callback = highlight_callback
  })
  vim.api.nvim_create_autocmd({'InsertLeave', 'TextChanged'}, {
    group = highlight_augroup,
    buffer = bufnr,
    callback = highlight_callback
  })

  if config.highlight.refresh_mode == 'insert' then
    vim.api.nvim_create_autocmd('TextChangedI', {
      group = highlight_augroup,
      buffer = bufnr,
      callback = highlight_callback
    })

    if vim.fn.exists('##TextChangedP') == 1 then
      vim.api.nvim_create_autocmd('TextChangedP', {
        group = highlight_augroup,
        buffer = bufnr,
        callback = highlight_callback
      })
    end
  end
end

local function get_default_config()
  return {
    automatic_dap_configuration = false,
    highlight = {
      enabled = false,
      fixSemanticTokens = false,
      refresh_mode = 'normal', -- 'normal' or 'insert'
      groups = nil,
    },
    is_mono = false,
    server = {}
  }
end

local function get_default_groups()
  -- TODO: Maybe add a way to use Treesitter groups instead?
  -- Once the offical support comes and there is a plugin that most people are using, or if the groups are included directly in neovim,
  -- then the plugin will be changed to be using those by default since it will make the most sense.
  return {
    OmniSharpComment = {link = 'Comment'},
    OmniSharpIdentifier = {link = 'Identifier'},
    OmniSharpKeyword = {link = 'Keyword'},
    OmniSharpControlKeyword = {link = 'Conditional'},
    OmniSharpNumericLiteral = {link = 'Number'},
    OmniSharpOperator = {link = 'Operator'},
    OmniSharpOperatorOverloaded = {link = 'Operator'},
    OmniSharpPreprocessorKeyword = {link = 'PreProc'},
    OmniSharpPreprocessorText = {link = 'String'},
    OmniSharpStringLiteral = {link = 'String'},
    OmniSharpText = {link = 'String'},
    OmniSharpVerbatimStringLiteral = {link = 'String'},
    OmniSharpStringEscapeCharacter = {link = 'Special'},
    OmniSharpClassName = {link = 'Type'},
    OmniSharpEnumName = {link = 'Type'},
    OmniSharpInterfaceName = {link = 'Type'},
    OmniSharpStructName = {link = 'Type'},
    OmniSharpConstantName = {link = 'Constant'},
    OmniSharpMethodName = {link = 'Function'},
    OmniSharpExtensionMethodName = {link = 'Function'},
    OmniSharpNamespaceName = {link = 'Include'},
  }
end

local M = {}

function M.setup(config)
  config = vim.tbl_deep_extend('force', get_default_config(), config or {})
  config.highlight.groups = vim.tbl_extend('force', get_default_groups(), config.highlight.groups or {})

  require('omnisharp.highlight').__setup_highlight_groups(config)

  config.server.root_dir = function(path)
    local root_pattern = require('lspconfig.util').root_pattern

    if config.is_mono then
      return root_pattern('.omnisharp_mono')(path)
    else
      return root_pattern('*.sln')(path) or root_pattern('*.csproj')(path)
    end
  end

  config.server.on_attach = require('lspconfig.util').add_hook_after(config.server.on_attach, function(client)
    if config.highlight and config.highlight.enabled then
      if vim.fn.has('nvim-0.9') == 1 then
        if config.highlight.fixSemanticTokens then
          -- TODO: Temporary. See here: https://github.com/OmniSharp/omnisharp-roslyn/issues/2483
          client.server_capabilities.semanticTokensProvider.legend = {
            tokenModifiers = { "static" },
            tokenTypes = { "comment", "excluded", "identifier", "keyword", "conditional", "number", "operator", "operator",
              "preproc", "string", "whitespace", "text", "static", "preproc", "punctuation", "string", "string",
              "class", "delegate", "enum", "interface", "module", "struct", "typeParameter", "field", "enumMember",
              "constant", "local", "parameter", "method", "method", "property", "event", "namespace", "label", "xml", "xml",
              "xml", "xml", "xml", "xml", "xml", "xml", "xml", "xml", "xml", "xml", "xml", "xml", "xml", "xml", "xml",
              "xml",
              "xml", "xml", "xml", "regexp", "regexp", "regexp", "regexp", "regexp", "regexp", "regexp", "regexp", "regexp" }
          }
        end
      else
        setup_highlight_autocmds(config)
        request.highlight(client, require('omnisharp.highlight').__highlight_handler)
      end
    end

    if config.automatic_dap_configuration then
      require('omnisharp.dap').configure_dap(client)
    end
  end)

  return config.server
end

function M.show_highlights_under_cursor()
  request.highlight(nil, require('omnisharp.highlight').__show_highlight_handler)
end

function M.launch_debug()
  log.info('Launching "dotnet build"')
  vim.fn.jobstart('dotnet build', {
    cwd = vim.fn.expand('%:p:h'), -- This will use the path of the current buffer as the current working directory to ensure that only the current project is built instead of the entire solution (if that's where your Neovim instance was started)
    on_exit = function(_, exit_code, _)
      if exit_code ~= 0 then
        log.error('"dotnet build" has failed. The debugging session will not be launched!')
      else
        log.info('Build finished, launching debugging session')
        require('omnisharp.dap').launch_current_configuration()
      end
    end
  })
end

function M.open_workspace_information()
  -- TODO: Information should be shown in a floating window similar to "LspInfo" instead of a floating preview next to the cursor
  request.projects(nil, function(workspace)
    local lines = {
      '# OmniSharp Workspace Information',
      '',
      'Solution Path: `' .. workspace.SolutionPath .. '`',
      '',
      '## Projects',
    }

    for _, project in pairs(workspace.Projects) do
      table.insert(lines, '')
      table.insert(lines, '### Project: ' .. project.AssemblyName)
      table.insert(lines, '')
      table.insert(lines, 'Project Path     : `' .. project.Path .. '`')
      table.insert(lines, 'Configuration    : `' .. project.Configuration .. '`')
      table.insert(lines, 'Is Executable    : `' .. tostring(project.IsExe) .. '`')
      table.insert(lines, 'Platform         : `' .. project.Platform .. '`')

      local frameworks = ''
      for _, framework in pairs(project.TargetFrameworks) do
        if frameworks ~= '' then
          frameworks = frameworks .. ';'
        end
        frameworks = frameworks .. framework.ShortName
      end

      table.insert(lines, 'Target Frameworks: `' .. frameworks .. '`')
      table.insert(lines, 'Target Path      : `' .. project.TargetPath .. '`')
    end

    vim.lsp.util.open_floating_preview(lines, 'markdown', {
      border = 'rounded',
      pad_left = 4,
      pad_right = 4
    })
  end)
end

return M
