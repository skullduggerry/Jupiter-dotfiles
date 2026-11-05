-- The drawing tablet, set through input.tablet and input.tablettool so that it
-- applies to any tablet, whatever Hyprland names it. Where it draws and how
-- its pen feels are the Settings app's Tablet page's, kept in tablet.lua in
-- the shell's state (.config/quickshell/services/Tablet.qml), which the shell
-- also hands over live with `hyprctl eval 'require("modules.tablet").use({…})'`.
-- On top of that, until the session ends, keybinds.lua's SUPER + T holds the
-- tablet to the focused screen and SUPER + SHIFT + T to the focused window;
-- the same keys again let go. The pad's keys are the shell's, which presses a
-- shortcut set on one through press().
local M = {}

local state = os.getenv("XDG_STATE_HOME")
if state == nil or state == "" then
	state = (os.getenv("HOME") or "") .. "/.local/state"
end

-- Before the page kept anything: every screen, libinput's pressure. area is
-- "all", "focused" (whichever screen has focus) or an output's name. width
-- and height are the tablet's in mm, which the shell reads from udev: without
-- them the whole tablet is used, whatever keepRatio says.
local defaults = {
	area = "all",
	keepRatio = true,
	leftHanded = false,
	pressureMin = 0,
	pressureMax = 1,
	width = 0,
	height = 0,
}
local kept = defaults
-- { screen = name } or { window = address }, from the binds.
local held = nil
-- What Hyprland was last given: every change makes it set up its input
-- devices again, so an unchanged one is not sent.
local last = nil
-- Follows the held window as it moves and resizes, which raises no event.
-- Made on first use, as cursor.lua's: timers belong to the running config.
local follow = nil
-- keybinds.lua's binds by their keys (combo()), for press(): Hyprland runs no
-- bind for keys it is sent.
local binds = {}
local modifiers = {
	SHIFT = "SHIFT",
	CTRL = "CTRL",
	CONTROL = "CTRL",
	ALT = "ALT",
	MOD1 = "ALT",
	SUPER = "SUPER",
	WIN = "SUPER",
	LOGO = "SUPER",
	MOD4 = "SUPER",
	META = "SUPER",
}

local function notify(text)
	hl.exec_cmd("notify-send -a Tablet -t 1500 Tablet '" .. text .. "'")
end

-- Output names are Hyprland's own, but go into a shell command.
local function where(area)
	if area == "all" then
		return "every screen"
	elseif area == "focused" then
		return "the focused screen"
	end
	return (area:gsub("[^%w%-]", ""))
end

local function letGo()
	held = nil
	if follow ~= nil then
		follow:set_enabled(false)
	end
	notify("Back on " .. where(kept.area))
end

-- The box every screen together covers, in the layout's coordinates: left,
-- top, width and height, nil before there is a screen.
local function layoutBox()
	local left, top, right, bottom = math.huge, math.huge, -math.huge, -math.huge
	for _, monitor in ipairs(hl.get_monitors()) do
		left = math.min(left, monitor.x)
		top = math.min(top, monitor.y)
		right = math.max(right, monitor.x + monitor.width / monitor.scale)
		bottom = math.max(bottom, monitor.y + monitor.height / monitor.scale)
	end
	if right <= left or bottom <= top then
		return nil
	end
	return left, top, right - left, bottom - top
end

-- Where the tablet draws: an output ("" for every screen, "current" for the
-- focused one), a box on it, or in the layout where absolute, and the shape
-- of what that is, width over height. Hyprland takes no 0x0 box for all of
-- it, so the box is the whole of it; with no screen yet, it is 0x0 and none
-- is given.
local function target()
	if held ~= nil and held.window ~= nil then
		local window = hl.get_window("address:" .. held.window)
		if window == nil then
			letGo()
		else
			local monitor, workspace = window.monitor, window.workspace
			if monitor ~= nil and workspace ~= nil and workspace.active then
				return {
					output = monitor.name,
					x = window.at.x - monitor.x,
					y = window.at.y - monitor.y,
					width = window.size.x,
					height = window.size.y,
					ratio = window.size.x / math.max(window.size.y, 1),
				}
			end
			-- On a workspace out of sight: where it would be unheld, until it shows.
		end
	end
	local area = held ~= nil and held.screen or kept.area
	local monitor = nil
	if area == "focused" then
		monitor = hl.get_active_monitor()
	elseif area ~= "all" then
		monitor = hl.get_monitor(area)
	end
	if monitor == nil then
		local output = area == "focused" and "current" or area == "all" and "" or area
		local x, y, width, height = layoutBox()
		if x == nil then
			return { output = output, x = 0, y = 0, width = 0, height = 0 }
		end
		return {
			output = output,
			absolute = true,
			x = x,
			y = y,
			width = width,
			height = height,
			ratio = width / height,
		}
	end
	return {
		output = area == "focused" and "current" or monitor.name,
		x = 0,
		y = 0,
		width = monitor.width / monitor.scale,
		height = monitor.height / monitor.scale,
		ratio = monitor.width / monitor.height,
	}
end

