import QtQuick 2.5
import QtGraphicalEffects 1.0
import QtQuick.Layouts 1.1

import Material 0.3
import Material.Extras 0.1 as Circle
import Material.ListItems 0.1 as ListItem

ListItem.BaseListItem {
	id: listItem

	property alias text: label.text
	property alias valueText: valueLabel.text

	property alias action: actionItem.children
	property alias iconName: icon.name
	property alias iconSource: icon.source
	property alias imageSource: image.source
	property alias secondaryItem: secondaryItem.children
	property alias content: contentItem.children

	property alias itemLabel: label
	property alias itemValueLabel: valueLabel

	property alias textColor: label.color
	property alias iconColor: icon.color
	property alias spacing: row.spacing

	property bool isIcon: true

	implicitHeight: 48 * Units.dp
	height: 48 * Units.dp

	dividerInset: actionItem.visible ? listItem.height : 0

	interactive: contentItem.children.length === 0

	implicitWidth: {
		var width = listItem.margins * 2

		if (actionItem.visible)
			width += actionItem.width + row.spacing

		if (contentItem.visible)
			width += contentItem.implicitWidth + row.spacing
		else
			width += label.implicitWidth + row.spacing

		if (valueLabel.visible)
			width += valueLabel.width + row.spacing

		if (secondaryItem.visible)
			width += secondaryItem.width + row.spacing

		return width
	}

	RowLayout {
		id: row

		anchors {
			fill: parent
			leftMargin: listItem.margins/2
			rightMargin: listItem.margins/2
		}

		spacing: 16 * Units.dp

		Item {
			id: actionItem

			Layout.preferredWidth: 32 * Units.dp
			Layout.preferredHeight: width
			Layout.alignment: Qt.AlignCenter

			visible: children.length > 1 || icon.valid

			Icon {
				id: icon

				anchors {
					verticalCenter: parent.verticalCenter
					left: parent.left
					leftMargin: dp(6)
				}

				visible: valid
				color: listItem.selected ? Theme.primaryColor
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

				width: parent.height
				height: parent.height

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
                                fillMode: Image.PreserveAspectCrop
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

		ColumnLayout {
			Layout.alignment: Qt.AlignVCenter
			Layout.preferredHeight: parent.height

			Item {
				id: contentItem

				Layout.fillWidth: true
				Layout.preferredHeight: parent.height

				visible: children.length > 0
			}

			Label {
				id: label

				Layout.alignment: Qt.AlignVCenter
				Layout.fillWidth: true

				elide: Text.ElideRight
				style: "subheading"

				color: listItem.selected ? Theme.primaryColor
										: darkBackground ? Theme.dark.textColor
														 : Theme.light.textColor

				visible: !contentItem.visible
			}
		}

		Label {
			id: valueLabel

			Layout.alignment: Qt.AlignVCenter

			color: darkBackground ? Theme.dark.subTextColor : Theme.light.subTextColor
			elide: Text.ElideRight
			style: "body1"

			visible: text != ""
		}

		Item {
			id: secondaryItem

			Layout.alignment: Qt.AlignCenter
			Layout.preferredWidth: childrenRect.width
			Layout.preferredHeight: parent.height

			visible: children.length > 0
		}
	}
}
