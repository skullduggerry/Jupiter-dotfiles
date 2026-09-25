import "../services"
import "../style"
import QtQuick

// What the bar's two usage meters summarise: load per core and what the CPU
// is doing, then where the memory went.
Item {
    id: root

    readonly property int preferredHeight: Style.bar.padding * 2 + header.height + Style.border.width + Style.bar.spacing + sections.implicitHeight
    readonly property int coreCount: Math.max(1, SystemUsage.cores.length)

    function gib(kib: real) : string {
        return (kib / 1024 / 1024).toFixed(1);
    }

    function duration(seconds: real) : string {
        const days = Math.floor(seconds / 86400);
        const hours = Math.floor((seconds % 86400) / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);
        if (days > 0)
            return days + "d " + hours + "h";

        if (hours > 0)
            return hours + "h " + minutes + "m";

        return minutes + "m";
    }

    Binding {
        target: SystemUsage
        property: "detailed"
        value: true
    }

    Item {
        anchors.fill: parent
        anchors.margins: Style.bar.padding

        Item {
            id: header

            height: Style.popup.itemHeight

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }

            Text {
                text: "System"
                color: Colors.text.base
                font.family: Style.text.font
                font.pixelSize: Style.text.size

                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }

            }

            Text {
                visible: SystemUsage.uptime > 0
                text: "up " + root.duration(SystemUsage.uptime)
                color: Colors.text.muted
                font.family: Style.text.font
                font.pixelSize: Style.text.smallSize

                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }

            }

        }

        Rectangle {
            id: separator

            height: Style.border.width
            color: Colors.base.border

            anchors {
                top: header.bottom
                left: parent.left
                right: parent.right
            }

        }

        Column {
            id: sections

            anchors {
                top: separator.bottom
                left: parent.left
                right: parent.right
                topMargin: Style.bar.spacing
            }

            Item {
                width: parent.width
                height: Style.popup.itemHeight

                Text {
                    text: "CPU"
                    color: Colors.text.base
                    font.family: Style.text.font
                    font.pixelSize: Style.text.size

                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                    }

                }

                Text {
                    text: Math.round(SystemUsage.cpu * 100) + "%"
                    color: SystemUsage.cpu > Style.usage.warnAbove ? Colors.usage.warn : Colors.text.base
                    font.family: Style.text.font
                    font.pixelSize: Style.text.size

                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }

                }

            }

            // One bar per core, filled from the bottom like the bar's meters
            // fill their ring; the gap shrinks before the bars do.
            Row {
                id: coreBars

                readonly property real gap: Math.min(Style.widgets.spacing, Math.floor(coreBars.width / root.coreCount / 3))

                width: parent.width
                height: Style.usage.coreHeight
                spacing: coreBars.gap

                Repeater {
                    model: SystemUsage.cores

                    delegate: Rectangle {
                        id: coreBar

                        required property real modelData

                        width: (coreBars.width - coreBars.gap * (root.coreCount - 1)) / root.coreCount
                        height: coreBars.height
                        radius: Style.slider.track / 2
                        color: Colors.base.hover

                        Rectangle {
                            width: parent.width
                            height: parent.height * coreBar.modelData
                            radius: parent.radius
                            color: coreBar.modelData > Style.usage.warnAbove ? Colors.usage.warn : Colors.usage.normal
                            anchors.bottom: parent.bottom

                            Behavior on height {
                                NumberAnimation {
                                    duration: Style.animation.normal
                                }

                            }

                        }

                    }

                }

            }

            Item {
                width: parent.width
                height: Style.bar.spacing
            }

            DetailRow {
                label: "Model"
                visible: SystemUsage.model !== ""
                value: SystemUsage.model
            }

            DetailRow {
                label: "Frequency"
                visible: SystemUsage.frequency > 0
                value: (SystemUsage.frequency / 1000).toFixed(2) + " GHz"
            }

            DetailRow {
                label: "Temperature"
                visible: SystemUsage.temperature >= 0
                value: Math.round(SystemUsage.temperature) + " °C"
            }

            DetailRow {
                label: "Load average"
                visible: SystemUsage.load.length === 3
                value: SystemUsage.load.map((average) => {
                    return average.toFixed(2);
                }).join("  ")
            }

            Item {
                width: parent.width
                height: Style.bar.spacing * 2 + Style.border.width

                Rectangle {
                    width: parent.width
                    height: Style.border.width
                    color: Colors.base.border
                    anchors.verticalCenter: parent.verticalCenter
                }

            }

            Item {
                width: parent.width
                height: Style.popup.itemHeight

                Text {
                    text: "Memory"
                    color: Colors.text.base
                    font.family: Style.text.font
                    font.pixelSize: Style.text.size

                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                    }

                }

                Text {
                    text: Math.round(SystemUsage.memory * 100) + "%"
                    color: SystemUsage.memory > Style.usage.warnAbove ? Colors.usage.warn : Colors.text.base
                    font.family: Style.text.font
                    font.pixelSize: Style.text.size

                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }

                }

            }

            // The volume slider's track, for looking at rather than dragging.
            PanelSlider {
                width: parent.width
                enabled: false
                value: SystemUsage.memory
            }

            DetailRow {
                label: "Used"
                value: root.gib(SystemUsage.memoryTotal - SystemUsage.memoryAvailable) + " of " + root.gib(SystemUsage.memoryTotal) + " GiB"
            }

            DetailRow {
                label: "Cache"
                value: root.gib(SystemUsage.memoryCache) + " GiB"
            }

            DetailRow {
                label: "Swap"
                visible: SystemUsage.swapTotal > 0
                value: root.gib(SystemUsage.swapTotal - SystemUsage.swapFree) + " of " + root.gib(SystemUsage.swapTotal) + " GiB"
            }

        }

    }

}
