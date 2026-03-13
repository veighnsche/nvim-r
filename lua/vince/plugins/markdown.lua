return {
  {
    'MeanderingProgrammer/render-markdown.nvim',
    ft = { 'markdown' },
    cmd = { 'RenderMarkdown' },
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'nvim-mini/mini.nvim',
    },
    keys = {
      { '<leader>tm', '<cmd>RenderMarkdown toggle<CR>', desc = '[T]oggle [M]arkdown render' },
    },
    config = function()
      local function get_hl(name)
        local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
        return ok and hl or {}
      end

      local function split_rgb(color)
        return math.floor(color / 0x10000) % 0x100, math.floor(color / 0x100) % 0x100, color % 0x100
      end

      local function join_rgb(r, g, b)
        return r * 0x10000 + g * 0x100 + b
      end

      local function blend(fg, bg, alpha)
        if not fg then return bg end
        if not bg then return fg end
        local fr, fg_green, fb = split_rgb(fg)
        local br, bg_green, bb = split_rgb(bg)
        local function channel(a, b)
          return math.floor((alpha * a) + ((1 - alpha) * b) + 0.5)
        end
        return join_rgb(
          channel(fr, br),
          channel(fg_green, bg_green),
          channel(fb, bb)
        )
      end

      local function pick_fg(...)
        for _, name in ipairs({ ... }) do
          local hl = get_hl(name)
          if hl.fg then return hl.fg end
        end
      end

      local function pick_bg(...)
        for _, name in ipairs({ ... }) do
          local hl = get_hl(name)
          if hl.bg then return hl.bg end
        end
      end

      local function set_hl(name, spec)
        vim.api.nvim_set_hl(0, name, spec)
      end

      local function apply_markdown_highlights()
        local base_bg = pick_bg('ColorColumn', 'CursorLine', 'NormalFloat')
        local code_bg = base_bg
        local subtle_bg = code_bg and { bg = code_bg } or {}
        local quote_fg = pick_fg('Comment', 'LineNr')
        local dash_fg = pick_fg('LineNr', 'Comment')
        local inline_fg = pick_fg('String', 'Special')
        local h1_fg = pick_fg('Title', 'Special')
        local h2_fg = pick_fg('Constant', 'Identifier')
        local h3_fg = pick_fg('Identifier', 'Function')
        local h4_fg = pick_fg('Statement', 'Keyword')
        local h5_fg = pick_fg('Type', 'PreProc')
        local h6_fg = pick_fg('Comment', 'LineNr')

        set_hl('RenderMarkdownH1', { fg = h1_fg, bold = true })
        set_hl('RenderMarkdownH2', { fg = h2_fg, bold = true })
        set_hl('RenderMarkdownH3', { fg = h3_fg, bold = true })
        set_hl('RenderMarkdownH4', { fg = h4_fg, bold = true })
        set_hl('RenderMarkdownH5', { fg = h5_fg, bold = true })
        set_hl('RenderMarkdownH6', { fg = h6_fg, italic = true })

        set_hl('RenderMarkdownH1Bg', { bg = blend(h1_fg, base_bg, 0.14) })
        set_hl('RenderMarkdownH2Bg', { bg = blend(h2_fg, base_bg, 0.12) })
        set_hl('RenderMarkdownH3Bg', { bg = blend(h3_fg, base_bg, 0.1) })
        set_hl('RenderMarkdownH4Bg', { bg = blend(h4_fg, base_bg, 0.09) })
        set_hl('RenderMarkdownH5Bg', { bg = blend(h5_fg, base_bg, 0.08) })
        set_hl('RenderMarkdownH6Bg', { bg = blend(h6_fg, base_bg, 0.06) })

        set_hl('RenderMarkdownCode', subtle_bg)
        set_hl('RenderMarkdownCodeBorder', vim.tbl_extend('force', subtle_bg, { fg = quote_fg }))
        set_hl('RenderMarkdownCodeInfo', { fg = quote_fg, italic = true })
        set_hl('RenderMarkdownCodeFallback', { fg = quote_fg })
        set_hl('RenderMarkdownCodeInline', vim.tbl_extend('force', subtle_bg, { fg = inline_fg }))

        set_hl('RenderMarkdownBullet', { fg = quote_fg })
        set_hl('RenderMarkdownDash', { fg = dash_fg })
        set_hl('RenderMarkdownQuote', { fg = quote_fg })
        set_hl('RenderMarkdownQuote1', { fg = quote_fg })
        set_hl('RenderMarkdownQuote2', { fg = quote_fg })
        set_hl('RenderMarkdownQuote3', { fg = quote_fg })
        set_hl('RenderMarkdownQuote4', { fg = quote_fg })
        set_hl('RenderMarkdownQuote5', { fg = quote_fg })
        set_hl('RenderMarkdownQuote6', { fg = quote_fg })

        set_hl('RenderMarkdownUnchecked', { fg = quote_fg })
        set_hl('RenderMarkdownChecked', { fg = pick_fg('DiagnosticOk', 'String'), bold = true })
        set_hl('RenderMarkdownTodo', { fg = pick_fg('DiagnosticWarn', 'Special') })

        set_hl('RenderMarkdownTableHead', vim.tbl_extend('force', subtle_bg, {
          fg = pick_fg('Title', 'Special'),
          bold = true,
        }))
        set_hl('RenderMarkdownTableRow', subtle_bg)

        set_hl('RenderMarkdownLink', { link = 'Underlined' })
        set_hl('RenderMarkdownLinkTitle', { fg = quote_fg, italic = true })
        set_hl('RenderMarkdownWikiLink', { link = 'Underlined' })
      end

      apply_markdown_highlights()

      vim.api.nvim_create_autocmd('ColorScheme', {
        group = vim.api.nvim_create_augroup('vince-markdown-highlights', { clear = true }),
        callback = apply_markdown_highlights,
      })

      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('vince-markdown-buffer', { clear = true }),
        pattern = { 'markdown' },
        callback = function()
          local opt = vim.opt_local
          opt.wrap = true
          opt.linebreak = true
          opt.breakindent = true
          opt.spell = true
          opt.conceallevel = 2
          opt.list = false
          opt.colorcolumn = ''
        end,
      })

      require('render-markdown').setup({
        preset = 'lazy',
        sign = { enabled = false },
        anti_conceal = {
          above = 1,
          below = 1,
        },
        heading = {
          sign = false,
          icons = { '', '', '', '', '', '' },
          position = 'inline',
          width = 'full',
          left_pad = 0,
          right_pad = 0,
          backgrounds = {
            'RenderMarkdownH1Bg',
            'RenderMarkdownH2Bg',
            'RenderMarkdownH3Bg',
            'RenderMarkdownH4Bg',
            'RenderMarkdownH5Bg',
            'RenderMarkdownH6Bg',
          },
          foregrounds = {
            'RenderMarkdownH1',
            'RenderMarkdownH2',
            'RenderMarkdownH3',
            'RenderMarkdownH4',
            'RenderMarkdownH5',
            'RenderMarkdownH6',
          },
        },
        code = {
          sign = false,
          width = 'block',
          border = 'thin',
          language_icon = false,
          language_name = true,
          language_info = false,
          position = 'right',
          right_pad = 1,
          highlight = 'RenderMarkdownCode',
          highlight_info = 'RenderMarkdownCodeInfo',
          highlight_border = 'RenderMarkdownCodeBorder',
          highlight_fallback = 'RenderMarkdownCodeFallback',
          highlight_inline = 'RenderMarkdownCodeInline',
        },
        bullet = {
          icons = { '•', '◦', '▪', '▫' },
          right_pad = 1,
        },
        checkbox = {
          enabled = true,
          unchecked = {
            icon = '□ ',
            highlight = 'RenderMarkdownUnchecked',
          },
          checked = {
            icon = '✓ ',
            highlight = 'RenderMarkdownChecked',
          },
          custom = {
            todo = {
              raw = '[-]',
              rendered = '⋯ ',
              highlight = 'RenderMarkdownTodo',
            },
          },
        },
        quote = {
          icon = '▎',
        },
        pipe_table = {
          preset = 'round',
          head = 'RenderMarkdownTableHead',
          row = 'RenderMarkdownTableRow',
        },
        link = {
          hyperlink = '',
          highlight = 'RenderMarkdownLink',
          highlight_title = 'RenderMarkdownLinkTitle',
          wiki = {
            enabled = true,
            highlight = 'RenderMarkdownWikiLink',
          },
        },
      })
    end,
  },
}
