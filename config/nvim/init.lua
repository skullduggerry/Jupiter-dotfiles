require 'colors'

vim.api.nvim_set_hl(0, "Normal", {bg = "NONE", ctermbg = "NONE"})

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

vim.keymap.set('n', '<leader>o', ':update<CR> :source<CR>') -- source current file
vim.keymap.set('n', '<leader>w', ':write<CR>')              -- write current file
vim.keymap.set('n', '<leader>q', ':q<CR>')                  -- quit
vim.keymap.set('t', '<Esc>', "<C-\\><C-n>")                 -- fix esc in terminal
vim.keymap.set({ 'v', 'v', 'x' }, '<leader>y', '"+y<CR>')   -- yank to system clipboard
vim.keymap.set({ 'v', 'v', 'x' }, '<leader>d', '"+d<CR>')   -- cut to sysyem clipboard
vim.keymap.set('n', '<leader>lf', vim.lsp.buf.format)       -- format code
vim.keymap.set('n', '<leader>f', ':lua MiniFiles.open() <CR>')

-- plugins

vim.pack.add({
	{ src = "https://github.com/nvim-mini/mini.nvim" },          -- autopairs (maybe replace with snipets),
	{ src = "https://github.com/mason-org/mason.nvim" },         -- manage lsp's
	{ src = "https://github.com/neovim/nvim-lspconfig" },        -- configurations for lsp's
	{ src = "https://github.com/mason-org/mason-lspconfig.nvim" }, -- automatically enable lsp's
	{ src = "https://github.com/hrsh7th/nvim-cmp" },             -- code completion, TODO: replace with native
	{ src = "https://github.com/hrsh7th/cmp-nvim-lsp" },         -- code completion source
	{ src = "https://github.com/L3MON4D3/LuaSnip" },             -- snippet engine TODO: propper setup/ replace with native
})


-- plugin config

require "mason".setup()           --disabled bc nix
require "mason-lspconfig".setup() --disabled bc nix
require 'mini.pairs'.setup()
require 'mini.files'.setup()
require 'mini.hipatterns'.setup()
require 'mini.clue'.setup({
	triggers = {
		{ mode = { 'n', 'x' }, keys = '<Leader>' },
		{ mode = { 'n', 'x' }, keys = 'g' },
	},
})
local ls = require 'luasnip'
local cmp = require 'cmp'

cmp.setup({
	snippet = {
		expand = function(args)
			ls.lsp_expand(args.body)
		end,
	},
	mapping = cmp.mapping.preset.insert({
		['<C-b>'] = cmp.mapping.scroll_docs(-4),
		['<C-f>'] = cmp.mapping.scroll_docs(4),
		['<C-e>'] = cmp.mapping.abort(),
		['<CR>'] = cmp.mapping.confirm({ select = true }),
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
		{ name = 'nvim_lsp' },
		{ name = 'luasnip' },
	})
})
