-- Every monitor numbers its own workspaces from 1, and the keys act on the
-- focused one (the one under the pointer). Workspace ids are global, so each
-- monitor gets a block of 100 by output name for the session, and a
-- workspace's number is its id % 100. The blocks are kept in
-- workspace-blocks.json beside Hyprland's socket: a reload starts Lua afresh,
-- and the shell reads them too (services/WorkspaceBlocks.qml).
local M = {}

local perMonitor = 100

-- output name -> block, read from the file on first use
local blocks = nil

local function blocksPath()
	return os.getenv("XDG_RUNTIME_DIR") .. "/hypr/" .. os.getenv("HYPRLAND_INSTANCE_SIGNATURE") .. "/workspace-blocks.json"
end

local function saveBlocks(known)
	local entries = {}
	for name, block in pairs(known) do
		table.insert(entries, string.format("%q: %d", name, block))
	end
	table.sort(entries)

	local file = assert(io.open(blocksPath(), "w"))
	file:write('{"blocks": {', table.concat(entries, ", "), "}}\n")
	file:close()
end

-- A monitor seen for the first time takes the block its workspace is in if no
-- other monitor has that one, as the first monitor to come up does, and the
-- lowest free block otherwise.
local function block(monitor)
	if blocks == nil then
		blocks = {}
		local file = io.open(blocksPath(), "r")
		if file then
			for name, known in file:read("a"):gmatch('"([^"]+)": (%d+)') do
				blocks[name] = tonumber(known)
			end
			file:close()
		end
	end

	if blocks[monitor.name] == nil then
		local taken = {}
		for _, known in pairs(blocks) do
			taken[known] = true
		end

		local candidate = monitor.active_workspace and math.floor(monitor.active_workspace.id / perMonitor)
		if candidate == nil or candidate < 0 or taken[candidate] then
			candidate = 0
			while taken[candidate] do
				candidate = candidate + 1
			end
		end

		blocks[monitor.name] = candidate
		saveBlocks(blocks)
	end

	return blocks[monitor.name]
end

-- The id before the monitor's workspace 1.
local function base(monitor)
	return block(monitor) * perMonitor
end

local function own(monitor, workspace)
	return math.floor(workspace.id / perMonitor) == block(monitor)
end

-- A monitor's workspace in a block: not a special one (the scratchpad), which
-- Hyprland 0.57 hands Lua without an id.
local function numbered(workspace, monitor)
	return not workspace.special and workspace.monitor == monitor
end

-- The first id in the monitor's block after `after` that no workspace has.
local function free(monitor, after)
	for id = after + 1, base(monitor) + perMonitor - 1 do
		if not hl.get_workspace(id) then
			return id
		end
	end
end

-- Nothing while no monitor has focus, as between the last one unplugged and
-- the next one up.
function M.focus(number)
	local monitor = hl.get_active_monitor()
	if monitor ~= nil then
		hl.dispatch(hl.dsp.focus({ workspace = base(monitor) + number }))
	end
end

function M.moveWindow(number)
	local monitor = hl.get_active_monitor()
	if monitor ~= nil then
		hl.dispatch(hl.dsp.window.move({ workspace = base(monitor) + number }))
	end
end

-- The previous or next workspace on the focused monitor, the way the
-- three-finger swipe goes: through the ones there are, and past the last one to
-- a new one, unless the last one is empty itself.
function M.step(direction)
	local monitor = hl.get_active_monitor()
	local current = monitor and monitor.active_workspace
	if monitor == nil or current == nil then
		return
	end
	local target = nil

	for _, workspace in ipairs(hl.get_workspaces()) do
		if numbered(workspace, monitor) then
			local distance = (workspace.id - current.id) * direction
			if distance > 0 and (target == nil or distance < (target - current.id) * direction) then
				target = workspace.id
			end
		end
	end

	if target == nil and direction > 0 and current.windows > 0 and own(monitor, current) then
		target = free(monitor, current.id)
	end

	if target ~= nil then
		hl.dispatch(hl.dsp.focus({ workspace = target }))
	end
end

-- A monitor comes up on a new workspace with the lowest free id, which for every
-- monitor but the first is in another one's block. One that was unplugged has
-- its own workspaces back by then, so it shows the first of those instead;
-- otherwise it opens its own workspace 1. That goes through focusing it rather
-- than renumbering the new workspace, which Hyprland could do but Quickshell
-- would not follow, and focus and pointer go back where they were straight
-- after, before anything is drawn.
--
-- Left alone: a mirror, which has no workspace of its own, FALLBACK, the
-- stand-in Hyprland puts up while no monitor is connected, a monitor
-- showing windows, which only takes its block here, and on a reload one
-- already on a workspace of its own, empty or not, which is where it was put.
local function settle(monitor, added)
	local workspace = monitor.active_workspace
	if not workspace or monitor.name == "FALLBACK" then
		return
	end

	local home = own(monitor, workspace)
	if workspace.windows > 0 or (home and not added) then
		return
	end

	local first = nil
	for _, other in ipairs(hl.get_workspaces()) do
		if numbered(other, monitor) and other.id ~= workspace.id and own(monitor, other) and (first == nil or other.id < first) then
			first = other.id
		end
	end

	if first ~= nil then
		monitor:set_workspace(first)
	elseif not home then
		local focused = hl.get_active_monitor()
		local pointer = hl.get_cursor_pos()
		hl.dispatch(hl.dsp.focus({ monitor = monitor }))
		hl.dispatch(hl.dsp.focus({ workspace = free(monitor, base(monitor)) }))
		if focused ~= nil and focused ~= monitor then
			hl.dispatch(hl.dsp.focus({ monitor = focused }))
			if pointer then
				hl.dispatch(hl.dsp.cursor.move({ x = pointer.x, y = pointer.y }))
			end
		end
	end
end

hl.on("monitor.added", function(monitor)
	settle(monitor, true)
end)

-- The monitors that were already there when the config was (re)loaded. The
-- ones showing windows go first, so that a monitor seen for the first time
-- keeps the block its windows are in.
hl.on("config.reloaded", function()
	local monitors = hl.get_monitors()
	local function windows(monitor)
		return monitor.active_workspace and monitor.active_workspace.windows or 0
	end
	table.sort(monitors, function(a, b)
		return windows(a) > windows(b)
	end)

	for _, monitor in ipairs(monitors) do
		settle(monitor)
	end
end)

return M
