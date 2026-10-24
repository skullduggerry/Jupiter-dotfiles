hl.config({
	general = {
		gaps_in = 6,
		gaps_out = 16,
		border_size = 1,
		col = {
			active_border = { colors = { "rgba(646464ff)" } },
			inactive_border = { colors = { "rgba(303030C8)" } },
		},
		resize_on_border = false,
		layout = "dwindle",
	},
	decoration = {
		rounding = 8,
		-- Strong enough that a busy wallpaper reads as colour, not detail,
		-- behind the shell's glass; a little noise keeps it from banding.
		blur = {
			enabled = true,
			size = 6,
			passes = 3,
			noise = 0.02,
			vibrancy = 0.17,
			ignore_opacity = true,
			-- The Settings app's dropdown lists are popups on the shell's glass
			-- (.config/quickshell/settings/ChoiceField.qml).
			popups = true,
		},
	},
	animations = {
		enabled = true,
	},
})

-- The blur size the shell's Settings app kept on this machine (Appearance →
-- Style), in place of the 6 above.
local state = os.getenv("XDG_STATE_HOME")
if state == nil or state == "" then
	state = (os.getenv("HOME") or "") .. "/.local/state"
end
local ok, kept = pcall(dofile, state .. "/quickshell/blur.lua")
if ok and type(kept) == "table" then
	hl.config({ decoration = { blur = kept } })
end

-- Ignore apps asking to be maximized, as kitty does whenever its last window
-- was closed maximized: they would cover the windows they should tile beside.
hl.window_rule({
	name = "suppress-maximize-events",
	match = { class = ".*" },
	suppress_event = "maximize",
})

hl.layer_rule({ name = "waybar-blur", match = { namespace = "^waybar$" }, blur = true, ignore_alpha = 0.0 })
hl.layer_rule({ name = "qs-bar-blur", match = { namespace = "^quickshell:bar$" }, blur = true, ignore_alpha = 0.2 })
hl.layer_rule({
	name = "qs-overview-blur",
	match = { namespace = "^quickshell:overview$" },
	blur = true,
	no_anim = true,
})
hl.layer_rule({
	name = "qs-shortcuts-blur",
	match = { namespace = "^quickshell:shortcuts$" },
	blur = true,
	no_anim = true,
})
-- The quick menu (the launcher too) blurs the screen and moves by itself.
hl.layer_rule({
	name = "qs-quickmenu-blur",
	match = { namespace = "^quickshell:quickmenu$" },
	blur = true,
	no_anim = true,
})
-- Not blurred: what is around the pointer is the point.
hl.layer_rule({
	name = "qs-cursorfinder",
	match = { namespace = "^quickshell:cursorfinder$" },
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
-- Dropdowns set to Swoosh in the shell's Settings app (Appearance → Style)
-- move by themselves, so Hyprland's fade stays off them. The shell switches
-- this rule live and keeps the choice in dropdowns.lua for the next load.
local swooshKept, dropdowns = pcall(dofile, state .. "/quickshell/dropdowns.lua")
hl.layer_rule({
	name = "qs-dropdown-swoosh",
	match = { namespace = "^quickshell:(dropdown|.*-popup)$" },
	no_anim = true,
	enabled = swooshKept and type(dropdowns) == "table" and dropdowns.swoosh == true,
})
-- The OSD and the toasts are not dropdowns: they keep the fade either way.
hl.layer_rule({
	name = "qs-not-dropdowns",
	match = { namespace = "^quickshell:(osd|toast)-popup$" },
	no_anim = false,
})
