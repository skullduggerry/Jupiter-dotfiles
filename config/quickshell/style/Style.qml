// style/Style.qml
pragma Singleton
import QtQuick

QtObject {
    readonly property QtObject bar: QtObject {
        id: barMetrics

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

    // Shared metrics for the individual bar widgets. `padding` is the
    // breathing room each widget adds around its own content row, so a
    // widget's implicit width is `content + padding * 2`.
    readonly property QtObject widgets: QtObject {
        readonly property int spacing: 4
        readonly property int padding: 8
        readonly property int iconSize: 22
    }

    readonly property QtObject text: QtObject {
        readonly property int size: 13
        // Nerd Font glyphs render a little small next to the label text at
        // the same pixel size, so icons get their own step.
        readonly property int iconSize: 15
        readonly property int smallSize: 11
        readonly property string font: "JetBrainsMono Nerd Font"
    }

    // Shared sizing for the WidgetPopup dropdown shell (Bluetooth, Wi-Fi,
    // power menu, ...) and the row-style lists inside them. Centralized so
    // every popup looks consistent instead of each widget picking its own
    // one-off width/row-height.
    readonly property QtObject popup: QtObject {
        id: popupMetrics

        readonly property int width: 240
        readonly property int minHeight: 60
        readonly property int maxHeight: 280
        readonly property int itemHeight: 28
        // Vertical gap between the bottom of the bar and the popup.
        readonly property int gap: 4
        // Distance from the top of the screen to the top of any dropdown
        // surface: clear the bar, its top gap, and `gap`. Shared by
        // WidgetPopup and the gesture dropdown so they line up.
        readonly property int topMargin: barMetrics.topGap + barMetrics.height + popupMetrics.gap
        // Width reserved for a row's leading glyph and its trailing inline
        // action ("Connect"/"Disconnect"/"Pair"), so the middle label knows
        // how much room is left to elide into.
        readonly property int rowIconWidth: 16
    }

    // Hyprland workspace pips in the bar's left zone.
    readonly property QtObject workspaces: QtObject {
        readonly property int size: 10
        readonly property int activeWidth: 22
        readonly property int spacing: 6
    }

    readonly property QtObject launcher: QtObject {
        readonly property int width: 400
        readonly property int height: 300
        readonly property int inputHeight: 32
        readonly property int rowHeight: 40
        readonly property int rowPadding: 6
        readonly property int iconSize: 24
    }

    readonly property QtObject animation: QtObject {
        readonly property int fast: 80
        readonly property int normal: 120
    }

    // The zone dropdown opened by a three-finger swipe (see dropdown/).
    // Wider and taller than a WidgetPopup because it holds a month grid.
    readonly property QtObject dropdown: QtObject {
        readonly property int width: 320
        readonly property int height: 400
    }

    // Month grid + agenda metrics for CalendarPanel. Cell *width* is derived
    // from the dropdown width divided by the seven weekday columns rather
    // than being a token of its own, so the grid always fills the panel.
    readonly property QtObject calendar: QtObject {
        readonly property int rowHeight: 32
        readonly property int weekdayHeight: 18
        readonly property int dotSize: 4
    }
}
