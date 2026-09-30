pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick

QtObject {
    id: metrics

    component BarStyle: QtObject {
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
    readonly property BarStyle bar: BarStyle {}

    component BorderStyle: QtObject {
        readonly property int width: 1
    }
    readonly property BorderStyle border: BorderStyle {}

    component WidgetsStyle: QtObject {
        readonly property int spacing: 4
        readonly property int padding: 8
        readonly property int iconSize: 18
    }
    readonly property WidgetsStyle widgets: WidgetsStyle {}

    component TrayStyle: QtObject {
        readonly property real colorization: 1
        readonly property int itemPadding: 4
    }
    readonly property TrayStyle tray: TrayStyle {}

    component TextStyle: QtObject {
        id: textMetrics

        readonly property int size: 13
        readonly property int iconSize: 13
        readonly property int smallSize: 11
        readonly property int largeSize: 17
        readonly property int displaySize: 72
        // The Settings app's choice, else the shell's own. Nerd Font icons
        // still draw in any font: fontconfig falls back to one that has them.
        readonly property string defaultFont: "JetBrainsMono Nerd Font"
        readonly property string font: Theme.font || textMetrics.defaultFont
    }
    readonly property TextStyle text: TextStyle {}

    component PopupStyle: QtObject {
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
        // How long a click that wants confirming (Forget) waits for the second.
        readonly property int confirmTimeout: 3000
    }
    readonly property PopupStyle popup: PopupStyle {}

    component WorkspacesStyle: QtObject {
        id: workspaceMetrics

        readonly property int size: 8
        readonly property int activeSize: 16
        readonly property int spacing: 8
        readonly property int cellSize: workspaceMetrics.activeSize
        readonly property int tileHeight: 35
        readonly property int tileSpacing: 6
        readonly property int tileColumns: 3
        // The wallpaper card under the grid, wider than the Settings grid's 2:1
        // so the workspaces keep the bulk of the dropdown.
        readonly property real previewRatio: 0.4
        // The monitor layout in the dropdown's header, drawn this high.
        readonly property int mapHeight: 12
        readonly property int mapGap: 2
        readonly property int mapRadius: 2
    }
    readonly property WorkspacesStyle workspaces: WorkspacesStyle {}

    component UsageStyle: QtObject {
        readonly property real warnAbove: 0.8
        readonly property int coreHeight: 32
        // The bar's meters, a ring of this stroke (icons/RingIcon).
        readonly property real ringWidth: 1.5
    }
    readonly property UsageStyle usage: UsageStyle {}

    // Percentages at and below which the bar's battery turns orange, then red,
    // and the battery it draws (icons/BatteryIcon).
    component BatteryStyle: QtObject {
        readonly property int lowAt: 20
        readonly property int criticalAt: 10
        readonly property int iconWidth: 17
        readonly property int iconHeight: 9
        readonly property int iconRadius: 3
        readonly property int fillGap: 1
        readonly property int terminalWidth: 2
        readonly property int terminalHeight: 4
    }
    readonly property BatteryStyle battery: BatteryStyle {}

    component LauncherStyle: QtObject {
        readonly property int width: 400
        readonly property int height: 300
        readonly property int inputHeight: 32
        readonly property int rowHeight: 40
        readonly property int rowPadding: 6
    }
    readonly property LauncherStyle launcher: LauncherStyle {}

    component NotificationsStyle: QtObject {
        readonly property int width: 340
        readonly property int timeout: 6000
        readonly property int actionHeight: 24
        readonly property int bodyMaxLines: 4
        readonly property int maxPopups: 4
    }
    readonly property NotificationsStyle notifications: NotificationsStyle {}

    component PagerStyle: QtObject {
        readonly property int width: 380
        readonly property int height: 240
        readonly property int dotSize: 6
        readonly property int dotSpacing: 8
        readonly property int swipeStep: 400
        readonly property int swipeRepeat: 10000
        readonly property int swipeIdle: 180
    }
    readonly property PagerStyle pager: PagerStyle {}

    component TogglesStyle: QtObject {
        readonly property int tileColumns: 3
        readonly property int tileHeight: 76
        readonly property int tileSpacing: metrics.workspaces.tileSpacing
        readonly property int badgeSize: 26
    }
    readonly property TogglesStyle toggles: TogglesStyle {}

    component WallpaperStyle: QtObject {
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
    readonly property WallpaperStyle wallpaper: WallpaperStyle {}

    // The Settings app, after the Figma file's "Settings" and "Wallpaper
    // Selector" frames at half their 2x size.
    component SettingsStyle: QtObject {
        readonly property int windowWidth: 1100
        readonly property int windowHeight: 720
        readonly property int minimumWidth: 820
        readonly property int minimumHeight: 520
        readonly property int padding: 20
        readonly property int spacing: 16
        readonly property int sidebarWidth: 260
        readonly property int itemHeight: 34
        readonly property int itemRadius: 7
        readonly property int iconWidth: 22
        // The column a page's controls and panels keep to.
        readonly property int pageWidth: 480
        // Pages that are a long list (Keybinds, Startup) take more of the width.
        readonly property int listWidth: 640
        readonly property int keyHeight: 20
        readonly property int appIconSize: 22
        // An On/Off pill in a list row, wide enough for either word.
        readonly property int switchWidth: 48
        readonly property int arrangementHeight: 160
        // The label either side of a slider row.
        readonly property int labelWidth: 56
        // The most of a page a card takes with more below it (Network's Wi-Fi),
        // and of a row a trailing detail (a startup command).
        readonly property real cardShare: 0.6
        readonly property real detailShare: 0.45
        // After a burst of change events, before the page reads again.
        readonly property int rereadDelay: 400
        readonly property int swatchSize: 24
        readonly property int swatchSpacing: 10
        readonly property int swatchRing: 2
        readonly property int fieldWidth: 210
        // A list opening in a page: fonts, resolutions, apps to add.
        readonly property int listHeight: 220
    }
    readonly property SettingsStyle settings: SettingsStyle {}

    component SliderStyle: QtObject {
        readonly property int track: 6
        readonly property int height: 20
    }
    readonly property SliderStyle slider: SliderStyle {}

    component AnimationStyle: QtObject {
        readonly property int fast: 80
        readonly property int normal: 120
        readonly property int slow: 260
    }
    readonly property AnimationStyle animation: AnimationStyle {}

    component DropdownStyle: QtObject {
        readonly property int width: 320
        readonly property int minHeight: 120
        readonly property int maxHeight: 560
    }
    readonly property DropdownStyle dropdown: DropdownStyle {}

    component CalendarStyle: QtObject {
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
        // Open tasks shown under the agenda before their list scrolls.
        readonly property int taskRows: 4
        // A task's ring, where an event has a dot.
        readonly property int taskRingSize: 8
    }
    readonly property CalendarStyle calendar: CalendarStyle {}

    // What bar/BackdropProbe reads of a wallpaper for adaptive glass: drawn
    // this wide, the upper share of the screen that has panels over it, and
    // the blocks it averages, at this width about Hyprland's blur.
    component BackdropStyle: QtObject {
        readonly property int sampleWidth: 128
        readonly property real coverage: 0.5
        readonly property int blockSize: 4
        // Hyprland's decoration:blur contrast and brightness, its defaults,
        // which config/hypr/styles/layout.lua keeps.
        readonly property real blurContrast: 0.8916
        readonly property real blurBrightness: 1
    }
    readonly property BackdropStyle backdrop: BackdropStyle {}

    component LockStyle: QtObject {
        readonly property int fieldWidth: 320
        readonly property int fieldHeight: 40
        readonly property int fieldRadius: 20
        readonly property int spacing: 18
        readonly property int blurMax: 48
        readonly property real blurAmount: 1
    }
    readonly property LockStyle lock: LockStyle {}
}
