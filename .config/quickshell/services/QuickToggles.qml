pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Services.UPower

Singleton {
    id: root

    readonly property int nightLightTemperature: 4000
    readonly property bool nightLight: sunset.running
    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property bool airplaneMode: !Networking.wifiEnabled && (root.adapter === null || !root.adapter.enabled)
    readonly property bool anyOn: root.nightLight || root.airplaneMode || NotificationService.doNotDisturb

    // hyprsunset lives exactly as long as the filter should: Hyprland resets
    // the colour matrix when its client disconnects, so stopping the process
    // is the off switch. setpriv hands it a parent-death signal, because an
    // orphan left behind by a killed shell would keep tinting the screen and
    // block the next shell's hyprsunset from starting.
    function setNightLight(enabled: bool) {
        settings.nightLight = enabled;
        writeDebounce.restart();
        sunset.running = enabled;
    }

    // Through NetworkManager and BlueZ rather than rfkill, so the Wi-Fi and
    // Bluetooth pages always agree with this tile.
    function setAirplaneMode(enabled: bool) {
        Networking.wifiEnabled = !enabled;
        if (root.adapter !== null)
            root.adapter.enabled = !enabled;

    }

    function cyclePowerProfile() {
        switch (PowerProfiles.profile) {
        case PowerProfile.PowerSaver:
            PowerProfiles.profile = PowerProfile.Balanced;
            break;
        case PowerProfile.Balanced:
            PowerProfiles.profile = PowerProfiles.hasPerformanceProfile ? PowerProfile.Performance : PowerProfile.PowerSaver;
            break;
        default:
            PowerProfiles.profile = PowerProfile.PowerSaver;
        }
    }

    Component.onCompleted: {
        settingsFile.text();
        sunset.running = settings.nightLight;
    }

    Process {
        id: sunset

        command: ["setpriv", "--pdeathsig", "TERM", "hyprsunset", "--temperature", String(root.nightLightTemperature)]
        onExited: (exitCode, exitStatus) => {
            if (settings.nightLight)
                console.warn("night light: hyprsunset exited with status", exitCode);

        }
    }

    Timer {
        id: writeDebounce

        interval: 200
        onTriggered: settingsFile.writeAdapter()
    }

    FileView {
        id: settingsFile

        path: Quickshell.statePath("quick-toggles.json")
        preload: true
        blockLoading: true
        printErrors: false
        watchChanges: false

        adapter: JsonAdapter {
            id: settings

            property bool nightLight: false
        }

    }

}
