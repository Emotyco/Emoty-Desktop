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

import Material 0.3 as Material
import Material.ListItems 0.1 as ListItem

import RoomParticipantsSortModel 0.2
import RoomInvitationSortModel 0.2
import MessagesModel 0.2

Card {
	property var chatId

	// For handling tokens
	property int stateToken_p: 0
	property int stateToken_msg: 0
	property int stateToken_gxsContacts: 0
	property int stateToken_unreadCount: 0

	Component.onDestruction: {
		mainGUIObject.unregisterTokenWithIndex(stateToken_p, cardIndex)
		mainGUIObject.unregisterTokenWithIndex(stateToken_msg, cardIndex)
		mainGUIObject.unregisterTokenWithIndex(stateToken_gxsContacts, cardIndex)
		mainGUIObject.unregisterTokenWithIndex(stateToken_unreadCount, cardIndex)
	}

	property bool firstTime_msg: true

	function getLobbyParticipants() {
		function callbackFn(par) {
			stateToken_p = JSON.parse(par.response).statetoken
			mainGUIObject.registerTokenWithIndex(stateToken_p, getLobbyParticipants, cardIndex)

			roomParticipantsSortModel.sourceModel.loadJSONParticipants(par.response)
			roomInvitationSortModel.sourceModel.loadJSONParticipants(par.response)
		}

		rsApi.request("/chat/lobby_participants/"+chatId, "", callbackFn)
	}

	function getLobbyMessages() {
		function callbackFn(par) {
			if(firstTime_msg)
				firstTime_msg = false

			messagesModel.loadJSONMessages(par.response)

			stateToken_msg = JSON.parse(par.response).statetoken
			mainGUIObject.registerTokenWithIndex(stateToken_msg, getLobbyMessages, cardIndex)
		}

		rsApi.request("/chat/messages/"+chatId, "", callbackFn)
	}

	function getContacts() {
		function callbackFn(par) {
			stateToken_gxsContacts = JSON.parse(par.response).statetoken
			mainGUIObject.registerTokenWithIndex(stateToken_gxsContacts, getContacts, cardIndex)

			roomParticipantsSortModel.sourceModel.loadJSONIdentities(par.response)
			roomInvitationSortModel.sourceModel.loadJSONInvitations(par.response)
		}

		rsApi.request("/identity/*/", "", callbackFn)
	}

	function getUnreadCount() {
		function callbackFn(par) {
			var jsonResp = JSON.parse(par.response)

			var found = false
			for (var i = 0; i<jsonResp.data.length; i++) {
				if(jsonResp.data[i].chat_id == chatId) {
					indicatorNumber = jsonResp.data[i].unread_count
					found = true
				}
			}

			if(!found)
				indicatorNumber = 0

			stateToken_unreadCount = jsonResp.statetoken
			mainGUIObject.registerTokenWithIndex(stateToken_unreadCount, getUnreadCount, cardIndex)
		}

		rsApi.request("/chat/unread_msgs/", "", callbackFn)
	}

	Component.onCompleted: {
		getLobbyMessages();
		getLobbyParticipants()
		getContacts()
		getUnreadCount()
	}

	RoomParticipantsSortModel {
		id: roomParticipantsSortModel
	}

	RoomInvitationSortModel {
		id: roomInvitationSortModel
	}

	MessagesModel {
		id: messagesModel
	}

	Item {
		id: chat
		anchors.fill: parent

		LoadingMask {
			id: loadingMask
			anchors.fill: parent

			state: firstTime_msg ? "visible" : "non-visible"
		}

		Item {
			anchors {
				top: parent.top
				bottom: parent.bottom
				left: parent.left
				right: parent.right
				rightMargin: parent.width*0.3
			}

			Item {
				anchors {
					top: parent.top
					bottom: chatFooter.top
					left: parent.left
					right: parent.right
					leftMargin: dp(15)
					rightMargin: dp(15)
				}

				ListView {
					id: contentm

					anchors {
						fill: parent
						leftMargin: dp(5)
						rightMargin: dp(5)
					}

					clip: true
					snapMode: ListView.NoSnap
					flickableDirection: Flickable.AutoFlickDirection

					model: messagesModel
					delegate: RoomMsgDelegate{}

					header: Item{
						width: 1
						height: dp(5)
					}

					footer: Item{
						width: 1
						height: dp(10)
					}

					property bool complete: false
					Component.onCompleted: complete = true

					add: Transition {
						ParallelAnimation {
							NumberAnimation {
								property: "timeText.anchors.bottomMargin"
								from: -dp(35)
								to: dp(0)
								easing.type: Easing.OutBounce
								duration: Material.MaterialAnimation.pageTransitionDuration
							}

							NumberAnimation {
								property: "opacity"
								from: 0
								to: 1
								easing.type: Easing.OutBounce
								duration: Material.MaterialAnimation.pageTransitionDuration
							}

							ScriptAction {
								script: {
									if(contentm.complete)
										contentm.positionViewAtEnd()
								}
							}
						}
					}
				}

				Material.Scrollbar {
					anchors.margins: 0
					flickableItem: contentm
				}
			}

			Item {
				id: chatFooter

				anchors {
					bottom: parent.bottom
					left: parent.left
					right: parent.right
				}

				height: (msgBox.contentHeight < dp(20) ? (msgBox.contentHeight+dp(30))
													   : (msgBox.contentHeight+dp(22))) < dp(200) ? (msgBox.contentHeight < dp(20) ? (msgBox.contentHeight+dp(30)) : (msgBox.contentHeight+dp(22))) : dp(200)
				z: 1

				/*Behavior on height {
					ScriptAction {
						script: {
							contentm.positionViewAtEnd()
						}
					}
				}*/

				Material.View {
					id: footerView

					anchors {
						top: parent.top
						bottom: parent.bottom
						left: parent.left
						right: parent.right
						leftMargin: dp(15)
						rightMargin: dp(15)
						bottomMargin: dp(10)
					}

					radius: 10
					elevation: 1
					backgroundColor: "white"

					TextArea {
						id: msgBox

						anchors {
							fill: parent
							verticalCenter: parent.verticalCenter
							topMargin: dp(5)
							bottomMargin: dp(5)
							leftMargin: dp(18)
							rightMargin: dp(18)
						}

						placeholderText: footerView.width > dp(195) ? "Say hello to your friend"
																	: "Say hello"

						font.pixelSize: dp(15)
						wrapMode: Text.WordWrap

						horizontalScrollBarPolicy: Qt.ScrollBarAlwaysOff
						verticalScrollBarPolicy: Qt.ScrollBarAlwaysOff

						focus: true
						frameVisible: false

						onActiveFocusChanged: {
							if(activeFocus) {
								if(chatId.length > 0)
									rsApi.request("/chat/mark_chat_as_read/"+chatId, "", function(){})

								footerView.elevation = 2
							}
							else
								footerView.elevation = 1
						}

						Keys.onPressed:{
							if(event.key == Qt.Key_Return) {
								event.accepted = true
								if(msgBox.text.length > 0) {
									var jsonData = {
										chat_id: chatId,
										msg: msgBox.text
									}

									rsApi.request("chat/send_message/", JSON.stringify(jsonData), function(){})

									getLobbyMessages()
									msgBox.text = "";

									soundNotifier.playChatMessageSended()
								}
							}
						}
					}
				}
			}
		}

		Item {
			anchors {
				top: parent.top
				bottom: parent.bottom
				left: parent.left
				right: parent.right
				leftMargin: chat.width < 6*dp(60) ? chat.width - dp(15+32+16) : chat.width*0.7
				rightMargin: dp(15)
			}

			z: 3

			Item {
				id: filterItem

				anchors.top: parent.top

				visible: chat.width > 6*dp(60)
				enabled: chat.width > 6*dp(60)

				height: dp(45)
				width: parent.width
				z: 1

				Material.View {
					id: friendFilter

					anchors {
						horizontalCenter: parent.horizontalCenter
						verticalCenter: parent.verticalCenter
					}

					height: dp(25)
					width: parent.width

					radius: 10
					elevation: 1
					backgroundColor: "white"

					Material.TextField {
						id: msgBox2

						anchors {
							fill: parent
							verticalCenter: parent.verticalCenter
							leftMargin: dp(18)
							rightMargin: dp(18)
						}

						placeholderText: "Search friends"
						placeholderPixelSize: dp(15)

						font {
							weight: Font.Light
							pixelSize: dp(15)
						}

						focus: true
						showBorder: false

						onActiveFocusChanged: {
							if(activeFocus)
								friendFilter.elevation = 2
							else
								friendFilter.elevation = 1
						}

						onTextChanged: {
							roomParticipantsSortModel.setSearchText(text)

							if(mainGUIObject.advmode)
								roomParticipantsSortModel.setSearchText(text)
						}
						onAccepted: {
							roomParticipantsSortModel.setSearchText(text)

							if(mainGUIObject.advmode)
								roomParticipantsSortModel.setSearchText(text)
						}
					}
				}
			}

			ListView {
				id: roomFriendsList

				anchors {
					top: chat.width < 6*dp(60) ? parent.top : filterItem.bottom
					bottom: parent.bottom
					left: parent.left
					right: parent.right
				}

				clip: true
				snapMode: ListView.NoSnap
				flickableDirection: Flickable.AutoFlickDirection

				model: roomParticipantsSortModel

				delegate: RoomFriend {
					id: roomFriend
					property string avatar: (gxs_avatars.getAvatar(model.gxs_id) == "none"
											 || gxs_avatars.getAvatar(model.gxs_id) == "")
											? "none"
											: gxs_avatars.getAvatar(model.gxs_id)

					onAvatarChanged: {
						imageSource = avatar
						image.loadImage(avatar)
					}

					width: parent.width

					text: model.name
					textColor: Material.Theme.light.textColor
					itemLabel.style: "body1"

					imageSource: avatar
					isIcon: avatar == "none"
					iconName: "awesome/user_o"
					iconSize: dp(32)

					Component.onCompleted: {
						if(gxs_avatars.getAvatar(model.gxs_id) == "")
							getIdentityAvatar()
					}

					function getIdentityAvatar() {
						var jsonData = {
							gxs_id: model.gxs_id
						}

						function callbackFn(par) {
							var json = JSON.parse(par.response)
							if(json.returncode == "fail") {
								getIdentityAvatar()
								return
							}

							gxs_avatars.storeAvatar(model.gxs_id, json.data.avatar)
							if(gxs_avatars.getAvatar(model.gxs_id) != "none")
								avatar = gxs_avatars.getAvatar(model.gxs_id)
						}

						rsApi.request("/identity/get_avatar", JSON.stringify(jsonData), callbackFn)
					}

					MouseArea {
						anchors.fill: parent
						acceptedButtons: Qt.LeftButton | Qt.RightButton

						onClicked: {
							if(mouse.button == Qt.RightButton)
								if(mainGUIObject.advmode || !model.own)
									overflowMenu2.open(roomFriend, mouse.x, mouse.y)
						}

						onDoubleClicked: {
							if(mouse.button == Qt.LeftButton)
								if(!model.own)
									mainGUIObject.createChatGxsCard(model.name, model.gxs_id, "ChatGxsCard.qml")
						}
					}

					Material.Dropdown {
						id: overflowMenu2
						objectName: "overflowMenu"
						overlayLayer: "dialogOverlayLayer"
						width: dp(200)
						height: (mainGUIObject.advmode
								 ? (model.is_contact
									? model.own ? dp(1*30) : dp(2*30)
									: model.own ? dp(2*30) : dp(3*30))
								 : (model.is_contact
									? model.own ? dp(0) : dp(1*30)
									: model.own ? dp(1*30) : dp(2*30)))
						enabled: true
						anchor: Item.TopLeft
						durationSlow: 300
						durationFast: 150

						Column {
							anchors.fill: parent

							ListItem.Standard {
								height: dp(30)
								text: "Add to contacts"
								itemLabel.style: "menu"

								visible: !model.is_contact
								enabled: !model.is_contact

								onClicked: {
									overflowMenu2.close()

									var jsonData = {
										gxs_id: model.gxs_id
									}

									rsApi.request("/identity/add_contact", JSON.stringify(jsonData), function(){})
								}
							}

							ListItem.Standard {
								height: dp(30)
								text: "Chat"
								itemLabel.style: "menu"

								visible: !model.own
								enabled: !model.own

								onClicked: {
									overflowMenu2.close()
									mainGUIObject.createChatGxsCard(model.name, model.gxs_id, "ChatGxsCard.qml")
								}
							}

							ListItem.Standard {
								height: dp(30)
								text: "Details"
								itemLabel.style: "menu"

								enabled: mainGUIObject.advmode
								visible: mainGUIObject.advmode

								onClicked: {
									overflowMenu2.close()
									identityDetailsDialog.showIdentity(model.name, model.gxs_id)
								}
							}
						}
					}
				}

				footer: RoomFriend {
					width: parent.width

					text: "Invite to room"
					textColor: Material.Theme.light.hintColor
					itemLabel.style: "body1"

					iconName: "awesome/plus"
					iconColor: Material.Theme.light.hintColor

					onClicked: {
						addFriendRoom.show()
					}
				}
			}

			Material.Scrollbar {
				anchors.margins: 0
				flickableItem: roomFriendsList
			}
		}

		Material.Dialog {
			id: addFriendRoom

			positiveButtonText: "Cancel"
			negativeButtonText: "Add"

			positiveButtonSize: dp(13)
			negativeButtonSize: dp(13)

			onRejected: {
				pgpsList = pgpsList.sort().filter((function(item, pos, ary) {
					return !pos || item != ary[pos - 1];
				}))
				pgpsList.forEach(inviteFriends)
			}
			onClosed: pgpsList = []

			property var pgpsList: []

			function inviteFriends(pgp) {
				var jsonData = {
					chat_id: chatId,
					pgp_id: pgp
				}

				rsApi.request("/chat/invite_to_lobby/", JSON.stringify(jsonData), function(){})
			}

			Material.Label {
				anchors.left: parent.left

				height: dp(50)
				verticalAlignment: Text.AlignVCenter

				wrapMode: Text.Wrap
				text: "Invite Friend"
				style: "title"
				color: Material.Theme.accentColor
			}

			Item {
				width: dp(300)
				height: dp(320)

				Material.View {
					id: addFriendFilter

					anchors {
						top: parent.top
						horizontalCenter: parent.horizontalCenter
					}

					height: dp(25)
					width: parent.width - dp(16)

					z: 1
					radius: 10
					elevation: 1
					backgroundColor: "white"

					Material.TextField {
						anchors {
							fill: parent
							verticalCenter: parent.verticalCenter
							leftMargin: dp(18)
							rightMargin: dp(18)
						}

						placeholderText: "Search friend"
						placeholderPixelSize: dp(15)

						font {
							weight: Font.Light
							pixelSize: dp(15)
						}

						focus: true
						showBorder: false

						onActiveFocusChanged: {
							if(activeFocus)
								addFriendFilter.elevation = 2
							else
								addFriendFilter.elevation = 1
						}
						onTextChanged: {
							roomInvitationSortModel.setSearchText(text)

							if(mainGUIObject.advmode)
								roomInvitationSortModel.setSearchText(text)
						}
						onAccepted: {
							roomInvitationSortModel.setSearchText(text)

							if(mainGUIObject.advmode)
								roomInvitationSortModel.setSearchText(text)
						}
					}
				}

				ListView {
					id: addRoomFriendsList

					anchors {
						fill: parent
						topMargin: dp(25)
					}

					clip: true
					snapMode: ListView.NoSnap
					flickableDirection: Flickable.AutoFlickDirection

					model: roomInvitationSortModel

					delegate: RoomFriend {
						property string avatar: (gxs_avatars.getAvatar(model.gxs_id) == "none"
												 || gxs_avatars.getAvatar(model.gxs_id) == "")
												? "none"
												: gxs_avatars.getAvatar(model.gxs_id)

						onAvatarChanged: {
							imageSource = avatar
							image.loadImage(avatar)
						}

						width: parent.width

						text: model.name
						textColor: selected ? Material.Theme.primaryColor : Material.Theme.light.textColor
						itemLabel.style: "body1"

						imageSource: avatar
						isIcon: avatar == "none"
						iconName: "awesome/user_o"
						iconSize: dp(32)

						Connections {
							target: addFriendRoom
							onClosed: selected = false
						}

						Component.onCompleted: {
							if(gxs_avatars.getAvatar(model.gxs_id) == "")
								getIdentityAvatar()
						}

						function getIdentityAvatar() {
							var jsonData = {
								gxs_id: model.gxs_id
							}

							function callbackFn(par) {
								var json = JSON.parse(par.response)
								if(json.returncode == "fail") {
									getIdentityAvatar()
									return
								}

								gxs_avatars.storeAvatar(model.gxs_id, json.data.avatar)
								if(gxs_avatars.getAvatar(model.gxs_id) != "none")
									avatar = gxs_avatars.getAvatar(model.gxs_id)
							}

							rsApi.request("/identity/get_avatar", JSON.stringify(jsonData), callbackFn)
						}

						onClicked: {
							if(selected)
								addFriendRoom.pgpsList.splice(addFriendRoom.pgpsList.indexOf(model.pgp_id), 1)
							else
								addFriendRoom.pgpsList.push(model.pgp_id)

							selected = !selected
						}
					}

					header: Item {
						height: dp(15)
						width: parent.width
					}
				}

				Material.Scrollbar {
					anchors.margins: 0
					flickableItem: addRoomFriendsList
				}
			}
		}
	}
}
