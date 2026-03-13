local M = {}

M.treesitter_parsers = {
	"bash",
	"c",
	"cmake",
	"cpp",
	"diff",
	"dart",
	"go",
	"html",
	"javascript",
	"json",
	"lua",
	"luadoc",
	"markdown",
	"markdown_inline",
	"python",
	"rust",
	"toml",
	"tsx",
	"typescript",
	"make",
	"objc",
	"vim",
	"vimdoc",
	"yaml",
	"zig",
}

function M.install_treesitter_parsers(timeout_ms)
	local treesitter = require("nvim-treesitter")
	local task = treesitter.install(M.treesitter_parsers, { summary = true })
	local ok = task:wait(timeout_ms or 300000)
	if ok == false then
		error("Timed out while installing tree-sitter parsers")
	end
end

function M.verify_markdown_buffer(timeout_ms)
	assert(vim.bo.filetype == "markdown", "buffer is not markdown")
	assert(vim.fn.executable("marksman") == 1, "marksman is not executable")
	assert(pcall(vim.treesitter.get_parser, 0, "markdown"), "markdown parser missing")
	assert(pcall(vim.treesitter.query.get, "markdown", "highlights"), "markdown highlights missing")
	assert(pcall(vim.treesitter.query.get, "markdown_inline", "highlights"), "markdown_inline highlights missing")

	local ok = vim.wait(timeout_ms or 10000, function()
		for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
			if client.name == "marksman" and not client:is_stopped() then
				return true
			end
		end
		return false
	end, 100)

	assert(ok, "marksman did not attach to markdown buffer")
end

return M
