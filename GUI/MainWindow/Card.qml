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
import QtQuick.Layouts 1.3

import Material 0.3
import Material.ListItems 0.1 as ListItem

DragTile {
	id: dragTile

	default property alias data: content.data
	property string headerName
	property int cardIndex

	// Just for "restore" option
	property int tmpCol: 0
	property int tmpRow: 0
	property int tmpGridX: 0   // Numbering starts from 0
	property int tmpGridY: 0   // Numbering starts from 0
	property bool maximized: false
	//

	Layout.alignment: Qt.AlignBottom
	Layout.maximumWidth: 0
	Layout.maximumHeight: 0

	width: 0
	height: 0

	col: parseInt(gridLayout.width / (dp(50) + gridLayout.columnSpacing))
	row: mainGUIObject.visibleRows

	opacity: 0

	Component.onDestruction: {
		cardsModel.removeCard(cardIndex)
	}

	onRefresh: {
		updateVisibleRows()
		if(
				dragTile.col === parseInt(gridLayout.width / (dp(50) + gridLayout.columnSpacing)) &&
				dragTile.row === mainGUIObject.visibleRows &&
				dragTile.gridX === 0 &&
				dragTile.gridY === 0
				)
			maximized = true
		else
			maximized = false
	}

	Behavior on col {
		ScriptAction {
			script: {
				dragTile.refresh()
				gridLayout.reorder()
			}
		}
	}

	Behavior on row {
		ScriptAction { script: {dragTile.refresh()} }
	}

	Behavior on gridX {
		ScriptAction { script: {dragTile.refresh()} }
	}

	ParallelAnimation {
		running: true
		SequentialAnimation {
			NumberAnimation {
				duration: 50
			}
			NumberAnimation {
				target: dragTile
				property: "opacity"
				from: 0
				to: 1
				easing.type: Easing.InOutQuad;
				duration: MaterialAnimation.pageTransitionDuration/2
			}
		}
	}

	View {
		anchors.fill: parent

		elevation: 2
		backgroundColor: Palette.colors["grey"]["50"]

		radius: dp(10)

		Item {
			id: header

			anchors {
				top: parent.top
				left: parent.left
				right: parent.right
			}

			height: dp(35)
			z: 2

			MouseArea {
				anchors.fill: parent

				acceptedButtons: Qt.RightButton
				onClicked: overflowMenu.open(dragTile, mouse.x, mouse.y);

				Item {
					anchors {
						fill: parent
						leftMargin: dp(15)
						rightMargin: dp(15)
					}

					Rectangle {
						anchors {
							left: parent.left
							right: parent.right
							bottom: parent.bottom
						}

						height: dp(1)

						color: Palette.colors["grey"]["200"]
					}

					Text {
						id: headertext

						anchors {
							verticalCenter: parent.verticalCenter
							left: parent.left
							leftMargin: dp(20)
						}

						font {
							family: "Roboto"
							pixelSize: dp(17)
						}

						text: dragTile.headerName
						color: Theme.primaryColor
					}

					Item {
						anchors {
							verticalCenter: parent.verticalCenter
							right: parent.right
							rightMargin: dp(18)
						}

						width: dp(23)
						height: dp(23)

						IconButton {
							id: closeButton

							anchors {
								verticalCenter: parent.verticalCenter
								horizontalCenter: parent.horizontalCenter
							}

							iconName: "awesome/times"
							size: dp(25)
							color: Theme.light.hintColor

							onClicked: dragTile.destroy()
							onEntered: closeButton.color = Theme.light.iconColor
							onExited:  closeButton.color = Theme.light.hintColor
						}
					}
				}

				Dropdown {
					id: overflowMenu
					objectName: "overflowMenu"
					overlayLayer: "dialogOverlayLayer"

					anchor: Item.TopLeft

					width: dp(200)
					height: dp(2*30)

					enabled: true

					durationSlow: 300
					durationFast: 150

					Column {
						anchors.fill: parent

						ListItem.Standard {
							height: dp(30)

							text: maximized ? "Restore" : "Maximize"
							itemLabel.style: "menu"

							onClicked: {
								overflowMenu.close()

								if(!maximized) {
									dragTile.tmpGridX = dragTile.gridX
									dragTile.tmpGridY = dragTile.gridY
									dragTile.tmpCol = dragTile.col
									dragTile.tmpRow = dragTile.row
									dragTile.gridX = 0
									dragTile.gridY = 0
									dragTile.col = Qt.binding(function() {
										return parseInt(gridLayout.width / (dp(50) + gridLayout.columnSpacing)) || 1
									})
									dragTile.row = Qt.binding(function() {
										return mainGUIObject.visibleRows
									})
									maximized = true
								}
								else if(maximized) {
									dragTile.gridX = dragTile.tmpGridX
									dragTile.gridY = dragTile.tmpGridY
									dragTile.col = dragTile.tmpCol
									dragTile.row = dragTile.tmpRow
									maximized = false
								}

								dragTile.refresh()
							}
						}

						ListItem.Standard {
							height: dp(30)

							text: "Close"

							itemLabel.style: "menu"

							onClicked: {
								overflowMenu.close()
								dragTile.destroy()
							}
						}
					}
				}
			}
		}

		Item {
			id: content
			anchors {
				top: header.bottom
				left: parent.left
				right: parent.right
				bottom: parent.bottom
			}

			clip: true
		}
	}
}
