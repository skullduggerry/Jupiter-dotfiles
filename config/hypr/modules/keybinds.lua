local vars = require("modules.vars")
hl.bind(vars.mainMod .. " + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
hl.bind(vars.mainMod .. " + E", hl.dsp.exec_cmd(vars.fileManager))
hl.bind(vars.mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(vars.mainMod .. " + R", hl.dsp.exec_cmd(vars.menu))
hl.bind(vars.mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(vars.mainMod .. " + C", hl.dsp.window.close())
hl.bind(vars.mainMod .. " + PRINT", hl.dsp.exec_cmd("hyprshot -m window"))
hl.bind("Print", hl.dsp.exec_cmd("hyprshot -m output"))
hl.bind(vars.mainMod .. " + SHIFT + PRINT", hl.dsp.exec_cmd("hyprshot -m region"))
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("swayosd-client --brightness raise"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("swayosd-client --brightness lower"), { locked = true, repeating = true })
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("swayosd-client --output-volume raise"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("swayosd-client --output-volume lower"), { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true, repeating = true })
hl.bind(vars.mainMod .. " + Q", hl.dsp.exec_cmd(vars.terminal))
hl.bind(vars.mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(vars.mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(vars.mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(vars.mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))
hl.bind(vars.mainMod .. " + SHIFT + C", hl.dsp.window.kill())
hl.bind(vars.mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(vars.mainMod .. " + J", hl.dsp.layout("togglesplit"))
hl.bind(vars.mainMod .. " + G", hl.dsp.group.toggle())
hl.bind(vars.mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(vars.mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))
hl.bind(vars.mainMod .. " + Tab", function()
  hl.dispatch(hl.dsp.window.cycle_next())
  hl.dispatch(hl.dsp.window.bring_to_top())
end)
for i = 1, 10 do
  local key = i % 10 -- maps 10 -> the "0" key
  hl.bind(vars.mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
  hl.bind(vars.mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end
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


