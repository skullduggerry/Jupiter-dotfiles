pragma Singleton

import QtQuick

// Hyprland's decoration:blur variants (0.57) as the Settings app offers them:
// `value` is the option's number, `options` the sub-options each reads, with
// the default (Hyprland's, but for acrylic's clarity) and the range offered
// (narrower than Hyprland's where the rest is unusable). Colours are not among them: Colors derives those
// from the theme (Colors.base.glassTint and the like).
//
// `clear` variants show the backdrop sharp through the glass rather than
// blurred (acrylic's lens, prism's facets), which Adaptive tint measures so;
// `specular` draws its own curved rim, which the shell's glass edges follow;
// `animated` ones redraw every frame, `interactive` ones on clicks or the
// pointer. Pure data: the greeter loads style/ too.
QtObject {
    id: root

    // The glass relief frost, prism, drops, heat shimmer and aurora share.
    readonly property var glassOptions: [
        {
            key: "glass.refraction",
            label: "Refraction",
            fallback: 20,
            least: 0,
            most: 20,
            step: 1,
            unit: "px"
        },
        {
            key: "glass.size",
            label: "Pattern",
            fallback: 40,
            least: 8,
            most: 160,
            step: 1,
            unit: "px"
        },
        {
            key: "glass.roughness",
            label: "Relief",
            fallback: 1,
            least: 0,
            most: 1,
            step: 0.05,
            unit: "%"
        }
    ]

    readonly property var variants: [
        {
            name: "kawase",
            value: 0,
            label: "Kawase",
            about: "Plain blur, the lightest on the GPU.",
            options: []
        },
        {
            name: "frost",
            value: 1,
            label: "Frost",
            about: "Blur behind a frosted pane with a fine relief.",
            options: root.glassOptions
        },
        {
            name: "acrylic",
            value: 8,
            label: "Acrylic",
            about: "Liquid glass: a clear pane whose curved rim bends and blurs what is behind it. Over a busy wallpaper, lower Clarity or set Tint to Adaptive.",
            clear: true,
            specular: true,
            options: [
                {
                    key: "acrylic.clarity",
                    label: "Clarity",
                    // Hyprland's 0.82 shows the backdrop nearly sharp under
                    // the shell's text, a busy wallpaper's detail and all.
                    fallback: 0.35,
                    least: 0,
                    most: 1,
                    step: 0.01,
                    unit: "%"
                },
                {
                    key: "acrylic.bulb",
                    label: "Rim",
                    fallback: 48,
                    least: 4,
                    most: 96,
                    step: 1,
                    unit: "px"
                },
                {
                    key: "acrylic.refraction",
                    label: "Refraction",
                    fallback: 24,
                    least: 0,
                    most: 48,
                    step: 1,
                    unit: "px"
                },
                {
                    key: "acrylic.aberration",
                    label: "Dispersion",
                    fallback: 0.025,
                    least: 0,
                    most: 0.25,
                    step: 0.005,
                    unit: "%"
                }
            ]
        },
        {
            name: "prism",
            value: 6,
            label: "Prism",
            about: "The backdrop through cut glass, split into facets with rainbow edges.",
            clear: true,
            options: root.glassOptions
        },
        {
            name: "haze",
            value: 10,
            label: "Haze",
            about: "Blur with a pearly sheen that shifts colour.",
            options: [
                {
                    key: "haze.intensity",
                    label: "Sheen",
                    fallback: 0.35,
                    least: 0,
                    most: 1,
                    step: 0.01,
                    unit: "%"
                },
                {
                    key: "haze.iridescence",
                    label: "Iridescence",
                    fallback: 0.7,
                    least: 0,
                    most: 1,
                    step: 0.01,
                    unit: "%"
                }
            ]
        },
        {
            name: "aurora",
            value: 9,
            label: "Aurora",
            about: "Blur lit by drifting curtains in the accent and a second theme colour.",
            animated: true,
            options: root.glassOptions.concat([
                {
                    key: "aurora.intensity",
                    label: "Glow",
                    fallback: 0.35,
                    least: 0,
                    most: 1,
                    step: 0.01,
                    unit: "%"
                },
                {
                    key: "aurora.speed",
                    label: "Speed",
                    fallback: 1,
                    least: 0,
                    most: 3,
                    step: 0.1,
                    unit: "×"
                }
            ])
        },
        {
            name: "drops",
            value: 3,
            label: "Drops",
            about: "Raindrops running down frosted glass.",
            animated: true,
            options: root.glassOptions.concat([
                {
                    key: "drops.speed",
                    label: "Speed",
                    fallback: 3,
                    least: 0,
                    most: 10,
                    step: 0.1,
                    unit: "×"
                }
            ])
        },
        {
            name: "heat_shimmer",
            value: 7,
            label: "Heat shimmer",
            about: "Blur that wavers as air over a hot road.",
            animated: true,
            options: root.glassOptions.concat([
                {
                    key: "heat_shimmer.speed",
                    label: "Speed",
                    fallback: 1,
                    least: 0,
                    most: 5,
                    step: 0.1,
                    unit: "×"
                }
            ])
        },
        {
            name: "ripple",
            value: 2,
            label: "Ripple",
            about: "Blur that ripples out from each click.",
            interactive: true,
            options: [
                {
                    key: "ripple.strength",
                    label: "Strength",
                    fallback: 30,
                    least: 0,
                    most: 32,
                    step: 1,
                    unit: "px"
                },
                {
                    key: "ripple.radius",
                    label: "Reach",
                    fallback: 400,
                    least: 50,
                    most: 1000,
                    step: 10,
                    unit: "px"
                },
                {
                    key: "ripple.width",
                    label: "Wave",
                    fallback: 32,
                    least: 4,
                    most: 128,
                    step: 1,
                    unit: "px"
                },
                {
                    key: "ripple.duration",
                    label: "Duration",
                    fallback: 0.45,
                    least: 0.1,
                    most: 2,
                    step: 0.05,
                    unit: "s"
                }
            ]
        },
        {
            name: "water",
            value: 4,
            label: "Water",
            about: "Blur like a water surface, stirred by the pointer.",
            animated: true,
            interactive: true,
            options: [
                {
                    key: "water.strength",
                    label: "Strength",
                    fallback: 32,
                    least: 0,
                    most: 32,
                    step: 1,
                    unit: "px"
                },
                {
                    key: "water.radius",
                    label: "Reach",
                    fallback: 20,
                    least: 5,
                    most: 200,
                    step: 1,
                    unit: "px"
                },
                {
                    key: "water.speed",
                    label: "Speed",
                    fallback: 0.76,
                    least: 0,
                    most: 3,
                    step: 0.01,
                    unit: "×"
                },
                {
                    key: "water.damping",
                    label: "Calming",
                    fallback: 0.95,
                    least: 0.8,
                    most: 0.99,
                    step: 0.01,
                    unit: "%"
                },
                {
                    key: "water.duration",
                    label: "Settles after",
                    fallback: 12,
                    least: 1,
                    most: 30,
                    step: 0.5,
                    unit: "s"
                }
            ]
        },
        {
            name: "fluid_jar",
            value: 5,
            label: "Fluid jar",
            about: "Blur over a liquid in the accent colour that sloshes as windows move.",
            animated: true,
            options: [
                {
                    key: "fluid_jar.fill_amount",
                    label: "Fill",
                    fallback: 0.5,
                    least: 0,
                    most: 1,
                    step: 0.01,
                    unit: "%"
                },
                {
                    key: "fluid_jar.speed",
                    label: "Speed",
                    fallback: 3.7,
                    least: 0,
                    most: 10,
                    step: 0.1,
                    unit: "×"
                },
                {
                    key: "fluid_jar.mass",
                    label: "Weight",
                    fallback: 1.4,
                    least: 0.1,
                    most: 10,
                    step: 0.1,
                    unit: "×"
                },
                {
                    key: "fluid_jar.turbulence",
                    label: "Turbulence",
                    fallback: 1.2,
                    least: 0,
                    most: 5,
                    step: 0.1,
                    unit: "×"
                },
                {
                    key: "fluid_jar.distortion",
                    label: "Distortion",
                    fallback: 8,
                    least: 0,
                    most: 10,
                    step: 0.1,
                    unit: "×"
                },
                {
                    key: "fluid_jar.precision",
                    label: "Precision",
                    fallback: 2,
                    least: 1,
                    most: 4,
                    step: 0.5,
                    unit: "×"
                }
            ]
        }
    ]

    // The variant called name, or Kawase for a name this Hyprland lacks.
    function find(name: string): var {
        return root.variants.find(variant => variant.name === name) ?? root.variants[0];
    }

    // Every sub-option any variant reads, once each, at the value picked
    // (chosen, by key) or Hyprland's default: written whole, so a value set
    // back to its default reaches the running Hyprland too.
    function effective(chosen: var): var {
        const values = {};
        for (let index = 0; index < root.variants.length; index++) {
            const options = root.variants[index].options;
            for (let option = 0; option < options.length; option++) {
                const key = options[option].key;
                values[key] = chosen && chosen[key] !== undefined ? chosen[key] : options[option].fallback;
            }
        }
        return values;
    }
}
