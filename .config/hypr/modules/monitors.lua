hl.monitor({
	output = "eDP-1",
	mode = "2880x1920@120",
	position = "0x0",
	scale = 2,
})
-- The desktop's monitors go by description, which follows the monitor rather
-- than the port, so another machine's ports keep Hyprland's defaults. This one
-- goes right of whichever monitor is at 0x0, touching it, however wide it is.
hl.monitor({
	output = "desc:Fujitsu Siemens Computers GmbH B24T-7 LED PG",
	mode = "1920x1080@60",
	position = "auto-right",
	scale = 1,
})
hl.monitor({
	output = "desc:LG Electronics 27GL650F",
	mode = "1920x1080@144",
	position = "0x0",
	scale = 1,
})

-- What the Settings app's Displays page kept, after the rules above so it wins
-- (the newest matching rule does). scripts/install-greeter.sh bakes it into
-- the login screen's copy, whose user may not even have a HOME.
local state = os.getenv("XDG_STATE_HOME")
if state == nil or state == "" then
	state = (os.getenv("HOME") or "") .. "/.local/state"
end
local ok, kept = pcall(dofile, state .. "/quickshell/monitors.lua")
if ok and type(kept) == "table" then
	for _, rule in ipairs(kept) do
		hl.monitor(rule)
	end
end
