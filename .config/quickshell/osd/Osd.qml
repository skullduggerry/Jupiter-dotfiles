import "../panels"
import "../services"
import "../style"
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Wayland

Scope {
    id: root

    readonly property real volumeStep: 0.05
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool sinkReady: root.sink !== null && root.sink.ready && root.sink.audio !== null
    readonly property ShellScreen screen: {
        const monitor = Hyprland.focusedMonitor;
        if (monitor === null)
            return null;

        return Quickshell.screens.find((candidate) => {
            return candidate.name === monitor.name;
        }) || null;
    }

    function adjustVolume(delta: real) {
        if (!root.sinkReady)
            return ;

        root.sink.audio.muted = false;
        root.sink.audio.volume = Math.max(0, Math.min(1, root.sink.audio.volume + delta));
        OsdState.show(OsdState.zoneAudio);
    }

    function toggleMute() {
        if (!root.sinkReady)
            return ;

        root.sink.audio.muted = !root.sink.audio.muted;
        OsdState.show(OsdState.zoneAudio);
    }

    function adjustBrightness(delta: int) {
        Brightness.adjust(delta);
        OsdState.show(OsdState.zoneBrightness);
    }

    PwObjectTracker {
        objects: root.sink !== null ? [root.sink] : []
    }

    GlobalShortcut {
        name: "volumeUp"
        onPressed: root.adjustVolume(root.volumeStep)
    }

    GlobalShortcut {
        name: "volumeDown"
        onPressed: root.adjustVolume(-root.volumeStep)
    }

    GlobalShortcut {
        name: "volumeMute"
        onPressed: root.toggleMute()
    }

    GlobalShortcut {
        name: "brightnessUp"
        onPressed: root.adjustBrightness(Brightness.step)
    }

    GlobalShortcut {
        name: "brightnessDown"
        onPressed: root.adjustBrightness(-Brightness.step)
    }

    PanelWindow {
        id: window

        visible: OsdState.showing
        screen: root.screen
        color: Colors.base.panel
        WlrLayershell.namespace: "quickshell:osd-popup"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        Rectangle {
            id: panel

            x: window.width - panel.width - Style.bar.edgeGap
            y: Style.popup.topMargin
            width: Style.dropdown.width
            height: content.item ? content.item.preferredHeight : Style.popup.minHeight
            radius: Style.bar.radius
            color: Colors.base.surface
            border.color: Colors.base.border
            border.width: Style.border.width
            clip: true

            Loader {
                id: content

                anchors.fill: parent
                active: OsdState.showing
                sourceComponent: OsdState.zone === OsdState.zoneBrightness ? brightnessPanel : audioPanel
            }

        }

        // Purely a readout: an empty mask means every click, scroll and
        // keystroke goes to whatever is underneath, so this can never take
        // input away from the window the user is working in.
        mask: Region {
        }

    }

    Component {
        id: audioPanel

        AudioPanel {
        }

    }

    Component {
        id: brightnessPanel

        BrightnessPanel {
        }

    }

}
