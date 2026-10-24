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
        text: Tablet.tablet !== null ? `${Tablet.tablet.name}, ${Tablet.tablet.width} × ${Tablet.tablet.height} mm` : "No tablet connected. What is set here applies once one is."
        textFormat: Text.PlainText
        color: Colors.text.muted
        font.family: Style.text.font
        font.pixelSize: Style.text.smallSize
    }

    Section {
        title: "AREA"
        // Above the sections after it, which its list opens over.
        z: 2

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

            // Last in the card: its list opens below it (.github/PROJECT_STRUCTURE.md,
            // "Qt 6.11 can stop delivering the pointer").
            FormRow {
                label: "Draws on"

                ChoiceField {
                    choices: [
                        {
                            label: "Every screen",
                            value: "all"
                        },
                        {
                            label: "The focused screen",
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

        Text {
            width: root.columnWidth
            wrapMode: Text.WordWrap
            text: "Keeping proportions leaves the tablet's edges unused where its shape differs from the screen's, so that circles stay round. SUPER+T holds it to the focused screen and SUPER+SHIFT+T to the focused window, until pressed again."
            color: Colors.text.muted
            font.family: Style.text.font
            font.pixelSize: Style.text.smallSize
        }
    }

    Section {
        title: "PRESSURE"
        z: 1

        FormCard {
            width: root.columnWidth

            FormRow {
                label: "Starts at"

                Row {
                    width: parent.width
                    height: Style.popup.itemHeight
                    spacing: Style.widgets.spacing

                    PanelSlider {
                        width: parent.width - Style.settings.labelWidth - Style.widgets.spacing
                        anchors.verticalCenter: parent.verticalCenter
                        value: Tablet.pressureMin / Tablet.startsAtMost
                        onMoved: position => Tablet.setPressure(Math.round(position * Tablet.startsAtMost * 100) / 100, Tablet.pressureMax)
                    }

                    Text {
                        width: Style.settings.labelWidth
                        anchors.verticalCenter: parent.verticalCenter
                        horizontalAlignment: Text.AlignRight
                        text: root.percent(Tablet.pressureMin)
                        color: Colors.text.muted
                        font.family: Style.text.font
                        font.pixelSize: Style.text.smallSize
                    }
                }
            }

            FormRow {
                label: "Full at"

                Row {
                    width: parent.width
                    height: Style.popup.itemHeight
                    spacing: Style.widgets.spacing

                    PanelSlider {
                        width: parent.width - Style.settings.labelWidth - Style.widgets.spacing
                        anchors.verticalCenter: parent.verticalCenter
                        value: (Tablet.pressureMax - Tablet.fullAtLeast) / (1 - Tablet.fullAtLeast)
                        onMoved: position => Tablet.setPressure(Tablet.pressureMin, Math.round((Tablet.fullAtLeast + position * (1 - Tablet.fullAtLeast)) * 100) / 100)
                    }

                    Text {
                        width: Style.settings.labelWidth
                        anchors.verticalCenter: parent.verticalCenter
                        horizontalAlignment: Text.AlignRight
                        text: root.percent(Tablet.pressureMax)
                        color: Colors.text.muted
                        font.family: Style.text.font
                        font.pixelSize: Style.text.smallSize
                    }
                }
            }
        }

        Text {
            width: root.columnWidth
            wrapMode: Text.WordWrap
            text: "Of the pen's whole range: a stroke starts once it presses harder than the first, and is at full strength from the second. Lower both for a lighter touch. Apps with a pressure curve of their own apply it on top."
            color: Colors.text.muted
            font.family: Style.text.font
            font.pixelSize: Style.text.smallSize
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

                    label: "Key " + (key.index + 1)
                    // Each list opens over the keys after it.
                    z: Tablet.padButtons - key.index

                    Column {
                        width: parent.width
                        spacing: Style.bar.spacing

                        ChoiceField {
                            choices: Tablet.actions.concat([
                                {
                                    label: "Shortcut…",
                                    value: "custom"
                                }
                            ])
                            current: key.custom ? "custom" : key.action
                            onPicked: action => Tablet.setButton(key.index, action === "custom" ? "keys:" : action)
                        }

                        InputField {
                            id: shortcut

                            readonly property bool valid: Tablet.shortcut(shortcut.text) !== null

                            visible: key.custom
                            width: Style.settings.fieldWidth
                            placeholder: "CTRL + SHIFT + z"
                            border.color: shortcut.text !== "" && !shortcut.valid ? Colors.status.error : shortcut.editing ? Colors.icon.active : Colors.base.border
                            Component.onCompleted: shortcut.text = key.action.slice(5)
                            onVisibleChanged: {
                                if (shortcut.visible)
                                    shortcut.text = key.action.slice(5);
                            }
                            onTextChanged: {
                                const action = "keys:" + shortcut.text.trim();
                                if (key.custom && shortcut.valid && action !== key.action)
                                    Tablet.setButton(key.index, action);
                            }
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
                    return "No pad seen yet: its keys show here once the tablet is connected.";
                if (Tablet.pad !== null && !Tablet.pad.readable)
                    return "The keys need the pad to be readable: run the installer's phase 4 again, or reconnect the tablet after it ran.";
                return "A shortcut goes to the focused window, as Hyprland names keys: modifiers, then a key such as z, F5 or Escape. While any key is set, apps no longer see the pad's keys themselves.";
            }
            color: Tablet.pad !== null && !Tablet.pad.readable ? Colors.status.error : Colors.text.muted
            font.family: Style.text.font
            font.pixelSize: Style.text.smallSize
        }
    }
}
