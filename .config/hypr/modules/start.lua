hl.on("hyprland.start", function()
	-- The quickshell shell (config/quickshell/): bar, launcher, swipe
	-- dropdown and lock screen. It has to be running for the SUPER+O and
	-- SUPER+L global shortcuts and the three-finger swipe to do anything,
	-- since all three call into it.
	--
	-- This replaced `hl.exec_cmd("waybar")`, which used to be the bar here.
	-- config/waybar/ is left in place and still works if you run `waybar` by
	-- hand — starting both just gives you two bars stacked on each other.
	hl.exec_cmd("qs")
	-- The wallpaper app (config/quickshell/services/WallpaperService.qml) keeps
	-- the wallpaper you picked as a hyprpaper config of its own, which sources
	-- hyprpaper.conf and overrides its wallpaper. It is not sourced from
	-- hyprpaper.conf instead because hyprpaper refuses to start at all on a
	-- `source =` whose file is missing, as it is until something is picked.
	local state = os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")
	local picked = state .. "/quickshell/hyprpaper.conf"
	local file = io.open(picked, "r")
	if file then
		file:close()
		hl.exec_cmd("hyprpaper -c '" .. picked .. "'")
	else
		hl.exec_cmd("hyprpaper")
	end
	hl.exec_cmd("hypridle")
	hl.exec_cmd("gnome-keyring-daemon --start --components=secrets,ssh,pkcs11")
	-- Bare, it applies the last theme again (the wallpaper app records it),
	-- which is also what renders the colour files on a fresh clone.
	hl.exec_cmd("~/.config/wallust/apply.sh")
	end
)
