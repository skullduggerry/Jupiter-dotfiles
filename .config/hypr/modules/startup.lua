-- What Hyprland starts with the session, in order: the desktop's own parts.
-- modules/start.lua runs them. The shell's Settings app (Startup page) lists
-- them by reading this file with plain `lua`, so it is data only and never
-- touches `hl`. Apps belong in XDG autostart instead (~/.config/autostart),
-- which uwsm hands to systemd and the same page switches on and off.
local state = os.getenv("XDG_STATE_HOME")
if state == nil or state == "" then
	state = os.getenv("HOME") .. "/.local/state"
end

-- The shell keeps the wallpaper picked as a hyprpaper config of its own, which
-- sources hyprpaper.conf (config/quickshell/services/WallpaperService.qml): a
-- `source =` the other way round stops hyprpaper while the file is missing.
local function hyprpaper()
	local picked = state .. "/quickshell/hyprpaper.conf"
	local file = io.open(picked, "r")
	if file then
		file:close()
		return "hyprpaper -c '" .. picked .. "'"
	end
	return "hyprpaper"
end

return {
	-- The global shortcuts and the three-finger swipe all call into it.
	{ name = "Shell", command = "qs", about = "The bar, launcher, notifications and lock screen" },
	{ name = "Wallpaper", command = hyprpaper(), about = "hyprpaper, on the wallpaper picked last" },
	{ name = "Idle", command = "hypridle", about = "Locks and turns the screens off when idle" },
	{ name = "Keyring", command = "gnome-keyring-daemon --start --components=secrets,ssh,pkcs11", about = "Keeps passwords and SSH keys for apps" },
	-- Bare, it applies the last theme again, which also renders the colour
	-- files on a fresh clone.
	{ name = "Theme", command = "~/.config/wallust/apply.sh", about = "Renders the colours of the last theme" },
}
