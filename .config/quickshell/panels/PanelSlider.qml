import "../style"
import QtQuick

Item {
    id: root

    required property real value

    signal moved(real position)

    function positionAt(x: real): real {
        return Math.max(0, Math.min(1, x / root.width));
    }

    implicitHeight: Style.slider.height

    Rectangle {
        id: track

        height: Style.slider.track
        radius: height / 2
        color: Colors.base.hover

        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
        }

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, root.value))
            radius: parent.radius
            color: Colors.icon.active

            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
            }

            Behavior on width {
                NumberAnimation {
                    duration: Style.animation.fast
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onPressed: mouse => root.moved(root.positionAt(mouse.x))
        onPositionChanged: mouse => {
            if (pressed)
                root.moved(root.positionAt(mouse.x));
        }
    }
}
