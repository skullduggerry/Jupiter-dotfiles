require("modules.env")
require("modules.keybinds")
require("modules.monitors")
require("modules.pointer")
require("modules.session")
require("modules.start")
require("modules.vars")
require("modules.workspaces")
require("styles.color")
require("styles.animations")
require("styles.layout")

-- Hyprland logs nothing to hyprland.log by default, and `hyprctl
-- configerrors` loses a Lua error at the next eval the shell sends.
hl.config({ debug = { disable_logs = false } })
