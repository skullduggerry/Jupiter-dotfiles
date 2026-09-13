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
	hl.exec_cmd("blueman-applet")
	hl.exec_cmd("hyprpaper")
	hl.exec_cmd("hypridle")
	hl.exec_cmd("gnome-keyring-daemon --start --components=secrets,ssh,pkcs11")
	hl.exec_cmd("~/.config/wallust/apply.sh")
	hl.exec_cmd("swayosd-server")
	end
)
