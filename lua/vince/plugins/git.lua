local function git_repo_root()
  local bufname = vim.api.nvim_buf_get_name(0)
  local cwd = bufname ~= '' and vim.fs.dirname(bufname) or vim.fn.getcwd()
  local result = vim.system({ 'git', '-C', cwd, 'rev-parse', '--show-toplevel' }, { text = true }):wait()

  if result.code ~= 0 then
    vim.notify('Not inside a git repository', vim.log.levels.WARN)
    return nil
  end

  return vim.trim(result.stdout)
end

local function open_git_graph()
  local root = git_repo_root()
  if not root then return end

  vim.cmd('botright split')
  vim.cmd('resize 14')
  vim.cmd('tcd ' .. vim.fn.fnameescape(root))

  require('gitgraph').draw({}, { all = true, max_count = 200 })
end

local function open_git_workspace()
  local root = git_repo_root()
  if not root then return end

  vim.cmd.tabnew()
  vim.cmd('tcd ' .. vim.fn.fnameescape(root))

  require('neogit').open { kind = 'replace' }

  vim.schedule(open_git_graph)
end

return {
  {
    'sindrets/diffview.nvim',
    cmd = {
      'DiffviewOpen',
      'DiffviewClose',
      'DiffviewFileHistory',
      'DiffviewFocusFiles',
      'DiffviewToggleFiles',
    },
    opts = {},
  },
  {
    'NeogitOrg/neogit',
    cmd = 'Neogit',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-telescope/telescope.nvim',
      'sindrets/diffview.nvim',
    },
    keys = {
      {
        '<leader>gg',
        function()
          local root = git_repo_root()
          if not root then return end

          vim.cmd('tcd ' .. vim.fn.fnameescape(root))
          require('neogit').open { kind = 'split' }
        end,
        desc = 'Git status',
      },
      {
        '<leader>gv',
        open_git_workspace,
        desc = 'Git workspace',
      },
    },
    opts = {
      graph_style = 'ascii',
      integrations = {
        diffview = true,
        telescope = true,
      },
    },
  },
  {
    'isakbm/gitgraph.nvim',
    dependencies = { 'sindrets/diffview.nvim' },
    keys = {
      {
        '<leader>gl',
        open_git_graph,
        desc = 'Git graph',
      },
      {
        '<leader>gd',
        '<cmd>DiffviewOpen<CR>',
        desc = 'Git diff view',
      },
      {
        '<leader>gh',
        '<cmd>DiffviewFileHistory %<CR>',
        desc = 'Git file history',
      },
      {
        '<leader>gH',
        '<cmd>DiffviewFileHistory<CR>',
        desc = 'Git repo history',
      },
    },
    opts = {
      git_cmd = 'git',
      symbols = {
        merge_commit = 'M',
        commit = '*',
      },
      format = {
        timestamp = '%Y-%m-%d %H:%M',
        fields = { 'hash', 'timestamp', 'author', 'branch_name', 'tag' },
      },
      hooks = {
        on_select_commit = function(commit)
          vim.cmd('DiffviewOpen ' .. commit.hash .. '^!')
        end,
        on_select_range_commit = function(from, to)
          vim.cmd('DiffviewOpen ' .. from.hash .. '~1..' .. to.hash)
        end,
      },
    },
    config = function(_, opts)
      require('gitgraph').setup(opts)
    end,
  },
}
