/****************************************************************
 *  This file is part of Emoty.
 *  Emoty is distributed under the following license:
 *
 *  Copyright (C) 2017, Konrad Dębiec
 *
 *  Emoty is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU General Public License
 *  as published by the Free Software Foundation; either version 3
 *  of the License, or (at your option) any later version.
 *
 *  Emoty is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin Street, Fifth Floor,
 *  Boston, MA  02110-1301, USA.
 ****************************************************************/

import QtQuick 2.5
import QtQuick.Layouts 1.1

import Material 0.3
import Material.ListItems 0.1 as ListItem
import Material.Extras 0.1 as Circle

ListItem.BaseListItem {
	id: listItem

	property bool isIcon
	property string srcIcon
	property bool rotate

	property alias action: actionItem.children
	property alias iconName: icon.name
	property alias iconSource: icon.source
	property alias iconColor: icon.color
	property alias iconSize: icon.size
	property string name

	implicitHeight: 48 * Units.dp
	height: 48 * Units.dp

	onEntered: {
		if(rotate)
			icon.rotation = 90
	}

	onExited:{
		if(rotate)
			icon.rotation = 0
	}

	dividerInset: actionItem.visible ? listItem.height : 0

	implicitWidth: {
		var width = listItem.margins * 2

		if (actionItem.visible)
			width += actionItem.width + row.spacing
		return width
	}

	RowLayout {
		id: row

		anchors {
			fill: parent
			leftMargin: listItem.margins
			rightMargin: listItem.margins
		}

		spacing: 16 * Units.dp

		Item {
			id: actionItem

			Layout.preferredWidth: dp(32)
			Layout.preferredHeight: width
			Layout.alignment: Qt.AlignCenter

			visible: children.length > 1 || icon.valid

			Icon {
				id: icon

				anchors.fill: parent

				name: isIcon ? srcIcon : ""
				visible: isIcon
				color: listItem.selected ? Theme.primaryColor
						: darkBackground ? Theme.dark.iconColor : Theme.light.iconColor

				size: 24 * Units.dp

				Behavior on rotation {
					NumberAnimation {
						easing.type: Easing.InOutQuad
						duration: MaterialAnimation.pageTransitionDuration
					}
				}
			}

			Circle.CircleImage {
				anchors.fill: parent

				visible: !isIcon
				source: !isIcon ? srcIcon : ""
				fillMode: Image.PreserveAspectCrop
			}
		}
	}

	Tooltip {
		id: toolTip
		text: name === "" ? toolTip.visible = false : name
		mouseArea: ink
	}
}
