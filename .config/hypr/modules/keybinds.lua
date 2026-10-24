local cursor = require("modules.cursor")
local quickmenu = require("modules.quickmenu")
local session = require("modules.session")
local tablet = require("modules.tablet")
local vars = require("modules.vars")
local workspaces = require("modules.workspaces")
-- tablet.bind is hl.bind that also lets a pad key's shortcut run the bind.
local bind = tablet.bind
-- Every bind carries a description: hyprctl binds reports Lua binds only as a
-- callback number, so the description is all the shell's Settings app
-- (Keyboard, Keybinds) has to name them by. Binds that share a description and
-- modifiers show there as one row, like the workspace numbers below.
bind(vars.mainMod .. " + SHIFT + M", session.logout, { description = "Log out" })
bind(vars.mainMod .. " + E", hl.dsp.exec_cmd(session.app(vars.fileManager)), { description = "Open the file manager" })
bind(vars.mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }), { description = "Float or tile the window" })
bind(vars.mainMod .. " + R", hl.dsp.global(vars.menu), { description = "Open the launcher" })
bind(vars.mainMod .. " + L", hl.dsp.global("quickshell:lock"), { description = "Lock the screen" })
bind(vars.mainMod .. " + B", hl.dsp.global("quickshell:barExpand"), { description = "Open or close the bar's drawer" })
bind(vars.mainMod .. " + W", hl.dsp.global("quickshell:wallpaperToggle"), { description = "Choose a wallpaper" })
bind(vars.mainMod .. " + I", hl.dsp.global("quickshell:settingsToggle"), { description = "Open Settings" })
-- The shelf on the bar, a folder Nextcloud syncs (.config/quickshell/services/Shelf.qml).
bind(vars.mainMod .. " + X", hl.dsp.global("quickshell:shelfToggle"), { description = "Open the shelf" })
bind(vars.mainMod .. " + SHIFT + V", hl.dsp.global("quickshell:shelfPaste"), { description = "Paste the clipboard onto the shelf" })
bind(vars.mainMod .. " + C", hl.dsp.window.close(), { description = "Close the window" })
bind(vars.mainMod .. " + PRINT", hl.dsp.exec_cmd(session.app("hyprshot -m window")), { description = "Screenshot of a window" })
bind("Print", hl.dsp.exec_cmd(session.app("hyprshot -m output")), { description = "Screenshot of a screen" })
bind(vars.mainMod .. " + SHIFT + PRINT", hl.dsp.exec_cmd(session.app("hyprshot -m region")), { description = "Screenshot of a region" })
-- The shell changes these and shows the reading (.config/quickshell/osd/).
bind("XF86MonBrightnessUp", hl.dsp.global("quickshell:brightnessUp"), { locked = true, repeating = true, description = "Brightness up" })
bind("XF86MonBrightnessDown", hl.dsp.global("quickshell:brightnessDown"), { locked = true, repeating = true, description = "Brightness down" })
bind("XF86AudioRaiseVolume", hl.dsp.global("quickshell:volumeUp"), { locked = true, repeating = true, description = "Volume up" })
bind("XF86AudioLowerVolume", hl.dsp.global("quickshell:volumeDown"), { locked = true, repeating = true, description = "Volume down" })
bind("XF86AudioMute", hl.dsp.global("quickshell:volumeMute"), { locked = true, description = "Mute" })
-- The player the bar shows (.config/quickshell/services/Media.qml).
bind("XF86AudioPlay", hl.dsp.global("quickshell:mediaPlayPause"), { locked = true, description = "Play or pause" })
bind("XF86AudioPause", hl.dsp.global("quickshell:mediaPlayPause"), { locked = true, description = "Play or pause" })
bind("XF86AudioNext", hl.dsp.global("quickshell:mediaNext"), { locked = true, description = "Next track" })
bind("XF86AudioPrev", hl.dsp.global("quickshell:mediaPrevious"), { locked = true, description = "Previous track" })
-- The next of input.kb_layout's layouts (.config/quickshell/services/KeyboardLayout.qml).
bind(vars.mainMod .. " + space", hl.dsp.global("quickshell:keyboardLayout"), { description = "Switch the keyboard layout" })
-- The shell holds logind off the power button while unlocked
-- (.config/quickshell/services/PowerButton.qml); locked, logind powers off.
bind("XF86PowerOff", hl.dsp.global("quickshell:powerMenu"), { description = "Open the power menu" })
bind(vars.mainMod .. " + Q", hl.dsp.exec_cmd(session.app(vars.terminal)), { description = "Open a terminal" })
-- Left and right go through the focused monitor's workspaces
-- (modules/workspaces.lua). With CTRL the arrows go to the next monitor over
-- instead, and with CTRL + SHIFT they take the window along, since SUPER+SHIFT+1
-- to 9 only reach the focused monitor's own workspaces.
bind(vars.mainMod .. " + left", function()
	workspaces.step(-1)
end, { description = "Previous workspace" })
bind(vars.mainMod .. " + right", function()
	workspaces.step(1)
end, { description = "Next workspace" })
bind(vars.mainMod .. " + up", hl.dsp.focus({ direction = "up" }), { description = "Focus the window above" })
bind(vars.mainMod .. " + down", hl.dsp.focus({ direction = "down" }), { description = "Focus the window below" })
for _, direction in ipairs({ "left", "right", "up", "down" }) do
	bind(vars.mainMod .. " + CTRL + " .. direction, hl.dsp.focus({ monitor = direction }), { description = "Focus the monitor in that direction" })
	bind(
		vars.mainMod .. " + CTRL + SHIFT + " .. direction,
		hl.dsp.window.move({ monitor = direction }),
		{ description = "Move the window to the monitor in that direction" }
	)
