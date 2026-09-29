-- A restarted shell can take a lock back over, so a lock that crashed is
-- undone from a TTY by running `qs` and unlocking, not by killing Hyprland.
-- Replacing the lock that way needs session access, which someone at a locked
-- screen does not have.
hl.config({
	misc = {
		allow_session_lock_restore = true,
	},
})
