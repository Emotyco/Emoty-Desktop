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
import Material.ListItems 0.1 as ListItem

Rectangle {
	color: "#f2f2f2"

	// For handling tokens
	property int stateToken: 0

	Component.onDestruction: main.unregisterToken(stateToken)

	property bool firstTime: true

	function getLobbies() {
		function callbackFn(par) {
			if(firstTime)
				firstTime = false

			privateLobbiesModel.json = par.response
			subscribedPublicLobbiesModel.json = par.response
			unsubscribedPublicLobbiesModel.json = par.response

			stateToken = JSON.parse(par.response).statetoken
			main.registerToken(stateToken, getLobbies)
		}

		rsApi.request("/chat/lobbies/", "", callbackFn)
	}

	function subscribeLobby(chatId) {
		var jsonData = {
			id: chatId,
			gxs_id: main.defaultGxsId
		}

		function callbackFn(par) {
			getLobbies()
		}

		rsApi.request("/chat/subscribe_lobby/", JSON.stringify(jsonData), callbackFn)
	}

	function unsubsribeLobby(chatId) {
		var jsonData = {
			id: chatId
		}

		function callbackFn(par) {
			getLobbies()
		}

		rsApi.request("/chat/unsubscribe_lobby/", JSON.stringify(jsonData), callbackFn)
	}

	function setAutosubsribeLobby(chatId, autosubsribe) {
		var jsonData = {
			chat_id: chatId,
			autosubsribe: autosubsribe
		}

		function callbackFn(par) {
			getLobbies()
		}

		rsApi.request("/chat/autosubscribe_lobby/", JSON.stringify(jsonData), callbackFn)
	}

	Component.onCompleted: getLobbies()

	LoadingMask {
		id: loadingMask
		anchors.fill: parent

		state: firstTime ? "visible" : "non-visible"
	}

	JSONListModel {
		id: privateLobbiesModel
		query: "$.data[?(@.is_private==true)]"
	}

	JSONListModel {
		id: subscribedPublicLobbiesModel
		query: "$.data[?((@.is_private==false)&&(@.subscribed==true)&&(@.is_broadcast==false))]"
	}

	JSONListModel {
		id: unsubscribedPublicLobbiesModel
		query: "$.data[?((@.is_private==false)&&(@.subscribed==false)&&(@.is_broadcast==false))]"
	}

	Flickable {
		anchors.fill: parent

		contentHeight: 2*dp(48)+(privateLobbiesModel.model.count+1)*dp(48)
					   + (subscribedPublicLobbiesModel.model.count+1)*dp(48)
					   + (unsubscribedPublicLobbiesModel.model.count+1)*dp(48)

		clip: true
		interactive: true

		Column {
			width: parent.width

			ListItem.Subheader {
				id: privateRooms

				width: parent.width

				text: "Private rooms"
				textColor: Theme.primaryColor
			}

			Repeater {
				model: privateLobbiesModel.model
				delegate: ListItem.Standard {
					id: subscribedPrivateDelegate
					width: parent.width

					text: model.name
					textColor: Theme.light.textColor

					itemLabel.style: "body1"

					onClicked: {
						main.createRoomCard(model.name, model.chat_id)
						leftBar.state = "narrow"
					}

					secondaryItem: View {
						anchors {
							verticalCenter: parent.verticalCenter
							right: parent.right
							rightMargin: dp(20)
						}

						width: dp(20)
						height: dp(20)
						radius: width/2

						backgroundColor: Theme.primaryColor
						elevation: 1

						visible: model.unread_msg_count > 0 ? true : false

						Text {
							anchors.fill: parent
							text: model.unread_msg_count
							color: "white"
							font.family: "Roboto"
							verticalAlignment: Text.AlignVCenter
							horizontalAlignment: Text.AlignHCenter
						}
					}

					Tooltip {
						text: "Topic: " + model.topic
							  + (main.advmode
								   ? "\n" + "Chat Id: " + model.chat_id
								   : "")
						mouseArea: ink
					}

					MouseArea {
						anchors.fill: parent

						acceptedButtons: Qt.RightButton
						onClicked: overflowMenuPrivate.open(subscribedPrivateDelegate, mouse.x, mouse.y);
					}

					Dropdown {
						id: overflowMenuPrivate
						objectName: "overflowMenu"
						overlayLayer: "dialogOverlayLayer"

						anchor: Item.TopLeft

						width: dp(200)
						height: dp(1*30)

						enabled: true

						durationSlow: 300
						durationFast: 150

						Column {
							anchors.fill: parent

							ListItem.Standard {
								height: dp(30)

								text: "Leave"
								itemLabel.style: "menu"

								onClicked: {
									overflowMenuPrivate.close()
									unsubsribeLobby(model.id)
									setAutosubsribeLobby(model.id, false)
								}
							}
						}
					}
				}
			}

			ListItem_Button {
				width: parent.width

				text: "Create private room"
				textColor: Theme.light.textColor

				selected: false
				itemLabel.style: "body1"
				iconName: "awesome/plus"

				onClicked: {
					leftBar.state = "narrow"
					var component = Qt.createComponent("CreateLobby.qml");
					if (component.status === Component.Ready) {
						var createId = component.createObject(main, {"isPrivate": true});
						createId.show();
					}
				}
			}

			ListItem.Subheader {
				width: parent.width

				text: "Followed public rooms"
				textColor: Theme.primaryColor
			}

			Repeater {
				model: subscribedPublicLobbiesModel.model
				delegate: ListItem.Standard {
					id: subscribedPublicDelegate
					width: parent.width

					text: model.name
					textColor: Theme.light.textColor

					itemLabel.style: "body1"

					onClicked: {
						main.createRoomCard(model.name, model.chat_id)
						leftBar.state = "narrow"
					}

					secondaryItem: View {
						anchors {
							verticalCenter: parent.verticalCenter
							right: parent.right
							rightMargin: dp(20)
						}

						width: dp(20)
						height: dp(20)
						radius: width/2

						backgroundColor: Theme.primaryColor
						elevation: 1

						visible: model.unread_msg_count > 0 ? true : false

						Text {
							anchors.fill: parent
							text: model.unread_msg_count
							color: "white"
							font.family: "Roboto"
							verticalAlignment: Text.AlignVCenter
							horizontalAlignment: Text.AlignHCenter
						}
					}

					Tooltip {
						text: "Topic: " + model.topic
							  + (main.advmode
								   ? "\n" + "Chat Id: " + model.chat_id
								   : "")
						mouseArea: ink
					}

					MouseArea {
						anchors.fill: parent

						acceptedButtons: Qt.RightButton
						onClicked: overflowMenu.open(subscribedPublicDelegate, mouse.x, mouse.y);
					}

					Dropdown {
						id: overflowMenu
						objectName: "overflowMenu"
						overlayLayer: "dialogOverlayLayer"

						anchor: Item.TopLeft

						width: dp(200)
						height: dp(1*30)

						enabled: true

						durationSlow: 300
						durationFast: 150

						Column {
							anchors.fill: parent

							ListItem.Standard {
								height: dp(30)

								text: "Leave"
								itemLabel.style: "menu"

								onClicked: {
									overflowMenu.close()
									unsubsribeLobby(model.id)
									setAutosubsribeLobby(model.id, false)
								}
							}
						}
					}
				}
			}

			ListItem_Button {
				width: parent.width

				text: "Create public room"
				textColor: Theme.light.textColor

				selected: false
				itemLabel.style: "body1"
				iconName: "awesome/plus"

				onClicked: {
					leftBar.state = "narrow"
					var component = Qt.createComponent("CreateLobby.qml");
					if (component.status === Component.Ready) {
						var createId = component.createObject(main, {"isPrivate": false});
						createId.show();
					}
				}
			}

			ListItem.Subheader {
				width: parent.width

				text: "Other public rooms"
				textColor: Theme.primaryColor
			}

			Repeater {
				model: unsubscribedPublicLobbiesModel.model
				delegate: ListItem.Standard {
					id: unsubscribedDelegate
					width: parent.width

					text: model.name
					textColor: Theme.light.textColor

					itemLabel.style: "body1"

					function openUnsubscribedPublicLobby() {
						subscribeLobby(model.id)
						setAutosubsribeLobby(model.id, true)
						main.content.activated = true;
						pageStack.push({item: Qt.resolvedUrl("RoomPage.qml"), immediate: true, replace: true,
										   properties: {roomName: model.name, chatId: model.chat_id}})

						main.content.refresh()
						leftBar.state = "narrow"
					}

					onClicked: openUnsubscribedPublicLobby()

					secondaryItem: View {
						anchors {
							verticalCenter: parent.verticalCenter
							right: parent.right
							rightMargin: dp(20)
						}

						width: dp(20)
						height: dp(20)
						radius: width/2

						backgroundColor: Theme.primaryColor
						elevation: 1

						visible: model.unread_msg_count > 0 ? true : false

						Text {
							anchors.fill: parent
							text: model.unread_msg_count
							color: "white"
							font.family: "Roboto"
							verticalAlignment: Text.AlignVCenter
							horizontalAlignment: Text.AlignHCenter
						}
					}

					Tooltip {
						text: "Topic: " + model.topic
							  + (main.advmode
								   ? "\n" + "Chat Id: " + model.chat_id
								   : "")
						mouseArea: ink
					}

					MouseArea {
						anchors.fill: parent

						acceptedButtons: Qt.RightButton
						onClicked: overflowMenu2.open(unsubscribedDelegate, mouse.x, mouse.y);
					}

					Dropdown {
						id: overflowMenu2
						objectName: "overflowMenu2"
						overlayLayer: "dialogOverlayLayer"

						anchor: Item.TopLeft

						width: dp(200)
						height: dp(1*30)

						enabled: true

						durationSlow: 300
						durationFast: 150

						Column {
							anchors.fill: parent

							ListItem.Standard {
								height: dp(30)

								text: "Join"
								itemLabel.style: "menu"

								onClicked: {
									overflowMenu2.close()
									openUnsubscribedPublicLobby()
								}
							}
						}
					}
				}
			}
		}
	}
}
