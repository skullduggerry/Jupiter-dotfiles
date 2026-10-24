import "../panels"
import "../services"
import "../style"
import QtQuick
import Quickshell.Services.UPower

// The quick settings' Battery page where there is a battery, which has the
// power modes too, or the modes alone where there is not; then when an idle
// session locks and suspends (Idle).
Item {
    id: root

    readonly property bool battery: UPower.displayDevice !== null && UPower.displayDevice.isLaptopBattery
    readonly property int columnWidth: Math.min(Style.settings.pageWidth, root.width - Style.settings.padding * 2)

    PanelCard {
        id: batteryCard

        visible: root.battery
        height: root.battery ? Math.min(Math.floor(batteryPanel.implicitHeight) + Style.settings.padding, root.height * Style.settings.cardShare) : 0
        preferredHeight: batteryPanel.implicitHeight

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }

        BatteryPanel {
            id: batteryPanel

            anchors.fill: parent
        }
    }

    Section {
        id: modes

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

    Section {
        id: idle

        title: "WHEN IDLE"

        anchors {
            top: root.battery ? batteryCard.bottom : modes.bottom
            left: parent.left
            leftMargin: Style.settings.padding
            topMargin: Style.settings.spacing
        }

        FormCard {
            width: root.columnWidth

            FormRow {
                label: "Lock after"

                ChoiceField {
                    choices: Idle.lockChoices
                    current: Idle.lockMinutes
                    onPicked: minutes => Idle.setLockMinutes(minutes)
                }
            }

            FormRow {
                label: "Suspend after"

                ChoiceField {
                    choices: Idle.suspendChoices
                    current: Idle.suspendMinutes
                    onPicked: minutes => Idle.setSuspendMinutes(minutes)
                }
            }
        }
    }

    Text {
        width: root.columnWidth
        wrapMode: Text.WordWrap
        text: "The screens go off half a minute after the lock, and suspending locks first. Caffeine, in the quick settings, holds all of it off."
        color: Colors.text.muted
        font.family: Style.text.font
        font.pixelSize: Style.text.smallSize

        anchors {
            top: idle.bottom
            left: parent.left
            leftMargin: Style.settings.padding
            topMargin: Style.bar.spacing
        }
    }
}
