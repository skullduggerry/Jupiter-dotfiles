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
}
