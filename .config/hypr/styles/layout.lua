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

-- Ignore apps asking to be maximized, as kitty does whenever its last window
-- was closed maximized: they would cover the windows they should tile beside.
hl.window_rule({
    name = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.layer_rule({ name = "waybar-blur",  match = { namespace = "^waybar$" }, blur = true, ignore_alpha = 0.0 })
hl.layer_rule({ name = "qs-bar-blur",  match = { namespace = "^quickshell:bar$" }, blur = true, ignore_alpha = 0.2 })
hl.layer_rule({
    match = { namespace = "quickshell:launcher" },
    blur = true,
    no_anim = true,
})
hl.layer_rule({
    name = "qs-popup-blur",
    match = { namespace = "^quickshell:.*-popup$" },
    blur = true,
    ignore_alpha = 0.2,
})
hl.layer_rule({
    name = "qs-dropdown-blur",
    match = { namespace = "^quickshell:dropdown$" },
    blur = true,
    ignore_alpha = 0.2,
})

