pragma ComponentBehavior: Bound

import "../panels"
import "../style"
import QtQuick
import Quickshell.Io

// The quick settings' Wi-Fi panel, then what NetworkManager says about each
// connected Wi-Fi or wired device (`nmcli device show`), read again whenever
// the kernel reports an address or a route changing.
Item {
    id: root

    readonly property int columnWidth: Math.min(Style.settings.pageWidth, root.width - Style.settings.padding * 2)
    // {device, type, connection, rows: [{label, value}]}
    property var connections: []

    function load(text: string) {
        const found = [];
        for (const block of text.split("\n\n")) {
            const fields = {};
            for (const line of block.split("\n")) {
                const colon = line.indexOf(":");
                if (colon < 0)
                    continue;

                const key = line.slice(0, colon).replace(/\[\d+\]$/, "");
                // Terse mode escapes the colons inside a value.
                const value = line.slice(colon + 1).replace(/\\:/g, ":");
                if (value !== "")
                    fields[key] = (fields[key] || []).concat([value]);
            }
            const type = (fields["GENERAL.TYPE"] || [""])[0];
            const state = (fields["GENERAL.STATE"] || [""])[0];
            if ((type !== "wifi" && type !== "ethernet") || !state.startsWith("100"))
                continue;

            const rows = [["IPv4", fields["IP4.ADDRESS"]], ["Gateway", fields["IP4.GATEWAY"]], ["DNS", fields["IP4.DNS"]], ["IPv6", fields["IP6.ADDRESS"]], ["Hardware address", fields["GENERAL.HWADDR"]]].filter(row => row[1] !== undefined).map(row => ({
                        label: row[0],
                        value: row[0] === "DNS" ? row[1].join(", ") : row[1][0]
                    }));
            found.push({
                device: fields["GENERAL.DEVICE"][0],
                type: type === "wifi" ? "Wi-Fi" : "Wired",
                connection: (fields["GENERAL.CONNECTION"] || [""])[0],
                rows: rows
            });
        }
        root.connections = found;
    }

    Component.onCompleted: reader.running = true

    Process {
        running: true
        command: ["setpriv", "--pdeathsig", "TERM", "ip", "monitor", "address", "route"]

        stdout: SplitParser {
            onRead: reread.restart()
        }
    }

    // Changes come in bursts; one read after the last of them.
    Timer {
        id: reread

        interval: Style.settings.rereadDelay
        onTriggered: {
            if (reader.running)
                reread.restart();
            else
                reader.running = true;
        }
    }

    Process {
        id: reader

        command: ["nmcli", "-t", "-f", "GENERAL.DEVICE,GENERAL.TYPE,GENERAL.STATE,GENERAL.CONNECTION,GENERAL.HWADDR,IP4.ADDRESS,IP4.GATEWAY,IP4.DNS,IP6.ADDRESS", "device", "show"]

        stdout: StdioCollector {
            onStreamFinished: root.load(text)
        }
    }

    PanelCard {
        id: wifiCard

        height: Math.min(Math.floor(wifi.implicitHeight) + Style.settings.padding, root.height * Style.settings.cardShare)
        preferredHeight: wifi.implicitHeight

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }

        WifiPanel {
            id: wifi

            anchors.fill: parent
            active: true
        }
    }

    ScrollPage {
        anchors {
            top: wifiCard.bottom
            bottom: parent.bottom
            left: parent.left
            right: parent.right
            topMargin: Style.settings.spacing
        }

        Repeater {
            model: root.connections

            delegate: Section {
                id: connection

                required property var modelData

                title: connection.modelData.type.toUpperCase() + "  ·  " + connection.modelData.device

                DetailRow {
                    width: root.columnWidth
                    label: "Connection"
                    value: connection.modelData.connection
                }

                Repeater {
                    model: connection.modelData.rows

                    delegate: DetailRow {
                        id: detail

                        required property var modelData

                        width: root.columnWidth
                        label: detail.modelData.label
                        value: detail.modelData.value
                    }
                }
            }
        }

        Text {
            visible: root.connections.length === 0
            text: "Not connected"
            color: Colors.text.muted
            font.family: Style.text.font
            font.pixelSize: Style.text.smallSize
        }
    }
}
