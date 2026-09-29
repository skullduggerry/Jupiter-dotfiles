-- The session's environment lives in config/uwsm/env, where uwsm reads it and
-- hands it to systemd as well, so what systemd starts (xdg autostart, D-Bus
-- activated apps, the portals) gets it too. Without uwsm, it is read here.
if os.getenv("UWSM_FINALIZE_VARNAMES") == nil then
	local config = os.getenv("XDG_CONFIG_HOME")
	if config == nil or config == "" then
		config = os.getenv("HOME") .. "/.config"
	end
	local file = io.open(config .. "/uwsm/env", "r")
	if file then
		for line in file:lines() do
			local key, value = line:match("^export%s+([%w_]+)=(.*)$")
			if key then
				hl.env(key, value)
			end
		end
		file:close()
	end
end
