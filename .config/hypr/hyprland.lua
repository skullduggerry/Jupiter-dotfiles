-- This is Hyprland's Lua config, not hyprlang, which changes how the compositor
-- is driven from a shell. `hyprctl dispatch X` evaluates X as Lua, wrapping it
-- as `return hl.dispatch(X)`, so the hyprlang spelling does not work:
--
--     hyprctl dispatch exit                 -- hl.dispatch(exit), exit is nil
--     hyprctl dispatch focusmonitor eDP-1   -- Lua syntax error
--
-- and the Lua spelling does:
--
--     hyprctl dispatch 'hl.dsp.exit()'
--     hyprctl dispatch 'hl.dsp.focus({ monitor = "eDP-1" })'
--
-- A wrong one prints an error and exits 7. Check the status: a script reading
-- only stdout sees nothing wrong and silently does nothing, which is how three
-- dispatches in a row can no-op without anyone noticing.
--
-- `hyprctl eval '<lua>'` runs arbitrary Lua but prints only "ok", so to get a
-- value back out of it, raise the value as an error:
--
--     hyprctl eval 'local t={} for k in pairs(hl.dsp) do t[#t+1]=k end error(table.concat(t," "))'
--
-- Dispatchers on Hyprland 0.56.2: cursor dpms event exec_cmd exec_raw exit
-- focus force_idle force_renderer_reload global group layout no_op pass
-- release_input_capture send_key_state send_shortcut submap window workspace.
-- hl.dsp.focus takes one of: direction, monitor, window, urgent_or_last, last.

require("modules.env")
require("modules.keybinds")
require("modules.monitors")
require("modules.session")
require("modules.start")
require("modules.vars")
require("styles.color")
require("styles.animations")
require("styles.layout")










