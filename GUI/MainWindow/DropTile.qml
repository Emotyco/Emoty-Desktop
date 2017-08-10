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
import Material 0.3

DropArea {
	property int index: modelData

	signal activeGrid
	signal nonActiveGrid

	width: dp(50)
	height: dp(50)

	onActiveGrid: dropRectangle.state = "visible"
	onNonActiveGrid: dropRectangle.state = "hidden"

	Rectangle {
		id: dropRectangle

		anchors.fill: parent

		color: Qt.rgba(0,0,0,0.2)
		state: "hidden"

		states: [
			State {
				name: "visible"
				PropertyChanges {
					target: dropRectangle
					opacity: 1
				}
			},
			State {
				name: "hidden"
				PropertyChanges {
					target: dropRectangle
					opacity: 0
				}
			}
		]

		transitions: [
			Transition {
				from: "hidden"; to: "visible"
				PropertyAnimation {
					target: dropRectangle
					properties: "opacity"
					easing.type: Easing.InOutQuad;
					duration: MaterialAnimation.pageTransitionDuration
				}
			},
			Transition {
				from: "visible"; to: "hidden"
				PropertyAnimation {
					target: dropRectangle
					properties: "opacity"
					easing.type: Easing.InOutQuad;
					duration: MaterialAnimation.pageTransitionDuration
				}
			}

		]

		Component.onCompleted: {
			gridRepeater.activeGrid.connect(activeGrid)
			gridRepeater.nonActiveGrid.connect(nonActiveGrid)
		}
	}
}
