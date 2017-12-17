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
		property alias timeText: timeText

		property int yOff: Math.round(y - contentm.contentY)
		property bool isFullyVisible: (yOff > contentm.y
									   && yOff + height < contentm.y + contentm.height)

		Behavior on isFullyVisible {
			ScriptAction {
				script: {
					if(model.message_index+1 == messagesModel.rowCount()) {
						contentm.lastVisible = Qt.binding(function() {
							return yOff + height < contentm.y + contentm.height
						})
					}
				}
			}
		}

		SequentialAnimation {
			running: !model.read && isFullyVisible && view.active && isRaised

			PauseAnimation {
				duration: 1000
			}
			NumberAnimation {
				target: readNot
				property: "opacity"
				from: 1
				to: 0
				easing.type: Easing.InOutQuad
				duration: MaterialAnimation.pageTransitionDuration*4
			}
			ScriptAction {
				script: {
					var jsonData = {
						chat_id: chatCard.chatId,
						msg_id: model.msg_id
					}

					rsApi.request("/chat/mark_message_as_read/", JSON.stringify(jsonData), function(){})
				}
			}
		}

		width: parent.width
		height: previous_author_same ?
					model.last_from_author ? msgView.height + dp(8) : msgView.height + dp(5)
		          : model.last_from_author ? msgView.height + dp(18) : msgView.height + dp(15)

		View {
			id: msgView

			anchors {
				right: model.incoming === false ? parent.right : undefined
				left: model.incoming === false ?  undefined : parent.left
				rightMargin: parent.width*0.03
				leftMargin: parent.width*0.03
				bottom: timeText.top
				bottomMargin: model.last_from_author ? dp(3) : 0
			}

			height: textMsg.implicitHeight + dp(12)
			width: (textMsg.implicitWidth + dp(20)) > (parent.width*0.8)
				    ? (parent.width*0.8)
					: textMsg.implicitWidth + dp(20)

			backgroundColor: model.incoming === false ? Theme.primaryColor : "white"
			elevation: 1
			radius: 10
			clipContent: false

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

			View {
				id: readNot
				anchors {
					top: parent.top
					right: parent.right
					topMargin: -dp(3)
					rightMargin: -dp(3)
				}

				width: dp(10)
				height: dp(10)
				radius: width/2

				elevation: 2
				backgroundColor: Theme.accentColor

				visible: !model.read && model.incoming
			}
		}

		Label {
			id: timeText
			anchors {
				right: model.incoming === false ? msgView.right : undefined
				left: model.incoming === false ?  undefined : msgView.left
				bottom: parent.bottom
				leftMargin: dp(7)
				rightMargin: dp(7)
			}

			visible: model.last_from_author
			enabled: model.last_from_author

			style: "caption"
			font.pixelSize: dp(10)
			text: {
				var now = Date.now()
				var time = new Date(1000 * model.send_time)

				if(((now - time) / (24 * 3600 * 1000)) >= 1)
					return time.getDate()+"."+time.getMonth()+"."+time.getFullYear()+" "+time.toLocaleTimeString("en-GB")

				return time.toLocaleTimeString("en-GB")
			}

			color: Theme.light.subTextColor
		}

		ProgressCircle {
			anchors {
				right: msgView.left
				rightMargin: dp(7)
				verticalCenter: msgView.verticalCenter
			}

			width: dp(15)
			height: dp(15)
			dashThickness: dp(2)

			color: Theme.light.iconColor

			visible: !model.was_send
		}
	}
}
