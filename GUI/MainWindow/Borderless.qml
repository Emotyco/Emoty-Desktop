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
import Material 0.3

Rectangle {

	color: Palette.colors["grey"]["200"]

	// Frame:
	    // Left edge
	    MouseArea {
			anchors {
				left: parent.left
				top: parent.top
				bottom: parent.bottom
				bottomMargin: 5 * Units.dp
				topMargin: 5 * Units.dp
			}

			width: 5 * Units.dp

			hoverEnabled: enabled
			onEntered: cursor.changeCursor(Qt.SizeHorCursor)
			onExited: cursor.changeCursor(Qt.ArrowCursor)

			MouseArea {
				anchors.fill: parent
				onPositionChanged: qMainPanel.resizeWin(mouse.x, 0, true, true)
			}
		}
		// Right edge
		MouseArea {
			anchors {
				right: parent.right
				top: parent.top
				bottom: parent.bottom
				bottomMargin: 5 * Units.dp
				topMargin: 5 * Units.dp
			}

			width: 5 * Units.dp

			hoverEnabled: enabled
			preventStealing: true

			onEntered: cursor.changeCursor(Qt.SizeHorCursor)
			onExited: cursor.changeCursor(Qt.ArrowCursor)

			MouseArea {
				anchors.fill: parent
				onPositionChanged: qMainPanel.resizeWin(mouse.x, 0, false, false)
			}
		}
		// Top edge
		MouseArea {
			anchors {
				top: parent.top
				right: parent.right
				left: parent.left
				leftMargin: 5 * Units.dp
				rightMargin: 5 * Units.dp
			}

			height: 5 * Units.dp

			hoverEnabled: enabled

			onEntered: cursor.changeCursor(Qt.SizeVerCursor)
			onExited: cursor.changeCursor(Qt.ArrowCursor)

			MouseArea {
				anchors.fill: parent
				onPositionChanged: qMainPanel.resizeWin(0, mouse.y, true, true)
			}
		}
		// Bottom edge
		MouseArea {
			anchors {
				bottom: parent.bottom
				right: parent.right
				left: parent.left
				leftMargin: 5 * Units.dp
				rightMargin: 5 * Units.dp
			}

			height: 5 * Units.dp

			hoverEnabled: enabled

			onEntered: cursor.changeCursor(Qt.SizeVerCursor)
			onExited: cursor.changeCursor(Qt.ArrowCursor)

			MouseArea {
				anchors.fill: parent
				onPositionChanged: qMainPanel.resizeWin(0, mouse.y, false, false)
			}
		}
		// Left-top corner
		MouseArea {
			anchors {
				top: parent.top
				left: parent.left
			}

			height: 5 * Units.dp
			width: 5 * Units.dp

			hoverEnabled: enabled

			onEntered: cursor.changeCursor(Qt.SizeFDiagCursor)
			onExited: cursor.changeCursor(Qt.ArrowCursor)

			MouseArea {
				anchors.fill: parent
				onPositionChanged: qMainPanel.resizeWin(mouse.x, mouse.y, true, true)
			}
		}
		// Right-top corner
		MouseArea {
			anchors {
				top: parent.top
				right: parent.right
			}

			height: 5 * Units.dp
			width: 5 * Units.dp

			hoverEnabled: enabled

			onEntered: cursor.changeCursor(Qt.SizeBDiagCursor)
			onExited: cursor.changeCursor(Qt.ArrowCursor)

			MouseArea {
				anchors.fill: parent
				onPositionChanged: qMainPanel.resizeWin(mouse.x, mouse.y, false, true)
			}
		}
		// Left-Bottom corner
		MouseArea {
			anchors {
				bottom: parent.bottom
				left: parent.left
			}

			height: 5 * Units.dp
			width: 5 * Units.dp

			hoverEnabled: enabled

			onEntered: cursor.changeCursor(Qt.SizeBDiagCursor)
			onExited: cursor.changeCursor(Qt.ArrowCursor)

			MouseArea {
				anchors.fill: parent
				onPositionChanged: qMainPanel.resizeWin(mouse.x, mouse.y, true, false)
			}
		}
		// Right-Bottom corner
		MouseArea {
			anchors {
				bottom: parent.bottom
				right: parent.right
			}

			height: 5 * Units.dp
			width: 5 * Units.dp

			hoverEnabled: enabled
			preventStealing: true

			onEntered: cursor.changeCursor(Qt.SizeFDiagCursor)
			onExited: cursor.changeCursor(Qt.ArrowCursor)

			MouseArea {
				anchors.fill: parent
				onPositionChanged: qMainPanel.resizeWin(mouse.x, mouse.y, false, false);
			}
		}

		MouseArea {
			anchors {
				fill: parent
				margins: 5 * Units.dp
			}

			acceptedButtons: Qt.LeftButton

			onPressed: qMainPanel.mouseLPressed()
			onDoubleClicked: qMainPanel.pushButtonMaximizeClicked()
		}

	MainGUI {
		anchors.fill: parent
		borderless: true
	}
}
