import "../../panels"
import "../../style"
import QtQuick

WidgetPopup {
    id: root

    readonly property alias pageBattery: settings.pageBattery
    readonly property alias pageWifi: settings.pageWifi
    readonly property alias pageBluetooth: settings.pageBluetooth
    readonly property alias pageAudio: settings.pageAudio
    readonly property alias pageBrightness: settings.pageBrightness

    function openAt(page: int, anchor: Item) {
        root.anchorItem = anchor;
        settings.currentIndex = page;
        root.visible = true;
    }

    function toggleAt(page: int, anchor: Item) {
        if (root.visible && settings.currentIndex === page)
            root.visible = false;
        else
            root.openAt(page, anchor);
    }

    onWheeled: (deltaX, deltaY) => {
        if (Math.abs(deltaX) < Math.abs(deltaY))
            return ;

        settings.swipe(deltaX);
    }
    namespaceSuffix: "quicksettings-popup"
    popupWidth: Style.pager.width
    popupHeight: Style.pager.height

    QuickSettingsPanel {
        id: settings

        anchors.fill: parent
        active: root.visible
    }

}
