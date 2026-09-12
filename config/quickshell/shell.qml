// shell.qml
//
// System tray context menus are platform menus, which quickshell can only
// display when it runs in QApplication mode. Without this pragma clicking a
// tray icon's menu logs "Cannot display PlatformMenuEntry ..." and nothing
// opens. Changing it requires a full restart, not just a config reload.
//@ pragma UseQApplication

import Quickshell
import "./bar"
import "./launcher"

Scope {
    Bar {}
    Launcher {}
}
