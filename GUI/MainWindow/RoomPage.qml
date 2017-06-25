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
import QtGraphicalEffects 1.0

import Material 0.3
import Material.ListItems 0.1 as ListItem

Item{
	id: page
	property string title: "roomPage"

	property string roomName
	property string chatId

	// For handling tokens
	property int stateToken_p: 0
	property int stateToken_msg: 0
	property int stateToken_gxs: 0

	Component.onDestruction: {
		main.unregisterToken(stateToken_p)
		main.unregisterToken(stateToken_msg)
		main.unregisterToken(stateToken_gxs)
	}

	property bool firstTime_msg: true

	// Just for "restore" option
	property int tmpCol: 0
	property int tmpRow: 0
	property int tmpGridX: 0   // Numbering starts from 0
	property int tmpGridY: 0   // Numbering starts from 0
	property bool maximized: false
	//

	function getLobbyParticipants() {
		function callbackFn(par) {
			lobbyParticipantsModel.json = par.response
			stateToken_p = JSON.parse(par.response).statetoken
			main.registerToken(stateToken_p, getLobbyParticipants)
		}

		rsApi.request("/chat/lobby_participants/"+chatId, "", callbackFn)
	}

	function getLobbyMessages() {
		function callbackFn(par) {
			if(firstTime_msg)
				firstTime_msg = false

			messagesModel.json = par.response
			contentm.positionViewAtEnd()

			stateToken_msg = JSON.parse(par.response).statetoken
			main.registerToken(stateToken_msg, getLobbyMessages)
		}

		rsApi.request("/chat/messages/"+chatId, "", callbackFn)
	}

	function getGxsId() {
		function callbackFn(par) {
			gxsIdModel.json = par.response
			stateToken_gxs = JSON.parse(par.response).statetoken
			main.registerToken(stateToken_gxs, getGxsId)
		}

		rsApi.request("/identity/notown_ids/", "", callbackFn)
	}

	Component.onCompleted: {
		getLobbyMessages();
		getLobbyParticipants()
		getGxsId()
	}

	Connections {
		target: main.content
		onRefresh: {
			updateVisibleRows()
			if(
					main.content.col === (parseInt(gridLayout.width / (dp(50) + gridLayout.columnSpacing))>= 14
										  ? 14
										  : parseInt(gridLayout.width / (dp(50) + gridLayout.columnSpacing))) &&
					main.content.row === main.visibleRows &&
					main.content.gridX === Math.floor(((parseInt(gridLayout.width / (dp(50) + gridLayout.columnSpacing)))-main.content.col)/2) &&
					main.content.gridY === 0
					)
				maximized = true
			else
				maximized = false
		}
	}

	JSONListModel {
		id: lobbyParticipantsModel
		query: "$.data[*]"
	}

	JSONListModel {
		id: messagesModel
		query: "$.data[*]"
	}

	JSONListModel {
		id: gxsIdModel
		query: "$.data[*]"
	}

	View {
		id: chat

		anchors.fill: parent

		elevation: 2
		backgroundColor: Palette.colors["grey"]["50"]

		LoadingMask {
			id: loadingMask
			anchors.fill: parent

			state: firstTime_msg ? "visible" : "non-visible"
		}

		Rectangle {
			id: chatHeader

			anchors {
				top: parent.top
				left: parent.left
				right: parent.right
			}

			height: dp(35)
			color: Palette.colors["grey"]["50"]
			z: 2

			MouseArea {
				anchors.fill: parent

				acceptedButtons: Qt.RightButton
				onClicked: overflowMenu.open(pageStack, mouse.x, mouse.y);

				Item {
					anchors {
						bottom: parent.bottom
						top: parent.top
						left: parent.left
						right: parent.right
						leftMargin: dp(15)
						rightMargin: dp(15)
					}

					Rectangle {
						anchors {
							left: parent.left
							right: parent.right
							bottom: parent.bottom
						}

						height: dp(1)
						color: Palette.colors["grey"]["200"]
					}

					Text {
						id: headertext

						anchors {
							verticalCenter: parent.verticalCenter
							leftMargin: dp(20)
							left: parent.left
						}

						text: roomName

						font.pixelSize: dp(17)
						font.family: "Roboto"

						color: Theme.primaryColor
					}
				}

				Dropdown {
					id: overflowMenu
					objectName: "overflowMenu"
					overlayLayer: "dialogOverlayLayer"

					anchor: Item.TopLeft

					width: dp(200)
					height: dp(2*30)

					enabled: true

					durationSlow: 300
					durationFast: 150

					Column{
						anchors.fill: parent

						ListItem.Standard {
							height: dp(30)

							text: maximized ? "Restore" : "Maximize"
							itemLabel.style: "menu"

							onClicked: {
								overflowMenu.close()
								updateVisibleRows()

								if(!maximized) {
									page.tmpGridX = main.content.gridX
									page.tmpGridY = main.content.gridY
									page.tmpCol = main.content.col
									page.tmpRow = main.content.row

									main.content.col = Qt.binding(function() {
										return parseInt(gridLayout.width / (dp(50) + gridLayout.columnSpacing))>= 14
												? 14
												: parseInt(gridLayout.width / (dp(50) + gridLayout.columnSpacing))
									});

									main.content.row = Qt.binding(function() {
										updateVisibleRows()
										return main.visibleRows
									});

									main.content.gridX = Qt.binding(function() {
										return Math.floor(((parseInt(gridLayout.width / (dp(50) + gridLayout.columnSpacing)))-main.content.col)/2)
									});

									main.content.gridY = 0

									maximized = true
								}
								else if(maximized) {
									main.content.gridX = page.tmpGridX
									main.content.gridY = page.tmpGridY
									main.content.col = page.tmpCol
									main.content.row = page.tmpRow
									maximized = false
								}

								main.content.refresh()
							}
						}

						ListItem.Standard {
							height: dp(30)

							text: "Hide"
							itemLabel.style: "menu"

							onClicked: {
								overflowMenu.close()
								main.content.activated = false
							}
						}
					}
				}
			}
		}

		DropShadow {
			anchors.fill: chatHeader

			verticalOffset: dp(5)
			radius: 30
			samples: 61

			color: Palette.colors["grey"]["50"]
			source: chatHeader
			z: 1
		}

		Item {
			anchors {
				top: chatHeader.bottom
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

				Item {
					anchors {
						fill: parent
						margins: dp(2)
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

						model: messagesModel.model
						delegate: RoomMsgDelegate{}
					}

					Scrollbar {
						anchors.margins: 0
						flickableItem: contentm
					}
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

				Behavior on height {
					ScriptAction{script: contentm.positionViewAtEnd()}
				}

				View {
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
								var jsonData = {
									chat_id: chatId,
									msg: msgBox.text
								}

								rsApi.request("chat/send_message/", JSON.stringify(jsonData), function(){})

								getLobbyMessages()
								contentm.positionViewAtEnd()
								msgBox.text = "";
								event.accepted = true;

								soundNotifier.playChatMessageSended()
							}
						}
					}
				}
			}
		}

		Item {
			anchors {
				top: chatHeader.bottom
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

				View {
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

					TextField {
						id: msgBox2

						anchors {
							fill: parent
							verticalCenter: parent.verticalCenter
							leftMargin: dp(18)
							rightMargin: dp(18)
						}

						readOnly: true

						placeholderText: "Search friends"
						placeholderPixelSize: dp(15)

						font {
							weight: Font.Light
							pixelSize: dp(15)
						}

						focus: true
						showBorder: false

						/*onActiveFocusChanged: {
							if(activeFocus)
								friendFilter.elevation = 2
							else
								friendFilter.elevation = 1
						}*/
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

				model: lobbyParticipantsModel.model

				delegate: RoomFriend {
					property string avatar: "avatar.png"

					width: parent.width

					text: model.identity.name
					textColor: Theme.light.textColor
					itemLabel.style: "body1"

					imageSource: avatar
					isIcon: false

					Component.onCompleted: {
						getIdentityAvatar()
					}

					function getIdentityAvatar() {
						var jsonData = {
							gxs_id: model.identity.gxs_id
						}

						function callbackFn(par) {
							var json = JSON.parse(par.response)
							if(json.data.avatar.length > 0)
								avatar = "data:image/png;base64," + json.data.avatar
						}

						rsApi.request("/identity/get_avatar", JSON.stringify(jsonData), callbackFn)
					}
				}

				footer: RoomFriend {
					width: parent.width

					interactive: false

					text: "Add to room"
					textColor: Theme.light.hintColor//Theme.light.textColor
					itemLabel.style: "body1"

					iconName: "awesome/plus"
					iconColor: Theme.light.hintColor

					onClicked: {
						addFriendRoom.show()
					}
				}
			}

			Scrollbar {
				anchors.margins: 0
				flickableItem: roomFriendsList
			}
		}

		Dialog {
			id: addFriendRoom

			positiveButtonText: "Cancel"
			negativeButtonText: "Add"

			contentMargins: dp(8)
			width: dp(250)

			positiveButtonSize: dp(13)
			negativeButtonSize: dp(13)

			Item {
				anchors {
					left: parent.left
					right: parent.right
				}

				height: dp(350)

				Item {
					anchors {
						top: parent.top
						left: parent.left
						right: parent.right
						leftMargin: dp(8)
						rightMargin: dp(8)
					}

					height: dp(45)
					width: parent.width
					z: 1

					View {
						id: addFriendFilter

						anchors {
							horizontalCenter: parent.horizontalCenter
							verticalCenter: parent.verticalCenter
						}

						height: dp(25)
						width: parent.width

						radius: 10
						elevation: 1
						backgroundColor: "white"

						TextField {
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
									addFriendFilter.elevation = 2
								else
									addFriendFilter.elevation = 1
							}
						}
					}
				}

				ListView {
					id: addRoomFriendsList

					anchors {
						fill: parent
						topMargin: dp(45)
					}

					clip: true
					snapMode: ListView.NoSnap
					flickableDirection: Flickable.AutoFlickDirection

					model: gxsIdModel.model

					delegate: RoomFriend {
						width: parent.width

						text: model.name
						textColor: selected ? Theme.primaryColor : Theme.light.textColor
						itemLabel.style: "body1"

						imageSource: "avatar.png"
						isIcon: false

						onClicked: {
							selected = !selected
						}
					}
				}

				Scrollbar {
					anchors.margins: 0
					flickableItem: addRoomFriendsList
				}
			}
		}

		ParallelAnimation {
			running: true
			NumberAnimation {
				target: content
				property: "opacity"
				from: 0
				to: 1
				duration: MaterialAnimation.pageTransitionDuration
			}
		}
	}
}
