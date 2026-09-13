// bar/widgets/SystemUsageWidget.qml
import QtQuick
import "../../services"
import "../../style"

Row {
    id: root

    spacing: Style.widgets.spacing

    Binding {
        target: SystemUsage
        property: "active"
        value: true
    }

    UsageMeter { value: SystemUsage.cpu }
    UsageMeter { value: SystemUsage.memory }
}
