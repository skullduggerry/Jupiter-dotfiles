-- The mouse and the touchpad: how fast the pointer goes and how far a scroll
-- goes, the Settings app's Keyboard & Mouse page's, kept in pointer.lua in the
-- shell's state (.config/quickshell/services/Pointer.qml), which the shell also
-- hands over live with `hyprctl eval 'require("modules.pointer").use({…})'`.
-- input.sensitivity is the mouse's. Hyprland has a scroll factor for every
-- touchpad but no sensitivity, so the touchpads the shell found are given
-- theirs by name, which comes before input.sensitivity.
local M = {}

local state = os.getenv("XDG_STATE_HOME")
if state == nil or state == "" then
	state = (os.getenv("HOME") or "") .. "/.local/state"
end

-- Before the page kept anything: libinput's own speed, scrolling as the app
-- asks. A speed is libinput's, from -1 to 1; a scroll multiplies.
local defaults = {
	mouseSpeed = 0,
	mouseScroll = 1,
	touchpadSpeed = 0,
	touchpadScroll = 1,
	touchpads = {},
}

function M.use(settings)
	local kept = {}
	for key, value in pairs(defaults) do
		kept[key] = value
	end
	if type(settings) == "table" then
		for key, value in pairs(settings) do
			kept[key] = value
		end
	end
	hl.config({
		input = {
			sensitivity = kept.mouseSpeed,
			scroll_factor = kept.mouseScroll,
			touchpad = { scroll_factor = kept.touchpadScroll },
		},
	})
	for _, name in ipairs(kept.touchpads) do
		hl.device({ name = name, sensitivity = kept.touchpadSpeed })
	end
end

local ok, file = pcall(dofile, state .. "/quickshell/pointer.lua")
M.use(ok and file or nil)

return M
