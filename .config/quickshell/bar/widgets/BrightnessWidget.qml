import "../../icons"
import "../../services"
import "../../style"
import QtQuick

Item {
    id: root

    required property QuickPager pager
    // The bar's drawer is out, so the icon is on screen.
    required property bool shown
    property bool counted: false
    readonly property list<string> ramp: [Icons.sunDim, Icons.sunMedium, Icons.sun]

    // Counted while shown, so the level is read meanwhile; as BrightnessPanel.
    function syncViewer() {
        if (root.shown === root.counted)
            return;

        Brightness.viewers += root.shown ? 1 : -1;
        root.counted = root.shown;
    }

    visible: Brightness.available
    onShownChanged: root.syncViewer()
    Component.onCompleted: root.syncViewer()
    Component.onDestruction: {
        if (root.counted)
            Brightness.viewers -= 1;
    }
    implicitWidth: visible ? icon.implicitWidth + Style.widgets.padding * 2 : 0
    implicitHeight: Style.bar.height

    Binding {
        target: Brightness
        property: "active"
        value: true
    }

    Icon {
        id: icon

        anchors.centerIn: parent
        text: root.ramp[Math.round(Brightness.fraction * (root.ramp.length - 1))]
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.pager.toggleAt(root.pager.pageBrightness, root)
        onWheel: wheel => Brightness.adjust(wheel.angleDelta.y > 0 ? Brightness.step : -Brightness.step)
    }
}
