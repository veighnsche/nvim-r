return {
  {
    'nvim-flutter/flutter-tools.nvim',
    ft = 'dart',
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
    config = function()
      require('flutter-tools').setup {
        flutter_path = '/home/vince/develop/flutter/bin/flutter',
        lsp = {
          color = {
            enabled = true,
          },
          settings = {
            showTodos = true,
            completeFunctionCalls = true,
          },
        },
      }

      vim.keymap.set('n', '<leader>Fr', '<cmd>FlutterRun<CR>', { desc = '[F]lutter [R]un' })
      vim.keymap.set('n', '<leader>FR', '<cmd>FlutterReload<CR>', { desc = '[F]lutter [R]eload' })
      vim.keymap.set('n', '<leader>Fd', '<cmd>FlutterDevices<CR>', { desc = '[F]lutter [D]evices' })
      vim.keymap.set('n', '<leader>Fo', '<cmd>FlutterOutlineToggle<CR>', { desc = '[F]lutter [O]utline' })
      vim.keymap.set('n', '<leader>Fq', '<cmd>FlutterQuit<CR>', { desc = '[F]lutter [Q]uit' })
    end,
  },
}
