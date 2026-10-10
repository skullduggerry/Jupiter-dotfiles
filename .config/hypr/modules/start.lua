-- The desktop's own parts, started with the session. The list is
-- modules/startup.lua, which the shell's Settings app shows as well.
local session = require("modules.session")
local startup = require("modules.startup")

hl.on("hyprland.start", function()
	for _, entry in ipairs(startup) do
		hl.exec_cmd(session.app(entry.command, entry.slice))
	end
end)
