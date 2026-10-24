-- The desktop's own parts, started with the session. The list is
-- modules/startup.lua, which the shell's Settings app shows as well.
local session = require("modules.session")
local startup = require("modules.startup")

-- One line, so the pipes M.apps() makes exist before any of them starts.
hl.on("hyprland.start", function()
	hl.exec_cmd(session.apps(startup))
end)
