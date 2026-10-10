local M = {}

-- uwsm, which sets this (modules/env.lua), runs the session as systemd units.
local uwsm = os.getenv("UWSM_FINALIZE_VARNAMES") ~= nil

-- A shell that crashed while locked is started again by Quickshell's crash
-- handler and locks again at once (services/LockService.qml), taking the lock
-- back over; until then Hyprland keeps the screen covered. If it does not come
-- back, `uwsm app -t service -- qs` from a TTY starts it with the session's
-- environment, locked. Replacing the lock that way needs session access, which
-- someone at a locked screen does not have.
hl.config({
	misc = {
		allow_session_lock_restore = true,
	},
})

-- Until hyprpaper is up, Hyprland draws a wallpaper of its own, which flashed
-- before the picked one at every login. The plain background instead, as on
-- the login screen (etc/greetd/hyprland.lua).
hl.config({
	misc = {
		disable_hyprland_logo = true,
		disable_splash_rendering = true,
	},
})

-- A command as the session should run it: under uwsm in a systemd scope of its
-- own (uwsm-app), as the Hyprland wiki asks, rather than inside Hyprland's
-- unit. `slice` is uwsm's: "a" for apps (the default), "b" for background
-- work, "s" for the session's own parts.
function M.app(command, slice)
	if not uwsm then
		return command
	end
	return "uwsm-app" .. (slice and " -s " .. slice or "") .. " -- " .. command
end

-- Under uwsm, `uwsm stop` takes the session down in order; the wiki warns
-- against Hyprland's exit there. The shell's power and quick menus call this.
function M.logout()
	if uwsm then
		hl.exec_cmd("uwsm stop")
	else
		hl.dispatch(hl.dsp.exit())
	end
end

return M
