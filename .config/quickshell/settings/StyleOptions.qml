pragma ComponentBehavior: Bound

import "../panels"
import "../services"
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
        const apps = Theme.applyToApps ? " Kitty and GTK 3 apps follow at once, Qt and GTK 4 apps when next opened." : "";
        if (!Theme.adaptiveTint)
            return `${least} in ${themes}, whatever the wallpaper behind.${apps}`;
        if (Colors.base.glassCeiling <= Colors.base.glassFloor)
            return `${least} in ${themes}, past where Adaptive would stop raising it.${apps}`;
        return `At least ${least} in ${themes}, raised up to ${root.percent(Colors.base.glassCeiling)} where the wallpaper behind would make text hard to read: ${root.percent(Colors.base.opacity)} now.${apps}`;
    }

    function percent(share: real): string {
        return Math.round(share * 100) + "%";
    }

    // What sets a blur variant apart in its list: how it shows the backdrop
    // and what it costs.
    function traits(variant: var): string {
        const traits = [];
        if (variant.clear)
            traits.push("clear");
        if (variant.animated)
            traits.push("animated");
        if (variant.interactive)
            traits.push("follows the pointer");
        return traits.join(", ");
    }

    // A slider's value on its option's steps, without the float's dust.
    function snapped(option: var, value: real): real {
        const least = Number(option.least);
        const step = Number(option.step);
        return Math.round((least + Math.round((value - least) / step) * step) * 10000) / 10000;
    }

    function formatted(option: var, value: real): string {
        switch (option.unit) {
        case "%":
            return Number((value * 100).toFixed(1)) + "%";
        case "px":
            return Math.round(value) + " px";
        case "s":
            return Number(value.toFixed(2)) + " s";
        default:
            return Number(value.toFixed(1)) + option.unit;
        }
    }

    spacing: Style.settings.spacing

    Section {
        title: "THEME"

        FormCard {
            width: Style.settings.pageWidth

            FormRow {
                label: "Mode"

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
                        textFormat: Text.PlainText
                        color: Theme.error !== "" ? Colors.status.error : Colors.text.muted
                        font.family: Style.text.font
                        font.pixelSize: Style.text.smallSize
                    }
                }
            }

            FormRow {
                label: "Accent"

                Row {
                    height: Style.popup.itemHeight
                    spacing: Style.settings.swatchSpacing

                    Repeater {
                        model: Colors.accentNames

                        delegate: Rectangle {
                            id: swatch

                            required property string modelData
                            readonly property bool selected: Theme.accent === swatch.modelData

                            anchors.verticalCenter: parent.verticalCenter
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

            // Every installed family, each written in itself, the shell's own first.
            FormRow {
                label: "Font"

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
                    width: parent.width
                    searchable: true
                    onPicked: family => Theme.setFont(family === Style.text.defaultFont ? "" : family)
                }
            }
        }
    }

    // Frosted glass, or opaque for a wallpaper too light to read the bar over.
    // Over glass, Hyprland's blur variant (BlurVariants) and its options, how
    // strongly Hyprland blurs what is behind, and how much of
    // the glass is the theme's background: the slider sets the least, for dark
    // and for light themes apart; Adaptive raises it where the wallpaper behind
    // would make text hard to read, and Static keeps to it. The line under the
    // slider says which, in numbers. Then whether the dropdowns fade in and
    // out, as Hyprland shows any panel, or swoosh out of the bar and back, and
    // last how the quick menu is drawn, and with Halo whether it shows labels
    // (the pencil at its centre offers the same choices).
    Section {
        title: "PANELS"

        FormCard {
            width: Style.settings.pageWidth

            FormRow {
                label: "Surface"

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

            // Hyprland's blur variant, what it looks like and costs, and back
            // to the defaults (BlurVariants) for its options below.
            FormRow {
                visible: Theme.blur
                label: "Material"

                Column {
                    width: parent.width
                    spacing: Style.bar.spacing

                    ChoiceField {
                        width: parent.width
                        choices: BlurVariants.variants.map(variant => ({
                                    label: variant.label,
                                    value: variant.name,
                                    detail: root.traits(variant)
                                }))
                        current: Colors.base.variant.name
                        onPicked: name => Theme.setBlurVariant(name)
                    }

                    Text {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: Colors.base.variant.about + (Colors.base.variant.animated ? " Redrawn every frame, so it costs GPU time while anything blurred is on screen." : "")
                        color: Colors.text.muted
                        font.family: Style.text.font
                        font.pixelSize: Style.text.smallSize
                    }

                    TextButton {
                        visible: Colors.base.variant.options.some(option => Theme.blurOptions[option.key] !== undefined)
                        text: "Defaults"
                        onClicked: Theme.resetBlurOptions(Colors.base.variant.options.map(option => option.key))
                    }
                }
            }

            FormRow {
                visible: Theme.blur
                label: "Blur"

                Row {
                    width: parent.width
                    height: Style.popup.itemHeight
                    spacing: Style.widgets.spacing

                    PanelSlider {
                        width: parent.width - Style.settings.labelWidth - Style.widgets.spacing
                        anchors.verticalCenter: parent.verticalCenter
                        value: (Theme.blurSize - Style.blur.least) / (Style.blur.most - Style.blur.least)
                        onMoved: position => Theme.setBlurSize(Math.round(Style.blur.least + position * (Style.blur.most - Style.blur.least)))
                    }

                    Text {
                        width: Style.settings.labelWidth
                        anchors.verticalCenter: parent.verticalCenter
                        horizontalAlignment: Text.AlignRight
                        text: Theme.blurSize
                        color: Colors.text.muted
                        font.family: Style.text.font
                        font.pixelSize: Style.text.smallSize
                    }
                }
            }

            // The variant's own options, each from its least to its most.
            Repeater {
                model: Colors.base.variant.options

                delegate: FormRow {
                    id: option

                    required property var modelData
                    readonly property real current: BlurVariants.effective(Theme.blurOptions)[option.modelData.key]
                    readonly property real range: option.modelData.most - option.modelData.least

                    label: option.modelData.label

                    Row {
                        width: parent.width
                        height: Style.popup.itemHeight
                        spacing: Style.widgets.spacing

                        PanelSlider {
                            width: parent.width - Style.settings.labelWidth - Style.widgets.spacing
                            anchors.verticalCenter: parent.verticalCenter
                            value: (option.current - option.modelData.least) / option.range
                            onMoved: position => Theme.setBlurOption(option.modelData.key, root.snapped(option.modelData, option.modelData.least + position * option.range))
                        }

                        Text {
                            width: Style.settings.labelWidth
                            anchors.verticalCenter: parent.verticalCenter
                            horizontalAlignment: Text.AlignRight
                            text: root.formatted(option.modelData, option.current)
                            color: Colors.text.muted
                            font.family: Style.text.font
                            font.pixelSize: Style.text.smallSize
                        }
                    }
                }
            }

            FormRow {
                visible: Theme.blur
                label: "Tint"

                Column {
                    width: parent.width
                    spacing: Style.bar.spacing

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
                        width: parent.width
                        height: Style.popup.itemHeight
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
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: root.tintText
                        color: Colors.text.muted
                        font.family: Style.text.font
                        font.pixelSize: Style.text.smallSize
                    }
                }
            }

            FormRow {
                label: "Dropdowns"

                PillGroup {
                    choices: [
                        {
                            label: "Fade",
                            value: false
                        },
                        {
                            label: "Swoosh",
                            value: true
                        }
                    ]
                    current: Theme.swoosh
                    onPicked: swoosh => Theme.setSwoosh(swoosh)
                }
            }

            FormRow {
                label: "Quick menu"

                Column {
                    width: parent.width
                    spacing: Style.bar.spacing

                    PillGroup {
                        choices: QuickMenu.looks.map(look => ({
                                    label: look.charAt(0).toUpperCase() + look.slice(1),
                                    value: look
                                }))
                        current: QuickMenu.look
                        onPicked: look => QuickMenu.setLook(look)
                    }

                    Text {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: {
                            switch (QuickMenu.look) {
                            case "halo":
                                return "One disc, its items in a band beside it.";
                            case "orbit":
                                return "A round button for each item, on a ring.";
                            }
                            return `Orbit over Blur, Halo over Solid: ${Theme.blur ? "Orbit" : "Halo"} now.`;
                        }
                        color: Colors.text.muted
                        font.family: Style.text.font
                        font.pixelSize: Style.text.smallSize
                    }
                }
            }

            // Orbit has none: it names what is selected in its hub.
            FormRow {
                visible: QuickMenu.look === "halo" || (QuickMenu.look === "auto" && !Theme.blur)
                label: "Menu labels"

                PillGroup {
                    choices: [
                        {
                            label: "Shown",
                            value: true
                        },
                        {
                            label: "Hidden",
                            value: false
                        }
                    ]
                    current: QuickMenu.labels
                    onPicked: labels => QuickMenu.setLabels(labels)
                }
            }
        }
    }
}
