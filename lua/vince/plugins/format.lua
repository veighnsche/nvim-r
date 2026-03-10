return {
  {
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<leader>cf',
        function() require('conform').format { async = true, lsp_format = 'fallback' } end,
        mode = { 'n', 'v' },
        desc = '[C]ode [F]ormat',
      },
    },
    opts = {
      notify_on_error = false,
      format_on_save = {
        timeout_ms = 1000,
        lsp_format = 'fallback',
      },
      formatters_by_ft = {
        dart = { 'dart_format' },
        go = { 'goimports', 'gofmt' },
        javascript = { 'biome' },
        javascriptreact = { 'biome' },
        json = { 'biome' },
        lua = { 'stylua' },
        python = { 'ruff_organize_imports', 'ruff_format' },
        rust = { 'rustfmt' },
        typescript = { 'biome' },
        typescriptreact = { 'biome' },
        zig = { 'zigfmt' },
      },
    },
  },
}
