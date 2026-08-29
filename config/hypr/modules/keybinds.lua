local vars = require("modules.vars")


hl.bind(vars.mainMod .. " + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
hl.bind(vars.mainMod .. " + E", hl.dsp.exec_cmd(vars.fileManager))
hl.bind(vars.mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(vars.mainMod .. " + R", hl.dsp.exec_cmd(vars.menu))
hl.bind(vars.mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(vars.mainMod .. " + C", hl.dsp.window.close())
hl.bind(vars.mainMod .. " + PRINT", hl.dsp.exec_cmd("hyprshot -m window"))
hl.bind("PRINT", hl.dsp.exec_cmd("hyprshot -m output"))
hl.bind(vars.mainMod .. " + SHIFT + PRINT", hl.dsp.exec_cmd("hyprshot -m region"))
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("swayosd-client --brightness raise"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("swayosd-client --brightness lower"), { locked = true, repeating = true })
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("swayosd-client --output-volume raise"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("swayosd-client --output-volume lower"), { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true, repeating = true })
hl.bind(vars.mainMod .. "+ Q", hl.dsp.exec_cmd(vars.terminal))
hl.config({
	input = {
		touchpad = {
			disable_while_typing = false,
			natural_scroll = true,
		},
	},
})

hl.gesture({
	fingers = 3,
	direction = "horizontal",
	action = "workspace",
})


