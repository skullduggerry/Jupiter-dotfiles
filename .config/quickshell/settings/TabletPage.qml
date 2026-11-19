pragma ComponentBehavior: Bound

import "../panels"
import "../services"
import "../style"
import QtQuick
import Quickshell

// The drawing tablet (Tablet): where it draws, how its pen feels and what the
// pad's buttons do. SUPER+T and SUPER+SHIFT+T hold it to a screen or a window
// on top of this, until pressed again.
ScrollPage {
    id: root

    function percent(share: real): string {
        return Math.round(share * 100) + "%";
    }

    Component.onCompleted: Tablet.refresh()

    Text {
        width: root.columnWidth
        wrapMode: Text.WordWrap
        text: Tablet.tablet !== null ? `${Tablet.tablet.name}, ${Tablet.tablet.width} × ${Tablet.tablet.height} mm` : "Connect tablet to apply settings."
        textFormat: Text.PlainText
        color: Colors.text.muted
        font.family: Style.text.font
        font.pixelSize: Style.text.smallSize
    }

    Section {
        title: "AREA"

        FormCard {
            width: root.columnWidth

            FormRow {
                label: "Shape"

                PillGroup {
                    choices: [
                        {
                            label: "Keep proportions",
                            value: true
                        },
                        {
                            label: "Stretch",
                            value: false
                        }
                    ]
                    current: Tablet.keepRatio
                    onPicked: keep => Tablet.setKeepRatio(keep)
                }
            }

            FormRow {
                label: "Hand"

                PillGroup {
                    choices: [
                        {
                            label: "Right",
                            value: false
                        },
                        {
                            label: "Left",
                            value: true
                        }
                    ]
                    current: Tablet.leftHanded
                    onPicked: left => Tablet.setLeftHanded(left)
                }
            }

            FormRow {
                label: "Focus area"

                ChoiceField {
                    choices: [
                        {
                            label: "Every screen",
                            value: "all"
                        },
                        {
                            label: "focused screen",
                            value: "focused"
                        }
                    ].concat(Quickshell.screens.map(screen => ({
                                label: screen.name,
                                value: screen.name,
                                detail: screen.model
                            }))).concat(["all", "focused"].includes(Tablet.area) || Quickshell.screens.some(screen => screen.name === Tablet.area) ? [] : [
                        {
                            label: Tablet.area,
                            value: Tablet.area,
                            detail: "not connected"
                        }
                    ])
                    current: Tablet.area
                    onPicked: area => Tablet.setArea(area)
                }
            }
        }
    }

    Section {
        title: "PRESSURE"

        FormCard {
            width: root.columnWidth

            LevelRow {
                label: "min Pressure"
                position: Tablet.pressureMin / Tablet.startsAtMost
                reading: root.percent(Tablet.pressureMin)
                onMoved: position => Tablet.setPressure(Math.round(position * Tablet.startsAtMost * 100) / 100, Tablet.pressureMax)
            }

            LevelRow {
                label: "max Pressure"
                position: (Tablet.pressureMax - Tablet.fullAtLeast) / (1 - Tablet.fullAtLeast)
                reading: root.percent(Tablet.pressureMax)
                onMoved: position => Tablet.setPressure(Tablet.pressureMin, Math.round((Tablet.fullAtLeast + position * (1 - Tablet.fullAtLeast)) * 100) / 100)
            }
        }
    }

    Section {
        title: "EXPRESSKEYS"

        FormCard {
            visible: Tablet.padButtons > 0
            width: root.columnWidth

            Repeater {
                model: Tablet.padButtons

                delegate: FormRow {
                    id: key

                    required property int index
                    readonly property string action: Tablet.actionOf(key.index)
                    // A shortcut that is none of the named ones.
                    readonly property bool custom: key.action.startsWith("keys:") && !Tablet.actions.some(choice => choice.value === key.action)
                    readonly property string bound: key.custom ? Keybinds.describe(key.action.slice(5)) : ""

                    label: "Key " + (key.index + 1)

                    Column {
                        width: parent.width
                        spacing: Style.bar.spacing

                        ChoiceField {
                            choices: Tablet.actions.concat([
                                {
                                    label: "Custom shortcut…",
                                    value: "custom"
                                }
                            ])
                            current: key.custom ? "custom" : key.action
                            onPicked: action => {
                                if (action !== "custom") {
                                    Tablet.setButton(key.index, action);
                                    return;
                                }
                                if (!key.custom)
                                    Tablet.setButton(key.index, "keys:");
                                shortcut.start();
                            }
                        }

                        ShortcutField {
                            id: shortcut

                            visible: key.custom
                            keys: key.action.slice(5)
                            onRecorded: keys => Tablet.setButton(key.index, "keys:" + keys)
                        }

                        Text {
                            visible: key.custom && key.action !== "keys:" && !shortcut.recording
                            width: parent.width
                            wrapMode: Text.WordWrap
                            text: key.bound !== "" ? "Your keybind: " + key.bound : "Sent to the focused window"
                            textFormat: Text.PlainText
                            color: Colors.text.muted
                            font.family: Style.text.font
                            font.pixelSize: Style.text.smallSize
                        }
                    }
                }
            }
        }

        Text {
            width: root.columnWidth
            wrapMode: Text.WordWrap
            text: {
                if (Tablet.padButtons === 0)
                    return "No tablet connected";
                if (Tablet.pad !== null && !Tablet.pad.readable)
                    return "The keys need the pad to be readable: run the installer's phase 4 again, or reconnect the tablet after it ran.";
                return "Overrides the default shortcuts";
            }
            color: Tablet.pad !== null && !Tablet.pad.readable ? Colors.status.error : Colors.text.muted
            font.family: Style.text.font
            font.pixelSize: Style.text.smallSize
        }
    }
}
