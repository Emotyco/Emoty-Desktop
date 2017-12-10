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

import MessagesModel 0.2

Card {
	id: drag

	property string rsPeerId
	property string chatId
	property alias contentm: contentm

	// For handling tokens
	property int stateToken: 0
	property int stateToken_unreadMsgs: 0

	Component.onDestruction: {
		mainGUIObject.unregisterTokenWithIndex(stateToken, cardIndex)
		mainGUIObject.unregisterTokenWithIndex(stateToken_unreadMsgs, cardIndex)
	}
	Behavior on height {
		ScriptAction { script: {contentm.positionViewAtEnd()} }
	}

	function getChatMessages() {
		function callbackFn(par) {
			stateToken = JSON.parse(par.response).statetoken
			mainGUIObject.registerTokenWithIndex(stateToken, getChatMessages, cardIndex)

			messagesModel.loadJSONMessages(par.response)
		}

		rsApi.request("/chat/messages/"+drag.chatId, "", callbackFn)
	}

	function getUnreadMsgs() {
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

			stateToken_unreadMsgs = jsonResp.statetoken
			mainGUIObject.registerTokenWithIndex(stateToken_unreadMsgs, getUnreadMsgs, cardIndex)
		}

		rsApi.request("/chat/unread_msgs/", "", callbackFn)
	}

	Component.onCompleted: {
		drag.getChatMessages()
		getUnreadMsgs()
	}

	MessagesModel {
		id: messagesModel
	}

	Item {
		anchors.fill: parent

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
				delegate: ChatMsgDelegate{}

				header: Item {
					width: 1
					height: dp(5)
				}

				footer: Item{
					width: 1
					height: dp(15)
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

			height: (msgBox.contentHeight < dp(20) ? (msgBox.contentHeight+dp(30)) : (msgBox.contentHeight+dp(22))) < dp(200)
					    ? (msgBox.contentHeight < dp(20) ? (msgBox.contentHeight+dp(30)) : (msgBox.contentHeight+dp(22)))
						: dp(200)

			z: 1

			Behavior on height {
				ScriptAction {script: contentm.positionViewAtEnd()}
			}

			Material.View {
				id: footerView

				anchors {
					fill: parent
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

					placeholderText: footerView.width > dp(195) ? "Say hello to your friend" : "Say hello"

					font.pixelSize: dp(15)

					wrapMode: Text.WordWrap
					frameVisible: false
					focus: true

					horizontalScrollBarPolicy: Qt.ScrollBarAlwaysOff
					verticalScrollBarPolicy: Qt.ScrollBarAlwaysOff

					onActiveFocusChanged: {
						if(activeFocus) {
							if(drag.chatId.length > 0)
								rsApi.request("/chat/mark_chat_as_read/"+drag.chatId, "", function(){})

							footerView.elevation = 2
						}
						else
							footerView.elevation = 1
					}

					Keys.onPressed: {
						if(event.key == Qt.Key_Return) {
							event.accepted = true
							if(msgBox.text.length > 0) {
								var jsonData = {
									chat_id: drag.chatId,
									msg: msgBox.text
								}
								rsApi.request("chat/send_message/", JSON.stringify(jsonData), function(){})
								drag.getChatMessages()
								msgBox.text = ""

								soundNotifier.playChatMessageSended()
							}
						}
					}
				}
			}
		}
	}
}
