# Jupiter-dotfiles

Dotfiles by @skullduggery and @lwctr, usually set up with [Jupiter-installer](https://codeberg.org/skullduggery/Jupiter-installer).

To use your own configuration it is recommended to create a fork and clone that and symlink it. 
Any changes in the dotfiles can then simply be pushed and reused upon reinstall, this is made easier by adding the link to your fork to config.sh in the installer.

## Contents

| Folder | Description |
|---|---|
| **hypr** | Hyprland window manager configuration — keybinds, monitor setup, window rules, autostart. |
| **quickshell** | Quickshell-based shell setup — bar, OSD, lock screen and the rest of the UI. The volume/brightness OSD lives here now; swayosd is gone. |
| **kitty** | Terminal emulator configuration, including wallust-generated color integration. |
| **wallust** | Color palette generation from wallpaper, templated out to other configs (e.g. kitty). |
| **nvim** | Neovim configuration. |
