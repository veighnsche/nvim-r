local function workspace_symbols()
	vim.ui.input({ prompt = "Workspace symbols > " }, function(query)
		if query and query ~= "" then
			vim.lsp.buf.workspace_symbol(query)
		end
	end)
end

local function sorted_keys(tbl)
	local keys = vim.tbl_keys(tbl)
	table.sort(keys)
	return keys
end

local function resolve_server_command(name, config, binary)
	local executable = vim.fn.exepath(binary)
	if executable == "" then
		return config
	end

	local resolved = vim.deepcopy(config)
	local default = vim.lsp.config[name]
	local cmd = vim.deepcopy(resolved.cmd or (default and default.cmd or nil))

	if type(cmd) == "table" and type(cmd[1]) == "string" then
		cmd[1] = executable
		resolved.cmd = cmd
	else
		resolved.cmd = { executable }
	end

	return resolved
end

return {
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"mason-org/mason.nvim",
			"mason-org/mason-lspconfig.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",
			{ "j-hui/fidget.nvim", opts = {} },
		},
		config = function()
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("vince-lsp-attach", { clear = true }),
				callback = function(event)
					local client = vim.lsp.get_client_by_id(event.data.client_id)

					local map = function(keys, func, desc, mode)
						vim.keymap.set(mode or "n", keys, func, { buffer = event.buf, desc = desc })
					end

					local telescope_ok, builtin = pcall(require, "telescope.builtin")
					if telescope_ok then
						map("grr", builtin.lsp_references, "References")
						map("gri", builtin.lsp_implementations, "Implementation")
						map("grd", builtin.lsp_definitions, "Definition")
						map("grt", builtin.lsp_type_definitions, "Type definition")
						map("gO", builtin.lsp_document_symbols, "Document symbols")
						map("gW", builtin.lsp_dynamic_workspace_symbols, "Workspace symbols")
					else
						map("grr", vim.lsp.buf.references, "References")
						map("gri", vim.lsp.buf.implementation, "Implementation")
						map("grd", vim.lsp.buf.definition, "Definition")
						map("grt", vim.lsp.buf.type_definition, "Type definition")
						map("gO", vim.lsp.buf.document_symbol, "Document symbols")
						map("gW", workspace_symbols, "Workspace symbols")
					end

					map("K", vim.lsp.buf.hover, "Hover")
					map("grn", vim.lsp.buf.rename, "Rename")
					map("gra", vim.lsp.buf.code_action, "Code action", { "n", "x" })
					map("grD", vim.lsp.buf.declaration, "Declaration")
					map("<leader>cr", vim.lsp.buf.rename, "[C]ode [R]ename")
					map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction", { "n", "x" })

					if client and client:supports_method("textDocument/completion", event.buf) then
						vim.lsp.completion.enable(true, client.id, event.buf, { autotrigger = true })
					end

					if client and client:supports_method("textDocument/documentHighlight", event.buf) then
						local highlight_group =
							vim.api.nvim_create_augroup("vince-lsp-highlight-" .. event.buf, { clear = true })
						vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
							buffer = event.buf,
							group = highlight_group,
							callback = vim.lsp.buf.document_highlight,
						})

						vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
							buffer = event.buf,
							group = highlight_group,
							callback = vim.lsp.buf.clear_references,
						})
					end

					if client and client:supports_method("textDocument/inlayHint", event.buf) then
						map("<leader>th", function()
							vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
						end, "[T]oggle inlay [H]ints")
					end
				end,
			})

			local servers = {
				bashls = {},
				basedpyright = {},
				clangd = {
					cmd = {
						"clangd",
						"--background-index",
						"--clang-tidy",
						"--completion-style=detailed",
						"--header-insertion=iwyu",
					},
					filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
				},
				gopls = {},
				jsonls = {},
				lua_ls = {
					on_init = function(client)
						if client.workspace_folders then
							local path = client.workspace_folders[1].name
							if
								path ~= vim.fn.stdpath("config")
								and (vim.uv.fs_stat(path .. "/.luarc.json") or vim.uv.fs_stat(path .. "/.luarc.jsonc"))
							then
								return
							end
						end

						client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua, {
							runtime = {
								version = "LuaJIT",
								path = { "lua/?.lua", "lua/?/init.lua" },
							},
							workspace = {
								checkThirdParty = false,
								library = vim.api.nvim_get_runtime_file("", true),
							},
						})
					end,
					settings = {
						Lua = {},
					},
				},
				marksman = {},
				nil_ls = {},
				rust_analyzer = {},
				taplo = {},
				ts_ls = {},
				yamlls = {},
				zls = {},
			}

			-- Pinned Mason versions make first-time bootstrap more repeatable across machines.
			-- Bootstrapped or SDK-owned tools still come from outside Mason: cppcheck, dart, gofmt, zig, marksman.
			local mason_packages = {
				{ "bash-language-server", version = "5.6.0" },
				{ "basedpyright", version = "1.38.2" },
				{ "clangd", version = "21.1.8" },
				{ "gopls", version = "v0.21.1" },
				{ "json-lsp", version = "4.10.0" },
				{ "lua-language-server", version = "3.17.1" },
				{
					"nil",
					version = "2025-06-13",
					condition = function()
						return vim.fn.executable("nix") == 1
					end,
				},
				{ "rust-analyzer", version = "2026-03-09" },
				{ "taplo", version = "0.10.0" },
				{ "typescript-language-server", version = "5.1.3" },
				{ "yaml-language-server", version = "1.21.0" },
				{ "zls", version = "0.15.1" },
				{ "clang-format", version = "22.1.0" },
				{ "goimports", version = "v0.42.0" },
				{ "oxfmt", version = "0.38.0" },
				{ "oxlint", version = "1.53.0" },
				{ "ruff", version = "0.15.5" },
				{ "rustfmt", version = "v1.5.1" },
				{ "stylua", version = "v2.4.0" },
			}

			local server_binaries = {
				bashls = "bash-language-server",
				basedpyright = "basedpyright-langserver",
				clangd = "clangd",
				gopls = "gopls",
				jsonls = "vscode-json-language-server",
				lua_ls = "lua-language-server",
				marksman = "marksman",
				nil_ls = "nil",
				rust_analyzer = "rust-analyzer",
				taplo = "taplo",
				ts_ls = "typescript-language-server",
				yamlls = "yaml-language-server",
				zls = "zls",
			}

			require("mason").setup()

			local function configure_servers()
				for name, config in pairs(servers) do
					local resolved = config
					local binary = server_binaries[name]
					if binary then
						resolved = resolve_server_command(name, config, binary)
					end
					vim.lsp.config(name, resolved)
				end
			end

			local function enable_configured_servers()
				for _, name in ipairs(sorted_keys(servers)) do
					vim.lsp.enable(name)
				end
			end

			configure_servers()

			require("mason-lspconfig").setup({
				automatic_enable = false,
			})

			require("mason-tool-installer").setup({
				ensure_installed = mason_packages,
				run_on_start = true,
				start_delay = 3000,
				debounce_hours = 12,
			})

			enable_configured_servers()

			vim.api.nvim_create_autocmd("User", {
				group = vim.api.nvim_create_augroup("vince-mason-enable-lsp", { clear = true }),
				pattern = "MasonToolsUpdateCompleted",
				callback = function()
					configure_servers()
					enable_configured_servers()
				end,
			})
		end,
	},
}
