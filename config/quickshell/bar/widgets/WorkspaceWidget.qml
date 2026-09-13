// bar/widgets/WorkspaceWidget.qml
//
// The Hyprland workspaces on this monitor, as dots: a small one for each
// workspace, a large one for the active workspace. Clicking the row opens the
// workspace dropdown (the same panel the three-finger swipe's left zone
// shows); clicking a dot switches to that workspace.
//
// Each dot sits in a fixed-width cell so the row keeps its geometry when the
// active workspace moves — the previous version widened the active pill,
// which shifted every dot to its right and made the row a moving target.
import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../panels"
import "../../style"

Item {
    id: root

    // The screen this bar instance belongs to (passed down from Bar.qml ->
    // BarContent.qml, same value PanelWindow.screen already gets in
    // Bar.qml). Used to show only the workspaces that live on this
    // monitor, per PROJECT_STRUCTURE.md's multi-monitor guidance.
    required property ShellScreen screen

    readonly property HyprlandMonitor monitor: screen ? Hyprland.monitorFor(screen) : null

    implicitWidth: row.implicitWidth
    implicitHeight: Style.bar.height

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.workspaces.spacing

        Repeater {
            model: Hyprland.workspaces

            delegate: Item {
                id: cell
                required property HyprlandWorkspace modelData

                // Only render workspaces that belong to this widget's
                // monitor; Hyprland.workspaces is global across monitors.
                visible: root.monitor !== null && cell.modelData.monitor === root.monitor
                width: visible ? Style.workspaces.cellSize : 0
                height: Style.workspaces.cellSize

                Rectangle {
                    id: dot

                    anchors.centerIn: parent
                    width: cell.modelData.active ? Style.workspaces.activeSize : Style.workspaces.size
                    height: width
                    radius: width / 2
                    // Three states rather than two: an empty workspace you
                    // could switch to reads differently from one holding
                    // windows.
                    color: cell.modelData.active ? Colors.workspaces.active
                        : cell.modelData.toplevels.values.length > 0 ? Colors.workspaces.occupied
                        : Colors.workspaces.inactive

                    Behavior on width {
                        NumberAnimation { duration: Style.animation.normal }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: cell.modelData.activate()
                }
            }
        }
    }

    // A click anywhere in the row that isn't on a dot opens the overview.
    // Declared after the Row so the per-dot areas, which are children of it,
    // win where they overlap.
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: workspacePopup.visible = !workspacePopup.visible
    }

    WidgetPopup {
        id: workspacePopup
        screen: root.screen
        anchorItem: root
        namespaceSuffix: "workspaces-popup"
        popupWidth: Style.dropdown.width
        popupHeight: Math.max(Style.popup.minHeight,
                              Math.min(Style.dropdown.maxHeight,
                                       panel.item ? panel.item.preferredHeight : Style.popup.minHeight))

        // Built per open, so a closed dropdown holds no bindings on the
        // window list (llm.md §15) — the same reason the gesture dropdown
        // loads its zones lazily.
        Loader {
            id: panel
            anchors.fill: parent
            active: workspacePopup.visible

            sourceComponent: WorkspacePanel {
                screen: root.screen
                onActivated: workspacePopup.visible = false
            }
        }
    }
}
