-- The system's keyboard layout, from /etc/vconsole.conf, where `localectl
-- set-keymap` and Jupiter-installer keep it beside the console's keymap. The
-- session (keybinds.lua) and the login screen (etc/greetd/vconsole.lua, a link
-- here that scripts/install-greeter.sh installs as a copy) type in it until the
-- Settings app's Keyboard page keeps layouts of their own; without it
-- Hyprland's own us stays.
local input = {}
local file = io.open("/etc/vconsole.conf", "r")
if file then
	for line in file:lines() do
		local key, value = line:match('^%s*XKB(%u+)%s*=%s*"?([^"]*)"?%s*$')
		if key == "LAYOUT" then
			input.kb_layout = value
		elseif key == "VARIANT" then
			input.kb_variant = value
		end
	end
	file:close()
end
return input
