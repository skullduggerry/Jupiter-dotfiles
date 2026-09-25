import "../services"
import "../style"
import QtQuick
import Quickshell.Services.UPower

Item {
    id: root

    readonly property int preferredHeight: Style.bar.padding * 2 + header.height + Style.border.width + Style.bar.spacing + rows.implicitHeight + Style.bar.spacing + profiles.height
    readonly property UPowerDevice device: UPower.displayDevice
    readonly property bool charging: root.device.state === UPowerDeviceState.Charging || root.device.state === UPowerDeviceState.PendingCharge
    // power-profiles-daemon's modes, Performance only where the hardware has it.
    readonly property var profileChoices: PowerProfiles.hasPerformanceProfile ? [PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance] : [PowerProfile.PowerSaver, PowerProfile.Balanced]

    function stateLabel(state: int) : string {
        switch (state) {
        case UPowerDeviceState.Charging:
            return "Charging";
        case UPowerDeviceState.PendingCharge:
            return "Waiting to charge";
        case UPowerDeviceState.Discharging:
            return "On battery";
        case UPowerDeviceState.PendingDischarge:
            return "Waiting to discharge";
        case UPowerDeviceState.FullyCharged:
            return "Fully charged";
        case UPowerDeviceState.Empty:
            return "Empty";
        default:
            return "Unknown";
        }
    }

    function durationLabel(seconds: real) : string {
        if (seconds <= 0)
            return "—";

        const hours = Math.floor(seconds / 3600);
        const minutes = Math.round((seconds % 3600) / 60);
        if (hours === 0)
            return minutes + "m";

        return hours + "h " + minutes + "m";
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
                text: "Battery"
                color: Colors.text.base
                font.family: Style.text.font
                font.pixelSize: Style.text.size

                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }

            }

            Text {
                text: Math.round(root.device.percentage * 100) + "%"
                color: root.charging ? Colors.battery.charging : Colors.text.base
                font.family: Style.text.font
                font.pixelSize: Style.text.size

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
            id: rows

            anchors {
                top: separator.bottom
                left: parent.left
                right: parent.right
                topMargin: Style.bar.spacing
            }

            DetailRow {
                label: "State"
                value: root.stateLabel(root.device.state)
            }

            DetailRow {
                label: root.charging ? "Until full" : "Remaining"
                visible: root.device.state !== UPowerDeviceState.FullyCharged
                value: root.durationLabel(root.charging ? root.device.timeToFull : root.device.timeToEmpty)
            }

            DetailRow {
                label: "Power draw"
                value: Math.abs(root.device.changeRate).toFixed(1) + " W"
            }

            DetailRow {
                label: "Capacity"
                visible: root.device.healthSupported
                value: Math.round(root.device.healthPercentage) + "%"
            }

            DetailRow {
                label: "Model"
                visible: root.device.model !== ""
                value: root.device.model
            }

        }

        Row {
            id: profiles

            spacing: Style.widgets.spacing

            anchors {
                top: rows.bottom
                left: parent.left
                right: parent.right
                topMargin: Style.bar.spacing
            }

            Repeater {
                model: root.profileChoices

                delegate: PillButton {
                    id: choice

                    required property int modelData

                    width: (profiles.width - profiles.spacing * (root.profileChoices.length - 1)) / root.profileChoices.length
                    compact: true
                    text: QuickToggles.profileName(choice.modelData)
                    checked: PowerProfiles.profile === choice.modelData
                    onClicked: PowerProfiles.profile = choice.modelData
                }

            }

        }

    }

}
