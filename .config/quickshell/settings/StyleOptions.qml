import "../panels"
import "../style"
import QtQuick

// The Appearance page's Style tab, the design's Appearance page. Light and
// Dark are the last light and the last dark wallust theme applied (Theme
// remembers both); the accent and the font reach the apps too when themes
// apply to them.
Column {
    id: root

    readonly property bool light: Colors.palette.background.hslLightness > 0.5
    // The TINT section's line: what the tint is now, and why.
    readonly property string tintText: {
        const least = root.percent(Colors.base.glassFloor);
        const themes = root.light ? "light themes" : "dark themes";
        const apps = Theme.applyToApps ? " Kitty follows at once, Qt apps when next opened." : "";
        if (!Theme.adaptiveTint)
            return `${least} in ${themes}, whatever the wallpaper behind.${apps}`;
        if (Colors.base.glassCeiling <= Colors.base.glassFloor)
            return `${least} in ${themes}, past where Adaptive would stop raising it.${apps}`;
        return `At least ${least} in ${themes}, raised up to ${root.percent(Colors.base.glassCeiling)} where the wallpaper behind would make text hard to read: ${root.percent(Colors.base.opacity)} now.${apps}`;
    }

    function percent(share: real): string {
        return Math.round(share * 100) + "%";
    }

    spacing: Style.settings.spacing

    Section {
        title: "THEME"

        Row {
            spacing: Style.settings.spacing

            PillGroup {
                choices: [
                    {
                        label: "Light",
                        value: true
                    },
                    {
                        label: "Dark",
                        value: false
                    }
                ]
                current: root.light
                onPicked: light => Theme.apply(light ? Theme.lightTheme : Theme.darkTheme)
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Theme.error !== "" ? Theme.error : Theme.applying ? "Applying…" : Theme.theme
                color: Theme.error !== "" ? Colors.status.error : Colors.text.muted
                font.family: Style.text.font
                font.pixelSize: Style.text.smallSize
            }
        }
    }

    Section {
        title: "ACCENT COLOR"

        Row {
            spacing: Style.settings.swatchSpacing

            Repeater {
                model: Colors.accentNames

                delegate: Rectangle {
                    id: swatch

                    required property string modelData
                    readonly property bool selected: Theme.accent === swatch.modelData

                    width: Style.settings.swatchSize
                    height: Style.settings.swatchSize
                    radius: width / 2
                    color: Colors.accentColor(swatch.modelData)
                    border.width: swatch.selected ? Style.settings.swatchRing : 0
                    border.color: Colors.text.base

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Theme.setAccent(swatch.modelData)
                    }
                }
            }
        }
    }

    Section {
        title: "FONT"
        // Above the sections after it, which its list opens over.
        z: 1

        // Every installed family, each written in itself, the shell's own first.
        ChoiceField {
            id: fontField

            readonly property list<string> families: [Style.text.defaultFont].concat(Qt.fontFamilies().filter(family => family !== Style.text.defaultFont))

            choices: fontField.families.map(family => ({
                        label: family,
                        value: family,
                        detail: family === Style.text.defaultFont ? "default" : "",
                        font: family
                    }))
            current: Style.text.font
            searchable: true
            listWidth: Style.settings.pageWidth
            onPicked: family => Theme.setFont(family === Style.text.defaultFont ? "" : family)
        }
    }

    Section {
        title: "PANELS"

        // Frosted glass, or opaque for a wallpaper too light to read the bar over.
        PillGroup {
            choices: [
                {
                    label: "Blur",
                    value: true
                },
                {
                    label: "Solid",
                    value: false
                }
            ]
            current: Theme.blur
            onPicked: blur => Theme.setBlur(blur)
        }
    }

    // How much of the glass is the theme's background over the blur. The
    // slider sets the least, for dark and for light themes apart; Adaptive
    // raises it where the wallpaper behind would make text hard to read, and
    // Static keeps to it. The line under the slider says which, in numbers.
    Section {
        visible: Theme.blur
        title: "TINT"

        PillGroup {
            choices: [
                {
                    label: "Adaptive",
                    value: true
                },
                {
                    label: "Static",
                    value: false
                }
            ]
            current: Theme.adaptiveTint
            onPicked: adaptive => Theme.setAdaptiveTint(adaptive)
        }

        Row {
            width: Style.settings.pageWidth
            spacing: Style.widgets.spacing

            PanelSlider {
                width: parent.width - Style.settings.labelWidth - Style.widgets.spacing
                anchors.verticalCenter: parent.verticalCenter
                value: (Colors.base.glassFloor - Colors.tintLeast) / (Colors.tintMost - Colors.tintLeast)
                onMoved: position => Theme.setTint(Colors.light, Math.round((Colors.tintLeast + position * (Colors.tintMost - Colors.tintLeast)) * 100) / 100)
            }

            Text {
                width: Style.settings.labelWidth
                anchors.verticalCenter: parent.verticalCenter
                horizontalAlignment: Text.AlignRight
                text: root.percent(Colors.base.glassFloor)
                color: Colors.text.muted
                font.family: Style.text.font
                font.pixelSize: Style.text.smallSize
            }
        }

        Text {
            width: Style.settings.pageWidth
            wrapMode: Text.WordWrap
            text: root.tintText
            color: Colors.text.muted
            font.family: Style.text.font
            font.pixelSize: Style.text.smallSize
        }
    }
}
