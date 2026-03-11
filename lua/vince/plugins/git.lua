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

local function current_repo_file(root)
  local path = vim.api.nvim_buf_get_name(0)
  if path == '' then
    vim.notify('Current buffer is not a file', vim.log.levels.WARN)
    return nil
  end

  local normalized_root = vim.fs.normalize(root)
  local normalized_path = vim.fs.normalize(path)
  local prefix = normalized_root .. '/'

  if normalized_path:sub(1, #prefix) ~= prefix then
    vim.notify('Current file is outside the repository root', vim.log.levels.WARN)
    return nil
  end

  return normalized_path:sub(#prefix + 1)
end

local function run_git(root, args)
  local cmd = { 'git', '-C', root, '--no-pager' }
  vim.list_extend(cmd, args)

  local result = vim.system(cmd, { text = true }):wait()
  if result.code ~= 0 then
    local stderr = vim.trim(result.stderr or '')
    vim.notify(stderr ~= '' and stderr or ('git command failed: ' .. table.concat(args, ' ')), vim.log.levels.ERROR)
    return nil
  end

  return result.stdout
end

local function open_readonly_buffer(title, content, filetype)
  vim.cmd.tabnew()

  local buf = vim.api.nvim_get_current_buf()
  local lines = vim.split(content, '\n', { plain = true })

  if lines[#lines] == '' then table.remove(lines, #lines) end
  if vim.tbl_isempty(lines) then lines = { '(no output)' } end

  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].swapfile = false
  vim.bo[buf].modifiable = true
  vim.bo[buf].readonly = false
  vim.bo[buf].filetype = filetype

  pcall(vim.api.nvim_buf_set_name, buf, title)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  vim.bo[buf].modifiable = false
  vim.bo[buf].readonly = true

  vim.keymap.set('n', 'q', '<cmd>tabclose<CR>', { buffer = buf, silent = true, desc = 'Close buffer' })
end

local function open_git_output(title, args, opts)
  local root = git_repo_root()
  if not root then return end

  local output = run_git(root, args)
  if not output then return end

  open_readonly_buffer(title, output, opts and opts.filetype or 'diff')
end

local function open_commit_view(commit_hash)
  local root = git_repo_root()
  if not root then return end

  vim.cmd('tcd ' .. vim.fn.fnameescape(root))
  vim.cmd('NeogitCommit ' .. commit_hash)
end

local function open_range_patch(from, to)
  open_git_output(
    ('Git Range %s..%s'):format(from.hash:sub(1, 7), to.hash:sub(1, 7)),
    { 'diff', '--stat', '--patch', from.hash .. '~1..' .. to.hash }
  )
end

local function open_worktree_diff()
  open_git_output('Git Diff', { 'diff', '--stat', '--patch', 'HEAD' })
end

local function open_file_history()
  local root = git_repo_root()
  if not root then return end

  local path = current_repo_file(root)
  if not path then return end

  local output = run_git(root, {
    'log',
    '--follow',
    '--decorate',
    '--date=short',
    '--stat',
    '-p',
    '-n',
    '128',
    '--',
    path,
  })
  if not output then return end

  open_readonly_buffer('Git File History: ' .. path, output, 'diff')
end

local function open_repo_history()
  open_git_output('Git Repo History', {
    'log',
    '--graph',
    '--decorate',
    '--date=short',
    '--stat',
    '-p',
    '--all',
    '-n',
    '128',
  })
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
    'NeogitOrg/neogit',
    cmd = { 'Neogit', 'NeogitCommit', 'NeogitLog', 'NeogitLogCurrent' },
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-telescope/telescope.nvim',
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
      {
        '<leader>gd',
        open_worktree_diff,
        desc = 'Git diff',
      },
      {
        '<leader>gh',
        open_file_history,
        desc = 'Git file history',
      },
      {
        '<leader>gH',
        open_repo_history,
        desc = 'Git repo history',
      },
    },
    opts = {
      graph_style = 'ascii',
      commit_view = {
        kind = 'tab',
      },
      integrations = {
        diffview = false,
        telescope = true,
      },
    },
  },
  {
    'isakbm/gitgraph.nvim',
    keys = {
      {
        '<leader>gl',
        open_git_graph,
        desc = 'Git graph',
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
          open_commit_view(commit.hash)
        end,
        on_select_range_commit = function(from, to)
          open_range_patch(from, to)
        end,
      },
    },
    config = function(_, opts)
      require('gitgraph').setup(opts)
    end,
  },
}
