return {
	{
		"nvim-treesitter/nvim-treesitter",
		lazy = false,
		build = ":TSUpdate",
		config = function()
			local bootstrap = require("vince.bootstrap")
			local treesitter = require("nvim-treesitter")
			treesitter.setup()

			local configured = {}
			for _, parser in ipairs(bootstrap.treesitter_parsers) do
				configured[parser] = true
			end

			vim.api.nvim_create_autocmd("FileType", {
				group = vim.api.nvim_create_augroup("vince-treesitter-start", { clear = true }),
				callback = function(args)
					local bufnr = args.buf
					local language = vim.treesitter.language.get_lang(vim.bo[bufnr].filetype)
					if not language or not configured[language] then
						return
					end
					vim.treesitter.language.add(language)
					vim.treesitter.start(bufnr, language)
					vim.bo[bufnr].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				end,
			})
		end,
	},
}
