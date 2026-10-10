-- What Hyprland starts with the session, in order: the desktop's own parts.
-- modules/start.lua runs them. The shell's Settings app (About, Startup) lists
-- them by reading this file with plain `lua`, so it is data only and never
-- touches `hl`. Apps belong in XDG autostart instead (~/.config/autostart),
-- which uwsm hands to systemd and the same page switches on and off.
local state = os.getenv("XDG_STATE_HOME")
if state == nil or state == "" then
	state = os.getenv("HOME") .. "/.local/state"
end

-- The shell keeps a config of its own for hyprpaper, the wallpaper picked
-- (.config/quickshell/services/WallpaperService.qml), and for hypridle, the
-- idle times (.config/quickshell/services/Idle.qml), each sourcing the one
-- here, and they start on it once it exists: a `source =` the other way round
-- stops hyprpaper while the file is missing, and cannot follow XDG_STATE_HOME.
local function kept(program, name)
	local path = state .. "/quickshell/" .. name
	local file = io.open(path, "r")
	if file then
		file:close()
		return program .. " -c '" .. path .. "'"
	end
	return program
end

return {
	-- The global shortcuts and the three-finger swipe all call into it.
	{ name = "Shell", command = "qs", about = "The bar, quick menu, notifications and lock screen" },
	{ name = "Wallpaper", command = kept("hyprpaper", "hyprpaper.conf"), about = "hyprpaper, on the wallpaper picked last" },
	{ name = "Idle", command = kept("hypridle", "hypridle.conf"), about = "Locks, turns the screens off and suspends when idle" },
	{ name = "Keyring", command = "gnome-keyring-daemon --start --components=secrets,ssh,pkcs11", about = "Keeps passwords and SSH keys for apps" },
	-- Bare, it applies the last theme again, which also renders the colour
	-- files on a fresh clone.
	{ name = "Theme", command = "~/.config/wallust/apply.sh", about = "Renders the colours of the last theme" },
}
