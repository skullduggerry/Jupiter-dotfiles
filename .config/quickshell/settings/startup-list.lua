-- lua startup-list.lua HYPR_CONFIG_DIR
--
-- Prints what Hyprland starts with the session (modules/startup.lua in its
-- config), one entry per line: name, command and about, tab-separated. The
-- module is plain data, so plain `lua` reads it the way Hyprland does,
-- conditions included, for the Settings app's About page, Startup tab.
package.path = arg[1] .. "/?.lua;" .. package.path

local ok, list = pcall(require, "modules.startup")
if not ok then
	io.stderr:write(tostring(list), "\n")
	os.exit(1)
end

local function field(value)
	return (tostring(value or ""):gsub("[\t\n]", " "))
end

for _, entry in ipairs(list) do
	print(field(entry.name) .. "\t" .. field(entry.command) .. "\t" .. field(entry.about))
end
