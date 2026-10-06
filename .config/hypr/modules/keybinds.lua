local cursor = require("modules.cursor")
local vars = require("modules.vars")
local workspaces = require("modules.workspaces")
-- Every bind carries a description: hyprctl binds reports Lua binds only as a
-- callback number, so the description is all the shell's Settings app
-- (Keyboard, Keybinds) has to name them by. Binds that share a description and
-- modifiers show there as one row, like the workspace numbers below.
hl.bind(vars.mainMod .. " + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"), { description = "Log out" })
hl.bind(vars.mainMod .. " + E", hl.dsp.exec_cmd(vars.fileManager), { description = "Open the file manager" })
hl.bind(vars.mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }), { description = "Float or tile the window" })
hl.bind(vars.mainMod .. " + R", hl.dsp.global(vars.menu), { description = "Open the launcher" })
hl.bind(vars.mainMod .. " + L", hl.dsp.global("quickshell:lock"), { description = "Lock the screen" })
hl.bind(vars.mainMod .. " + B", hl.dsp.global("quickshell:barExpand"), { description = "Open or close the bar's drawer" })
hl.bind(vars.mainMod .. " + W", hl.dsp.global("quickshell:wallpaperToggle"), { description = "Choose a wallpaper" })
hl.bind(vars.mainMod .. " + I", hl.dsp.global("quickshell:settingsToggle"), { description = "Open Settings" })
-- The shelf on the bar, a folder Nextcloud syncs (.config/quickshell/services/Shelf.qml).
hl.bind(vars.mainMod .. " + X", hl.dsp.global("quickshell:shelfToggle"), { description = "Open the shelf" })
hl.bind(vars.mainMod .. " + SHIFT + V", hl.dsp.global("quickshell:shelfPaste"), { description = "Paste the clipboard onto the shelf" })
hl.bind(vars.mainMod .. " + C", hl.dsp.window.close(), { description = "Close the window" })
hl.bind(vars.mainMod .. " + PRINT", hl.dsp.exec_cmd("hyprshot -m window"), { description = "Screenshot of a window" })
hl.bind("Print", hl.dsp.exec_cmd("hyprshot -m output"), { description = "Screenshot of a screen" })
hl.bind(vars.mainMod .. " + SHIFT + PRINT", hl.dsp.exec_cmd("hyprshot -m region"), { description = "Screenshot of a region" })
-- The shell changes these and shows the reading (.config/quickshell/osd/).
hl.bind("XF86MonBrightnessUp",   hl.dsp.global("quickshell:brightnessUp"), { locked = true, repeating = true, description = "Brightness up" })
hl.bind("XF86MonBrightnessDown", hl.dsp.global("quickshell:brightnessDown"), { locked = true, repeating = true, description = "Brightness down" })
hl.bind("XF86AudioRaiseVolume",  hl.dsp.global("quickshell:volumeUp"), { locked = true, repeating = true, description = "Volume up" })
hl.bind("XF86AudioLowerVolume",  hl.dsp.global("quickshell:volumeDown"), { locked = true, repeating = true, description = "Volume down" })
hl.bind("XF86AudioMute",         hl.dsp.global("quickshell:volumeMute"), { locked = true, description = "Mute" })
-- The player the bar shows (.config/quickshell/services/Media.qml).
hl.bind("XF86AudioPlay",  hl.dsp.global("quickshell:mediaPlayPause"), { locked = true, description = "Play or pause" })
hl.bind("XF86AudioPause", hl.dsp.global("quickshell:mediaPlayPause"), { locked = true, description = "Play or pause" })
hl.bind("XF86AudioNext",  hl.dsp.global("quickshell:mediaNext"), { locked = true, description = "Next track" })
hl.bind("XF86AudioPrev",  hl.dsp.global("quickshell:mediaPrevious"), { locked = true, description = "Previous track" })
-- The next of input.kb_layout's layouts (.config/quickshell/services/KeyboardLayout.qml).
hl.bind(vars.mainMod .. " + space", hl.dsp.global("quickshell:keyboardLayout"), { description = "Switch the keyboard layout" })
-- The shell holds logind off the power button while unlocked
-- (.config/quickshell/services/PowerButton.qml); locked, logind powers off.
hl.bind("XF86PowerOff", hl.dsp.global("quickshell:powerMenu"), { description = "Open the power menu" })
hl.bind(vars.mainMod .. " + Q", hl.dsp.exec_cmd(vars.terminal), { description = "Open a terminal" })
-- Left and right go through the focused monitor's workspaces
-- (modules/workspaces.lua). With CTRL the arrows go to the next monitor over
-- instead, and with CTRL + SHIFT they take the window along, since SUPER+SHIFT+1
-- to 9 only reach the focused monitor's own workspaces.
hl.bind(vars.mainMod .. " + left",  function() workspaces.step(-1) end, { description = "Previous workspace" })
hl.bind(vars.mainMod .. " + right", function() workspaces.step(1) end, { description = "Next workspace" })
hl.bind(vars.mainMod .. " + up",    hl.dsp.focus({ direction = "up" }), { description = "Focus the window above" })
hl.bind(vars.mainMod .. " + down",  hl.dsp.focus({ direction = "down" }), { description = "Focus the window below" })
for _, direction in ipairs({ "left", "right", "up", "down" }) do
  hl.bind(vars.mainMod .. " + CTRL + " .. direction, hl.dsp.focus({ monitor = direction }), { description = "Focus the monitor in that direction" })
  hl.bind(vars.mainMod .. " + CTRL + SHIFT + " .. direction, hl.dsp.window.move({ monitor = direction }), { description = "Move the window to the monitor in that direction" })
