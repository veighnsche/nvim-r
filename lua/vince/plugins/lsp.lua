local function workspace_symbols()
  vim.ui.input({ prompt = 'Workspace symbols > ' }, function(query)
    if query and query ~= '' then vim.lsp.buf.workspace_symbol(query) end
  end)
end

return {
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      { 'j-hui/fidget.nvim', opts = {} },
    },
    config = function()
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('vince-lsp-attach', { clear = true }),
        callback = function(event)
          local client = vim.lsp.get_client_by_id(event.data.client_id)

          local map = function(keys, func, desc, mode)
            vim.keymap.set(mode or 'n', keys, func, { buffer = event.buf, desc = desc })
          end

          local telescope_ok, builtin = pcall(require, 'telescope.builtin')
          if telescope_ok then
            map('grr', builtin.lsp_references, 'References')
            map('gri', builtin.lsp_implementations, 'Implementation')
            map('grd', builtin.lsp_definitions, 'Definition')
            map('grt', builtin.lsp_type_definitions, 'Type definition')
            map('gO', builtin.lsp_document_symbols, 'Document symbols')
            map('gW', builtin.lsp_dynamic_workspace_symbols, 'Workspace symbols')
          else
            map('grr', vim.lsp.buf.references, 'References')
            map('gri', vim.lsp.buf.implementation, 'Implementation')
            map('grd', vim.lsp.buf.definition, 'Definition')
            map('grt', vim.lsp.buf.type_definition, 'Type definition')
            map('gO', vim.lsp.buf.document_symbol, 'Document symbols')
            map('gW', workspace_symbols, 'Workspace symbols')
          end

          map('K', vim.lsp.buf.hover, 'Hover')
          map('grn', vim.lsp.buf.rename, 'Rename')
          map('gra', vim.lsp.buf.code_action, 'Code action', { 'n', 'x' })
          map('grD', vim.lsp.buf.declaration, 'Declaration')
          map('<leader>cr', vim.lsp.buf.rename, '[C]ode [R]ename')
          map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction', { 'n', 'x' })

          if client and client:supports_method('textDocument/completion', event.buf) then
            vim.lsp.completion.enable(true, client.id, event.buf, { autotrigger = true })
          end

          if client and client:supports_method('textDocument/documentHighlight', event.buf) then
            local highlight_group = vim.api.nvim_create_augroup('vince-lsp-highlight-' .. event.buf, { clear = true })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              buffer = event.buf,
              group = highlight_group,
              callback = vim.lsp.buf.document_highlight,
            })

            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              buffer = event.buf,
              group = highlight_group,
              callback = vim.lsp.buf.clear_references,
            })
          end

          if client and client:supports_method('textDocument/inlayHint', event.buf) then
            map('<leader>th', function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }) end, '[T]oggle inlay [H]ints')
          end
        end,
      })

      local servers = {
        bashls = {},
        basedpyright = {},
        clangd = {
          cmd = {
            'clangd',
            '--background-index',
            '--clang-tidy',
            '--completion-style=detailed',
            '--header-insertion=iwyu',
          },
          filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda', 'proto' },
        },
        gopls = {},
        jsonls = {},
        lua_ls = {
          on_init = function(client)
            if client.workspace_folders then
              local path = client.workspace_folders[1].name
              if path ~= vim.fn.stdpath 'config' and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc')) then
                return
              end
            end

            client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
              runtime = {
                version = 'LuaJIT',
                path = { 'lua/?.lua', 'lua/?/init.lua' },
              },
              workspace = {
                checkThirdParty = false,
                library = vim.api.nvim_get_runtime_file('', true),
              },
            })
          end,
          settings = {
            Lua = {},
          },
        },
        marksman = {},
        nil_ls = {},
        rust_analyzer = {},
        taplo = {},
        ts_ls = {},
        yamlls = {},
        zls = {},
      }

      local server_binaries = {
        bashls = 'bash-language-server',
        basedpyright = 'basedpyright-langserver',
        clangd = 'clangd',
        gopls = 'gopls',
        jsonls = 'vscode-json-language-server',
        lua_ls = 'lua-language-server',
        marksman = 'marksman',
        nil_ls = 'nil',
        rust_analyzer = 'rust-analyzer',
        taplo = 'taplo',
        ts_ls = 'typescript-language-server',
        yamlls = 'yaml-language-server',
        zls = 'zls',
      }

      for name, config in pairs(servers) do
        vim.lsp.config(name, config)

        if vim.fn.executable(server_binaries[name] or name) == 1 then
          vim.lsp.enable(name)
        end
      end
    end,
  },
}
