hl.config(
	{
	general = {
		gaps_in  = 6,
		gaps_out = 16,
		border_size = 1,
		col = {
			active_border = {colors = {"rgba(646464ff)"}},
			inactive_border = {colors = {"rgba(303030C8)"}},
		},
		resize_on_border = false,
		layout = "dwindle",


	},
	decoration = {
		rounding = 8,
		blur = {
			enabled = true,
			size = 2,
			passes = 2,
			ignore_opacity = true,
		},
	},
	animations = {
		enabled = true,
	},
	}
)

hl.layer_rule({ name = "waybar-blur",  match = { namespace = "^waybar$" }, blur = true, ignore_alpha = 0.0 })
hl.layer_rule({ name = "swayosd-blur", match = { namespace = "^swayosd$" }, blur = true, ignore_alpha = 0.0 })
hl.layer_rule({ name = "qs-bar-blur",  match = { namespace = "^quickshell:bar$" }, blur = true, ignore_alpha = 0.2 })

