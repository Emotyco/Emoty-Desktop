import QtQuick 2.5

import Material 0.3
import Material.ListItems 0.1 as ListItem

Rectangle {
	color: "#f2f2f2"

	// For handling tokens
	property int stateToken_P:	0
	property int stateToken_SP:	0
	property int stateToken_UP:	0

	function getPrivateLobbies() {
		if(!main.isTokenValid(stateToken_P)) {
			var jsonData = {
				callback_name: "leftbar_rooms_chat_private_lobbies"
			}

			function callbackFn(par) {
				privateLobbiesModel.json = par.response
				stateToken_P = JSON.parse(par.response).statetoken
				main.pushToken(stateToken_P)
			}

			rsApi.request("/chat/private_lobbies/", JSON.stringify(jsonData), callbackFn)
		}
	}

	function getSubscribedPublicLobbies() {
		if(!main.isTokenValid(stateToken_SP)) {
			var jsonData = {
				callback_name: "leftbar_rooms_chat_subscribed_public_lobbies"
			}

			function callbackFn(par) {
				subscribedPublicLobbiesModel.json = par.response
				stateToken_SP = JSON.parse(par.response).statetoken
				main.pushToken(stateToken_SP)
			}

			rsApi.request("/chat/subscribed_public_lobbies/", JSON.stringify(jsonData), callbackFn)
		}
	}

	function getUnsubscribedPublicLobbies() {
		if(!main.isTokenValid(stateToken_UP)) {
			var jsonData = {
				callback_name: "leftbar_rooms_chat_unsubscribed_public_lobbies"
			}

			function callbackFn(par) {
				unsubscribedPublicLobbiesModel.json = par.response
				stateToken_UP = JSON.parse(par.response).statetoken
				main.pushToken(stateToken_UP)
			}

			rsApi.request("/chat/unsubscribed_public_lobbies/", JSON.stringify(jsonData), callbackFn)
		}
	}

	Component.onCompleted: {
		getPrivateLobbies()
		getSubscribedPublicLobbies()
		getUnsubscribedPublicLobbies()
	}

	JSONListModel {
		id: privateLobbiesModel
		query: "$.data[*]"
	}

	JSONListModel {
		id: subscribedPublicLobbiesModel
		query: "$.data[*]"
	}

	JSONListModel {
		id: unsubscribedPublicLobbiesModel
		query: "$.data[*]"
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
					width: parent.width

					text: model.name
					textColor: Theme.light.textColor

					itemLabel.style: "body1"

					onClicked: {
						main.content.activated = true;
						pageStack.push({item: Qt.resolvedUrl("RoomPage.qml"), immediate: true, replace: true,
										   properties: {roomName: model.name, chatId: model.chat_id}})

						leftBar.state = "narrow"
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

				onClicked: leftBar.state = "narrow"
			}

			ListItem.Subheader {
				width: parent.width

				text: "Followed public rooms"
				textColor: Theme.primaryColor
			}

			Repeater {
				model: subscribedPublicLobbiesModel.model
				delegate: ListItem.Standard {
					width: parent.width

					text: model.name
					textColor: Theme.light.textColor

					itemLabel.style: "body1"

					onClicked: {
						main.content.activated = true;
						pageStack.push({item: Qt.resolvedUrl("RoomPage.qml"), immediate: true, replace: true,
										   properties: {roomName: model.name, chatId: model.chat_id}})

						leftBar.state = "narrow"
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

				onClicked: leftBar.state = "narrow"
			}

			ListItem.Subheader {
				width: parent.width

				text: "Other public rooms"
				textColor: Theme.primaryColor
			}

			Repeater {
				model: unsubscribedPublicLobbiesModel.model
				delegate: ListItem.Standard {
					width: parent.width

					text: model.name
					textColor: Theme.light.textColor

					itemLabel.style: "body1"

					onClicked: {
						main.content.activated = true;
						pageStack.push({item: Qt.resolvedUrl("RoomPage.qml"), immediate: true, replace: true,
										   properties: {roomName: model.name, chatId: model.chat_id}})

						leftBar.state = "narrow"
					}
				}
			}
		}
	}

	Timer {
		interval: 5000
		running: true
		repeat: true

		onTriggered: {
			getPrivateLobbies()
			getSubscribedPublicLobbies()
			getUnsubscribedPublicLobbies()
		}
	}
}
