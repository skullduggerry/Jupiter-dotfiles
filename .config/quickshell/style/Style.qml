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
        // The hairline between groups of widgets. Not full height: a divider
        // that touches the bar's own border reads as a seam in the bar
        // rather than as a gap between two groups.
        readonly property int separatorHeight: 18
    }

    readonly property QtObject border: QtObject {
        readonly property int width: 1
    }

    // The battery's outlined pill, with its charge as an inner fill and the
    // percentage centred on top. 102x48 in the design.
    readonly property QtObject battery: QtObject {
        readonly property int width: 38
        readonly property int height: 18
        readonly property int radius: 6
        // Gap between the outline and the fill, so the fill never touches
        // the border.
        readonly property int inset: 2
    }

    // Shared metrics for the individual bar widgets. `padding` is the
    // breathing room each widget adds around its own content row, so a
    // widget's implicit width is `content + padding * 2`.
    readonly property QtObject widgets: QtObject {
        readonly property int spacing: 4
        readonly property int padding: 8
        // Tray icons. Deliberately smaller than the bar has room for: a tray
        // is a row of other applications' artwork, and it shouldn't outweigh
        // the shell's own widgets.
        readonly property int iconSize: 18
    }

    readonly property QtObject text: QtObject {
        readonly property int size: 13
        // Nerd Font glyphs render a little small next to the label text at
        // the same pixel size, so icons get their own step — but only just,
        // since the bar reads better with restrained glyphs than with the
        // large ones the design sketches.
        readonly property int iconSize: 13
        readonly property int smallSize: 11
        // One step up from `size`, for a single emphasized line: the
        // launcher's search field.
        readonly property int largeSize: 17
        // The lock screen's clock, which is the only thing on its surface
        // and is read from across the room.
        readonly property int displaySize: 72
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
        // Distance from the top of a full-screen overlay window to the top of
        // a dropdown surface. Just `gap`, because the compositor already
        // starts such a window below the bar's exclusive zone — an overlay
        // anchored to all four edges is handed the screen minus every
        // reserved strip. Adding the bar's own height here (as this token
        // used to) counted it twice and left a 55px gap under a 35px bar.
        readonly property int topMargin: popupMetrics.gap
        // Width reserved for a row's leading glyph and its trailing inline
        // action ("Connect"/"Disconnect"/"Pair"), so the middle label knows
        // how much room is left to elide into.
        readonly property int rowIconWidth: 16
        // Corner radius of a row inside a surface — a power menu entry, a
        // launcher result, a calendar day. Softer than the surface's own
        // `bar.radius`, which several files used to spell `bar.radius / 2`.
        readonly property int rowRadius: 5
    }

    // Hyprland workspace dots in the bar's left zone, and the tiles the
    // workspace dropdown shows.
    //
    // Sizes come from the design file, which is drawn at 2x (its canvas is
    // 2880x1920 — eDP-1's native mode, and that output runs at scale 2), so
    // every figure there is halved to reach these logical pixels.
    readonly property QtObject workspaces: QtObject {
        id: workspaceMetrics

        // Halfway between the design (a 10.5 dot growing to 21, on a 31
        // pitch) and what was here before (a 10 dot growing into a 22-wide
        // pill, on a 16 pitch). The design's circles are the better shape and
        // its airiness the better instinct; at its actual sizes they take a
        // third of the bar.
        readonly property int size: 8
        readonly property int activeSize: 16
        readonly property int spacing: 8
        // Each dot sits in a cell this wide, so the row keeps its geometry
        // when the active workspace moves instead of shifting every dot to
        // the right of it.
        readonly property int cellSize: workspaceMetrics.activeSize

        // Workspace dropdown tiles.
        readonly property int tileHeight: 35
        readonly property int tileSpacing: 6
        readonly property int tileColumns: 3
    }

    // The load and brightness ramps next to the workspaces. Each is one
    // glyph from a nine-step ramp and nothing else, so the only token they
    // need is where "high" starts.
    readonly property QtObject usage: QtObject {
        // Above this fraction a load ramp switches to the warning colour.
        readonly property real warnAbove: 0.8
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
    // Wider than a WidgetPopup because it holds a month grid; its height is
    // whatever the zone panel asks for, clamped to this range, so a short
    // Wi-Fi list no longer sits in a box sized for the calendar.
    readonly property QtObject dropdown: QtObject {
        readonly property int width: 320
        readonly property int minHeight: 120
        readonly property int maxHeight: 560
    }

    // Month grid + agenda metrics for CalendarPanel. Cell *width* is derived
    // from the dropdown width divided by the seven weekday columns rather
    // than being a token of its own, so the grid always fills the panel.
    readonly property QtObject calendar: QtObject {
        id: calendarMetrics

        readonly property int rowHeight: 34
        readonly property int weekdayHeight: 18
        // The strip at the bottom of a day cell that holds its event dots,
        // and therefore what separates the cell height from the diameter of
        // the round highlight above it.
        readonly property int dotRowHeight: 9
        readonly property int dotSize: 4
        readonly property int dotSpacing: 3
        // More events than this on one day still only draw this many dots.
        readonly property int maxDots: 3
        // Round highlight behind a day number (today's ring, the selected
        // day's fill). Square, so its radius makes it a circle.
        readonly property int daySize: calendarMetrics.rowHeight - calendarMetrics.dotRowHeight
        // How many events the "Upcoming" fallback lists when the selected
        // day itself has none.
        readonly property int upcomingCount: 4
        // The agenda's leading column, so every summary starts at the same
        // x instead of being pushed around by "all day" vs "09:30". Wide
        // enough for its longest label in each of the two modes: "all day"
        // for one day's agenda, "Wed 16 08:15" for the upcoming list.
        readonly property int agendaTimeWidth: 48
        readonly property int upcomingTimeWidth: 80
    }

    // Session lock (lock/).
    readonly property QtObject lock: QtObject {
        readonly property int fieldWidth: 320
        readonly property int fieldHeight: 40
        readonly property int fieldRadius: 20
        readonly property int spacing: 18
        // Diameter of the password dots.
        readonly property int dotSize: 8
        readonly property int dotSpacing: 6
    }
}
