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
    readonly property int pageCount: 5
    readonly property bool wantsKeyboard: pages.currentIndex === root.pageWifi
    readonly property int preferredHeight: Style.pager.height
    property real swipeTravel: 0
    property bool swipeConsumed: false

    function swipe(deltaX: real) {
        swipeIdle.restart();
        root.swipeTravel += deltaX;
        if (root.swipeConsumed || Math.abs(root.swipeTravel) < Style.pager.swipeStep)
            return ;

        root.swipeConsumed = true;
        if (root.swipeTravel < 0)
            pages.incrementCurrentIndex();
        else
            pages.decrementCurrentIndex();
    }

    Timer {
        id: swipeIdle

        interval: Style.pager.swipeIdle
        onTriggered: {
            root.swipeTravel = 0;
            root.swipeConsumed = false;
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
        highlightMoveDuration: Style.animation.normal
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
                    default:
                        return brightnessPage;
                    }
                }
            }

        }

    }

    Row {
        id: dots

        height: Style.pager.dotRow
        spacing: Style.pager.dotSpacing

        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
        }

        Repeater {
            model: root.pageCount

            delegate: Rectangle {
                id: dot

                required property int index

                anchors.verticalCenter: parent.verticalCenter
                width: Style.pager.dotSize
                height: Style.pager.dotSize
                radius: width / 2
                color: pages.currentIndex === dot.index ? Colors.icon.active : Colors.icon.disabled

                MouseArea {
                    anchors.fill: parent
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

        BatteryPanel {
        }

    }

    Component {
        id: bluetoothPage

        BluetoothPanel {
        }

    }

    Component {
        id: audioPage

        AudioPanel {
        }

    }

    Component {
        id: brightnessPage

        BrightnessPanel {
        }

    }

    Component {
        id: wifiPage

        WifiPanel {
            active: root.active && pages.currentIndex === root.pageWifi
        }

    }

}
