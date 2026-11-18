pragma ComponentBehavior: Bound

import "../icons"
import "../services"
import "../style"
import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

// What the quick menu's slots can hold, by the IDs QuickMenu keeps: the
// categories, and the items in them or in a slot of their own. describe()
// gives an item's glyph, label and state; use() and adjust() act through the
// services the quick-settings tiles use, so the two always agree. Kinds:
// toggle (on or off), level (scroll or the arrows change it), cycle (each use
// switches to the next choice), action, open (another surface), and list
// (its entries in a panel beside its slot, as a category's items are in an
// arc, so a slot of its own: the apps, the clipboard, the notifications).
Scope {
    id: root

    readonly property WifiDevice wifi: Networking.devices.values.find(device => device.type === DeviceType.Wifi) ?? null
    readonly property WifiNetwork network: root.wifi?.networks.values.find(network => network.connected) ?? null
    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property bool bluetoothOn: root.adapter?.enabled ?? false
    // Paired devices, connected first, as the Bluetooth panel lists them.
    readonly property var devices: Bluetooth.devices.values.filter(device => device.paired).sort((left, right) => right.connected - left.connected || left.name.localeCompare(right.name))
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property bool microphoneReady: root.source !== null && root.source.ready && root.source.audio !== null
    readonly property list<string> shortcuts: ["wifi", "bluetooth", "airplane", "doNotDisturb", "caffeine", "nightLight", "mute", "microphone", "record", "region", "playPause", "lock", "apps", "clipboard", "overview", "notifications", "calendar", "shelf", "wallpaper"]
    readonly property var categories: ({
            network: {
                label: "Network",
                keys: "WN",
                icon: () => Networking.wifiEnabled ? Icons.wifi : Icons.wifiOff,
                detail: () => QuickToggles.airplaneMode ? "Airplane Mode" : root.describe("item:wifi").detail,
                items: ["wifi", "airplane", "networks"]
            },
            bluetooth: {
                label: "Bluetooth",
                keys: "B",
                icon: () => root.describe("item:bluetooth").icon,
                detail: () => root.describe("item:bluetooth").detail,
                items: ["bluetooth", "devices", "bluetoothSettings"]
            },
            sound: {
                label: "Sound",
                keys: "S",
                icon: () => Volume.muted ? Icons.volumeX : Icons.volume2,
                detail: () => root.describe("item:volume").detail,
                items: ["mute", "volume", "microphone", "output"]
            },
            display: {
                label: "Display",
                keys: "D",
                icon: () => QuickToggles.nightLight ? Icons.moon : Icons.sunMedium,
                detail: () => QuickToggles.nightLight ? "Night Light on" : Brightness.available ? "Brightness " + Math.round(Brightness.fraction * 100) + "%" : "Night Light off",
                items: ["brightness", "nightLight", "displays"]
            },
            media: {
                label: "Media",
                keys: "M",
                icon: () => Icons.music,
                detail: () => Media.active?.trackTitle ?? "Nothing playing",
                items: ["previous", "playPause", "next"]
            },
            capture: {
                label: "Capture",
                keys: "CP",
                icon: () => QuickToggles.recording ? Icons.circleStop : Icons.camera,
                detail: () => QuickToggles.recording ? "Recording" : "Screenshots",
                items: ["region", "window", "screen", "record"]
            },
            focus: {
                label: "Focus",
                keys: "F",
                icon: () => NotificationService.doNotDisturb ? Icons.bellOff : Icons.bell,
                detail: () => [NotificationService.doNotDisturb ? "Do Not Disturb" : "", QuickToggles.caffeine ? "Caffeine" : ""].filter(part => part !== "").join(" · ") || "Nothing on",
                items: ["doNotDisturb", "caffeine", "nightLight", "lock"],
                shows: ["doNotDisturb", "caffeine", "lock"]
            },
            power: {
                label: "Power",
                keys: "P",
                icon: () => Icons.power,
                detail: () => QuickToggles.profileName(PowerProfiles.profile),
                items: ["powerMode", "lock", "suspend", "logOut", "restart", "shutDown"],
                shows: ["powerMode", "suspend", "logOut", "restart", "shutDown"]
            }
        })
    readonly property var definitions: ({
            wifi: {
                label: "Wi-Fi",
                keys: "W",
                kind: "toggle",
                available: () => root.wifi !== null,
                on: () => Networking.wifiEnabled,
                icon: () => Networking.wifiEnabled ? Icons.wifi : Icons.wifiOff,
                detail: () => !Networking.wifiEnabled ? "Off" : root.network?.name ?? "Not connected",
                use: () => {
                    Networking.wifiEnabled = !Networking.wifiEnabled;
                }
            },
            airplane: {
                label: "Airplane Mode",
                short: "Airplane",
                keys: "A",
                kind: "toggle",
                on: () => QuickToggles.airplaneMode,
                icon: () => Icons.plane,
                use: () => QuickToggles.setAirplaneMode(!QuickToggles.airplaneMode)
            },
            networks: {
                label: "Networks…",
                short: "Networks",
                keys: "N",
                kind: "open",
                icon: () => Icons.settings,
                detail: () => "Settings",
                use: () => SettingsState.show("network")
            },
            bluetooth: {
                label: "Bluetooth",
                keys: "B",
                kind: "toggle",
                available: () => root.adapter !== null,
                on: () => root.bluetoothOn,
                icon: () => !root.bluetoothOn ? Icons.bluetoothOff : root.devices.some(device => device.connected) ? Icons.bluetoothConnected : Icons.bluetooth,
                detail: () => !root.bluetoothOn ? "Off" : root.devices.filter(device => device.connected).map(device => device.name).join(", ") || "On",
                use: () => {
                    root.adapter.enabled = !root.adapter.enabled;
                }
            },
            bluetoothSettings: {
                label: "Devices…",
                short: "Devices",
                keys: "D",
                kind: "open",
                icon: () => Icons.settings,
                detail: () => "Settings",
                use: () => SettingsState.show("bluetooth")
            },
            mute: {
                label: "Mute",
                keys: "M",
                kind: "toggle",
                available: () => Volume.ready,
                on: () => Volume.muted,
                icon: () => Volume.muted ? Icons.volumeX : Icons.volume2,
                detail: () => Volume.muted ? "Muted" : "Sound on",
                use: () => Volume.toggleMute()
            },
            volume: {
                label: "Volume",
                keys: "V",
                kind: "level",
                available: () => Volume.ready,
                level: () => Volume.muted ? 0 : Volume.volume,
                icon: () => Volume.muted ? Icons.volumeX : Volume.volume < 1 / 3 ? Icons.volume : Volume.volume < 2 / 3 ? Icons.volume1 : Icons.volume2,
                detail: () => Volume.muted ? "Muted" : Math.round(Volume.volume * 100) + "%",
                adjust: steps => Volume.adjust(steps * Volume.step)
            },
            microphone: {
                label: "Microphone",
                short: "Mic",
                keys: "I",
                kind: "toggle",
                available: () => root.microphoneReady,
                on: () => !root.source.audio.muted,
                icon: () => root.source.audio.muted ? Icons.micOff : Icons.mic,
                detail: () => root.source.audio.muted ? "Muted" : "On",
                use: () => {
                    root.source.audio.muted = !root.source.audio.muted;
                }
            },
            // Greyed out with nothing to switch to, as plugging in headphones
            // would otherwise move the items beside it.
            output: {
                label: "Output",
                keys: "O",
                kind: "cycle",
                disabled: () => Volume.outputs.length < 2,
                icon: () => Icons.speaker,
                detail: () => Volume.sink !== null ? Volume.label(Volume.sink) : "",
                use: () => {
                    const outputs = Volume.outputs;
                    const index = outputs.findIndex(node => node.id === Volume.sink?.id);
                    Pipewire.preferredDefaultAudioSink = outputs[(index + 1) % outputs.length];
                }
            },
            // A built-in screen's backlight; greyed out on a machine with
            // none (external monitors), rather than gone.
            brightness: {
                label: "Brightness",
                keys: "B",
                kind: "level",
                disabled: () => !Brightness.available,
                level: () => Brightness.fraction,
                icon: () => Icons.sunMedium,
                detail: () => Brightness.available ? Math.round(Brightness.fraction * 100) + "%" : "No backlight",
                adjust: steps => Brightness.adjust(steps * Brightness.step)
            },
            // A click turns it on or off, scrolling makes it warmer (up) or
            // cooler, as the Displays page's slider has it, on or off.
            nightLight: {
                label: "Night Light",
                keys: "N",
                kind: "toggle",
                on: () => QuickToggles.nightLight,
                icon: () => Icons.moon,
                // "K" kept with its number where the centre wraps.
                detail: () => (QuickToggles.nightLight ? "" : "Off, ") + QuickToggles.nightLightTemperature + "\u00A0K",
                use: () => QuickToggles.setNightLight(!QuickToggles.nightLight),
                adjust: steps => QuickToggles.setNightLightTemperature(Math.round(QuickToggles.nightLightTemperature - steps * Style.quickMenu.levelStep * (QuickToggles.nightLightCoolest - QuickToggles.nightLightWarmest)))
            },
            displays: {
                label: "Displays…",
                short: "Displays",
                keys: "D",
                kind: "open",
                icon: () => Icons.monitor,
                detail: () => "Settings",
                use: () => SettingsState.show("displays")
            },
            playPause: {
                label: () => Media.active?.isPlaying ? "Pause" : "Play",
                name: "Play or Pause",
                keys: "P",
                kind: "action",
                disabled: () => !(Media.active?.canTogglePlaying ?? false),
                icon: () => Media.active?.isPlaying ? Icons.pause : Icons.play,
                detail: () => Media.active?.trackTitle ?? "Nothing playing",
                use: () => Media.togglePlaying()
            },
            previous: {
                label: "Previous",
                keys: "B",
                kind: "action",
                disabled: () => !(Media.active?.canGoPrevious ?? false),
                icon: () => Icons.skipBack,
                detail: () => Media.active?.identity ?? "",
                use: () => Media.previous()
            },
            next: {
                label: "Next",
                keys: "N",
                kind: "action",
                disabled: () => !(Media.active?.canGoNext ?? false),
                icon: () => Icons.skipForward,
                detail: () => Media.active?.identity ?? "",
                use: () => Media.next()
            },
            // Taken once the menu is off the screen.
            region: {
                label: "Region",
                name: "Region Screenshot",
                keys: "R",
                kind: "action",
                closes: true,
                icon: () => Icons.crop,
                detail: () => "Screenshot",
                use: () => root.later(() => Session.app(["hyprshot", "-m", "region"]))
            },
            window: {
                label: "Window",
                name: "Window Screenshot",
                keys: "W",
                kind: "action",
                closes: true,
                icon: () => Icons.appWindow,
                detail: () => "Screenshot",
                use: () => root.later(() => Session.app(["hyprshot", "-m", "window"]))
            },
            screen: {
                label: "Screen",
                name: "Screen Screenshot",
                keys: "S",
                kind: "action",
                closes: true,
                icon: () => Icons.monitor,
                detail: () => "Screenshot",
                use: () => root.later(() => Session.app(["hyprshot", "-m", "output"]))
            },
            record: {
                label: () => QuickToggles.recording ? "Stop Recording" : "Record Screen",
                short: () => QuickToggles.recording ? "Stop" : "Record",
                name: "Screen Record",
                keys: "RV",
                kind: "toggle",
                closes: true,
                on: () => QuickToggles.recording,
                icon: () => QuickToggles.recording ? Icons.circleStop : Icons.video,
                detail: () => QuickToggles.recording ? "Recording" : "Off",
                use: () => {
                    const start = !QuickToggles.recording;
                    root.later(() => QuickToggles.setRecording(start));
                }
            },
            // The launcher: QuickMenuApps, which SUPER+R opens.
            apps: {
                label: "Apps",
                keys: "A",
                kind: "list",
                icon: () => Icons.layoutGrid
            },
            // Its entries are QuickMenuClipboard's, with the history's own
            // switch.
            clipboard: {
                label: "Clipboard",
                keys: "C",
                kind: "list",
                icon: () => Icons.clipboard,
                detail: () => QuickToggles.clipboardHistory ? "History on" : "History off"
            },
            doNotDisturb: {
                label: "Do Not Disturb",
                keys: "N",
                kind: "toggle",
                on: () => NotificationService.doNotDisturb,
                icon: () => NotificationService.doNotDisturb ? Icons.bellOff : Icons.bell,
                detail: () => NotificationService.doNotDisturb ? "On" : "Off",
                use: () => {
                    NotificationService.doNotDisturb = !NotificationService.doNotDisturb;
                }
            },
            caffeine: {
                label: "Caffeine",
                keys: "CA",
                kind: "toggle",
                on: () => QuickToggles.caffeine,
                icon: () => Icons.coffee,
                detail: () => {
                    if (QuickToggles.caffeineEnd !== 0)
                        return "until " + Qt.formatDateTime(new Date(QuickToggles.caffeineEnd * 60000), "HH:mm");
                    const minutes = QuickToggles.caffeineMinutes;
                    return QuickToggles.caffeine || minutes === 0 ? "no limit" : minutes % 60 === 0 ? minutes / 60 + " h" : minutes + " min";
                },
                use: () => QuickToggles.setCaffeine(!QuickToggles.caffeine),
                adjust: steps => QuickToggles.cycleCaffeineMinutes(steps > 0 ? 1 : -1)
            },
            lock: {
                label: "Lock",
                keys: "L",
                kind: "action",
                closes: true,
                icon: () => Icons.lock,
                detail: () => "The screen",
                use: () => LockService.lock()
            },
            powerMode: {
                label: "Power Mode",
                keys: "M",
                kind: "cycle",
                icon: () => Icons.gauge,
                detail: () => QuickToggles.profileName(PowerProfiles.profile),
                use: () => {
                    const choices = QuickToggles.profileChoices;
                    const index = choices.findIndex(choice => choice.value === PowerProfiles.profile);
                    PowerProfiles.profile = choices[(index + 1) % choices.length].value;
                }
            },
            // As the bar's power menu does them; the ones that end the session
            // ask twice first.
            suspend: {
                label: "Suspend",
                keys: "S",
                kind: "action",
                closes: true,
                icon: () => Icons.bed,
                use: () => Session.suspend()
            },
            logOut: {
                label: "Logout",
                keys: "O",
                kind: "action",
                closes: true,
                confirm: true,
                icon: () => Icons.logOut,
                use: () => Session.logout()
            },
            restart: {
                label: "Reboot",
                keys: "R",
                kind: "action",
                closes: true,
                confirm: true,
                danger: true,
                icon: () => Icons.rotateCcw,
                use: () => Session.reboot()
            },
            shutDown: {
                label: "Shutdown",
                keys: "U",
                kind: "action",
                closes: true,
                confirm: true,
                danger: true,
                icon: () => Icons.power,
                use: () => Session.poweroff()
            },
            overview: {
                label: "Every Workspace",
                short: "Workspaces",
                keys: "O",
                kind: "open",
                icon: () => Icons.layoutGrid,
                use: () => root.shortcut("overview")
            },
            // Its entries are QuickMenuNotifications', with Clear and Do Not
            // Disturb.
            notifications: {
                label: "Notifications",
                keys: "N",
                kind: "list",
                icon: () => NotificationService.doNotDisturb ? Icons.bellOff : NotificationService.count > 0 ? Icons.bellDot : Icons.bell,
                detail: () => [NotificationService.count === 0 ? "None" : NotificationService.count === 1 ? "1 notification" : NotificationService.count + " notifications", NotificationService.doNotDisturb ? "Do Not Disturb" : ""].filter(part => part !== "").join(" · ")
            },
            calendar: {
                label: "Calendar",
                keys: "C",
                kind: "open",
                icon: () => Icons.calendar,
                use: () => DropdownState.open(DropdownState.zoneCalendar, Screens.focused)
            },
            shelf: {
                label: "Shelf",
                keys: "S",
                kind: "open",
                icon: () => Icons.inbox,
                use: () => Shelf.toggleRequested()
            },
            wallpaper: {
                label: "Wallpaper",
                keys: "W",
                kind: "open",
                icon: () => Icons.image,
                use: () => SettingsState.show("wallpaper")
            }
        })
    property var pending: null

    // An entry is "kind:id"; a device's id is its address, which has colons
    // of its own, so the split is at the first one only.
    function entryKind(entry: string): string {
        return entry.slice(0, Math.max(0, entry.indexOf(":")));
    }

    function entryId(entry: string): string {
        return entry.indexOf(":") < 0 ? "" : entry.slice(entry.indexOf(":") + 1);
    }

    // A slot's or an item's look and state now: {kind, label, short, name,
    // icon, detail, on, level, adjustable (scroll and the arrows change it),
    // disabled, closes, confirm, danger}; "category" for a category, "empty"
    // for nothing.
    function describe(entry: string): var {
        const kind = root.entryKind(entry);
        const id = root.entryId(entry);
        if (kind === "category" && root.categories[id] !== undefined) {
            const category = root.categories[id];
            return {
                kind: "category",
                label: category.label,
                short: category.label,
                name: category.label,
                icon: category.icon(),
                detail: category.detail()
            };
        }
        if (kind === "device")
            return root.describeDevice(root.devices.find(device => device.address === id));

        const item = root.definitions[id];
        if (item === undefined)
            return {
                kind: "empty",
                label: "",
                short: "",
                name: "Nothing",
                icon: Icons.plus,
                detail: ""
            };

        const value = field => typeof item[field] === "function" ? item[field]() : item[field];
        const usable = item.available === undefined || item.available();
        return {
            kind: item.kind,
            label: value("label"),
            short: value("short") ?? value("label"),
            name: item.name ?? value("short") ?? value("label"),
            icon: usable ? item.icon() : Icons.circle,
            detail: usable ? value("detail") ?? "" : "Unavailable",
            on: usable && item.on !== undefined && item.on(),
            level: usable && item.level !== undefined ? item.level() : 0,
            adjustable: usable && item.adjust !== undefined,
            disabled: !usable || (item.disabled !== undefined && item.disabled()),
            closes: item.closes === true || item.kind === "open",
            confirm: item.confirm === true,
            danger: item.danger === true
        };
    }

    // What a slot holds, without its state: "category", an item's kind, or "".
    function kindOf(entry: string): string {
        const id = root.entryId(entry);
        if (entry.startsWith("category:"))
            return root.categories[id] !== undefined ? "category" : "";
        return entry.startsWith("item:") ? root.definitions[id]?.kind ?? "" : "";
    }

    function describeDevice(device: BluetoothDevice): var {
        if (device === undefined || device === null)
            return root.describe("");

        const glyph = device.icon.startsWith("audio-head") ? Icons.headphones : device.icon.startsWith("audio") ? Icons.speaker : device.icon.startsWith("input-keyboard") ? Icons.keyboard : Icons.bluetooth;
        return {
            kind: "toggle",
            label: device.name,
            short: device.name,
            name: device.name,
            icon: glyph,
            detail: !root.bluetoothOn ? "Bluetooth off" : !device.connected ? "Not connected" : device.batteryAvailable ? Math.round(device.battery * 100) + "%" : "Connected",
            on: root.bluetoothOn && device.connected,
            level: 0,
            adjustable: false,
            disabled: !root.bluetoothOn,
            closes: false,
            confirm: false,
            danger: false
        };
    }

    // A category's items as the menu shows them: those picked for it (or
    // its defaults), the paired devices in place of "devices" (as many as
    // the others leave room for, so a long list does not push them out), any
    // this machine has no use for left out, at most maxItems.
    function itemsOf(entry: string): list<string> {
        const kind = root.entryKind(entry);
        const id = root.entryId(entry);
        const category = root.categories[id];
        if (kind !== "category" || category === undefined)
            return [];

        const picked = QuickMenu.categories[id] ?? category.shows ?? category.items;
        const usable = item => root.definitions[item] !== undefined && (root.definitions[item].available === undefined || root.definitions[item].available());
        const room = Style.quickMenu.maxItems - picked.filter(item => item !== "devices" && usable(item)).length;
        const expanded = [];
        for (const item of picked) {
            if (item === "devices") {
                for (const device of root.devices.slice(0, Math.max(0, room)))
                    expanded.push("device:" + device.address);
            } else if (usable(item)) {
                expanded.push("item:" + item);
            }
        }
        return expanded.slice(0, Style.quickMenu.maxItems);
    }

    // A letter for each entry, as unused as can be: its own choice first,
    // then the letters of its label.
    function keysFor(entries: list<string>): list<string> {
        const used = [];
        return entries.map(entry => {
            const described = root.describe(entry);
            if (described.kind === "empty")
                return "";

            const id = root.entryId(entry);
            const preferred = (entry.startsWith("category:") ? root.categories[id]?.keys : root.definitions[id]?.keys) ?? "";
            for (const letter of preferred + described.short.toUpperCase().replace(/[^A-Z]/g, "")) {
                if (!used.includes(letter)) {
                    used.push(letter);
                    return letter;
                }
            }
            return "";
        });
    }

    function use(entry: string) {
        const id = root.entryId(entry);
        if (entry.startsWith("device:")) {
            const device = root.devices.find(candidate => candidate.address === id);
            if (device?.connected)
                device.disconnect();
            else
                device?.connect();
            return;
        }
        if (root.definitions[id]?.use !== undefined)
            root.definitions[id].use();
    }

    // Scroll or the arrows: a level, Caffeine's length, Night Light's warmth.
    function adjust(entry: string, steps: int) {
        const item = root.definitions[root.entryId(entry)];
        if (item?.adjust !== undefined)
            item.adjust(steps);
    }

    function shortcut(name: string) {
        Hyprland.dispatch(`hl.dsp.global("quickshell:${name}")`);
    }

    function later(action) {
        root.pending = action;
        offScreen.restart();
    }

    PwObjectTracker {
        objects: root.source !== null ? [root.source] : []
    }

    // The menu's Brightness, whichever bar there is.
    Binding {
        target: Brightness
        property: "active"
        value: true
    }

    Timer {
        id: offScreen

        interval: Style.quickMenu.captureDelay
        onTriggered: {
            if (root.pending !== null)
                root.pending();
            root.pending = null;
        }
    }
}
