// bar/widgets/SystemUsageWidget.qml
//
// CPU and memory load, next to the workspace dots. CPU first, memory second.
//
// Two glyphs, no text — the pattern the waybar config used for brightness.
// The two are told apart by position rather than by a label, the way a status
// bar's icons always are; a letter next to each would cost more clarity in
// clutter than it bought in precision.
import QtQuick
import "../../services"
import "../../style"

Row {
    id: root

    spacing: Style.widgets.spacing

    // Nothing else in the shell displays load, so this widget is what turns
    // the sampler on — and it holds it on for its own lifetime, which is the
    // bar's.
    Binding {
        target: SystemUsage
        property: "active"
        value: true
    }

    UsageMeter { value: SystemUsage.cpu }
    UsageMeter { value: SystemUsage.memory }
}
