import "../panels"
import "../services"
import "../style"
import QtQuick
import Quickshell.Services.UPower

// The quick settings' Battery page where there is a battery, which has the
// power modes too; the modes alone where there is not.
Item {
    id: root

    readonly property bool battery: UPower.displayDevice !== null && UPower.displayDevice.isLaptopBattery

    PanelCard {
        visible: root.battery
        anchors.fill: parent
        preferredHeight: batteryPanel.implicitHeight

        BatteryPanel {
            id: batteryPanel

            anchors.fill: parent
        }
    }

    Section {
        visible: !root.battery
        title: "POWER MODE"

        anchors {
            top: parent.top
            left: parent.left
            leftMargin: Style.settings.padding
        }

        PillGroup {
            choices: QuickToggles.profileChoices
            current: PowerProfiles.profile
            onPicked: profile => {
                PowerProfiles.profile = profile;
            }
        }
    }
}
