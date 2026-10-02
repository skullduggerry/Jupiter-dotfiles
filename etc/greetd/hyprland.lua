-- Compositor for the quickshell greeter, run by greetd as the `greeter` user.
--
-- Deliberately minimal: no keybinds, no animations, no autostart beyond the
-- greeter itself. The greeter takes exclusive keyboard focus through
-- layer-shell, so there is nothing else here to drive.
--
-- The monitors are config/hypr/modules/monitors.lua itself: monitors.lua here
-- is a symlink to it, which scripts/install-greeter.sh installs as a copy, so
-- the greeter comes up in the session's layout on the laptop and the desktop
-- alike. Without the laptop's scale it renders at scale 1 on the 2880x1920
-- panel and is unusably small — the reason the greeter has a config at all.
require("monitors")

hl.config({
	misc = {
		disable_hyprland_logo = true,
		disable_splash_rendering = true,
		-- greetd supervises this compositor, so it is started as plain
		-- Hyprland rather than through start-hyprland. Without this the
		-- greeter wears a red "launched without start-hyprland" banner.
		disable_watchdog_warning = true,
	},
})

-- greetd launches the session only after the greeter COMMAND exits, and
-- Hyprland does not end when its last client does the way cage would. The
-- greeter therefore dispatches hl.dsp.exit() itself once greetd has taken the
-- session -- see GreeterService.qml. Getting this wrong is not subtle: the
-- first vt-2 attempt authenticated fine and then greetd sat waiting until it
-- gave up with "check_children: greeter exited without creating a session".
-- LOCKSCREEN_STYLE is the Lock & Login page's choices, installed beside the
-- greeter, since it cannot read them from $HOME (style/LockLook.qml).
hl.on("hyprland.start", function()
	hl.exec_cmd("LOCKSCREEN_STYLE=/etc/greetd/quickshell/lockscreen.json qs -p /etc/greetd/quickshell/shell.qml")
end)
