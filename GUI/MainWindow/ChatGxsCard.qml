/****************************************************************
 *  This file is part of Sonet.
 *  Sonet is distributed under the following license:
 *
 *  Copyright (C) 2017, Konrad Dębiec
 *
 *  Sonet is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU General Public License
 *  as published by the Free Software Foundation; either version 3
 *  of the License, or (at your option) any later version.
 *
 *  Sonet is distributed in the hope that it will be useful,
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
import QtGraphicalEffects 1.0

import Material 0.3
import Material.ListItems 0.1 as ListItem

DragTile {
	id: drag

	property string gxsId
	property string chatId
	property string name
	property alias contentm: contentm

	property int status: 1

	// For handling tokens
	property int stateToken: 0

	// Just for "restore" option
	property int tmpCol
	property int tmpRow
	property int tmpGridX: 0   // Numbering starts from 0
	property int tmpGridY: 0   // Numbering starts from 0
	property bool maximized: false
	//

	Layout.alignment: Qt.AlignBottom
	Layout.maximumWidth: 0
	Layout.maximumHeight: 0

	width: 0
	height: 0

	col: 5
	row: 3

	opacity: 0

	Behavior on gridX {
		ScriptAction { script: {drag.refresh()} }
	}

	Behavior on row {
		ScriptAction { script: {contentm.positionViewAtEnd()} }
	}

	ParallelAnimation {
		running: true
		SequentialAnimation {
			NumberAnimation {
				duration: 50
			}
			NumberAnimation {
				target: drag
				property: "opacity"
				from: 0
				to: 1
				duration: MaterialAnimation.pageTransitionDuration/2
			}
		}
	}

	JSONListModel {
		id: msgModel
		query: "$.data[*]"
	}

	Component.onDestruction: closeChat()

	function initiateChat() {
		var jsonData = {
			own_gxs_hex: main.defaultGxsId,
			remote_gxs_hex: drag.gxsId
		}

		function callbackFn(par) {
			chatId = String(JSON.parse(par.response).data.chat_id)
			timer.running = true
		}

		rsApi.request("/chat/initiate_distant_chat/", JSON.stringify(jsonData), callbackFn)
	}

	function checkChatStatus() {
		var jsonData = {
			chat_id: drag.chatId
		}

		function callbackFn(par) {
			if(status != String(JSON.parse(par.response).data.status)) {
				status = String(JSON.parse(par.response).data.status)
				if(status == 2)
					drag.getChatMessages()
			}

		}

		rsApi.request("/chat/distant_chat_status/", JSON.stringify(jsonData), callbackFn)
	}

	function closeChat() {
		var jsonData = {
			distant_chat_hex: drag.chatId
		}

		rsApi.request("/chat/close_distant_chat/", JSON.stringify(jsonData))
	}

	function getChatMessages() {
		if (drag.chatId == "")
			return

		function callbackFn(par) {
			msgModel.json = par.response
			contentm.positionViewAtEnd()

			stateToken = JSON.parse(par.response).statetoken
			main.registerToken(stateToken, getChatMessages)
		}

		rsApi.request("/chat/messages/"+drag.chatId, "", callbackFn)
	}

	Component.onCompleted: drag.initiateChat()

	View {
		id: chat

		anchors.fill: parent

		elevation: 2
		backgroundColor: Palette.colors["grey"]["50"]

		Behavior on anchors.topMargin {
			NumberAnimation { duration: MaterialAnimation.pageTransitionDuration }
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
				onClicked: overflowMenu5.open(drag, mouse.x, mouse.y);

				Item {
					anchors {
						bottom: parent.bottom
						top: parent.top
						horizontalCenter: parent.horizontalCenter
					}

					width: parent.width > dp(9*60+(30)) ? dp(9*60) : (parent.width-dp(30))

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
							left: parent.left
							leftMargin: dp(20)
						}

						font {
							family: "Roboto"
							pixelSize: dp(17)
						}

						text: name

						color: Theme.primaryColor
					}

					Item {
						anchors {
							verticalCenter: parent.verticalCenter
							right: parent.right
							rightMargin: dp(18)
						}

						width: dp(23)
						height: dp(23)

						Rectangle {
							id: closeButton

							anchors.centerIn: parent

							width: dp(20)
							height: dp(2.5)

							rotation: 45
							color: Palette.colors["grey"]["500"]
						}

						Rectangle {
							id: closeButton2

							anchors.centerIn: parent

							width: dp(20)
							height: dp(2.5)

							rotation: -45
							color: Palette.colors["grey"]["500"]
						}

						MouseArea {
							anchors.fill: parent

							hoverEnabled: true

							onEntered: {
								closeButton.color = Theme.accentColor
								closeButton2.color = Theme.accentColor
							}
							onExited: {
								closeButton.color = Palette.colors["grey"]["500"]
								closeButton2.color = Palette.colors["grey"]["500"]
							}
							onClicked: drag.destroy()
						}
					}
				}

				Dropdown {
					id: overflowMenu5
					objectName: "overflowMenu5"
					overlayLayer: "dialogOverlayLayer"

					anchor: Item.TopLeft

					width: dp(200)
					height: dp(2*30)

					enabled: true

					durationSlow: 300
					durationFast: 150

					Column {
						anchors.fill: parent

						ListItem.Standard {
							height: dp(30)

							text: maximized ? "Restore" : "Maximize"
							itemLabel.style: "menu"

							onClicked: {
								overflowMenu5.close()

								if(!maximized) {
									drag.tmpGridX = drag.gridX
									drag.tmpGridY = drag.gridY
									drag.tmpCol = drag.col
									drag.tmpRow = drag.row
									drag.gridX = 0
									drag.gridY = 0
									drag.col = Qt.binding(function() {
										return parseInt(gridLayout.width / dp(60))>= 11
												? 11
												: parseInt(gridLayout.width / dp(60)) || 1
									})
									drag.row = Qt.binding(function() {
										return main.visibleRows
									})
									maximized = true
								}
								else if(maximized) {
									drag.gridX = drag.tmpGridX
									drag.gridY = drag.tmpGridY
									drag.col = drag.tmpCol
									drag.row = drag.tmpRow
									maximized = false
								}

								drag.refresh()
							}
						}

						ListItem.Standard {
							height: dp(30)

							text: "Close"

							itemLabel.style: "menu"

							onClicked: {
								overflowMenu5.close()
								drag.destroy()
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
				bottom: itemInfo.top
				horizontalCenter: parent.horizontalCenter
			}

			width: parent.width > dp(9*60+(30)) ? dp(9*60) : (parent.width-dp(30))

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

					model: msgModel.model
					delegate: ChatMsgDelegate{}
				}

				Scrollbar {
					anchors.margins: 0
					flickableItem: contentm
				}
			}
		}

		Item {
			id: itemInfo
			anchors {
				bottom: chatFooter.top
				horizontalCenter: parent.horizontalCenter
			}

			width: parent.width > dp(9*60+(30)) ? dp(9*60) : (parent.width-dp(30))
			height: viewInfo.height + dp(5)

			states: [
				State {
					name: "hide"; when: drag.status == 2
					PropertyChanges {
						target: itemInfo
						visible: false
					}
				},
				State {
					name: "show"; when: drag.status != 2
					PropertyChanges {
						target: itemInfo
						visible: true
					}
				}
			]

			transitions: [
				Transition {
					from: "hide"; to: "show"

					SequentialAnimation {
						PropertyAction {
							target: itemInfo
							property: "visible"
							value: true
						}
						ParallelAnimation {
							NumberAnimation {
								target: itemInfo
								property: "opacity"
								from: 0
								to: 1
								easing.type: Easing.InOutQuad;
								duration: MaterialAnimation.pageTransitionDuration
							}
							NumberAnimation {
								target: itemInfo
								property: "anchors.bottomMargin"
								from: -itemInfo.height
								to: 0
								easing.type: Easing.InOutQuad;
								duration: MaterialAnimation.pageTransitionDuration
							}
						}
					}
				},
				Transition {
					from: "show"; to: "hide"

					SequentialAnimation {
						PauseAnimation {
							duration: 2000
						}
						ParallelAnimation {
							NumberAnimation {
								target: itemInfo
								property: "opacity"
								from: 1
								to: 0
								easing.type: Easing.InOutQuad
								duration: MaterialAnimation.pageTransitionDuration
							}
							NumberAnimation {
								target: itemInfo
								property: "anchors.bottomMargin"
								from: 0
								to: -itemInfo.height
								easing.type: Easing.InOutQuad
								duration: MaterialAnimation.pageTransitionDuration
							}
						}
						PropertyAction {
							target: itemInfo;
							property: "visible";
							value: false
						}
					}
				}
			]

			View {
				id: viewInfo
				anchors {
					right: parent.right
					left: parent.left
					top: parent.top
					rightMargin: parent.width*0.03
					leftMargin: parent.width*0.03
				}

				height: textMsg.implicitHeight + dp(12)
				width: (parent.width*0.8)

				backgroundColor: Theme.accentColor
				elevation: 1
				radius: 10


				TextEdit {
					id: textMsg

					anchors {
						top: parent.top
						topMargin: dp(6)
						left: parent.left
						right: parent.right
					}

					text: drag.status == 0 ? "Something goes wrong..."
						: drag.status == 1 ? "Tunnel is pending..."
						: drag.status == 2 ? "Connection is established"
						: drag.status == 3 ? "Your friend closed chat."
						: "Something goes wrong..."

					textFormat: Text.RichText
					wrapMode: Text.WordWrap

					color: "white"
					readOnly: true

					selectByMouse: false

					horizontalAlignment: TextEdit.AlignHCenter

					font {
						family: "Roboto"
						pixelSize: dp(13)
					}
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

			height: (msgBox.contentHeight < dp(20) ? (msgBox.contentHeight+dp(30)) : (msgBox.contentHeight+dp(22))) < dp(200)
					    ? (msgBox.contentHeight < dp(20) ? (msgBox.contentHeight+dp(30)) : (msgBox.contentHeight+dp(22)))
						: dp(200)

			z: 1

			Behavior on height {
				ScriptAction {script: contentm.positionViewAtEnd()}
			}

			View {
				id: footerView

				anchors {
					bottom: parent.bottom
					top: parent.top
					horizontalCenter: parent.horizontalCenter
					bottomMargin: dp(10)
				}

				width: parent.width > dp(9*60+(30)) ? dp(9*60) : (parent.width-dp(30))

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
							rsApi.request("/chat/mark_chat_as_read/"+drag.chat_id)
							footerView.elevation = 2
						}
						else
							footerView.elevation = 1
					}

					Keys.onPressed: {
						if(event.key == Qt.Key_Return) {
							var jsonData = {
								chat_id: drag.chatId,
								msg: msgBox.text
							}
							rsApi.request("chat/send_message/", JSON.stringify(jsonData))
							drag.getChatMessages()
							msgBox.text = ""
							event.accepted = true
						}
					}
				}
			}
		}

		Timer {
			id: timer
			interval: 1000
			repeat: true
			running: false

			onTriggered: drag.checkChatStatus()
		}
	}
}
