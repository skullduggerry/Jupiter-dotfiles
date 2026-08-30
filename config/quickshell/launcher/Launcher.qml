import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

Scope {
	id: launcherScope

	property bool launcherVisible: false

	// `qs -c <config> ipc call launcher toggle/open/close`
	// Bind this to a Hyprland keybind, e.g.:
	//   bind = SUPER, R, exec, qs ipc call launcher toggle
	IpcHandler {
		target: "launcher"
		function toggle(): void { launcherScope.launcherVisible = !launcherScope.launcherVisible }
		function open(): void { launcherScope.launcherVisible = true }
		function close(): void { launcherScope.launcherVisible = false }
	}

	// TODO: wrap this in Variants { model: Quickshell.screens }, same as
	// Bar.qml, once you want it to follow the focused monitor instead of
	// just the default one.
	PanelWindow {
		id: window
		visible: launcherScope.launcherVisible
		onVisibleChanged: if (visible) content.reset()

		WlrLayershell.namespace: "quickshell:launcher"
		WlrLayershell.layer: WlrLayer.Overlay
		WlrLayershell.keyboardFocus: window.visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

		anchors {
			top: true
			bottom: true
			left: true
			right: true
		}
		color: Qt.rgba(0, 0, 0, 0.35)

		// click the dimmed backdrop to close
		MouseArea {
			anchors.fill: parent
			onClicked: launcherScope.launcherVisible = false
		}

		LauncherContent {
			id: content
			anchors.centerIn: parent
			onLaunched: launcherScope.launcherVisible = false
			onCancelled: launcherScope.launcherVisible = false
		}
	}
}
