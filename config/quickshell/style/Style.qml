pragma Singleton
import QtQuick

QtObject{
	readonly property QtObject bar: QtObject{
	readonly property int height: 35
	readonly property int sideGap:14
	readonly property int topGap: 8
	readonly property int radius: 10
	readonly property int padding: 12
	readonly property int spacing: 8
	}

	readonly property QtObject border: QtObject{
	readonly property int width: 1
	}
	readonly property QtObject widgets: QtObject{
	readonly property int spacing: 4
}
	readonly property QtObject text: QtObject{
	readonly property int size: 13
	readonly property string font:      "JetBrainsMono Nerd Font"
	}

}
