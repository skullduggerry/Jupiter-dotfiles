import "../services"
import "../style"
import QtQuick
import Quickshell
import Quickshell.Hyprland

// Measures the wallpaper behind this screen's panels for Colors' adaptive
// glass, and hands it to Theme. The picture is drawn small, cropped as
// hyprpaper's cover mode crops it (the Image, decoded small, is only there for
// its proportions: a Canvas cannot draw an Image item it does not show), and
// read in its upper part, where the bar, the dropdowns and the toasts are, in
// blocks about the size of the blur. What it reports is the brightest and the
// darkest block: a bright corner under the bar's icons counts, a few stars in
// a night sky average away. A Canvas only paints in a window, which is why
// this lives in the bar's.
Item {
    id: root

    required property ShellScreen screen
    // Taken at the start: an unplugged screen is gone before its bar is.
    property string name: ""
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.screen)
    // Nothing to read while nothing would use it.
    readonly property string wallpaper: Theme.blur && Theme.adaptiveTint && root.monitor ? WallpaperService.wallpaperFor(root.monitor.activeWorkspace) : ""
    readonly property string source: root.wallpaper === "" ? "" : "file://" + root.wallpaper
    // The blur's size in the sample's units, which a stronger blur averages
    // over; a clear variant's glass averages nothing, so each sample counts.
    readonly property real block: Colors.base.clear ? 1 : Style.backdrop.blockSize * Theme.blurSize / Style.backdrop.blockBlurSize

    function load() {
        if (root.source === "")
            Theme.clearBackdrop(root.name);
        else
            canvas.loadImage(root.source);
    }

    // A channel as Hyprland's blur leaves it: its contrast, then its brightness.
    function blurred(channel: real): real {
        return ((channel - 0.5) * Style.backdrop.blurContrast + 0.5) * Style.backdrop.blurBrightness;
    }

    function measure() {
        if (picture.status !== Image.Ready || !canvas.isImageLoaded(root.source))
            return;

        const context = canvas.getContext("2d");
        const scale = Math.max(canvas.width / picture.implicitWidth, canvas.height / picture.implicitHeight);
        const width = picture.implicitWidth * scale;
        const height = picture.implicitHeight * scale;
        context.clearRect(0, 0, canvas.width, canvas.height);
        context.drawImage(root.source, (canvas.width - width) / 2, (canvas.height - height) / 2, width, height);
        canvas.unloadImage(root.source);

        // Each block's average is what the blur makes of that patch. The
        // drawing is in the window's units, the image data in its pixels.
        const ratio = root.screen.devicePixelRatio;
        const block = Math.max(1, Math.round(root.block * ratio));
        const columns = Math.floor(canvas.width * ratio / block);
        const rows = Math.max(1, Math.floor(canvas.height * ratio * Style.backdrop.coverage / block));
        const data = context.getImageData(0, 0, columns * block, rows * block).data;
        const stride = columns * block * 4;
        let brightest = null;
        let darkest = null;
        for (let row = 0; row < rows; row++) {
            for (let column = 0; column < columns; column++) {
                let red = 0;
                let green = 0;
                let blue = 0;
                for (let y = row * block; y < (row + 1) * block; y++) {
                    for (let x = column * block; x < (column + 1) * block; x++) {
                        const index = y * stride + x * 4;
                        red += data[index];
                        green += data[index + 1];
                        blue += data[index + 2];
                    }
                }
                const count = block * block * 255;
                const patch = Qt.rgba(root.blurred(red / count), root.blurred(green / count), root.blurred(blue / count), 1);
                const luminance = Colors.luminance(patch);
                if (brightest === null || luminance > brightest.luminance)
                    brightest = {
                        colour: patch,
                        luminance: luminance
                    };
                if (darkest === null || luminance < darkest.luminance)
                    darkest = {
                        colour: patch,
                        luminance: luminance
                    };
            }
        }
        Theme.setBackdrop(root.name, brightest.colour, darkest.colour);
    }

    visible: false
    onSourceChanged: root.load()
    onBlockChanged: root.load()
    Component.onCompleted: {
        root.name = root.screen.name;
        root.load();
    }
    Component.onDestruction: Theme.clearBackdrop(root.name)

    Image {
        id: picture

        source: root.source
        sourceSize.width: Style.backdrop.sampleWidth
        asynchronous: true
        onStatusChanged: canvas.requestPaint()
    }

    Canvas {
        id: canvas

        width: Style.backdrop.sampleWidth
        height: root.screen === null ? 1 : Math.max(1, Math.round(canvas.width * root.screen.height / root.screen.width))
        onPaint: root.measure()
        onImageLoaded: canvas.requestPaint()
    }
}
