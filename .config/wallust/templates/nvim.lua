{#- Rendered to ~/.config/nvim/lua/colors.lua, which init.lua runs at start and
    again whenever wallust rewrites it. base16's slots are roles, not the
    terminal's: 00 to 07 run from the background to the text, 08 to 0F are the
    accents. The surfaces are the shell's (style/Colors.qml). -#}
{%- from "palette.jinja" import shade, mix -%}
vim.pack.add({
	{ src = "https://github.com/nvim-mini/mini.nvim" },
})

require('mini.base16').setup({
	palette = {
		base00 = '{{ background }}',
		base01 = '{{ shade(0.08) }}',
		base02 = '{{ shade(0.16) }}',
		base03 = '{{ shade(0.42) }}',
		base04 = '{{ shade(0.58) }}',
		base05 = '{{ foreground }}',
		base06 = '{{ shade(0.9) }}',
		base07 = '{{ foreground }}',
		base08 = '{{ color1 }}',
		base09 = '{{ mix(color1, color3, 0.5) }}',
		base0A = '{{ color3 }}',
		base0B = '{{ color2 }}',
		base0C = '{{ color6 }}',
		base0D = '{{ color4 }}',
		base0E = '{{ color5 }}',
		base0F = '{{ mix(color1, background, 0.4) }}',
	},
})
