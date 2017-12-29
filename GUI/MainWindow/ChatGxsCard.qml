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
import QtQuick.Controls 2.2

import Material 0.3 as Material
import Material.ListItems 0.1 as ListItem

import MessagesModel 0.2

import "qrc:/eojson.js" as EmojiOneJson

Card {
	id: chatCard

	property string ownGxsId
	property string ownAvatar
	property string gxsId
	property string chatId
	property alias contentm: contentm
	property int statusTimestamp: 0

	property string typingIdentityName: ""
	property int typingTimestamp: 0
	property bool isTyping: false

	property int status: 1

	// For handling tokens
	property int stateToken: 0
	property int stateToken_unreadMsgs: 0
	property int stateToken_status: 0

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

	function getChatAvatar(gxs_id) {
		if(gxs_avatars.getAvatar(gxs_id) == "") {
			var jsonData = {
				gxs_id: gxs_id
			}

			function callbackFn(par) {
				var json = JSON.parse(par.response)
				if(json.returncode == "fail") {
					getChatAvatar(gxs_id)
					return
				}

				gxs_avatars.storeAvatar(gxs_id, json.data.avatar)
				ownAvatar = gxs_avatars.getAvatar(gxs_id)
			}

			rsApi.request("/identity/get_avatar", JSON.stringify(jsonData), callbackFn)
		}
		else
			ownAvatar = gxs_avatars.getAvatar(gxs_id)
	}

	function initiateChat(gxs_id) {
		ownGxsId = gxs_id
		getChatAvatar(gxs_id)
		messagesModel.clear()

		var jsonData = {
			own_gxs_hex: gxs_id,
			remote_gxs_hex: chatCard.gxsId
		}

		function callbackFn(par) {
			chatId = String(JSON.parse(par.response).data.chat_id)
			getUnreadMsgs()
			getChatStatus()
			getChatMessages()
			timer.running = true
		}

		rsApi.request("/chat/initiate_distant_chat/", JSON.stringify(jsonData), callbackFn)
	}

	function checkChatStatus() {
		var jsonData = {
			chat_id: chatCard.chatId
		}

		function callbackFn(par) {
			if(status != String(JSON.parse(par.response).data.status)) {
				status = String(JSON.parse(par.response).data.status)
				if(status == 2)
					chatCard.getChatMessages()
			}
		}

		rsApi.request("/chat/distant_chat_status/", JSON.stringify(jsonData), callbackFn)
	}

	function closeChat() {
		var jsonData = {
			distant_chat_hex: chatCard.chatId
		}

		rsApi.request("/chat/close_distant_chat/", JSON.stringify(jsonData), function(){})
	}

	function getChatMessages() {
		if (chatCard.chatId == "")
			return

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

	Component.onCompleted: chatCard.initiateChat(mainGUIObject.defaultGxsId)
	Component.onDestruction: {
		mainGUIObject.unregisterTokenWithIndex(stateToken, cardIndex)
		mainGUIObject.unregisterTokenWithIndex(stateToken_unreadMsgs, cardIndex)
		mainGUIObject.unregisterTokenWithIndex(stateToken_status, cardIndex)
		closeChat()
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

	headerData: Item {
		id: changeIdItem
		anchors {
			right: parent.right
			verticalCenter: parent.verticalCenter
		}

		width: dp(24)
		height: dp(24)

		Canvas {
			id: image
			anchors.fill: parent

			Connections {
				target: chatCard
				onOwnAvatarChanged: {
					if(ownAvatar != "none")
						image.loadImage(ownAvatar)
				}
			}

			visible: ownAvatar != "none"
			enabled: ownAvatar != "none"
			onPaint: {
				var ctx = getContext("2d");
				if (image.isImageLoaded(ownAvatar)) {
					var profile = Qt.createQmlObject('
                        import QtQuick 2.5;
                        Image{
                            source: "'+ownAvatar+'";
                            visible:false;
                            /*fillMode: Image.PreserveAspectCrop*/
                        }', image);

					var centreX = width/2;
					var centreY = height/2;

					ctx.save()
					ctx.beginPath();
					ctx.moveTo(centreX, centreY);
					ctx.arc(centreX, centreY, width / 2, 0, Math.PI * 2, false);
					ctx.clip();
					ctx.drawImage(profile, 0, 0, image.width, image.height);
					ctx.restore()
				}
			}
			onImageLoaded:requestPaint()

			Rectangle {
				id: shaderMask
				anchors.fill: parent
				color: Qt.rgba(0,0,0,0.2)
				opacity: 0
				radius: width/2

				Behavior on opacity {
					NumberAnimation {
						duration: Material.MaterialAnimation.pageTransitionDuration
					}
				}
			}

			Material.Ink {
				anchors.fill: parent
				circular:true

				onEntered: shaderMask.opacity = 1
				onExited: shaderMask.opacity = 0
				onClicked: changeIdentity.open(changeIdItem, 0, changeIdItem.height)
			}
		}

		Material.Icon {
			id: icon
			anchors.fill: parent

			name: "awesome/user_o"
			color: Material.Theme.light.iconColor

			size: dp(width)

			visible: ownAvatar == "none"
			enabled: ownAvatar == "none"

			Material.Ink {
				anchors.fill: parent
				circular:true

				onEntered: icon.color = Material.Theme.primaryColor
				onExited: icon.color = Material.Theme.light.iconColor
				onClicked: changeIdentity.open(changeIdItem, 0, changeIdItem.height)
			}
		}

		Material.Dropdown {
			id: changeIdentity
			objectName: "overflowMenu"
			overlayLayer: "dialogOverlayLayer"

			anchor: Item.TopLeft

			width: dp(200)
			height: dp(ownGxsIdModel.count*35)

			enabled: true

			durationSlow: 300
			durationFast: 150
			internalView.radius: dp(10)
			internalView.clipContent: true

			ListView {
				anchors.fill: parent
				model: ownGxsIdModel.model
				clip: true
				delegate: Item {
					id: gxsIdentityItem
					property string avatarSrc: ""
					height: dp(35)
					width: parent.width

					function getAvatar() {
						if(gxs_avatars.getAvatar(model.own_gxs_id) == "") {
							var jsonData = {
								gxs_id: model.own_gxs_id
							}

							function callbackFn(par) {
								var json = JSON.parse(par.response)
								if(json.returncode == "fail") {
									getAvatar()
									return
								}

								gxs_avatars.storeAvatar(model.own_gxs_id, json.data.avatar)
								avatarSrc = gxs_avatars.getAvatar(model.own_gxs_id)
							}

							rsApi.request("/identity/get_avatar", JSON.stringify(jsonData), callbackFn)
						}
						else
							avatarSrc = gxs_avatars.getAvatar(model.own_gxs_id)
					}

					Component.onCompleted: {
						getAvatar()
					}

					Canvas {
						id: canvasAvatar
						anchors {
							left: parent.left
							verticalCenter: parent.verticalCenter
							leftMargin: dp(10)
						}

						width: dp(24)
						height: dp(24)

						Connections {
							target: gxsIdentityItem
							onAvatarSrcChanged: {
								if(avatarSrc != "none" && avatarSrc != "")
									canvasAvatar.loadImage(avatarSrc)
							}
						}

						visible: avatarSrc != "none" && avatarSrc != ""
						enabled: avatarSrc != "none" && avatarSrc != ""
						onPaint: {
							var ctx = getContext("2d");
							if (canvasAvatar.isImageLoaded(ownAvatar)) {
								var profile = Qt.createQmlObject('
                                    import QtQuick 2.5;
                                    Image{
                                        source: "'+avatarSrc+'";
                                        visible:false;
                                        /*fillMode: Image.PreserveAspectCrop*/
                                    }', canvasAvatar);

								var centreX = width/2;
								var centreY = height/2;

								ctx.save()
								ctx.beginPath();
								ctx.moveTo(centreX, centreY);
								ctx.arc(centreX, centreY, width / 2, 0, Math.PI * 2, false);
								ctx.clip();
								ctx.drawImage(profile, 0, 0, canvasAvatar.width, canvasAvatar.height);
								ctx.restore()
							}
						}
						onImageLoaded:requestPaint()
					}

					Material.Icon {
						anchors {
							left: parent.left
							verticalCenter: parent.verticalCenter
							leftMargin: dp(10)
						}

						name: "awesome/user_o"
						color: Material.Theme.light.iconColor

						size: dp(24)

						visible: avatarSrc == "none" || avatarSrc == ""
						enabled: avatarSrc == "none" || avatarSrc == ""
					}

					Text {
						id: identityName
						anchors {
							left: canvasAvatar.right
							right: parent.right
							verticalCenter: parent.verticalCenter
							leftMargin: dp(10)
						}

						text: model.name
						font.pixelSize: dp(12)
						font.family: "Roboto"
						color: model.own_gxs_id == chatCard.ownGxsId ? Material.Theme.primaryColor : Material.Theme.light.textColor
					}

					Material.Ink {
						anchors.fill: parent
						circular:true

						onEntered: cursor.changeCursor(Qt.PointingHandCursor)
						onExited: cursor.changeCursor(Qt.ArrowCursor)
						onClicked: {
							if(model.own_gxs_id != chatCard.ownGxsId) {
								closeChat()
								initiateChat(model.own_gxs_id)
							}

							changeIdentity.close()
						}
					}
				}
			}
		}
	}

	Item {
		id: chat
		anchors.fill: parent

		Item {
			anchors {
				top: parent.top
				bottom: itemInfo.top
				left: parent.left
				right: parent.right
				leftMargin: dp(15)
				rightMargin: dp(15)
			}

			ScrollView {
				anchors {
					fill: parent
					leftMargin: dp(5)
					rightMargin: dp(5)
				}

				ListView {
					id: contentm

					property bool lastVisible: true
					property bool complete: false
					Component.onCompleted: complete = true

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
			}
		}

		Item {
			id: itemInfo
			anchors {
				bottom: chatFooter.top
				left: parent.left
				right: parent.right
				leftMargin: dp(15)
				rightMargin: dp(15)
			}

			height: viewInfo.height + dp(5)

			states: [
				State {
					name: "hide"; when: chatCard.status == 2
					PropertyChanges {
						target: itemInfo
						visible: false
					}
				},
				State {
					name: "show"; when: chatCard.status != 2
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
								duration: Material.MaterialAnimation.pageTransitionDuration
							}
							NumberAnimation {
								target: itemInfo
								property: "anchors.bottomMargin"
								from: -itemInfo.height
								to: 0
								easing.type: Easing.InOutQuad;
								duration: Material.MaterialAnimation.pageTransitionDuration
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
								duration: Material.MaterialAnimation.pageTransitionDuration
							}
							NumberAnimation {
								target: itemInfo
								property: "anchors.bottomMargin"
								from: 0
								to: -itemInfo.height
								easing.type: Easing.InOutQuad
								duration: Material.MaterialAnimation.pageTransitionDuration
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

			Material.View {
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

				backgroundColor: Material.Theme.accentColor
				elevation: 1
				radius: 10

				Text {
					id: textMsg

					anchors {
						top: parent.top
						topMargin: dp(6)
						horizontalCenter: parent.horizontalCenter
					}

					text: chatCard.status == 0 ? "Something goes wrong..."
						: chatCard.status == 1 ? "Tunnel is pending"
						: chatCard.status == 2 ? "Connection is established"
						: chatCard.status == 3 ? "Your friend closed chat."
						: "Something goes wrong..."

					textFormat: Text.RichText
					wrapMode: Text.WordWrap

					color: "white"
					horizontalAlignment: TextEdit.AlignHCenter

					font {
						family: "Roboto"
						pixelSize: dp(13)
					}

					Text {
						id: dots
						anchors {
							left: textMsg.right
							top: parent.top
						}

						font {
							family: "Roboto"
							pixelSize: dp(13)
						}

						textFormat: Text.RichText
						wrapMode: Text.WordWrap
						color: "white"

						visible: chatCard.status == 1
						enabled: chatCard.status == 1

						function addDot() {
							if(dots.text != "...")
								dots.text += "."
							else
								dots.text = ""
						}

						Timer {
							running: chatCard.status == 1
							repeat: chatCard.status == 1
							interval: 500
							onTriggered: {
								dots.addDot()
							}
						}
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

			height: msgBox.contentHeight+dp(40) < dp(200) ? msgBox.contentHeight+dp(40) : dp(200)
			z: 1

			Material.View {
				id: footerView

				anchors {
					fill: parent
					bottomMargin: dp(20)
					leftMargin: dp(15)
					rightMargin: dp(15)
				}

				radius: 10
				elevation: 1
				backgroundColor: "white"

				MouseArea {
					id: searchHoverMA
					anchors.fill: parent
					hoverEnabled: true

					onEntered: {
						footerView.elevation = 2
						emojiButton.state = "color"
					}
					onExited: {
						emojiButton.state = "grey"

						if(msgBox.activeFocus == false)
							footerView.elevation = 1
					}
					onClicked: msgBox.forceActiveFocus()
				}

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

					hoverEnabled: true
					onHoveredChanged: {
						if(hovered) {
							footerView.elevation = 2
							emojiButton.state = "color"
						}
						else {
							emojiButton.state = "grey"

							if(msgBox.activeFocus == false)
								footerView.elevation = 1
						}
					}

					ScrollBar.vertical.visible: msgBox.contentHeight+dp(40) >= dp(200)

					TextArea {
						id: msgBox

						placeholderText: "Say hello to your friend"
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

						Keys.onPressed: {
							if(event.key == Qt.Key_Return) {
								event.accepted = true
								if(msgBox.text.length > 0 && chatCard.status == 2) {
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

						onEntered: {
							footerView.elevation = 2
							emojiButton.state = "color"
						}
						onExited: {
							emojiButton.state = "grey"

							if(msgBox.activeFocus == false)
								footerView.elevation = 1
						}

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

								ScrollView {
									anchors {
										fill: parent
										leftMargin: dp(13)
										rightMargin: dp(13)
									}

									GridView {
										id: emojiGridView

										property int idealCellHeight: dp(36)
										property int idealCellWidth: dp(36)

										clip: true

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

		Timer {
			id: timer
			interval: 1000
			repeat: true
			running: false

			onTriggered: chatCard.checkChatStatus()
		}
	}
}
