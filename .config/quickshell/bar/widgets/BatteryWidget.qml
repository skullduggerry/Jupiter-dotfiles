// bar/widgets/BatteryWidget.qml
import QtQuick
import Quickshell
import Quickshell.Services.UPower
import "../../panels"
import "../../style"

Item {
    id: root

    required property ShellScreen screen

    readonly property UPowerDevice device: UPower.displayDevice

    visible: device.isLaptopBattery
    implicitWidth: visible ? Style.battery.width + Style.widgets.padding * 2 : 0
    implicitHeight: Style.bar.height

    readonly property int percent: Math.round(device.percentage * 100)

    readonly property bool charging: device.state === UPowerDeviceState.Charging
        || device.state === UPowerDeviceState.PendingCharge
    readonly property bool full: device.state === UPowerDeviceState.FullyCharged

    readonly property color levelColor: {
        if (charging || full) return Colors.battery.charging
        if (percent <= 15) return Colors.battery.critical
        if (percent <= 30) return Colors.battery.low
        return Colors.battery.normal
    }

    Rectangle {
        id: pill

        anchors.centerIn: parent
        width: Style.battery.width
        height: Style.battery.height
        radius: Style.battery.radius
        color: "transparent"
        border.width: Style.border.width
        border.color: Colors.base.border

        Rectangle {
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
                margins: Style.battery.inset
            }
            width: Math.max(height, (parent.width - Style.battery.inset * 2) * root.device.percentage)
            radius: Style.battery.radius - Style.battery.inset
            color: root.levelColor
            opacity: Colors.base.opacity

            Behavior on width {
                NumberAnimation { duration: Style.animation.normal }
            }
        }

        Text {
            anchors.centerIn: parent
            text: root.charging ? "\uf0e7 " + root.percent : root.percent
            color: Colors.text.base
            font.family: Style.text.font
            font.pixelSize: Style.text.smallSize
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: batteryPopup.visible = !batteryPopup.visible
    }

    WidgetPopup {
        id: batteryPopup
        screen: root.screen
        anchorItem: root
        namespaceSuffix: "battery-popup"
        popupWidth: Style.dropdown.width
        popupHeight: Math.max(Style.popup.minHeight,
                              Math.min(Style.dropdown.maxHeight,
                                       panel.item ? panel.item.preferredHeight : Style.popup.minHeight))

        Loader {
            id: panel
            anchors.fill: parent
            active: batteryPopup.visible

            sourceComponent: BatteryPanel {}
        }
    }
}