end
bind(vars.mainMod .. " + SHIFT + C", hl.dsp.window.kill(), { description = "Force-quit the window" })
bind(vars.mainMod .. " + P", hl.dsp.window.pseudo(), { description = "Pseudo-tile the window" })
bind(vars.mainMod .. " + J", hl.dsp.layout("togglesplit"), { description = "Swap the split direction" })
bind(vars.mainMod .. " + G", hl.dsp.group.toggle(), { description = "Group or ungroup windows" })
bind(vars.mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"), { description = "Show or hide the scratchpad" })
bind(vars.mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }), { description = "Move the window to the scratchpad" })
bind(vars.mainMod .. " + Tab", hl.dsp.global("quickshell:overview"), { description = "Show every workspace" })
-- The bar's surfaces without the bar: the quick menu where the pointer is
-- (modules/quickmenu.lua; hold, move and let go to pick, or tap to keep it
-- open), the notifications, the calendar, the power menu.
bind(vars.mainMod .. " + A", quickmenu.press, { description = "Open the quick menu" })
bind(vars.mainMod .. " + A", quickmenu.release, { release = true, description = "Open the quick menu" })
bind(vars.mainMod .. " + N", hl.dsp.global("quickshell:notificationsToggle"), { description = "Show the notifications" })
bind(vars.mainMod .. " + D", hl.dsp.global("quickshell:calendarToggle"), { description = "Show the calendar" })
bind("CTRL + ALT + Delete", hl.dsp.global("quickshell:powerMenu"), { description = "Open the power menu" })
bind(vars.mainMod .. " + slash", hl.dsp.global("quickshell:shortcutsToggle"), { description = "Show the keyboard shortcuts" })
-- Left Ctrl tapped twice shows where the pointer is (modules/cursor.lua),
-- seen on the release and passed on to the window, so Ctrl stays Ctrl.
bind("Control_L", cursor.tap, { release = true, non_consuming = true, ignore_mods = true, description = "Find the pointer (tap twice)" })
-- Workspace 1 to 9 of the focused monitor, i.e. the one the pointer is on.
for number = 1, 9 do
	bind(vars.mainMod .. " + " .. number, function()
		workspaces.focus(number)
	end, { description = "Go to that workspace" })
	bind(vars.mainMod .. " + SHIFT + " .. number, function()
		workspaces.moveWindow(number)
	end, { description = "Move the window to that workspace" })
end
hl.config({
	input = {
		touchpad = {
			disable_while_typing = false,
			natural_scroll = true,
		},
	},
})

-- The keyboard layouts the Settings app's Keyboard page kept on this machine,
-- the system's until then (modules/vconsole.lua). scripts/install-greeter.sh
-- gives the login screen the same.
local state = os.getenv("XDG_STATE_HOME")
if state == nil or state == "" then
	state = (os.getenv("HOME") or "") .. "/.local/state"
end
local ok, kept = pcall(dofile, state .. "/quickshell/keyboard.lua")
if ok and type(kept) == "table" then
	hl.config({ input = kept })
else
	hl.config({ input = require("modules.vconsole") })
end
-- Caps Lock opens the quick menu unless the Keyboard page kept it off
-- (.config/quickshell/services/QuickMenu.qml).
local menuKept, menu = pcall(dofile, state .. "/quickshell/quickmenu.lua")
quickmenu.useCapsLock(not (menuKept and type(menu) == "table" and menu.capsLock == false))

hl.gesture({
	fingers = 3,
	direction = "horizontal",
	action = "workspace",
})

-- Three-finger swipe down opens the shell's dropdown for the third of the
-- monitor under the pointer: workspaces, calendar or quick settings.
hl.gesture({
	fingers = 3,
	direction = "down",
	-- The stubs know a dispatcher or a function here, but Hyprland takes
	-- callbacks for the gesture's phases too.
	---@diagnostic disable-next-line: assign-type-mismatch
	action = {
		finish = function()
			local pos = hl.get_cursor_pos()
			if pos then
				hl.exec_cmd(string.format("qs ipc call dropdown openAt %d %d", math.floor(pos.x), math.floor(pos.y)))
			end
		end,
	},
})

-- The drawing tablet (modules/tablet.lua) on the focused screen or window
-- alone, until the same keys let it go again.
bind(vars.mainMod .. " + T", tablet.holdScreen, { description = "Hold the tablet to this screen" })
bind(vars.mainMod .. " + SHIFT + T", tablet.holdWindow, { description = "Hold the tablet to this window" })
