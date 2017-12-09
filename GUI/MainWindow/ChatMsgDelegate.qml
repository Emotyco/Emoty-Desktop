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

Component {
	Item {
		property bool previous_author_same: model.author_id == model.author_id_previous
		property alias view: view

		width: parent.width
		height: previous_author_same ? view.height + dp(5) : view.height + dp(15)

		View {
			id: view

			anchors {
				right: model.incoming === false ? parent.right : undefined
				left: model.incoming === false ?  undefined : parent.left
				rightMargin: parent.width*0.03
				leftMargin: parent.width*0.03
				bottom: parent.bottom
			}

			height: textMsg.implicitHeight + dp(12)
			width: (textMsg.implicitWidth + dp(20)) > (parent.width*0.8)
				    ? (parent.width*0.8)
					: textMsg.implicitWidth + dp(20)

			backgroundColor: model.incoming === false ? Theme.primaryColor : "white"
			elevation: 1
			radius: 10

			Rectangle {
				anchors.fill: parent
				radius: 10

				visible: !model.was_send
				opacity: 0.3
			}

			TextEdit {
				id: textMsg

				anchors {
					top: parent.top
					topMargin: dp(6)
					left: parent.left
					leftMargin: dp(10)
					right: parent.right
					rightMargin: dp(10)
				}

				text: model.msg_content
				textFormat: Text.RichText
				wrapMode: Text.WordWrap

				color: model.incoming === false ? "white" : Theme.light.textColor
				readOnly: true

				selectByMouse: true
				selectionColor: Theme.accentColor

				horizontalAlignment: TextEdit.AlignLeft

				font {
					family: "Roboto"
					pixelSize: dp(13)
				}
			}
		}

		ProgressCircle {
			anchors {
				right: view.left
				rightMargin: dp(7)
				verticalCenter: view.verticalCenter
			}

			width: dp(15)
			height: dp(15)
			dashThickness: dp(2)

			color: Theme.light.iconColor

			visible: !model.was_send
		}
	}
}
