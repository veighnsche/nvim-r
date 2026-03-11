return {
  {
    'nvim-treesitter/nvim-treesitter',
    lazy = false,
    build = ':TSUpdate',
    config = function()
      local parsers = {
        'bash',
        'c',
        'cmake',
        'cpp',
        'diff',
        'dart',
        'go',
        'html',
        'javascript',
        'json',
        'lua',
        'luadoc',
        'markdown',
        'markdown_inline',
        'python',
        'query',
        'rust',
        'toml',
        'tsx',
        'typescript',
        'make',
        'objc',
        'vim',
        'vimdoc',
        'yaml',
        'zig',
      }

      require('nvim-treesitter').install(parsers)

      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('vince-treesitter-start', { clear = true }),
        callback = function(args)
          local bufnr = args.buf
          local language = vim.treesitter.language.get_lang(vim.bo[bufnr].filetype)
          if not language then return end
          if not pcall(vim.treesitter.language.add, language) then return end
          if not pcall(vim.treesitter.start, bufnr, language) then return end
          vim.bo[bufnr].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
    end,
  },
}
