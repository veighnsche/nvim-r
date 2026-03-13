return {
  {
    'folke/trouble.nvim',
    cmd = 'Trouble',
    keys = {
      { '<leader>xx', '<cmd>Trouble diagnostics toggle<CR>', desc = 'Diagnostics' },
      { '<leader>xX', '<cmd>Trouble diagnostics toggle filter.buf=0<CR>', desc = 'Buffer diagnostics' },
      { '<leader>xs', '<cmd>Trouble symbols toggle focus=false<CR>', desc = 'Symbols' },
      { '<leader>xl', '<cmd>Trouble lsp toggle focus=false win.position=right<CR>', desc = 'LSP locations' },
      { '<leader>xq', '<cmd>Trouble qflist toggle<CR>', desc = 'Quickfix list' },
      { '<leader>xt', '<cmd>Trouble todo toggle<CR>', desc = 'Todo list' },
    },
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    opts = {
      focus = true,
      modes = {
        lsp = {
          win = { position = 'right' },
        },
      },
    },
  },
  {
    'stevearc/aerial.nvim',
    keys = {
      { '<leader>cs', '<cmd>AerialToggle!<CR>', desc = '[C]ode [S]ymbols' },
      { ']]', '<cmd>AerialNext<CR>', desc = 'Next symbol' },
      { '[[', '<cmd>AerialPrev<CR>', desc = 'Previous symbol' },
    },
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'nvim-tree/nvim-web-devicons',
    },
    opts = {
      backends = { 'lsp', 'treesitter', 'markdown', 'man' },
      layout = {
        default_direction = 'right',
        min_width = 28,
      },
      show_guides = true,
      filter_kind = false,
    },
  },
  {
    'folke/todo-comments.nvim',
    event = 'VimEnter',
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
    opts = {
      signs = true,
      highlight = {
        keyword = 'bg',
        after = '',
      },
      search = {
        pattern = [[\b(KEYWORDS):]],
      },
    },
    keys = {
      { ']t', function() require('todo-comments').jump_next() end, desc = 'Next todo comment' },
      { '[t', function() require('todo-comments').jump_prev() end, desc = 'Previous todo comment' },
      { '<leader>st', function() require('telescope').extensions['todo-comments'].todo() end, desc = '[S]earch [T]odos' },
      { '<leader>sT', function() require('telescope').extensions['todo-comments'].keywords { keywords = { 'TODO', 'FIX', 'FIXME', 'BUG' } } end, desc = 'Search critical todos' },
    },
  },
}
