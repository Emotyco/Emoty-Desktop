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

import QtQuick 2.7
import QtQuick.Controls 2.2

import Material 0.3 as Material
import Material.ListItems 0.1 as ListItem

import RoomParticipantsSortModel 0.2
import RoomInvitationSortModel 0.2
import MessagesModel 0.2

import "qrc:/eojson.js" as EmojiOneJson

Card {
	id: roomCard
	property var chatId
	property int statusTimestamp: 0

	property string typingIdentityName: ""
	property int typingTimestamp: 0
	property bool isTyping: false

	// For handling tokens
	property int stateToken_p: 0
	property int stateToken_msg: 0
	property int stateToken_gxsContacts: 0
	property int stateToken_unreadCount: 0
	property int stateToken_status: 0

	Component.onDestruction: {
		mainGUIObject.unregisterTokenWithIndex(stateToken_p, cardIndex)
		mainGUIObject.unregisterTokenWithIndex(stateToken_msg, cardIndex)
		mainGUIObject.unregisterTokenWithIndex(stateToken_gxsContacts, cardIndex)
		mainGUIObject.unregisterTokenWithIndex(stateToken_unreadCount, cardIndex)
		mainGUIObject.unregisterTokenWithIndex(stateToken_status, cardIndex)
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

	function getChatStatus() {
		function callbackFn(par) {
			stateToken_status = JSON.parse(par.response).statetoken
			mainGUIObject.registerTokenWithIndex(stateToken_status, getChatStatus, cardIndex)

			var jsonResp = JSON.parse(par.response)
			if(jsonResp.data.status_string == "is typing...") {
				typingIdentityName = jsonResp.data.author_name

				if(typingIdentityName != ""
						&& Date.now()/1000 < parseInt(jsonResp.data.timestamp)+4) {
					typingTimer.start()
					roomCard.isTyping = true
					roomCard.typingTimestamp = jsonResp.data.timestamp
				}
			}
		}

		rsApi.request("/chat/receive_status/"+chatId, "", callbackFn)
	}

	Component.onCompleted: {
		getLobbyMessages();
		getLobbyParticipants()
		getContacts()
		getUnreadCount()
		getChatStatus()
	}

	Timer {
		id: typingTimer
		running: false
		repeat: true
		interval: 1000
		onTriggered: {
			if(Date.now()/1000 > typingTimestamp+4 || typingTimestamp == 0) {
				roomCard.isTyping = false
				typingTimer.stop()
			}
		}
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

					property bool lastVisible: true
					property bool complete: false
					Component.onCompleted: complete = true

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
									if(contentm.complete) {
										contentm.positionViewAtEnd()
										contentm.lastVisible = true
									}
								}
							}
						}
					}

					Material.View {
						id: notiView
						anchors {
							bottom: parent.bottom
							horizontalCenter: parent.horizontalCenter
							bottomMargin: dp(15)
						}

						height: notiMsg.implicitHeight + dp(8)
						width: parent.width*0.8

						backgroundColor: Material.Theme.accentColor
						elevation: 2
						radius: 10

						states: [
							State {
								name: "hide"; when: !(indicatorNumber > 0 && !contentm.lastVisible)
								PropertyChanges {
									target: notiView
									visible: false
								}
							},
							State {
								name: "show"; when: indicatorNumber > 0 && !contentm.lastVisible
								PropertyChanges {
									target: notiView
									visible: true
								}
							}
						]

						transitions: [
							Transition {
								from: "hide"; to: "show"

								SequentialAnimation {
									PropertyAction {
										target: notiView
										property: "visible"
										value: true
									}
									ParallelAnimation {
										NumberAnimation {
											target: notiView
											property: "opacity"
											from: 0
											to: 1
											easing.type: Easing.InOutQuad;
											duration: Material.MaterialAnimation.pageTransitionDuration
										}
										NumberAnimation {
											target: notiView
											property: "anchors.bottomMargin"
											from: -notiView.height
											to: dp(15)
											easing.type: Easing.InOutQuad;
											duration: Material.MaterialAnimation.pageTransitionDuration
										}
									}
								}
							},
							Transition {
								from: "show"; to: "hide"

								SequentialAnimation {
									ParallelAnimation {
										NumberAnimation {
											target: notiView
											property: "opacity"
											from: 1
											to: 0
											easing.type: Easing.InOutQuad
											duration: Material.MaterialAnimation.pageTransitionDuration
										}
										NumberAnimation {
											target: notiView
											property: "anchors.bottomMargin"
											from: dp(15)
											to: -notiView.height
											easing.type: Easing.InOutQuad
											duration: Material.MaterialAnimation.pageTransitionDuration
										}
									}
									PropertyAction {
										target: notiView;
										property: "visible";
										value: false
									}
								}
							}
						]

						MouseArea {
							anchors.fill: parent
							onClicked: contentm.positionViewAtEnd()
						}

						Text {
							id: notiMsg

							anchors {
								top: parent.top
								topMargin: dp(4)
								left: parent.left
								right: parent.right
							}
							text: "New message arrived"

							color: "white"
							horizontalAlignment: TextEdit.AlignHCenter

							font {
								family: "Roboto"
								pixelSize: dp(13)
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

				height: msgBox.contentHeight+dp(40) < dp(200) ? msgBox.contentHeight+dp(40) : dp(200)
				z: 1

				Material.View {
					id: footerView

					anchors {
						top: parent.top
						bottom: parent.bottom
						left: parent.left
						right: parent.right
						leftMargin: dp(15)
						rightMargin: dp(15)
						bottomMargin: dp(20)
					}

					radius: 10
					elevation: 1
					backgroundColor: "white"

					ScrollView {
						anchors {
							left: parent.left
							top: parent.top
							bottom: parent.bottom
							right: emojiButton.left
							topMargin: dp(5)
							bottomMargin: dp(5)
							leftMargin: dp(18)
							rightMargin: dp(18)
						}

						TextArea {
							id: msgBox

							placeholderText: "Say hello to your friends"
							font.pixelSize: dp(15)
							font.family: "Roboto"
							wrapMode: Text.Wrap
							focus: true
							selectedTextColor: "white"
							selectionColor: Material.Theme.accentColor
							selectByMouse: true

							onActiveFocusChanged: {
								if(activeFocus)
									footerView.elevation = 2
								else
									footerView.elevation = 1
							}

							onTextChanged: {
								if(msgBox.text.length != 0 && (statusTimestamp == 0 || statusTimestamp+2000 < Date.now())) {
									var jsonData = {
										chat_id: chatId,
										status: "is typing..."
									}

									rsApi.request("chat/send_status/", JSON.stringify(jsonData), function(){})
									statusTimestamp = Date.now()
								}
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

					Item {
						id: emojiButton
						anchors {
							verticalCenter: parent.verticalCenter
							right: parent.right
							rightMargin: dp(13)
						}

						width: dp(26)
						height: dp(26)

						property bool colorized: emojiPicker.showing || mA.containsMouse

						states: [
							State{
								name: "grey"; when: !(emojiPicker.showing || mA.containsMouse)
								PropertyChanges {
									target: emojiColor
									opacity: 0
								}
								PropertyChanges {
									target: emojiGrey
									opacity: 0.7
								}
							},
							State {
								name: "color"; when: (emojiPicker.showing || mA.containsMouse)
								PropertyChanges {
									target: emojiColor
									opacity: 1
								}
								PropertyChanges {
									target: emojiGrey
									opacity: 0
								}
							}
						]

						Image {
							id: emojiColor
							anchors.fill: parent

							sourceSize {
								width: dp(26)
								height: dp(26)
							}
							source: "qrc:/32/1f601.png"
							opacity: 0

							Behavior on opacity {
								NumberAnimation {
									easing.type: Easing.InOutQuad
									duration: Material.MaterialAnimation.pageTransitionDuration
								}
							}
						}

						ShaderEffect {
							id: emojiGrey
							anchors.fill: parent
							property variant src: emojiColor

							Behavior on opacity {
								NumberAnimation {
									easing.type: Easing.InOutQuad
									duration: Material.MaterialAnimation.pageTransitionDuration
								}
							}

							vertexShader: "
                                uniform highp mat4 qt_Matrix;
                                attribute highp vec4 qt_Vertex;
                                attribute highp vec2 qt_MultiTexCoord0;
                                varying highp vec2 coord;
                                void main() {
                                    coord = qt_MultiTexCoord0;
                                    gl_Position = qt_Matrix * qt_Vertex;
                                }"
							fragmentShader: "
                                varying highp vec2 coord;
                                uniform sampler2D src;
                                uniform lowp float qt_Opacity;
                                void main() {
                                    lowp vec4 tex = texture2D(src, coord);
                                    gl_FragColor = vec4(vec3(dot(tex.rgb,
                                                        vec3(0.344, 0.5, 0.156))),
                                                             tex.a) * qt_Opacity;
                                }"
						}

						MouseArea {
							id: mA
							anchors.fill: parent
							hoverEnabled: true

							onClicked: emojiPicker.open(contentm, 0, contentm.height-emojiPicker.height-dp(10))

							Material.Dropdown {
								id: emojiPicker
								objectName: "overflowMenu"
								overlayLayer: "dialogOverlayLayer"
								width: dp(400)
								height: dp(400)
								durationSlow: 300
								durationFast: 150
								internalView.radius: dp(10)

								Item {
									id: emojiPickerField
									anchors.fill: parent

									GridView {
										id: emojiGridView
										anchors {
											fill: parent
											leftMargin: dp(13)
											rightMargin: dp(13)
										}
										clip: true

										property int idealCellHeight: dp(36)
										property int idealCellWidth: dp(36)

										cellHeight: idealCellHeight
										cellWidth: width / Math.floor(width / idealCellWidth)

										model: Object.keys(EmojiOneJson.emojiAlphaCodes)
										delegate: Item {
											width: GridView.view.cellWidth
											height: GridView.view.cellHeight

											Image {
												width: dp(28)
												height: dp(28)
												source: "qrc:/32/"+ Object.keys(EmojiOneJson.emojiAlphaCodes)[index] +".png"

												MouseArea {
													anchors.fill: parent

													onClicked: {
														msgBox.insert(msgBox.cursorPosition, EmojiOneJson.emojiAlphaCodes[Object.keys(EmojiOneJson.emojiAlphaCodes)[index]]["alpha_code"])
														emojiPicker.close()
														msgBox.focus = true
													}
												}
											}
										}
									}

									Material.Scrollbar {
										anchors.margins: 0
										flickableItem: emojiGridView
									}
								}
							}
						}
					}
				}

				Material.Label {
					id: infoLabel
					anchors {
						top: footerView.bottom
						topMargin: dp(2)
						left: footerView.left
						leftMargin: dp(21)
					}

					visible: roomCard.isTyping

					style: "caption"
					font.pixelSize: dp(11)
					font.weight: Font.DemiBold

					color: Material.Theme.light.subTextColor
					text: roomCard.typingIdentityName + " is typing..."

					function addDot() {
						if(infoLabel.text.charAt(infoLabel.text.length-3) != ".")
							infoLabel.text += "."
						else
							infoLabel.text = infoLabel.text.slice(0, infoLabel.text.length-2)
					}

					Timer {
						running: infoLabel.visible
						repeat: infoLabel.visible
						interval: 500
						onTriggered: {
							infoLabel.addDot()
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
