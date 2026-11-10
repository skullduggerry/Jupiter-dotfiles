pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick

QtObject {
    id: metrics

    component BarStyle: QtObject {
        id: barMetrics

        readonly property int height: 35
        // The bar lines up on the windows (services/WindowGaps): it draws its
        // frame one border inside its window, which starts a border short of
        // the gaps, so the frame's edges are the windows' outer edges. Below
        // its window's top it keeps a strip `depth` deep, to the frame's
        // bottom, and Hyprland puts the windows the same gap below that.
        readonly property int depth: barMetrics.height - metrics.border.width
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
        // The Settings app's choice, else the shell's own. Icons have a font
        // of their own (Icons.font), whatever this is.
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

    // The bar's player and its dropdown (panels/MediaPanel).
    component MediaStyle: QtObject {
        // The track's title and artist on the bar, at most this wide.
        readonly property int trackWidth: 320
        readonly property int artSize: 64
        readonly property int artRadius: metrics.wallpaper.cardRadius
        // How often an open dropdown asks the player where it is.
        readonly property int positionInterval: 1000
        // A drag along the track seeks once it has rested this long.
        readonly property int seekDelay: 150
    }
    readonly property MediaStyle media: MediaStyle {}

    // Caps Lock's quick menu (quickmenu/): a hub of `centerRadius`, a ring
    // of slots out to `ringOuter` and, past a category's slot, an arc of its
    // items from `arcInner` to `arcOuter` (at most `maxItems`, each
    // `itemSpan` degrees, `fewItemSpan` for up to `fewItems`), in one of two
    // looks (QuickMenu.look). Halo draws the ring as one disc and the arc as
    // a band hugging it, the selection a tint `inset` inside them, `gap`
    // between neighbours. Orbit draws a round button of `buttonSize` per
    // slot (`itemButtonSize` per item) on a track, the selection scaled by
    // `selectedScale` and joined to the hub by a line; what is not chosen
    // while a category is out fades to `dimmed`. A slot is picked by
    // direction alone, up to `reach` past the arc. A press shorter than
    // `tapTime` that moves less than `tapSlop` keeps the menu open; one
    // shifted off the pointer to fit waits for `armSlop` of movement. Once
    // the pointer has been among a category's items, crossing another slot
    // switches only after `switchDelay`. The letters show once the pointer
    // has rested `keyDelay`, or a key is pressed. The pencil's panel beside
    // it (quickmenu/RingPanel) is `panelWidth` wide and up to `panelHeight`
    // tall. A list (quickmenu/RingList) is a wheel out from `arcInner`,
    // `fanWidth` deep, its rows spokes `fanStep` degrees apart, up to
    // `fanSpan` degrees either way of its middle; toward its ends they shrink
    // by up to `fanShrink` and fade (Colors.faded()), and the picked one is a
    // pill `fanRowHeight` high.
    // Playful motion springs each slot from `popFrom` of its size, `stagger`
    // after the one before, over `spring`; calm fades in from `calmFrom`.
    // All of it is drawn at one of `sizes` (QuickMenu.size), less where the
    // screen is too small.
    component QuickMenuStyle: QtObject {
        readonly property list<real> sizes: [0.8, 1, 1.2, 1.4, 1.6]
        readonly property int centerRadius: 56
        readonly property int ringOuter: 144
        readonly property int arcInner: 152
        readonly property int arcOuter: 232
        readonly property int gap: 3
        // The tint's corners are the panels' less this, so the two curves
        // run parallel (Style.popup.rowRadius inside Style.bar.radius).
        readonly property int inset: 5
        readonly property int buttonSize: 50
        readonly property int itemButtonSize: 44
        readonly property real selectedScale: 1.12
        readonly property real dimmed: 0.4
        readonly property int connectorWidth: 2
        readonly property int maxItems: 5
        readonly property int itemSpan: 34
        readonly property int fewItemSpan: 40
        readonly property int fewItems: 3
        readonly property int panelWidth: 280
        readonly property int panelHeight: 320
        readonly property int fanWidth: 200
        readonly property real fanStep: 6.7
        readonly property int fanSpan: 26
        readonly property real fanShrink: 0.16
        readonly property int fanRowHeight: 22
        readonly property int slotWidth: 84
        // The least the text in the centre shrinks to, for a long word.
        readonly property int leastTextSize: 9
        // How long the apps' search caret shows, then hides.
        readonly property int caretBlink: 530
        // Each slot's and item's letter, beside its glyph toward the hub.
        readonly property int keyCapHeight: 15
        readonly property int keyDelay: 600
        readonly property int reach: 120
        readonly property int margin: 12
        readonly property int tapTime: 260
        readonly property int tapSlop: 10
        readonly property int armSlop: 6
        readonly property int switchDelay: 170
        readonly property int wheelStep: 120
        // A notch of the wheel moves Night Light's warmth this share of its
        // range; screenshots wait `captureDelay` for the menu to go.
        readonly property real levelStep: 0.05
        readonly property int captureDelay: 250
        readonly property real popFrom: 0.55
        readonly property real calmFrom: 0.94
        readonly property int stagger: 14
        readonly property int itemStagger: 24
        readonly property int spring: 300
        readonly property real overshoot: 1.4
        // The dashes of a slot being changed, in border widths.
        readonly property list<real> dash: [4, 3]
    }
    readonly property QuickMenuStyle quickMenu: QuickMenuStyle {}

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
        // The label column of a card's rows (FormRow).
        readonly property int rowLabelWidth: 120
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

    // The dropdowns' swoosh (Theme.swoosh, panels/PopupFrame): out of the
    // bar from `fromWidth` by `fromHeight` of its size over `enter`, past its
    // height by OutBack's `overshoot` before it settles, the glass there by
    // `fade` of the way and the content from `contentFrom`; back into the
    // bar over `leave`.
    component SwooshStyle: QtObject {
        readonly property int enter: 440
        readonly property int leave: 200
        readonly property real overshoot: 1.6
        readonly property real fromWidth: 0.8
        readonly property real fromHeight: 0.12
        readonly property real fade: 0.25
        readonly property real contentFrom: 0.4
    }
    readonly property SwooshStyle swoosh: SwooshStyle {}

    // SUPER+Tab's overview: each screen's workspaces as tiles of this width at
    // most, in rows of `columns`, kept `margin` from the screen's edges. As it
    // opens, the workspace on screen shrinks from the whole screen into its
    // tile (`zoom`), and the others pop in from `popFrom` of their size, each
    // `stagger` after the one before it, outwards from that tile.
    component OverviewStyle: QtObject {
        readonly property int tileWidth: 560
        readonly property int columns: 4
        readonly property int spacing: 24
        readonly property int margin: 48
        readonly property int zoom: 320
        readonly property int stagger: 45
        readonly property real popFrom: 0.6
    }
    readonly property OverviewStyle overview: OverviewStyle {}

    // SUPER+/'s shortcuts overlay: its sections in columns this wide, as many
    // as fit up to `columns`, `margin` from the screen's edges, and the
    // keyboard at `keySize` a key, down to `keyLeast` on a short screen; a
    // legend too big for its key shrinks, down to `legendLeast`. A search or
    // a key under the pointer fades the binds that do not match to `faded`.
    component ShortcutsStyle: QtObject {
        readonly property int columnWidth: 380
        readonly property int columns: 3
        readonly property int margin: 48
        readonly property int keySize: 36
        readonly property int keyLeast: 26
        readonly property int legendLeast: 7
        readonly property real faded: 0.35
    }
    readonly property ShortcutsStyle shortcuts: ShortcutsStyle {}

    // Left Ctrl tapped twice: every screen dims but a circle of `radius`
    // around the pointer, ringed `ring` wide, which closes in from `zoomFrom`
    // times its size over `zoom` ms as it appears.
    component CursorFinderStyle: QtObject {
        readonly property int radius: 80
        readonly property int ring: 2
        readonly property real zoomFrom: 6
        readonly property int zoom: 450
    }
    readonly property CursorFinderStyle cursorFinder: CursorFinderStyle {}

    // The bar's shelf (panels/ShelfPanel): an image's row shows it this high,
    // and a text file is previewed up to this size.
    component ShelfStyle: QtObject {
        readonly property int thumbnailHeight: 48
        readonly property int previewBytes: 65536
    }
    readonly property ShelfStyle shelf: ShelfStyle {}

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
        // Blocks this many samples wide are about Hyprland's blur at
        // blockBlurSize (size 6 × 3 passes); they follow Theme.blurSize.
        readonly property int blockSize: 4
        readonly property int blockBlurSize: 6
        // Hyprland's decoration:blur contrast and brightness, its defaults,
        // which .config/hypr/styles/layout.lua keeps.
        readonly property real blurContrast: 0.8916
        readonly property real blurBrightness: 1
    }
    readonly property BackdropStyle backdrop: BackdropStyle {}

    // The sizes of Hyprland's decoration:blur the Settings app offers
    // (Theme.blurSize); .config/hypr/styles/layout.lua starts at 6.
    component BlurStyle: QtObject {
        readonly property int least: 1
        readonly property int most: 12
        // On a specular variant's glass (panels/GlassHighlight), how far down
        // the light on its upper edge fades out, as a share of its height.
        readonly property real highlightFade: 0.45
        // The rim drawn where Hyprland's lens cannot reach: as wide as the
        // lens's (acrylic's bulb), and at most this share of the glass's
        // smaller side, as Hyprland bounds it; in bands this wide, thin
        // enough that none shows as a step.
        readonly property real rim: BlurVariants.effective(Theme.blurOptions)["acrylic.bulb"]
        readonly property real rimShare: 0.4
        readonly property int rimBand: 2
    }
    readonly property BlurStyle blur: BlurStyle {}

    component LockStyle: QtObject {
        readonly property int fieldWidth: 320
        readonly property int fieldHeight: 40
        readonly property int fieldRadius: 20
        readonly property int spacing: 18
        readonly property int blurMax: 48
        readonly property real blurAmount: 1
        // The Lock Screen tab's previews of both screens.
        readonly property real previewRatio: 0.5625
        readonly property int previewBlurMax: 8
        readonly property int previewFieldWidth: 72
        readonly property int previewFieldHeight: 10
        // The darkest the page's Dim slider goes.
        readonly property real dimMost: 0.9
    }
    readonly property LockStyle lock: LockStyle {}
}
