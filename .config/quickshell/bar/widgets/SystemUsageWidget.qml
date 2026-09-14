import "../../services"
import "../../style"
import QtQuick

Row {
    id: root

    spacing: Style.widgets.spacing

    Binding {
        target: SystemUsage
        property: "active"
        value: true
    }

    UsageMeter {
        value: SystemUsage.cpu
    }

    UsageMeter {
        value: SystemUsage.memory
    }

}
