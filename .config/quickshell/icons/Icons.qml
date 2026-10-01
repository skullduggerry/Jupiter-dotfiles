pragma Singleton

import QtQuick
import Quickshell

// Lucide's glyphs by name (lucide-static 1.49.0's font, ISC, see LICENSE), for
// Icon to draw. A new one is its codepoint from the package's
// font/codepoints.json, written as an escape like the rest.
Singleton {
    id: root

    readonly property string font: loader.name

    readonly property string bell: "\u{E059}"
    readonly property string bellDot: "\u{E42B}"
    readonly property string bellOff: "\u{E05A}"
    readonly property string bluetooth: "\u{E05C}"
    readonly property string bluetoothConnected: "\u{E1B8}"
    readonly property string bluetoothOff: "\u{E1B9}"
    readonly property string check: "\u{E06C}"
    readonly property string chevronDown: "\u{E06D}"
    readonly property string chevronLeft: "\u{E06E}"
    readonly property string chevronRight: "\u{E06F}"
    readonly property string chevronUp: "\u{E070}"
    readonly property string circle: "\u{E076}"
    readonly property string circleDot: "\u{E345}"
    readonly property string circleEllipsis: "\u{E346}"
    readonly property string clipboard: "\u{E085}"
    readonly property string coffee: "\u{E096}"
    readonly property string command: "\u{E09A}"
    readonly property string ellipsis: "\u{E0B6}"
    readonly property string globe: "\u{E0E8}"
    readonly property string hourglass: "\u{E296}"
    readonly property string info: "\u{E0F9}"
    readonly property string key: "\u{E0FD}"
    readonly property string keyboard: "\u{E284}"
    readonly property string lock: "\u{E10B}"
    readonly property string mic: "\u{E118}"
    readonly property string micOff: "\u{E119}"
    readonly property string monitor: "\u{E11D}"
    readonly property string monitorOff: "\u{E1DC}"
    readonly property string moon: "\u{E11E}"
    readonly property string music: "\u{E122}"
    readonly property string palette: "\u{E1DD}"
    readonly property string pause: "\u{E12E}"
    readonly property string plane: "\u{E1DE}"
    readonly property string play: "\u{E13C}"
    readonly property string power: "\u{E140}"
    readonly property string reply: "\u{E22A}"
    readonly property string rocket: "\u{E286}"
    readonly property string search: "\u{E151}"
    readonly property string send: "\u{E152}"
    readonly property string settings: "\u{E154}"
    readonly property string skipBack: "\u{E15F}"
    readonly property string skipForward: "\u{E160}"
    readonly property string square: "\u{E167}"
    readonly property string squareCheck: "\u{E559}"
    readonly property string sun: "\u{E178}"
    readonly property string sunDim: "\u{E299}"
    readonly property string sunMedium: "\u{E2B1}"
    readonly property string user: "\u{E19F}"
    readonly property string video: "\u{E1A5}"
    readonly property string volume: "\u{E1A9}"
    readonly property string volume1: "\u{E1AA}"
    readonly property string volume2: "\u{E1AB}"
    readonly property string volumeX: "\u{E1AC}"
    readonly property string wifi: "\u{E1AE}"
    readonly property string wifiHigh: "\u{E5F7}"
    readonly property string wifiLow: "\u{E5F8}"
    readonly property string wifiOff: "\u{E1AF}"
    readonly property string wifiZero: "\u{E5F9}"
    readonly property string x: "\u{E1B2}"
    readonly property string zap: "\u{E1B4}"

    FontLoader {
        id: loader

        source: Qt.resolvedUrl("lucide.ttf")
    }
}
