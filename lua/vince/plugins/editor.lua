return {
  {
    'NMAC427/guess-indent.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    opts = {},
  },
  {
    'lewis6991/gitsigns.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    keys = {
      {
        ']h',
        function()
          if vim.wo.diff then
            vim.cmd.normal { ']c', bang = true }
            return
          end

          require('gitsigns').nav_hunk 'next'
        end,
        desc = 'Next changed hunk',
      },
      {
        '[h',
        function()
          if vim.wo.diff then
            vim.cmd.normal { '[c', bang = true }
            return
          end

          require('gitsigns').nav_hunk 'prev'
        end,
        desc = 'Previous changed hunk',
      },
    },
    opts = {
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '^' },
        changedelete = { text = '~' },
      },
    },
  },
  {
    'folke/which-key.nvim',
    event = 'VimEnter',
    opts = {
      delay = 0,
      icons = { mappings = vim.g.have_nerd_font },
      spec = {
        { '<leader>c', group = '[C]ode' },
        { '<leader>F', group = '[F]lutter' },
        { '<leader>g', group = '[G]it' },
        { '<leader>s', group = '[S]earch' },
        { '<leader>t', group = '[T]oggles' },
      },
    },
  },
  {
    'nvim-mini/mini.nvim',
    version = false,
    config = function()
      require('mini.ai').setup { n_lines = 500 }
      require('mini.comment').setup()
      require('mini.surround').setup()
      require('mini.statusline').setup { use_icons = vim.g.have_nerd_font }
    end,
  },
}
