pragma ComponentBehavior: Bound

import "../services"
import "../style"
import QtQuick

Item {
    id: root

    property bool active: false
    property alias currentIndex: pages.currentIndex
    readonly property int pageBattery: 0
    readonly property int pageWifi: 1
    readonly property int pageBluetooth: 2
    readonly property int pageAudio: 3
    readonly property int pageBrightness: 4
    readonly property int pageToggles: 5
    readonly property int pageClipboard: 6
    readonly property int pageCount: 7
    implicitHeight: Style.pager.height
    property real swipeTravel: 0
    property bool swipePaged: false
    property bool counted: false

    // The first page of a gesture lands almost at once; holding the swipe keeps
    // paging, but every page after the first costs a lot more travel, so a flick
    // moves one page and a long drag walks through several.
    function swipe(deltaX: real) {
        swipeIdle.restart();
        root.swipeTravel += deltaX;
        const needed = root.swipePaged ? Style.pager.swipeRepeat : Style.pager.swipeStep;
        if (Math.abs(root.swipeTravel) < needed)
            return;

        if (root.swipeTravel < 0)
            pages.incrementCurrentIndex();
        else
            pages.decrementCurrentIndex();
        root.swipeTravel = 0;
        root.swipePaged = true;
    }

    // The arrow keys: the next page over. A host with somewhere else to go
    // from either end (the dropdown's zones) turns wrapping off and gets false.
    function step(direction: int, wrap: bool): bool {
        const next = pages.currentIndex + direction;
        if (!wrap && (next < 0 || next >= root.pageCount))
            return false;

        pages.currentIndex = (next + root.pageCount) % root.pageCount;
        return true;
    }

    // A media key while these panels are already up: turn to that page rather
    // than changing a value out of sight. `zoneAt` is what's watched, not
    // `zone`, so a second press of the same key still counts.
    function followOsd() {
        if (!root.active)
            return;

        const page = root.pageFor(OsdState.zone);
        if (page >= 0)
            root.currentIndex = page;
    }

    function pageFor(zone: string): int {
        switch (zone) {
        case OsdState.zoneAudio:
            return root.pageAudio;
        case OsdState.zoneBrightness:
            return root.pageBrightness;
        default:
            return -1;
        }
    }

    // Tell the OSD that these panels are already on screen. Kept idempotent
    // because the dropdown's Loader destroys this while `active` is still true.
    function syncViewer() {
        if (root.active === root.counted)
            return;

        OsdState.viewers += root.active ? 1 : -1;
        root.counted = root.active;
    }

    onActiveChanged: root.syncViewer()
    Component.onCompleted: root.syncViewer()
    Component.onDestruction: {
        if (root.counted)
            OsdState.viewers -= 1;
    }

    Connections {
        function onZoneAtChanged() {
            root.followOsd();
        }

        target: OsdState
    }

    Timer {
        id: swipeIdle

        interval: Style.pager.swipeIdle
        onTriggered: {
            root.swipeTravel = 0;
            root.swipePaged = false;
        }
    }

    PathView {
        id: pages

        clip: true
        model: root.pageCount
        interactive: false
        pathItemCount: 3
        cacheItemCount: root.pageCount
        snapMode: PathView.SnapOneItem
        highlightRangeMode: PathView.StrictlyEnforceRange
        preferredHighlightBegin: 0.5
        preferredHighlightEnd: 0.5
        highlightMoveDuration: Style.animation.fast
        movementDirection: PathView.Shortest

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: dots.top
        }

        path: Path {
            startX: -pages.width
            startY: pages.height / 2

            PathLine {
                x: pages.width * 2
                y: pages.height / 2
            }
        }

        delegate: Item {
            id: page

            required property int index

            width: pages.width
            height: pages.height

            Loader {
                anchors.fill: parent
                sourceComponent: {
                    switch (page.index) {
                    case root.pageBattery:
                        return batteryPage;
                    case root.pageWifi:
                        return wifiPage;
                    case root.pageBluetooth:
                        return bluetoothPage;
                    case root.pageAudio:
                        return audioPage;
                    case root.pageBrightness:
                        return brightnessPage;
                    case root.pageClipboard:
                        return clipboardPage;
                    default:
                        return togglesPage;
                    }
                }
            }
        }
    }

    Row {
        id: dots

        height: Style.pager.dotSize
        spacing: Style.pager.dotSpacing

        anchors {
            bottom: parent.bottom
            bottomMargin: Style.bar.padding
            horizontalCenter: parent.horizontalCenter
        }

        Repeater {
            model: root.pageCount

            delegate: Rectangle {
                id: dot

                required property int index

                width: Style.pager.dotSize
                height: Style.pager.dotSize
                radius: width / 2
                color: pages.currentIndex === dot.index ? Colors.icon.active : Colors.icon.disabled

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -Style.widgets.spacing
                    onClicked: pages.currentIndex = dot.index
                }

                Behavior on color {
                    ColorAnimation {
                        duration: Style.animation.normal
                    }
                }
            }
        }
    }

    Component {
        id: batteryPage

        BatteryPanel {}
    }

    Component {
        id: bluetoothPage

        BluetoothPanel {
            active: root.active && pages.currentIndex === root.pageBluetooth
        }
    }

    Component {
        id: audioPage

        AudioPanel {}
    }

    Component {
        id: brightnessPage

        BrightnessPanel {
            active: root.active && pages.currentIndex === root.pageBrightness
        }
    }

    Component {
        id: togglesPage

        TogglesPanel {
            onClipboardRequested: pages.currentIndex = root.pageClipboard
        }
    }

    Component {
        id: clipboardPage

        ClipboardPanel {
            active: root.active && pages.currentIndex === root.pageClipboard
        }
    }

    Component {
        id: wifiPage

        WifiPanel {
            active: root.active && pages.currentIndex === root.pageWifi
        }
    }
}
