// bar/widgets/BatteryWidget.qml
//
// The battery as the design draws it: an outlined pill whose inner fill is
// the charge, with the percentage centred on top of it — rather than a glyph
// plus a number. Clicking it opens the battery dropdown.
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

    // UPowerDevice.percentage is a 0.0-1.0 ratio (energy / energyCapacity),
    // not a 0-100 number: Quickshell scales UPower's wire value by 0.01. The
    // previous Math.round(percentage) therefore always produced 0 or 1, so
    // the bar read "0%"/"1%" and every tier below picked the empty glyph.
    readonly property int percent: Math.round(device.percentage * 100)

    // Charge state comes from the device itself. `!UPower.onBattery` only
    // says AC is present, so a laptop sitting at 100% on the charger showed
    // the charging bolt indefinitely.
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

        // The charge itself. Inset all round so it never touches the
        // outline, and clipped to the pill's rounded corners by matching the
        // radius rather than by a clip, which would soften the whole thing.
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
            // The design shows the bare number; the pill is what says it is a
            // battery, so a "%" next to it would be the third thing saying so.
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
