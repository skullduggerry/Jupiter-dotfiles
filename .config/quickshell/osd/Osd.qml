import "../panels"
import "../services"
import "../style"
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

Scope {
    id: root

    function adjustVolume(delta: real) {
        Volume.adjust(delta);
        OsdState.show(OsdState.zoneAudio);
    }

    function toggleMute() {
        Volume.toggleMute();
        OsdState.show(OsdState.zoneAudio);
    }

    function adjustBrightness(delta: int) {
        Brightness.adjust(delta);
        OsdState.show(OsdState.zoneBrightness);
    }

    GlobalShortcut {
        name: "volumeUp"
        onPressed: root.adjustVolume(Volume.step)
    }

    GlobalShortcut {
        name: "volumeDown"
        onPressed: root.adjustVolume(-Volume.step)
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
        screen: Screens.focused
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
            height: content.item ? Math.floor(content.implicitHeight) : Style.popup.minHeight
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
        mask: Region {}
    }

    Component {
        id: audioPanel

        AudioPanel {}
    }

    Component {
        id: brightnessPanel

        BrightnessPanel {}
    }
}
