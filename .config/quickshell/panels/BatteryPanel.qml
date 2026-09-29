import "../services"
import "../style"
import QtQuick
import Quickshell.Services.UPower

PanelFrame {
    id: root

    implicitHeight: root.chromeHeight + rows.implicitHeight
    readonly property UPowerDevice device: UPower.displayDevice
    readonly property bool charging: root.device.state === UPowerDeviceState.Charging || root.device.state === UPowerDeviceState.PendingCharge

    function stateLabel(state: int): string {
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

    function durationLabel(seconds: real): string {
        if (seconds <= 0)
            return "—";

        const hours = Math.floor(seconds / 3600);
        const minutes = Math.round((seconds % 3600) / 60);
        return hours === 0 ? minutes + "m" : hours + "h " + minutes + "m";
    }

    title: "Battery"

    Column {
        id: rows

        width: parent.width

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

        Item {
            width: parent.width
            height: Style.bar.spacing
        }

        PillGroup {
            width: parent.width
            compact: true
            fill: true
            choices: QuickToggles.profileChoices
            current: PowerProfiles.profile
            onPicked: profile => {
                PowerProfiles.profile = profile;
            }
        }
    }

    trailing: Text {
        text: Math.round(root.device.percentage * 100) + "%"
        color: root.charging ? Colors.battery.charging : Colors.text.base
        font.family: Style.text.font
        font.pixelSize: Style.text.size
    }
}
