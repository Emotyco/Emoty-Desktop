/****************************************************************
 *  This file is part of Sonet.
 *  Sonet is distributed under the following license:
 *
 *  Copyright (C) 2017, Konrad Dębiec
 *
 *  Sonet is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU General Public License
 *  as published by the Free Software Foundation; either version 3
 *  of the License, or (at your option) any later version.
 *
 *  Sonet is distributed in the hope that it will be useful,
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
import QtGraphicalEffects 1.0

import Material 0.3
import Material.Extras 0.1 as Circle
import Material.ListItems 0.1 as ListItem

Item {
	id: page

	property string title: "profilePage"

	// Just for "restore" option
	property int tmpCol: 0
	property int tmpRow: 0
	property int tmpGridX: 0   // Numbering starts from 0
	property int tmpGridY: 0   // Numbering starts from 0
	property bool maximized: false
	//

	Connections {
		target: main.content
		onRefresh: {
			updateVisibleRows()
			if(
					main.content.col === (parseInt(gridLayout.width / (dp(50) + gridLayout.columnSpacing))>= 14
									  ? 14
									  : parseInt(gridLayout.width / (dp(50) + gridLayout.columnSpacing))) &&
				main.content.row === main.visibleRows &&
				main.content.gridX === Math.floor(((parseInt(gridLayout.width / (dp(50) + gridLayout.columnSpacing)))-main.content.col)/2) &&
				main.content.gridY === 0
				)
				maximized = true
			else
				maximized = false
		}
	}

	View {
		id: chat

		anchors.fill: parent

		elevation: 2
		backgroundColor: Palette.colors["grey"]["50"]

		MouseArea {
			anchors.fill: parent

			acceptedButtons: Qt.RightButton
			onClicked: overflowMenu.open(pageStack, mouse.x, mouse.y);

			Dropdown {
				id: overflowMenu
				objectName: "overflowMenu"
				overlayLayer: "dialogOverlayLayer"

				anchor: Item.TopLeft

				width: dp(200)
				height: dp(2*30)

				enabled: true

				durationSlow: 200
				durationFast: 100

				Column {
					anchors.fill: parent

					ListItem.Standard {
						height: dp(30)
						text: maximized ? "Restore" : "Maximize"
						itemLabel.style: "menu"
						onClicked: {
							overflowMenu.close()
							updateVisibleRows()

							if(!maximized) {
								page.tmpGridX = main.content.gridX
								page.tmpGridY = main.content.gridY
								page.tmpCol = main.content.col
								page.tmpRow = main.content.row

								main.content.col = Qt.binding(function() {
									return parseInt(gridLayout.width / (dp(50) + gridLayout.columnSpacing))>= 14
											    ? 14
												: parseInt(gridLayout.width / (dp(50) + gridLayout.columnSpacing))
								});
								main.content.row = Qt.binding(function() {
									updateVisibleRows(); return main.visibleRows
								});
								main.content.gridX = Qt.binding(function() {
									return Math.floor(((parseInt(gridLayout.width / (dp(50) + gridLayout.columnSpacing)))-main.content.col)/2)
								});
								main.content.gridY = 0

								maximized = true
							}
							else if(maximized) {
								main.content.gridX = page.tmpGridX
								main.content.gridY = page.tmpGridY
								main.content.col = page.tmpCol
								main.content.row = page.tmpRow
								maximized = false
							}

							main.content.refresh()
						}
					}

					ListItem.Standard {
						height: dp(30)

						text: "Hide"
						itemLabel.style: "menu"

						onClicked: {
							overflowMenu.close()
							main.content.activated = false;
						}
					}
				}
			}
		}

		ParallelAnimation {
			running: true
			NumberAnimation {
				target: content
				property: "anchors.bottomMargin"
				from: -dp(50)
				to: 0
				duration: MaterialAnimation.pageTransitionDuration
			}
			NumberAnimation {
				target: content
				property: "opacity"
				from: 0
				to: 1
				duration: MaterialAnimation.pageTransitionDuration
			}
		}
	}
}
