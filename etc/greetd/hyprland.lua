-- Compositor for the quickshell greeter, run by greetd as the `greeter` user.
--
-- Deliberately minimal: no keybinds, no animations, no autostart beyond the
-- greeter itself. The greeter takes exclusive keyboard focus through
-- layer-shell, so there is nothing else here to drive.
--
-- The monitor block mirrors config/hypr/modules/monitors.lua. Without the
-- scale the greeter renders at scale 1 on the 2880x1920 panel and is unusably
-- small — this is the only reason the greeter needs a compositor config at all.
hl.monitor({
	output = "eDP-1",
	mode = "2880x1920@120",
	position = "0x0",
	scale = 2,
})

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
hl.on("hyprland.start", function()
	hl.exec_cmd("qs -p /etc/greetd/quickshell/shell.qml")
end)
