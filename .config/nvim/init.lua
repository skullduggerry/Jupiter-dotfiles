vim.o.number = true
vim.o.relativenumber = true
vim.o.wrap = true
vim.o.signcolumn = "yes"
vim.o.shiftwidth = 2
vim.o.smarttab = true
vim.o.tabstop = 4
vim.o.softtabstop = 0
vim.o.winborder = "rounded"

-- keybinds

vim.g.mapleader = " "

vim.keymap.set("n", "<leader>o", ":update<CR> :source<CR>") -- source current file
vim.keymap.set("n", "<leader>w", ":write<CR>") -- write current file
vim.keymap.set("n", "<leader>q", ":q<CR>") -- quit
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>") -- fix esc in terminal
vim.keymap.set("v", "<leader>y", '"+y') -- yank to system clipboard
vim.keymap.set("v", "<leader>d", '"+d') -- cut to system clipboard
vim.keymap.set("n", "<leader>lf", vim.lsp.buf.format) -- format code
vim.keymap.set("n", "<leader>f", ":lua MiniFiles.open() <CR>")

-- plugins

vim.pack.add({
	{ src = "https://github.com/nvim-mini/mini.nvim" }, -- autopairs (maybe replace with snipets),
	{ src = "https://github.com/mason-org/mason.nvim" }, -- manage lsp's
	{ src = "https://github.com/neovim/nvim-lspconfig" }, -- configurations for lsp's
	{ src = "https://github.com/mason-org/mason-lspconfig.nvim" }, -- automatically enable lsp's
	{ src = "https://github.com/hrsh7th/nvim-cmp" }, -- code completion, TODO: replace with native
	{ src = "https://github.com/hrsh7th/cmp-nvim-lsp" }, -- code completion source
	{ src = "https://github.com/L3MON4D3/LuaSnip" }, -- snippet engine TODO: propper setup/ replace with native
})

-- theme

-- Colours from the wallust theme: lua/colors.lua, which .config/wallust
-- renders as a mini.base16 palette (mini.nvim is added above). It runs again
-- whenever a theme is applied, so an open nvim follows. The background stays
-- the terminal's, which is translucent.
local colors = vim.fn.stdpath("config") .. "/lua/colors.lua"
local function load_colors()
	if vim.uv.fs_stat(colors) then
		dofile(colors)
	end
	local normal = vim.api.nvim_get_hl(0, { name = "Normal" })
	vim.api.nvim_set_hl(0, "Normal", vim.tbl_extend("force", normal, { bg = "NONE", ctermbg = "NONE" }))
end
load_colors()
-- Watched before the first theme is applied too, so the folder must exist.
vim.fn.mkdir(vim.fs.dirname(colors), "p")
local watch = vim.uv.new_fs_event()
if watch then
	watch:start(
		vim.fs.dirname(colors),
		{},
		vim.schedule_wrap(function(_, name)
			if name == "colors.lua" then
				load_colors()
			end
		end)
	)
end

-- plugin config

require("mason").setup()
require("mason-lspconfig").setup()

-- Language servers for the languages the Jupiter repos use, from the
-- system's packages (Jupiter-installer's pacman.txt and packages.nix) rather
-- than mason's downloads, which NixOS cannot run; nvim-lspconfig configures
-- them. Each starts only where its command is on PATH, as those lists can be
-- trimmed. Arch links Qt 6's qmlls as qmlls6, beside Qt 5's tools.
vim.lsp.config("qmlls", { cmd = { vim.fn.executable("qmlls6") == 1 and "qmlls6" or "qmlls" } })
local servers = {
	"qmlls", -- QML
	"lua_ls", -- Lua (.luarc.json)
	"ruff", -- Python: lint and format
	"pyright", -- Python: types
	"bashls", -- shell, with shellcheck
	"jsonls", -- JSON
	"cssls", -- GTK's CSS
	"yamlls", -- YAML (workflows)
	"taplo", -- TOML
	"nixd", -- Nix (on NixOS: Arch has no official package)
}
for _, server in ipairs(servers) do
	local cmd = vim.lsp.config[server].cmd
	if type(cmd) == "table" and vim.fn.executable(cmd[1]) == 1 then
		vim.lsp.enable(server)
	end
end
-- Each problem's message at the end of its line, which nvim 0.11 stopped
-- showing by default.
vim.diagnostic.config({ virtual_text = true })

require("mini.pairs").setup()
require("mini.files").setup()
require("mini.hipatterns").setup()
require("mini.clue").setup({
	triggers = {
		{ mode = { "n", "x" }, keys = "<Leader>" },
		{ mode = { "n", "x" }, keys = "g" },
	},
})
local ls = require("luasnip")
local cmp = require("cmp")

cmp.setup({
	snippet = {
		expand = function(args)
			ls.lsp_expand(args.body)
		end,
	},
	mapping = cmp.mapping.preset.insert({
		["<C-b>"] = cmp.mapping.scroll_docs(-4),
		["<C-f>"] = cmp.mapping.scroll_docs(4),
		["<C-e>"] = cmp.mapping.abort(),
		["<CR>"] = cmp.mapping.confirm({ select = true }),
		["<Tab>"] = cmp.mapping(function(fallback)
			if cmp.visible() then
				cmp.select_next_item()
			elseif ls.locally_jumpable(1) then
				ls.jump(1)
			else
				fallback()
			end
		end, { "i", "s" }),

		["<S-Tab>"] = cmp.mapping(function(fallback)
			if cmp.visible() then
				cmp.select_prev_item()
			elseif ls.locally_jumpable(-1) then
				ls.jump(-1)
			else
				fallback()
			end
		end, { "i", "s" }),
	}),
	sources = cmp.config.sources({
		{ name = "nvim_lsp" },
		{ name = "luasnip" },
	}),
})