end
hl.bind(vars.mainMod .. " + SHIFT + C", hl.dsp.window.kill(), { description = "Force-quit the window" })
hl.bind(vars.mainMod .. " + P", hl.dsp.window.pseudo(), { description = "Pseudo-tile the window" })
hl.bind(vars.mainMod .. " + J", hl.dsp.layout("togglesplit"), { description = "Swap the split direction" })
hl.bind(vars.mainMod .. " + G", hl.dsp.group.toggle(), { description = "Group or ungroup windows" })
hl.bind(vars.mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"), { description = "Show or hide the scratchpad" })
hl.bind(vars.mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }), { description = "Move the window to the scratchpad" })
hl.bind(vars.mainMod .. " + Tab", hl.dsp.global("quickshell:overview"), { description = "Show every workspace" })
hl.bind(vars.mainMod .. " + slash", hl.dsp.global("quickshell:shortcutsToggle"), { description = "Show the keyboard shortcuts" })
-- Left Ctrl tapped twice shows where the pointer is (modules/cursor.lua),
-- seen on the release and passed on to the window, so Ctrl stays Ctrl.
hl.bind("Control_L", cursor.tap, { release = true, non_consuming = true, ignore_mods = true, description = "Find the pointer (tap twice)" })
-- Workspace 1 to 9 of the focused monitor, i.e. the one the pointer is on.
for number = 1, 9 do
  hl.bind(vars.mainMod .. " + " .. number, function() workspaces.focus(number) end, { description = "Go to that workspace" })
  hl.bind(vars.mainMod .. " + SHIFT + " .. number, function() workspaces.moveWindow(number) end, { description = "Move the window to that workspace" })
end
hl.config({
	input = {
		touchpad = {
			disable_while_typing = false,
			natural_scroll = true,
		},
	},
})

-- The keyboard layouts the Settings app's Keyboard page kept on this machine
-- (Hyprland's own us until then). scripts/install-greeter.sh gives the login
-- screen the same.
local state = os.getenv("XDG_STATE_HOME")
if state == nil or state == "" then
	state = (os.getenv("HOME") or "") .. "/.local/state"
end
local ok, kept = pcall(dofile, state .. "/quickshell/keyboard.lua")
if ok and type(kept) == "table" then
	hl.config({ input = kept })
end

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
	action = {
		finish = function()
			local pos = hl.get_cursor_pos()
			hl.exec_cmd(string.format("qs ipc call dropdown openAt %d %d",
				math.floor(pos.x), math.floor(pos.y)))
		end,
	},
})
