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

    readonly property QtObject battery: QtObject {
        readonly property int width: 38
        readonly property int height: 18
        readonly property int radius: 6
        readonly property int inset: 2
    }

    readonly property QtObject widgets: QtObject {
        readonly property int spacing: 4
        readonly property int padding: 8
        readonly property int iconSize: 18
    }

    readonly property QtObject tray: QtObject {
        readonly property real saturation: -1
        readonly property real passiveOpacity: 0.45
        readonly property int itemPadding: 4
    }

    readonly property QtObject text: QtObject {
        readonly property int size: 13
        readonly property int iconSize: 13
        readonly property int smallSize: 11
        readonly property int largeSize: 17
        readonly property int displaySize: 72
        readonly property string font: "JetBrainsMono Nerd Font"
    }

    readonly property QtObject popup: QtObject {
        id: popupMetrics

        readonly property int width: 240
        readonly property int minHeight: 60
        readonly property int maxHeight: 280
        readonly property int itemHeight: 28
        readonly property int gap: 4
        readonly property int topMargin: popupMetrics.gap
        readonly property int rowIconWidth: 16
        readonly property int rowRadius: 5
    }

    readonly property QtObject workspaces: QtObject {
        id: workspaceMetrics

        readonly property int size: 8
        readonly property int activeSize: 16
        readonly property int spacing: 8
        readonly property int cellSize: workspaceMetrics.activeSize

        readonly property int tileHeight: 35
        readonly property int tileSpacing: 6
        readonly property int tileColumns: 3
    }

    readonly property QtObject usage: QtObject {
        readonly property real warnAbove: 0.8
    }

    readonly property QtObject launcher: QtObject {
        readonly property int width: 400
        readonly property int height: 300
        readonly property int inputHeight: 32
        readonly property int rowHeight: 40
        readonly property int rowPadding: 6
    }

    readonly property QtObject notifications: QtObject {
        readonly property int width: 340
        readonly property int timeout: 6000
        readonly property int actionHeight: 24
        readonly property int bodyMaxLines: 4
        readonly property int maxPopups: 4
    }

    readonly property QtObject animation: QtObject {
        readonly property int fast: 80
        readonly property int normal: 120
    }

    readonly property QtObject dropdown: QtObject {
        readonly property int width: 320
        readonly property int minHeight: 120
        readonly property int maxHeight: 560
    }

    readonly property QtObject calendar: QtObject {
        id: calendarMetrics

        readonly property int rowHeight: 34
        readonly property int weekdayHeight: 18
        readonly property int dotRowHeight: 9
        readonly property int dotSize: 4
        readonly property int dotSpacing: 3
        readonly property int maxDots: 3
        readonly property int daySize: calendarMetrics.rowHeight - calendarMetrics.dotRowHeight
        readonly property int upcomingCount: 4
        readonly property int upcomingLookahead: 45
        readonly property int agendaTimeWidth: 48
        readonly property int upcomingTimeWidth: 80
    }

    readonly property QtObject lock: QtObject {
        readonly property int fieldWidth: 320
        readonly property int fieldHeight: 40
        readonly property int fieldRadius: 20
        readonly property int spacing: 18
    }
}
