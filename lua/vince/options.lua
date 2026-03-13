vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.g.have_nerd_font = false

vim.filetype.add {
  extension = {
    rhai = 'rhai',
  },
}

local opt = vim.opt

opt.number = true
opt.relativenumber = true
opt.mouse = 'a'
opt.showmode = false
opt.breakindent = true
opt.undofile = true
opt.ignorecase = true
opt.smartcase = true
opt.signcolumn = 'yes'
opt.updatetime = 250
opt.timeoutlen = 300
opt.splitright = true
opt.splitbelow = true
opt.list = true
opt.listchars = { tab = '> ', trail = '.', nbsp = '+' }
opt.inccommand = 'split'
opt.cursorline = true
opt.scrolloff = 8
opt.confirm = true
opt.termguicolors = true
opt.completeopt = { 'menuone', 'noselect', 'popup' }

vim.schedule(function() vim.opt.clipboard = 'unnamedplus' end)

vim.diagnostic.config {
  severity_sort = true,
  float = { border = 'rounded', source = 'if_many' },
  underline = { severity = { min = vim.diagnostic.severity.WARN } },
  virtual_text = true,
  virtual_lines = false,
}

local transparent_editor_groups = {
  'Normal',
  'NormalNC',
  'SignColumn',
  'EndOfBuffer',
  'FoldColumn',
  'LineNr',
  'CursorLineNr',
  'NeoTreeNormal',
  'NeoTreeNormalNC',
  'NeoTreeEndOfBuffer',
  'NeoTreeWinSeparator',
}

local function apply_transparent_background()
  for _, group in ipairs(transparent_editor_groups) do
    vim.api.nvim_set_hl(0, group, { bg = 'none', ctermbg = 'none' })
  end
end

local function copy_background(source, targets)
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = source, link = false })
  if not ok or not hl.bg then return end

  for _, target in ipairs(targets) do
    vim.api.nvim_set_hl(0, target, { bg = hl.bg, ctermbg = hl.ctermbg })
  end
end

local function apply_opaque_ui_backgrounds()
  copy_background('NormalFloat', {
    'TelescopeNormal',
    'TelescopePromptNormal',
    'TelescopeResultsNormal',
    'TelescopePreviewNormal',
  })

  copy_background('FloatBorder', {
    'TelescopeBorder',
    'TelescopePromptBorder',
    'TelescopeResultsBorder',
    'TelescopePreviewBorder',
  })
end

local function apply_background_preferences()
  apply_transparent_background()
  apply_opaque_ui_backgrounds()
end

vim.api.nvim_create_autocmd('ColorScheme', {
  callback = apply_background_preferences,
})

vim.cmd.colorscheme 'habamax'
apply_background_preferences()
