import "../services"
import "../style"
import QtQuick

// The mouse's and the touchpad's speed and scrolling (Pointer). A speed's
// slider runs over libinput's whole range, with the device's own in the
// middle; a scroll's is logarithmic, so that as the app asks is in the middle
// too.
ScrollPage {
    id: root

    // In steps of 0.05, as libinput's -1 to 1.
    function speedAt(position: real): real {
        return Math.round((position * 2 - 1) * 20) / 20;
    }

    function speedPosition(speed: real): real {
        return (speed + 1) / 2;
    }

    function speedText(speed: real): string {
        return (speed > 0 ? "+" : "") + speed.toFixed(2);
    }

    function scrollAt(position: real): real {
        return Math.round(Pointer.scrollLeast * Math.pow(Pointer.scrollMost / Pointer.scrollLeast, position) * 20) / 20;
    }

    function scrollPosition(scroll: real): real {
        return Math.log(scroll / Pointer.scrollLeast) / Math.log(Pointer.scrollMost / Pointer.scrollLeast);
    }

    function scrollText(scroll: real): string {
        return scroll.toFixed(2) + "×";
    }

    Component.onCompleted: Pointer.refresh()

    Section {
        title: "MOUSE"

        FormCard {
            width: root.columnWidth

            LevelRow {
                label: "Speed"
                position: root.speedPosition(Pointer.mouseSpeed)
                reading: root.speedText(Pointer.mouseSpeed)
                onMoved: position => Pointer.setMouse(root.speedAt(position), Pointer.mouseScroll)
            }

            LevelRow {
                label: "Scrolling"
                position: root.scrollPosition(Pointer.mouseScroll)
                reading: root.scrollText(Pointer.mouseScroll)
                onMoved: position => Pointer.setMouse(Pointer.mouseSpeed, root.scrollAt(position))
            }
        }
    }

    Section {
        title: "TOUCHPAD"

        FormCard {
            width: root.columnWidth

            LevelRow {
                label: "Speed"
                position: root.speedPosition(Pointer.touchpadSpeed)
                reading: root.speedText(Pointer.touchpadSpeed)
                onMoved: position => Pointer.setTouchpad(root.speedAt(position), Pointer.touchpadScroll)
            }

            LevelRow {
                label: "Scrolling"
                position: root.scrollPosition(Pointer.touchpadScroll)
                reading: root.scrollText(Pointer.touchpadScroll)
                onMoved: position => Pointer.setTouchpad(Pointer.touchpadSpeed, root.scrollAt(position))
            }
        }

        Text {
            width: root.columnWidth
            wrapMode: Text.WordWrap
            text: (Pointer.touchpads.length === 0 ? "No touchpad found: its speed applies once this page has seen one. " : "") + "A speed of 0 is the device's own, and the pointer still speeds up with a faster movement. Scrolling multiplies how far each notch of the wheel or each swipe goes."
            color: Colors.text.muted
            font.family: Style.text.font
            font.pixelSize: Style.text.smallSize
        }
    }
}
