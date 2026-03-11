return {
  {
    'mfussenegger/nvim-lint',
    event = { 'BufReadPost', 'BufWritePost', 'InsertLeave' },
    config = function()
      local lint = require 'lint'

      lint.linters_by_ft = {
        javascript = { 'oxlint' },
        javascriptreact = { 'oxlint' },
        python = { 'ruff' },
        typescript = { 'oxlint' },
        typescriptreact = { 'oxlint' },
      }

      local lint_group = vim.api.nvim_create_augroup('vince-lint', { clear = true })

      vim.api.nvim_create_autocmd({ 'BufWritePost', 'InsertLeave' }, {
        group = lint_group,
        callback = function() lint.try_lint() end,
      })

      vim.keymap.set('n', '<leader>cl', function() lint.try_lint() end, { desc = '[C]ode [L]int' })
    end,
  },
}
