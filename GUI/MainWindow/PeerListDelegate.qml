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
import Material.Extras 0.1 as Circle
import Material.ListItems 0.1 as ListItem

Component {
	Rectangle {
		id: friendroot

		property string msg: model.custom_state_string
		property string state_string: model.state_string
		property color statuscolor: state_string === "online"	? "#4caf50" :   // green
									state_string === "busy"		? "#FF5722" :   // red
									state_string === "away"		? "#FFEB3B" :   // yellow
																  "#9E9E9E"		// grey

		height: dp(50)
		width: parent.width

		state: "hidden"
		states: [
			State {
				name: "hidden";
				PropertyChanges { target: friendroot; color: Qt.rgba(0,0,0,0.03)}
			},
			State {
				name: "entered";
				PropertyChanges { target: friendroot; color: Qt.rgba(0,0,0,0.06) }
			}
		]

		MouseArea{
			anchors.fill: parent

			acceptedButtons: Qt.RightButton | Qt.LeftButton
			hoverEnabled: true

			onEntered: friendroot.state = "entered"
			onExited: friendroot.state = "hidden"
			onClicked: {
				if(mouse.button == Qt.RightButton)
					overflowMenu.open(friendroot, mouse.x, mouse.y)
				else if(mouse.button == Qt.LeftButton) {
					mainGUIObject.createChatPeerCard(model.name, model.location, model.peer_id, model.chat_id, "ChatPeerCard.qml")
					rsApi.request("/chat/mark_chat_as_read/"+model.chat_id, "", function(){})
				}
			}

			states: [
				State {
					name: "name"; when: msg === ""
					PropertyChanges {
						target: name
						height: friendroot.height
						verticalAlignment: Text.AlignVCenter
					}
				},
				State {
					name: "smsg"; when: msg != ""
					PropertyChanges {
						target: name
						height: friendroot.height/2
						verticalAlignment: Text.AlignBottom
					}
				}
			]

			Dropdown {
				id: overflowMenu
				objectName: "overflowMenu"
				overlayLayer: "dialogOverlayLayer"
				width: dp(200)
				height: state_string === "online"
						|| state_string === "busy"
						|| state_string === "away" ? dp(2*30)
												   : dp(3*30)
				enabled: true
				anchor: Item.TopLeft
				durationSlow: 300
				durationFast: 150

				Column{
					anchors.fill: parent

					ListItem.Standard {
						height: dp(30)
						text: "Chat"
						itemLabel.style: "menu"
						onClicked: {
							overflowMenu.close()

							mainGUIObject.createChatPeerCard(model.name, model.location, model.peer_id, model.chat_id, "ChatPeerCard.qml")
							rsApi.request("/chat/mark_chat_as_read/"+model.chat_id, "", function(){})
						}
					}

					ListItem.Standard {
						height: dp(30)
						text: "Details"
						itemLabel.style: "menu"
						onClicked: {
							overflowMenu.close()

							nodeDetailsDialog.showAccount(model.name, model.pgp_id, model.location, model.peer_id)
						}
					}

					ListItem.Standard {
						height: dp(30)
						text: "Attempt Connection"
						itemLabel.style: "menu"

						enabled: !(state_string === "online"
								 || state_string === "busy"
								 || state_string === "away")
						visible: !(state_string === "online"
								 || state_string === "busy"
								 || state_string === "away")

						onClicked: {
							overflowMenu.close()

							var jsonData = {
								peer_id: model.peer_id
							}
							rsApi.request("/peers/attempt_connection", JSON.stringify(jsonData), function(){})
						}
					}
				}
			}

			Icon {
				anchors.verticalCenter: parent.verticalCenter

				x: dp(14)
				width: dp(32)
				height: dp(32)

				size: dp(32)

				name: "awesome/user"
				color: friendroot.state != "entered"
					    ? Theme.light.iconColor
						: Theme.primaryColor
			}

			Item {
				id: text

				x: dp(60)
				width: dp(151)
				height: parent.height

				Text {
					id: name

					height: parent.height
					text: model.location
					color: Theme.light.textColor

					font {
						family: "Roboto"
						pixelSize: dp(14)
					}

					verticalAlignment: Text.AlignVCenter
					horizontalAlignment: Text.AlignLeft
				}
				Text {
					id: smsg

					y: parent.height/2
					height: parent.height/2

					color: statuscolor
					text: msg

					font {
						family: "Roboto"
						pixelSize: dp(12)
					}

					verticalAlignment: Text.AlignTop
					horizontalAlignment: Text.AlignLeft
				}
			}

			Rectangle {
				anchors {
					verticalCenter: parent.verticalCenter
					right: parent.right
					rightMargin: model.unread_msgs > 0 ? dp(10) : dp(15)
				}

				width: model.unread_msgs > 0 ? dp(20) : dp(10)
				height: model.unread_msgs > 0 ? dp(20) : dp(10)

				radius: width/2
				color: statuscolor

				Text {
					anchors.fill: parent

					text: model.unread_msgs
					color: "white"
					font.family: "Roboto"

					visible: model.unread_msgs > 0 ? true : false

					verticalAlignment: Text.AlignVCenter
					horizontalAlignment: Text.AlignHCenter
				}
			}
		}
	}
}
