{#- Rendered to ~/.config/nvim/lua/colors.lua, which init.lua runs at start,
    once it has added mini.nvim, and again whenever wallust rewrites it.
    base16's slots as palette.jinja's base16() fills them, which NixOS's
    Stylix apps get too. -#}
{%- from "palette.jinja" import base16 -%}
require('mini.base16').setup({
	palette = {
		base00 = '{{ base16("00") }}',
		base01 = '{{ base16("01") }}',
		base02 = '{{ base16("02") }}',
		base03 = '{{ base16("03") }}',
		base04 = '{{ base16("04") }}',
		base05 = '{{ base16("05") }}',
		base06 = '{{ base16("06") }}',
		base07 = '{{ base16("07") }}',
		base08 = '{{ base16("08") }}',
		base09 = '{{ base16("09") }}',
		base0A = '{{ base16("0A") }}',
		base0B = '{{ base16("0B") }}',
		base0C = '{{ base16("0C") }}',
		base0D = '{{ base16("0D") }}',
		base0E = '{{ base16("0E") }}',
		base0F = '{{ base16("0F") }}',
	},
})
