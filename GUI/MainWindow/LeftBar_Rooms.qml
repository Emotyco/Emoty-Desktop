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
			chatid: chatId,
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
					width: parent.width

					text: model.name
					textColor: Theme.light.textColor

					itemLabel.style: "body1"

					onClicked: {
						main.content.activated = true;
						pageStack.push({item: Qt.resolvedUrl("RoomPage.qml"), immediate: true, replace: true,
										   properties: {roomName: model.name, chatId: model.chat_id}})

						main.content.refresh()
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
						main.content.activated = true;
						pageStack.push({item: Qt.resolvedUrl("RoomPage.qml"), immediate: true, replace: true,
										   properties: {roomName: model.name, chatId: model.chat_id}})

						main.content.refresh()
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
