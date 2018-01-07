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

Item {
	id: root

	property int col
	property int row

	property int gridX: 0   // Numbering starts from 0
	property int gridY: 0   // Numbering starts from 0

	property bool activated: true

	signal refresh
	signal pressedTile

	Drag.active: mouseArea.drag.active || leftMA.drag.active || rightMA.drag.active || topMA.drag.active || botMA.drag.active
	Drag.hotSpot.x: 0
	Drag.hotSpot.y: 0

	Behavior on activated {
		ScriptAction {
			script: {
				if(!root.activated) {
					root.visible = true
					root.enabled = true
				}
				else if(root.activated) {
					root.enabled = false
					root.visible = false
				}
			}
		}
	}

	onRefresh: {
		if(root.activated) {
			root.enabled = true;
			if(gridLayout.columns >= (gridX+root.col)) {
				var indexofgrid = gridLayout.columns*gridY + gridX
				root.anchors.left = gridRepeater.itemAt(indexofgrid).left
				root.anchors.bottom = gridRepeater.itemAt((gridLayout.columns*(root.row-1))+indexofgrid).bottom
				root.anchors.top = gridRepeater.itemAt(indexofgrid).top
				root.anchors.right = gridRepeater.itemAt(indexofgrid+root.col-1).right
				root.visible = true;
			}
			else if(gridLayout.columns <= (gridX+root.col) && !(gridLayout.columns < root.col)) {
				var indexofgrid2 = gridLayout.columns*(gridY+1)-root.col
				root.anchors.left = gridRepeater.itemAt(indexofgrid2).left
				root.anchors.bottom = gridRepeater.itemAt((gridLayout.columns*(root.row-1))+indexofgrid2).bottom
				root.anchors.top = gridRepeater.itemAt(indexofgrid2).top
				root.anchors.right = gridRepeater.itemAt(indexofgrid2+root.col-1).right
				root.visible = true;
			}
			else
				root.visible = false;
		}
		else {
			root.enabled = false;
			root.visible = false;
		}
	}

	Component.onCompleted: {
		mainGUIObject.gridChanged.connect(refresh)
	}

	states: [
		State {
			name: ""
			StateChangeScript {
				script: gridRepeater.nonActiveGrid()
			}
		},
		State {
			when: mouseArea.drag.active
			AnchorChanges {
				target: root
				anchors.top: undefined
				anchors.bottom: undefined
				anchors.left: undefined
				anchors.right: undefined
			}
			StateChangeScript {
				script: gridRepeater.activeGrid()
			}
		},
		State {
			when: leftMA.drag.active
			AnchorChanges {
				target: root
				anchors.top: undefined
				anchors.bottom: undefined
				anchors.left: undefined
				anchors.right: undefined
			}
			StateChangeScript {
				script: gridRepeater.activeGrid()
			}
		},
		State {
			when: rightMA.drag.active
			AnchorChanges {
				target: root
				anchors.top: undefined
				anchors.bottom: undefined
				anchors.left: undefined
				anchors.right: undefined
			}
			StateChangeScript {
				script: gridRepeater.activeGrid()
			}
		},
		State {
			when: topMA.drag.active
			AnchorChanges {
				target: root
				anchors.top: undefined
				anchors.bottom: undefined
				anchors.left: undefined
				anchors.right: undefined
			}
			StateChangeScript {
				script: gridRepeater.activeGrid()
			}
		},
		State {
			when: botMA.drag.active
			AnchorChanges {
				target: root
				anchors.top: undefined
				anchors.bottom: undefined
				anchors.left: undefined
				anchors.right: undefined
			}
			StateChangeScript {
				script: gridRepeater.activeGrid()
			}
		}
	]

	Item {
		anchors {
			left: parent.left
			verticalCenter: parent.verticalCenter
		}

		width: dp(5)
		height: parent.height

		MouseArea {
			id: leftMA

			property bool press: false

			anchors.fill: parent

			hoverEnabled: true
			preventStealing: true

			drag {
				target: parent
				axis: Drag.XAxis
			}

			onPressed: {
				leftMA.press = true
				cursor.changeCursor(Qt.SizeHorCursor)
			}

			onEntered: cursor.changeCursor(Qt.SizeHorCursor)
			onExited: if(!leftMA.press)cursor.changeCursor(Qt.ArrowCursor)

			onMouseXChanged: {
				if(drag.active) {
					root.width = root.width - mouseX
					root.x = root.x + mouseX
					if(root.width < dp(30))
						root.width = dp(30)
				}
			}
			onReleased: {
				if(root.Drag.target !== null) {
					var newGridX = ((root.Drag.target.index)%gridLayout.columns)
					root.col = (root.col + (gridX - newGridX)) > 1 ? (root.col + (gridX - newGridX)) : 1
					gridX = ((root.Drag.target.index)%gridLayout.columns)

					root.anchors.left = gridRepeater.itemAt(root.Drag.target.index).left
					root.refresh()
				}
				else
					root.refresh()

				leftMA.press = false
				cursor.changeCursor(Qt.ArrowCursor)
			}
		}
	}

	Item {
		anchors {
			right: parent.right
			verticalCenter: parent.verticalCenter
		}

		width: dp(5)
		height: parent.height

		MouseArea {
			id: rightMA

			property bool press: false

			anchors.fill: parent

			hoverEnabled: true
			preventStealing: true

			drag{
				target: parent
				axis: Drag.XAxis
			}

			onPressed: {
				rightMA.press = true
				cursor.changeCursor(Qt.SizeHorCursor)
			}

			onEntered: cursor.changeCursor(Qt.SizeHorCursor)
			onExited: if(!rightMA.press)cursor.changeCursor(Qt.ArrowCursor)

			onMouseXChanged: {
				if(drag.active) {
					root.width = root.width + mouseX
					if(root.width < dp(30))
						root.width = dp(30)
				}
			}

			onReleased: {
				if(root.Drag.target !== null) {
					var cols = Math.round(root.width/(50 + gridLayout.columnSpacing))
					root.col = cols >= gridLayout.columns ? gridLayout.columns : cols
					root.refresh()
				}
				else
					root.refresh()

				rightMA.press = false
				cursor.changeCursor(Qt.ArrowCursor)
			}
		}
	}

	Item {
		anchors {
			horizontalCenter: parent.horizontalCenter
			top: parent.top
		}

		width: parent.width
		height: dp(5)

		MouseArea {
			id: topMA

			property bool press: false

			anchors.fill: parent

			hoverEnabled: true
			preventStealing: true

			drag {
				target: parent
				axis: Drag.YAxis
			}

			onPressed: {
				topMA.press = true
				cursor.changeCursor(Qt.SizeVerCursor)
			}

			onEntered: cursor.changeCursor(Qt.SizeVerCursor)
			onExited: if(!topMA.press)cursor.changeCursor(Qt.ArrowCursor)

			onMouseXChanged: {
				if(drag.active) {
					root.height = root.height - mouseY
					root.y = root.y + mouseY
					if(root.height < dp(30))
						root.height = dp(30)
				}
			}
			onReleased: {
				if(root.Drag.target !== null) {
					gridY = Math.floor(root.Drag.target.index/gridLayout.columns)
					root.row = Math.ceil(root.height/(50 + gridLayout.rowSpacing))
					root.anchors.top = gridRepeater.itemAt(root.Drag.target.index).top
					root.refresh()
				}
				else
					root.refresh()

				topMA.press = false
				cursor.changeCursor(Qt.ArrowCursor)
			}
		}
	}

	Item {
		anchors {
			horizontalCenter: parent.horizontalCenter
			bottom: parent.bottom
		}

		width: parent.width
		height: dp(5)

		MouseArea {
			id: botMA

			property bool press: false

			anchors.fill: parent

			hoverEnabled: true
			preventStealing: true

			drag {
				target: parent
				axis: Drag.YAxis
			}

			onPressed: {
				botMA.press = true
				cursor.changeCursor(Qt.SizeVerCursor)
			}

			onEntered: cursor.changeCursor(Qt.SizeVerCursor)
			onExited: if(!botMA.press)cursor.changeCursor(Qt.ArrowCursor)

			onMouseXChanged: {
				if(drag.active) {
					root.height = root.height + mouseY
					if(root.height < dp(30))
						root.height = dp(30)
				}
			}

			onReleased: {
				if(root.Drag.target !== null) {
					var rows = Math.round(root.height/(dp(50) + gridLayout.rowSpacing))
					root.row = rows
					root.refresh()
				}
				else
					root.refresh()

				botMA.press = false
				cursor.changeCursor(Qt.ArrowCursor)
			}
		}
	}

	MouseArea {
		id: mouseArea

		anchors.centerIn: parent

		width: parent.width - dp(10)
		height: parent.height - dp(10)

		drag.target: root

		onPressed: {
			pressedTile()
			cursor.changeCursor(Qt.ClosedHandCursor)
		}
		onReleased: {
			if(root.Drag.target !== null) {
				if(!(((root.Drag.target.index+root.col-1)%gridLayout.columns)<(root.col-1))) {
					gridX = ((root.Drag.target.index)%gridLayout.columns)
					gridY = Math.floor(root.Drag.target.index/gridLayout.columns)

					root.anchors.left = gridRepeater.itemAt(root.Drag.target.index).left
					root.anchors.bottom = gridRepeater.itemAt((gridLayout.columns*(root.row-1))+root.Drag.target.index).bottom
					root.anchors.top = gridRepeater.itemAt(root.Drag.target.index).top
					root.anchors.right = gridRepeater.itemAt(root.Drag.target.index+root.col-1).right
				}
				else
					root.refresh()
			}
			else
				root.refresh()

			cursor.changeCursor(Qt.ArrowCursor)
		}
	}
}

