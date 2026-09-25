pragma Singleton

import QtQuick

QtObject {
    id: metrics

    readonly property QtObject
    bar: QtObject {
        id: barMetrics

        readonly property int height: 35
        readonly property int sideGap: 14
        // The bar draws its frame one border inside the window it is given, so
        // anything floating below it lines up on this, not on sideGap.
        readonly property int edgeGap: barMetrics.sideGap + metrics.border.width
        readonly property int topGap: 8
        readonly property int bottomGap: -2
        readonly property int radius: 10
        readonly property int padding: 12
        readonly property int spacing: 8
    }

    readonly property QtObject
    border: QtObject {
        readonly property int width: 1
    }

    readonly property QtObject
    widgets: QtObject {
        readonly property int spacing: 4
        readonly property int padding: 8
        readonly property int iconSize: 18
    }

    readonly property QtObject
    tray: QtObject {
        readonly property real colorization: 1
        readonly property int itemPadding: 4
    }

    readonly property QtObject
    text: QtObject {
        readonly property int size: 13
        readonly property int iconSize: 13
        readonly property int smallSize: 11
        readonly property int largeSize: 17
        readonly property int displaySize: 72
        readonly property string font: "JetBrainsMono Nerd Font"
    }

    readonly property QtObject
    popup: QtObject {
        id: popupMetrics

        readonly property int width: 240
        readonly property int minHeight: 60
        readonly property int maxHeight: 280
        readonly property int itemHeight: 28
        readonly property int dismissDelay: 180
        readonly property int gap: 16
        readonly property int topMargin: popupMetrics.gap
        readonly property int rowIconWidth: 16
        readonly property int rowRadius: 5
    }

    readonly property QtObject
    workspaces: QtObject {
        id: workspaceMetrics

        readonly property int size: 8
        readonly property int activeSize: 16
        readonly property int spacing: 8
        readonly property int cellSize: workspaceMetrics.activeSize
        readonly property int tileHeight: 35
        readonly property int tileSpacing: 6
        readonly property int tileColumns: 3
        // The wallpaper card under the grid: wider than the app's 2:1, so the
        // workspaces keep the bulk of the dropdown.
        readonly property real previewRatio: 0.4
    }

    readonly property QtObject
    usage: QtObject {
        readonly property real warnAbove: 0.8
        readonly property int coreHeight: 32
    }

    readonly property QtObject
    launcher: QtObject {
        readonly property int width: 400
        readonly property int height: 300
        readonly property int inputHeight: 32
        readonly property int rowHeight: 40
        readonly property int rowPadding: 6
    }

    readonly property QtObject
    notifications: QtObject {
        readonly property int width: 340
        readonly property int timeout: 6000
        readonly property int actionHeight: 24
        readonly property int bodyMaxLines: 4
        readonly property int maxPopups: 4
    }

    readonly property QtObject
    pager: QtObject {
        readonly property int width: 380
        readonly property int height: 240
        readonly property int dotSize: 6
        readonly property int dotSpacing: 8
        readonly property int swipeStep: 400
        readonly property int swipeRepeat: 10000
        readonly property int swipeIdle: 180
    }

    readonly property QtObject
    toggles: QtObject {
        readonly property int tileColumns: 2
        readonly property int tileHeight: 64
        readonly property int tileSpacing: metrics.workspaces.tileSpacing
        readonly property int badgeSize: 26
    }

    readonly property QtObject
    wallpaper: QtObject {
        readonly property int windowWidth: 1100
        readonly property int windowHeight: 720
        readonly property int minimumWidth: 720
        readonly property int minimumHeight: 480
        readonly property int padding: 20
        readonly property int spacing: 16
        readonly property int cardWidth: 320
        readonly property real cardRatio: 0.5
        readonly property int cardRadius: 8
        readonly property int thumbnailWidth: 640
        readonly property int badgeSize: 18
        readonly property int badgeInset: 8
        readonly property int labelHeight: 20
        readonly property int labelPadding: 6
        readonly property int labelRadius: 4
        readonly property int themeCardWidth: 180
        readonly property int themeCardHeight: 72
        readonly property int swatchSize: 10
        readonly property int searchWidth: 280
    }

    readonly property QtObject
    slider: QtObject {
        readonly property int track: 6
        readonly property int height: 20
    }

    readonly property QtObject
    animation: QtObject {
        readonly property int fast: 80
        readonly property int normal: 120
        readonly property int slow: 260
    }

    readonly property QtObject
    dropdown: QtObject {
        readonly property int width: 320
        readonly property int minHeight: 120
        readonly property int maxHeight: 560
    }

    readonly property QtObject
    calendar: QtObject {
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

    readonly property QtObject
    lock: QtObject {
        readonly property int fieldWidth: 320
        readonly property int fieldHeight: 40
        readonly property int fieldRadius: 20
        readonly property int spacing: 18
        readonly property int blurMax: 48
        readonly property real blurAmount: 1
    }

}
