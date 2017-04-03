import QtQuick 2.5
import QtQuick.Layouts 1.1

import Material 0.3
import Material.ListItems 0.1 as ListItem

ListItem.BaseListItem {
	id: listItem

	property alias text: label.text

	property alias action: actionItem.children
	property alias iconName: icon.name
	property alias iconSource: icon.source

	property alias itemLabel: label

	property alias textColor: label.color
	property alias iconColor: icon.color
	property alias spacing: row.spacing

	implicitHeight: dp(48)
	height: dp(48)

	dividerInset: actionItem.visible ? listItem.height : 0

	implicitWidth: {
		var width = listItem.margins * 2

		if (actionItem.visible)
			width += actionItem.width + row.spacing

		width += label.implicitWidth + row.spacing
		return width
	}

	RowLayout {
		id: row

		anchors {
			fill: parent
			leftMargin: listItem.margins
			rightMargin: listItem.margins
		}

		spacing: dp(16)

		ColumnLayout {
			Layout.alignment: Qt.AlignVCenter
			Layout.preferredHeight: parent.height

			Label {
				id: label

				Layout.alignment: Qt.AlignVCenter
				Layout.fillWidth: true

				elide: Text.ElideRight
				style: "subheading"

				color: listItem.selected ? Theme.primaryColor
										: darkBackground ? Theme.dark.textColor : Theme.light.textColor
			}
		}

		Item {
			id: actionItem

			Layout.preferredWidth: dp(40)
			Layout.preferredHeight: width
			Layout.alignment: Qt.AlignCenter

			visible: children.length > 1 || icon.valid

			Icon {
				id: icon

				anchors {
					verticalCenter: parent.verticalCenter
					left: parent.left
				}

				visible: valid
				color: listItem.selected ? Theme.primaryColor
										: darkBackground ? Theme.dark.iconColor : Theme.light.iconColor

				size: dp(20)
			}
		}
	}
}
