-- Environment for everything Hyprland starts.
--
-- Qt apps (Dolphin and every KIO file dialog) take their colours, font, icon
-- theme and widget style from the platform theme. "kde" is plasma-integration,
-- which is the only thing that actually reads ~/.config/kdeglobals — the
-- wallust-generated colour scheme is inert without it, verified by launching
-- Dolphin with a garish red `[Colors:View]` and watching nothing change.
-- kdeglobals then points `[KDE] widgetStyle` at Kvantum, whose translucent
-- theme is what Hyprland's blur shows through. See .github/THEMING.md.
--
-- These reach anything launched by the compositor, which includes the SUPER+E
-- file manager bind. Something launched by the systemd user session instead
-- (/etc/xdg/autostart) does not — put it in ~/.config/environment.d/ as well
-- if that ever matters.
hl.env("QT_QPA_PLATFORMTHEME", "kde")

-- Let Hyprland draw the frame instead of Qt drawing its own titlebar, so a
-- Dolphin window gets the same border and 8px rounding as everything else.
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
