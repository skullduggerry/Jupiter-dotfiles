hl.on("hyprland.start", function()
	hl.exec_cmd("waybar")
	hl.exec_cmd("hyprpaper")
	hl.exec_cmd("hypridle")
	hl.exec_cmd("gnome-keyring-daemon --start --components=secrets,ssh,pkcs11")
	hl.exec_cmd("~/.config/wallust/apply.sh")
	hl.exec_cmd("swayosd-server")
	end	
)