-- The part of the tablet in use, in mm: with keepRatio, as much of it as has
-- the shape of what it draws on, centred, so that a circle stays round.
local function activeArea(ratio)
	local width, height = kept.width, kept.height
	if not kept.keepRatio or ratio == nil then
		return { 0, 0 }, { width, height }
	end
	if width / height > ratio then
		return { (width - height * ratio) / 2, 0 }, { height * ratio, height }
	end
	return { 0, (height - width / ratio) / 2 }, { width, width / ratio }
end

function M.apply()
	local to = target()
	local tablet = { output = to.output, left_handed = kept.leftHanded }
	if to.width > 0 and to.height > 0 then
		tablet.region_position = { to.x, to.y }
		tablet.region_size = { to.width, to.height }
		tablet.absolute_region_position = to.absolute == true
	end
	-- Hyprland keeps the last active area set when it is set back to 0x0, so
	-- the whole tablet is given as an area too.
	if kept.width > 0 and kept.height > 0 then
		tablet.active_area_position, tablet.active_area_size = activeArea(to.ratio)
	end
	local tool = { pressure_range_min = kept.pressureMin, pressure_range_max = kept.pressureMax }
	local given = string.format(
		"%s %s %g %g %g %g %s %s %s %s",
		to.output,
		tostring(to.absolute == true),
		to.x,
		to.y,
		to.width,
		to.height,
		tostring(kept.leftHanded),
		table.concat(tablet.active_area_position or {}, ","),
		table.concat(tablet.active_area_size or {}, ","),
		kept.pressureMin .. "," .. kept.pressureMax
	)
	if given == last then
		return
	end
	last = given
	hl.config({ input = { tablet = tablet, tablettool = tool } })
end

-- Keys as a bind spells them ("SUPER + SHIFT + M"), spelt one way whatever
-- the case or the order: "SUPER SHIFT m"; nil for a modifier Hyprland lacks.
local function combo(keys)
	local parts = {}
	for part in keys:gmatch("[^+]+") do
		table.insert(parts, (part:gsub("^%s+", ""):gsub("%s+$", "")))
	end
	local key = table.remove(parts)
	local named = {}
	for _, part in ipairs(parts) do
		local modifier = modifiers[part:upper()]
		if modifier == nil then
			return nil
		end
		named[modifier] = true
	end
	local spelt = {}
	for _, modifier in ipairs({ "SUPER", "CTRL", "ALT", "SHIFT" }) do
		if named[modifier] then
			table.insert(spelt, modifier)
		end
	end
	table.insert(spelt, key ~= nil and key:lower() or "")
	return table.concat(spelt, " ")
end

-- keybinds.lua's hl.bind, which press() can then run.
function M.bind(keys, dispatcher, options)
	local name = combo(keys)
	if name ~= nil and not (options ~= nil and options.release) then
		binds[name] = dispatcher
	end
	return hl.bind(keys, dispatcher, options)
end

-- A pad key's shortcut ("CTRL SHIFT", "z") as if pressed on the keyboard: the
-- bind on those keys runs, or else the focused window gets them, down and up
-- at once, since Hyprland releases the modifiers right after the key and a
-- key held down would repeat bare.
function M.press(mods, key)
	local bind = binds[combo((mods ~= "" and mods:gsub("%s+", " + ") .. " + " or "") .. key)]
	if bind ~= nil then
		hl.dispatch(bind)
		return
	end
	for _, state in ipairs({ "down", "up" }) do
		hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = state }))
	end
end

-- What the Settings app kept, live, or from tablet.lua.
function M.use(settings)
	kept = {}
	for key, value in pairs(defaults) do
		kept[key] = value
	end
	if type(settings) == "table" then
		for key, value in pairs(settings) do
			kept[key] = value
		end
	end
	M.apply()
end

function M.holdScreen()
	local monitor = hl.get_active_monitor()
	if monitor == nil then
		return
	end
	if held ~= nil and held.screen == monitor.name then
		letGo()
	else
		if follow ~= nil then
			follow:set_enabled(false)
		end
		held = { screen = monitor.name }
		notify("Held to " .. where(monitor.name))
	end
	M.apply()
end

function M.holdWindow()
	local window = hl.get_active_window()
	if window == nil then
		return
	end
	if held ~= nil and held.window == window.address then
		letGo()
	else
		held = { window = window.address }
		follow = follow or hl.timer(M.apply, { timeout = 200, type = "repeat" })
		follow:set_enabled(true)
		notify("Held to the window")
	end
	M.apply()
end

-- While the Settings app records a pad key's shortcut, every key goes to it,
-- the binds' too. Escape leaves, as the page does, even with the shell gone.
hl.define_submap("tablet-record", function()
	hl.bind("Escape", hl.dsp.submap("reset"), { description = "Stop recording a pad key's shortcut" })
end)

-- The shape of what the tablet draws on changes with the screens, and with
-- focus where it follows focus.
hl.on("monitor.focused", M.apply)
hl.on("monitor.layout_changed", M.apply)

local ok, file = pcall(dofile, state .. "/quickshell/tablet.lua")
M.use(ok and file or nil)

return M
