import QtQuick 2.5

import Material 0.3
import Material.Extras 0.1 as Circle

Rectangle {
	id: roomFriend

	property alias text: label.text
	property alias itemLabel: label
	property alias textColor: label.color

	property bool isIcon: true
	property alias iconName: icon.name
	property alias iconSource: icon.source
	property alias iconSize: icon.size
	property alias iconColor: icon.color

	property alias imageSource: image.source

	property bool containMouse
	property bool darkBackground
	property bool selected

	signal entered()
	signal exited()
	signal clicked()

	height: dp(48)
	color: containMouse ? Qt.rgba(0,0,0,0.03) : Qt.rgba(0,0,0,0)

	MouseArea {
		anchors.fill: parent

		z: -1
		hoverEnabled: true

		onClicked: roomFriend.clicked()
		onEntered: {
			containMouse = true
			roomFriend.entered()
		}
		onExited: {
			containMouse = false
			roomFriend.exited()
		}
	}

	Item {
		id: actionItem

		anchors {
			left: parent.left
			top: parent.top
			bottom: parent.bottom
			leftMargin: dp(8)
		}

		width: dp(48)

		visible: children.length > 1 || icon.valid

		Icon {
			id: icon

			anchors {
				verticalCenter: parent.verticalCenter
				horizontalCenter: parent.horizontalCenter
			}

			visible: isIcon
			color: roomFriend.selected ? Theme.primaryColor
									: darkBackground ? Theme.dark.iconColor
													 : Theme.light.iconColor

			size: 24 * Units.dp
		}

		Canvas {
			id: image

			property string source

			anchors {
				verticalCenter: parent.verticalCenter
				horizontalCenter: parent.horizontalCenter
			}

			width: dp(32)
			height: dp(32)

			visible: !isIcon

			onSourceChanged: loadImage(source)
			Component.onCompleted: loadImage(source)
			onPaint: {
				var ctx = getContext("2d");
				if (image.isImageLoaded(source)) {
					var profile = Qt.createQmlObject('
                        import QtQuick 2.5;
                        Image{
                            source: "'+source+'";
                            visible:false;
                            /*fillMode: Image.PreserveAspectCrop*/
                        }', image);

					var centreX = width/2;
					var centreY = height/2;

					ctx.save()
					ctx.beginPath();
					ctx.moveTo(centreX, centreY);
					ctx.arc(centreX, centreY, width / 2, 0, Math.PI * 2, false);
					ctx.clip();
					ctx.drawImage(profile, 0, 0, image.width, image.height);
					ctx.restore()
				}
			}
			onImageLoaded:requestPaint()
		}
	}

	Label {
		id: label

		anchors {
			right: parent.right
			left: actionItem.right
			verticalCenter: parent.verticalCenter
			rightMargin: dp(8)
			leftMargin: dp(8)
		}

		elide: Text.ElideRight
		style: "subheading"

		color: roomFriend.selected ? Theme.primaryColor
								: darkBackground ? Theme.dark.textColor
												 : Theme.light.textColor
	}
}
