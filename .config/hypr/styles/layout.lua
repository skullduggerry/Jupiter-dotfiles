hl.config({
	general = {
		gaps_in = 4,
		gaps_out = 10,
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
			noise = 0.04,
			vibrancy = 0.17,
			ignore_opacity = true,
			-- The Settings app's dropdown lists are popups on the shell's glass
			-- (.config/quickshell/settings/ChoiceField.qml). Their glass, and
			-- the layers' below (ignore_alpha), may be as light as the shell's
			-- least tint (Colors.tintLeast, 0.1) and still be blurred.
			popups = true,
			popups_ignorealpha = 0.05,
		},
	},
	animations = {
		enabled = true,
	},
})

-- The blur the shell's Settings app kept on this machine (Appearance → Style,
-- .config/quickshell/services/HyprBlur.qml): its size in place of the 6
-- above, the variant (Hyprland 0.57's, Kawase by default) and the variants'
-- options, with the glass colours taken from the theme.
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

hl.layer_rule({ name = "qs-bar-blur", match = { namespace = "^quickshell:bar$" }, blur = true, ignore_alpha = 0.05 })
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
	ignore_alpha = 0.05,
})
hl.layer_rule({
	name = "qs-dropdown-blur",
	match = { namespace = "^quickshell:dropdown$" },
	blur = true,
	ignore_alpha = 0.05,
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
