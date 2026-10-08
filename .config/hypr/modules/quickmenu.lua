-- The shell's quick menu (.config/quickshell/quickmenu/) opens where the
-- pointer is, so its key tells the shell in custom events, as cursor.lua
-- does: "quickmenu press X Y" as the key goes down, "quickmenu release" as it
-- comes up, which uses what the pointer moved to. keybinds.lua binds SUPER + A
-- and, unless the Settings app's Keyboard page kept it off (quickmenu.lua in
-- the shell's state), Caps Lock; the shell switches that live with
-- `hyprctl eval 'require("modules.quickmenu").useCapsLock(...)'`.
local M = {}

function M.press()
	local pointer = hl.get_cursor_pos()
	if pointer ~= nil then
		hl.dispatch(hl.dsp.event(string.format("quickmenu press %.1f %.1f", pointer.x, pointer.y)))
	end
end

function M.release()
	hl.dispatch(hl.dsp.event("quickmenu release"))
end

-- caps:none stops Caps Lock locking capitals, and leaves the key no keysym,
-- so the bind goes by its keycode.
function M.useCapsLock(enabled)
	hl.unbind("code:66")
	hl.config({ input = { kb_options = enabled and "caps:none" or "" } })
	if enabled then
		hl.bind("code:66", M.press, { description = "Open the quick menu" })
		hl.bind("code:66", M.release, { release = true, description = "Open the quick menu" })
	end
end

return M
