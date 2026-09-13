-- Session behaviour, as opposed to layout (styles/) or input (keybinds).
--
-- allow_session_lock_restore lets a restarted lock client take an existing
-- session lock back over. Without it, a lock client that dies while the
-- session is locked leaves the compositor locked with nothing left to unlock
-- it, and the only way back is a TTY and killing Hyprland — losing the
-- session. The shell's lock lives in config/quickshell/lock/, so with this on
-- the recovery is "switch to a TTY, run `qs`, unlock normally".
--
-- The trade-off is that any process already running as this user could
-- replace the lock surface. That needs session access, which is exactly what
-- someone standing at a locked screen does not have.
hl.config({
	misc = {
		allow_session_lock_restore = true,
	},
})
