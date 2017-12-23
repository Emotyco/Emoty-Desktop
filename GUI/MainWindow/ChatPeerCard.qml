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
	id: chatCard

	property string rsPeerId
	property string chatId
	property alias contentm: contentm
	property int statusTimestamp: 0

	property string typingIdentityName: ""
	property int typingTimestamp: 0
	property bool isTyping: false

	// For handling tokens
	property int stateToken: 0
	property int stateToken_unreadMsgs: 0
	property int stateToken_status: 0

	Component.onDestruction: {
		mainGUIObject.unregisterTokenWithIndex(stateToken, cardIndex)
		mainGUIObject.unregisterTokenWithIndex(stateToken_unreadMsgs, cardIndex)
		mainGUIObject.unregisterTokenWithIndex(stateToken_status, cardIndex)
	}
	Behavior on height {
		ScriptAction { script: {contentm.positionViewAtEnd()} }
	}

	function getChatStatus() {
		function callbackFn(par) {
			stateToken_status = JSON.parse(par.response).statetoken
			mainGUIObject.registerTokenWithIndex(stateToken_status, getChatStatus, cardIndex)

			var jsonResp = JSON.parse(par.response)
			if(jsonResp.data.status_string == "is typing...") {
				chatCard.typingIdentityName = jsonResp.data.author_name

				if(chatCard.typingIdentityName != ""
						&& Date.now()/1000 < parseInt(jsonResp.data.timestamp)+4) {
					typingTimer.start()
					chatCard.isTyping = true
					chatCard.typingTimestamp = jsonResp.data.timestamp
				}
			}
		}

		rsApi.request("/chat/receive_status/"+chatId, "", callbackFn)
	}

	function getChatMessages() {
		function callbackFn(par) {
			stateToken = JSON.parse(par.response).statetoken
			mainGUIObject.registerTokenWithIndex(stateToken, getChatMessages, cardIndex)

			messagesModel.loadJSONMessages(par.response)
		}

		rsApi.request("/chat/messages/"+chatCard.chatId, "", callbackFn)
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
		chatCard.getChatMessages()
		getUnreadMsgs()
		getChatStatus()
	}

	Timer {
		id: typingTimer
		running: false
		repeat: true
		interval: 1000
		onTriggered: {
			if(Date.now()/1000 > chatCard.typingTimestamp+4
					|| chatCard.typingTimestamp == 0) {
				chatCard.isTyping = false
				typingTimer.stop()
			}
		}
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
				delegate: ChatMsgDelegate{}

				header: Item {
					width: 1
					height: dp(5)
				}

				footer: Item{
					width: 1
					height: dp(15)
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

			height: (msgBox.contentHeight < dp(20) ? (msgBox.contentHeight+dp(40)) : (msgBox.contentHeight+dp(32))) < dp(200)
					    ? (msgBox.contentHeight < dp(20) ? (msgBox.contentHeight+dp(40)) : (msgBox.contentHeight+dp(32)))
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
					bottomMargin: dp(20)
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

					Keys.onPressed: {
						if(event.key == Qt.Key_Return) {
							event.accepted = true
							if(msgBox.text.length > 0) {
								var jsonData = {
									chat_id: chatCard.chatId,
									msg: msgBox.text
								}
								rsApi.request("chat/send_message/", JSON.stringify(jsonData), function(){})
								chatCard.getChatMessages()
								msgBox.text = ""

								soundNotifier.playChatMessageSended()
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

				visible: chatCard.isTyping

				style: "caption"
				font.pixelSize: dp(11)
				font.weight: Font.DemiBold

				color: Material.Theme.light.subTextColor
				text: chatCard.typingIdentityName + " is typing..."

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
}
