-- Tapping Left Ctrl twice shows where the pointer is: the shell
-- (config/quickshell/cursor/) dims every screen but a circle around it, told
-- here where the pointer goes in custom events, until a key is pressed or
-- the pointer has rested a moment. A tap is a press and a release with no
-- other key between them, so Ctrl + C then Ctrl + V is no double tap, and the
-- two presses come within doubleTap and with the pointer still, as for a
-- double click. Over a fullscreen window (a game) it does nothing.
-- keybinds.lua binds tap() to the release, so the shell lists it too.
local M = {}

local doubleTap = 400 -- ms between the two presses
local slop = 8 -- px the pointer may move between them
local tick = 8 -- ms between readings of the pointer while it shows
local rest = 500 -- ms the pointer rests, having moved, before it ends
local linger = 2000 -- ms it shows while the pointer never moves

local pressed = nil -- the last key pressed: its keycode, time and the pointer then
local released = nil -- the keycode of the last key released
local tapped = nil -- the press of the last tap
local shown = false
local last = nil -- where the pointer was at the last reading
local still = 0 -- ms the pointer has been where it is
local moved = false
local ticker = nil

local function send(message)
	hl.dispatch(hl.dsp.event("cursorfinder " .. message))
end

function M.hide()
	if shown then
		shown = false
		ticker:set_enabled(false)
		send("hide")
	end
end

local function read()
	local pointer = hl.get_cursor_pos()
	if pointer.x ~= last.x or pointer.y ~= last.y then
		last, still, moved = pointer, 0, true
		send(string.format("move %.1f %.1f", pointer.x, pointer.y))
	else
		still = still + tick
		if still >= (moved and rest or linger) then
			M.hide()
		end
	end
end

local function show()
	last, still, moved, shown = hl.get_cursor_pos(), 0, false, true
	send(string.format("show %.1f %.1f", last.x, last.y))
	-- Made on first use: timers belong to the running config, and a reload
	-- drops them along with this module's state.
	ticker = ticker or hl.timer(read, { timeout = tick, type = "repeat" })
	ticker:set_enabled(true)
end

hl.on("input.keyboard.key", function(keycode, time, state)
	if state == 1 then
		M.hide()
		if tapped ~= nil and keycode ~= tapped.keycode then
			tapped = nil
		end
		local pointer = hl.get_cursor_pos()
		pressed = { keycode = keycode, time = time, x = pointer.x, y = pointer.y }
	elseif state == 0 then
		released = keycode
	end
end)

-- On Left Ctrl's release, which reaches keybinds after the hook above.
function M.tap()
	local press = pressed
	if press == nil or press.keycode ~= released then
		return
	end

	local previous = tapped
	tapped = press
	if previous == nil or press.time - previous.time > doubleTap
		or math.abs(press.x - previous.x) > slop or math.abs(press.y - previous.y) > slop then
		return
	end

	tapped = nil
	local window = hl.get_active_window()
	if window == nil or window.fullscreen ~= 2 then
		show()
	end
end

return M
