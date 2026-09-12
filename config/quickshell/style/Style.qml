// style/Style.qml
pragma Singleton
import QtQuick

QtObject {
    readonly property QtObject bar: QtObject {
        readonly property int height: 35
        readonly property int sideGap: 14
        readonly property int topGap: 8
        readonly property int radius: 10
        readonly property int padding: 12
        readonly property int spacing: 8
    }

    readonly property QtObject border: QtObject {
        readonly property int width: 1
    }

    readonly property QtObject widgets: QtObject {
        readonly property int spacing: 4
    }

    readonly property QtObject text: QtObject {
        readonly property int size: 13
        readonly property string font: "JetBrainsMono Nerd Font"
    }

    // Shared sizing for the WidgetPopup dropdown shell (Bluetooth, Wi-Fi,
    // power menu, ...) and the row-style lists inside them. Centralized so
    // every popup looks consistent instead of each widget picking its own
    // one-off width/row-height.
    readonly property QtObject popup: QtObject {
        readonly property int width: 240
        readonly property int maxHeight: 280
        readonly property int itemHeight: 28
    }

    // Hyprland workspace pips in the bar's left zone.
    readonly property QtObject workspaces: QtObject {
        readonly property int size: 10
        readonly property int activeWidth: 22
        readonly property int spacing: 6
    }
}
