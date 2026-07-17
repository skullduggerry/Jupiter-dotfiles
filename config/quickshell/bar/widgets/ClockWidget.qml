import QtQuick
import "../../style"
Text {  
	text: Time.time
	color: Colors.text.base
	font.pixelSize: Style.text.size
	font.family: Style.text.font
}
