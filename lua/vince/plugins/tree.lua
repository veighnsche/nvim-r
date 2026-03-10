return {
  {
    'nvim-neo-tree/neo-tree.nvim',
    branch = 'v3.x',
    lazy = false,
    cmd = 'Neotree',
    keys = {
      { '<leader>e', '<cmd>Neotree toggle filesystem reveal right<CR>', desc = 'Explorer' },
    },
    dependencies = {
      'nvim-lua/plenary.nvim',
      'MunifTanjim/nui.nvim',
      { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
    },
    init = function()
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1
    end,
    config = function(_, opts)
      require('neo-tree').setup(opts)

      if vim.fn.argc() == 1 then
        local dir = vim.fn.argv(0)
        if vim.fn.isdirectory(dir) == 1 then
          local dir_buf = vim.api.nvim_get_current_buf()

          vim.cmd.cd(vim.fn.fnameescape(dir))
          vim.cmd.enew()
          pcall(vim.api.nvim_buf_delete, dir_buf, { force = true })

          require('neo-tree.command').execute {
            action = 'show',
            source = 'filesystem',
            position = 'right',
            dir = dir,
            reveal = true,
          }

          vim.cmd.wincmd 'p'
        end
      end
    end,
    opts = function()
      return {
        close_if_last_window = true,
        popup_border_style = 'rounded',
        enable_git_status = true,
        enable_diagnostics = true,
        default_component_configs = {
          indent = {
            with_expanders = true,
            expander_collapsed = vim.g.have_nerd_font and '' or '+',
            expander_expanded = vim.g.have_nerd_font and '' or '-',
          },
        },
        filesystem = {
          bind_to_cwd = true,
          follow_current_file = { enabled = true },
          hijack_netrw_behavior = 'open_current',
          use_libuv_file_watcher = true,
        },
        window = {
          position = 'right',
          width = 32,
        },
      }
    end,
  },
}
