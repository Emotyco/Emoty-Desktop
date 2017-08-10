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
import QtQuick.Layouts 1.1

import Material 0.3
import Material.ListItems 0.1 as ListItem

Rectangle
{
	id: main

	property bool borderless: false
	property bool attemptLogin: false
	property bool prev_is_bad: false

	anchors.fill: parent

	state: "waiting_init"
	states:[
		State {
			name: "waiting_account_select"
			PropertyChanges { target: mask; state: "invisible"}
			StateChangeScript {script: {runStateHelper.setRunState("waiting_account_select"); getLocations()}}
		},
		State {
			name: "running_ok"
			StateChangeScript {script: {runStateHelper.setRunState("running_ok"); Qt.quit()}}
		},
		State {
			name: "running_ok_no_full_control"
			StateChangeScript {script: {runStateHelper.setRunState("running_ok_no_full_control"); Qt.quit()}}
		},
		State {
			name: "fatal_error"
			StateChangeScript {script: {runStateHelper.setRunState("fatal_error"); Qt.quit()}}
		},
		State {
			name: "waiting_startup"
			PropertyChanges { target: mask; state: "visible"}
			StateChangeScript {script: {runStateHelper.setRunState("waiting_startup")}}
		},
		State {
			name: "waiting_init"
			PropertyChanges { target: mask; state: "visible"}
			StateChangeScript {script: {runStateHelper.setRunState("waiting_init")}}
		},
		State {
			name: "checking_pass"
			PropertyChanges { target: mask; state: "visible"}
		}
	]

	transitions: Transition {
		from: "checking_pass"
		to: "waiting_account_select"

		ScriptAction {
			script: {passwordLogin.incorrect = main.prev_is_bad}
		}
	}

	Component.onCompleted: {
		getRunState()
		getLocations()
	}

	function getRunState() {
		var jsonData = {
			callback_name: "bordered_control_runstate"
		}

		function callbackFn(par) {
			if(main.state != String(JSON.parse(par.response).data.runstate))
				main.state = String(JSON.parse(par.response).data.runstate)
		}

		rsApi.request("/control/runstate/", JSON.stringify(jsonData), callbackFn)
	}

	function getLocations() {
		var jsonData = {
			callback_name: "bordered_control_locations"
		}

		function callbackFn(par) {
			if(JSON.parse(par.response).callback_name == "bordered_control_locations")
				locationsModel.json = par.response
		}

		rsApi.request("/control/locations/", JSON.stringify(jsonData), callbackFn)
	}

	Connections {
		target: rsApi
		onResponseReceived: {
			var jsonData = JSON.parse(msg)

			if(jsonData) {
				if(jsonData.data) {
					if (jsonData.data.key_name) {
						if(main.state == "checking_pass")
							main.prev_is_bad = jsonData.data.prev_is_bad
						else {
							main.prev_is_bad = jsonData.data.prev_is_bad
							passwordLogin.incorrect = main.prev_is_bad
						}

						if(jsonData.data.want_password) {
							main.state = "checking_pass"
							var jsonPass = { password: passwordLogin.text }
							rsApi.request("/control/password/", JSON.stringify(jsonPass), function(){})
						}
					}
				}
			}
		}
	}

	JSONListModel {
		id: locationsModel
		query: "$.data[*]"
	}

	CustomFontLoader {}

	AppTheme {
		primaryColor: Palette.colors["green"]["500"]
		accentColor: Palette.colors["deepOrange"]["500"]
		tabHighlightColor: "white"
	}

	Rectangle {
		id: mask

		anchors.fill: parent

		color: Qt.rgba(0,0,0,0.3)
		z: 10

		states:[
			State {
				name: "visible"
				PropertyChanges {
					target: mask
					enabled: true
					opacity: 1
				}
			},
			State {
				name: "invisible"
				PropertyChanges {
					target: mask
					enabled: false
					opacity: 0
				}
			}
		]

		transitions: [
			Transition {
				NumberAnimation {
					property: "opacity"
					easing.type: Easing.InOutQuad
					duration: 250*2
				}
			}
		]

		MouseArea {
			anchors.fill: parent

			hoverEnabled: true

			onClicked: {
				if(mouse.button == Qt.LeftButton)
					qMainPanel.mouseLPressed()
			}
			onPressed: {
				if(mouse.button == Qt.LeftButton)
					qMainPanel.mouseLPressed()
			}
		}

		Rectangle {
			anchors.fill: parent

			color: Qt.rgba(1,1,1,0.85)

			Image {
				id: logoMask

				anchors.centerIn: parent
				height: parent.height*0.3
				width: parent.width*0.3

				source: "/logo.png"
				fillMode: Image.PreserveAspectFit
				mipmap: true
			}

			ProgressCircle {
				anchors {
					top: logoMask.bottom
					horizontalCenter: parent.horizontalCenter
				}

				width: dp(35)
				height: dp(35)
				dashThickness: dp(5)

				color: Theme.primaryColor
			}
		}
	}

	Image {
		anchors {
			top: parent.top
			right: parent.right
			left: parent.horizontalCenter
			bottom: parent.bottom
		}

		source: "/robin.jpg"
		fillMode: Image.PreserveAspectCrop
		clip: true

		mipmap: true
		smooth: true

		Image {
			anchors.fill: parent

			source: "/colorful.png"
			fillMode: Image.PreserveAspectCrop
			opacity: 0.5
		}

		Item {
			anchors {
				left: parent.left
				right: parent.right
				bottom: parent.bottom
				bottomMargin: parent.height*0.65*0.25
			}

			Text {
				anchors {
					bottom: secondText.top
					left: parent.left
					right: parent.right

					leftMargin: parent.width*0.15
					rightMargin: parent.width*0.15
				}

				verticalAlignment: Text.AlignBottom
				height: dp(40)

				color: "white"
				text: "Welcome to Emoty"
				font.family: "Roboto"
				font.weight: Font.Black
				font.pixelSize: dp(34)

				wrapMode: Text.WordWrap
			}

			Text {
				id: secondText
				anchors {
					bottom: parent.bottom
					left: parent.left
					right: parent.right

					leftMargin: parent.width*0.15
					rightMargin: parent.width*0.15
				}

				verticalAlignment: Text.AlignTop
				height: dp(27)

				color: "white"
				text: "Sign in or simply get your free account"
				font.family: "Roboto"
				font.pixelSize: dp(14)

				wrapMode: Text.WordWrap
			}
		}
	}

	Rectangle {
		id: loginBody

		anchors {
			top: parent.top
			left: parent.left
			right: parent.horizontalCenter
			bottom: parent.bottom
		}

		Image {
			id: logo

			anchors {
				top: parent.top
				left: parent.left
				right: parent.right
				topMargin: parent.width*0.05
				leftMargin: parent.width*0.3
				rightMargin: parent.width*0.3
			}

			height: parent.height*0.35

			source: "/logo.png"
			fillMode: Image.PreserveAspectFit
			mipmap: true

			Component.onCompleted: {
				if(borderless)
				{
					Qt.createQmlObject('
                    import QtQuick 2.5
                    import QtQuick.Layouts 1.1

                    import Material 0.3
                    import Material.Extras 0.1

                    Row {
                        anchors {
                            top: parent.top
                            right: parent.right
                            rightMargin: dp(17)
                            topMargin: dp(12)
                        }

                        z: 100
                        spacing: 7 * Units.dp

                        MouseArea {
                            anchors.top: parent.top

                            width: dp(24)
                            height: closeButton.height - dp(7)

                            hoverEnabled: true
                            z:1

                            onEntered: mini.color = Theme.accentColor
                            onExited: mini.color = "white"
                            onClicked: qMainPanel.pushButtonMinimizeClicked()

                            Rectangle {
                                id: mini

                                anchors.bottom: parent.bottom

                                width: parent.width
                                height: dp(3)

                                color: "white"
                            }
                        }

                        IconButton {
                            id: closeButton

                            anchors.top: parent.top

                            iconSource: "/navigation_close.png"
                            inkHeight: closeButton.height
                            inkWidth: closeButton.width
                            size: dp(35)
                            color: "white"

                            onEntered: closeButton.color = Theme.accentColor
                            onExited: closeButton.color = "white"
                            onClicked: Qt.quit()
                        }
                    }', main);
				}
			}
		}

		IconButton {
			id: advButton

			anchors {
				top: parent.top
				topMargin: parent.width*0.05
				right: parent.right
				rightMargin: parent.width*0.05
			}

			iconName: "awesome/cog"
			hoverAnimation: true
			size: dp(30)
			color: Theme.light.disabledColor

			opacity: loginContent.state == "signUp" ? 1 : 0

			Behavior on opacity {
				SequentialAnimation {
					ScriptAction {
						script: {
							if(loginContent.state == "signUp") {
								advButton.visible = true
								advButton.enabled = true
							}
						}
					}
					NumberAnimation {
						easing.type: Easing.InOutQuad
						duration: 250
					}
					ScriptAction {
						script: {
							if(loginContent.state != "signUp") {
								advButton.visible = false
								advButton.enabled = false
							}
						}
					}
				}
			}

			onClicked: overflowMenu.open(advButton, -25 * Units.dp, 25 * Units.dp)
		}

		Dropdown {
			id: overflowMenu

			objectName: "overflowMenu"
			overlayLayer: "dialogOverlayLayer"

			width: dp(300)
			height: columnView.height + columnView2.height

			enabled: true

			Behavior on height {
				NumberAnimation { duration: 200 }
			}

			Rectangle {
				anchors.top: parent.top

				width: parent.width
				height: columnView.height

				z: 1

				Column {
					id: columnView

					anchors.top: parent.top
					width: parent.width

					spacing: 0

					Item {
						width: parent.width
						height: dp(10)
					}

					Item {
						width: parent.width
						height: dp(38)

						TextField {
							id: node

							anchors.centerIn: parent
							width: parent.width-dp(32)

							placeholderText: "Node name"
							floatingLabel: true
							text: "Desktop"
							font.family: "Roboto"
							font.pixelSize: dp(16)
						}
					}

					ListItem.Subtitled {
						text: "TOR/I2P Hidden node"

						height: dp(43)

						secondaryItem: Switch {
							id: hiddenNode
							anchors.verticalCenter: parent.verticalCenter
							enabled: true
						}

						onClicked: {
							hiddenNode.checked = !hiddenNode.checked
						}
					}
				}
			}



			Column {
				id: columnView2

				anchors.bottom: parent.bottom
				width: parent.width

				spacing: 0

				Item {
					width: parent.width
					height: hiddenNode.checked ? dp(10) : 0
				}

				Item {
					width: parent.width
					height: hiddenNode.checked ? dp(38) : 0

					enabled: hiddenNode.checked
					visible: hiddenNode.checked

					TextField {
						id: hiddenAddress

						anchors.centerIn: parent
						width: parent.width-dp(32)

						placeholderText: "TOR/I2P address"
						floatingLabel: true
						text: "xa76giaf6ifda7ri63i263.onion"
					}
				}

				Item {
					width: parent.width
					height: hiddenNode.checked ? dp(10) : 0
				}

				Item {
					width: parent.width
					height: hiddenNode.checked ? dp(38) : 0

					enabled: hiddenNode.checked
					visible: hiddenNode.checked

					TextField {
						id: port

						anchors.centerIn: parent
						width: parent.width-dp(32)

						placeholderText: "Port"
						floatingLabel: true
						text: "7812"

						validator: IntValidator {bottom: 0; top: 65535;}
					}
				}
			}
		}

		Item {
			anchors {
				top: logo.bottom
				left: parent.left
				right: parent.right
				bottom: parent.bottom

				leftMargin: parent.width*0.2
				rightMargin: parent.width*0.2
			}

			Item {
				id: loginContent
				anchors {
					top: parent.top
					left: parent.left
					right: parent.right
					bottom: buttonsRow.top
				}

				clip: true

				state: "signIn"

				states: [
					State {
						name: "signIn";
						PropertyChanges { target: signInContent; x: 0}
						PropertyChanges { target: signInContent; opacity: 1}

						PropertyChanges { target: signUpContent; x: width}
						PropertyChanges { target: signUpContent; opacity: 0}
					},
					State {
						name: "signUp";
						PropertyChanges { target: signInContent; x: -width}
						PropertyChanges { target: signInContent; opacity: 0}

						PropertyChanges { target: signUpContent; x: 0}
						PropertyChanges { target: signUpContent; opacity: 1}
					}
				]

				transitions: [
					Transition {
						from: "signIn"; to: "signUp"

						ParallelAnimation {
							NumberAnimation {
								target: signInContent
								property: "x"
								easing.type: Easing.InOutQuad
								duration: 250
							}
							NumberAnimation {
								target: signInContent
								property: "opacity"
								easing.type: Easing.InOutQuad
								duration: 250
							}

							NumberAnimation {
								target: signUpContent
								property: "x"
								easing.type: Easing.InOutQuad
								duration: 250
							}
							NumberAnimation {
								target: signUpContent
								property: "opacity"
								easing.type: Easing.InOutQuad
								duration: 250
							}
						}
					},
					Transition {
						from: "signUp"; to: "signIn"

						ParallelAnimation {
							NumberAnimation {
								target: signInContent
								property: "x"
								easing.type: Easing.InOutQuad
								duration: 250
							}
							NumberAnimation {
								target: signInContent
								property: "opacity"
								easing.type: Easing.InOutQuad
								duration: 250
							}

							NumberAnimation {
								target: signUpContent
								property: "x"
								easing.type: Easing.InOutQuad
								duration: 250
							}
							NumberAnimation {
								target: signUpContent
								property: "opacity"
								easing.type: Easing.InOutQuad
								duration: 250
							}
						}
					}
				]

				Item {
					id: signInContent

					width: parent.width
					height: parent.height

					Column {
						anchors {
							fill: parent
							leftMargin: -dp(8)
						}

						ListItem.Standard {
							margins: 0
							spacing: dp(5)
							action: Icon {
								anchors.centerIn: parent
								name: "awesome/user"
							}

							content: TextField {
								id: usernameLogin

								property alias selectedIndex: listView.currentIndex

								anchors.centerIn: parent
								width: parent.width

								color: Theme.primaryColor
								readOnly: true
								text: locationsModel.count > 0 ? listView.currentItem.text : ""
								placeholderText: "Username"

								IconButton {
									id: overflowButton2

									anchors {
										right: parent.right
										rightMargin: dp(8)
									}

									width: parent.height
									height: parent.height

									iconName: "awesome/caret_down"
									color: Theme.light.iconColor

									onClicked: overflowMenu2.open(overflowButton2, dp(7), 25 * Units.dp)
									onEntered: color = Theme.primaryColor
									onExited: color = Theme.light.iconColor
								}

								Dropdown {
									id: overflowMenu2

									objectName: "overflowMenu2"
									overlayLayer: "dialogOverlayLayer"

									width: 200 * Units.dp
									height: Math.min(8 * 48 * Units.dp + 16 * Units.dp, locationsModel.count * 40 * Units.dp)

									enabled: true

									ListView {
										id: listView

										anchors.fill: parent

										model: locationsModel.model
										delegate: ListItem.Standard {
											height: dp(40)
											text: model.name
											onClicked: {
												listView.currentIndex = index
												overflowMenu2.close()
											}
										}
									}

									Scrollbar {
										flickableItem: listView
									}
								}
							}
						}

						ListItem.Standard {
							height: dp(58)
							margins: 0
							spacing: dp(5)
							action: Icon {
								anchors.centerIn: parent
								name: "awesome/unlock_alt"
							}

							content: TextField {
								id: passwordLogin
								property bool incorrect: false

								anchors.centerIn: parent
								width: parent.width

								color: Theme.primaryColor

								echoMode: TextInput.Password
								placeholderText: "Password"

								helperText: incorrect ?  "Incorrect password" : ""
								hasError: incorrect

								onAccepted: {
									if(passwordLogin.text.length >= 3) {
										passwordLogin.incorrect = false
										main.attemptLogin = true
										var jsonData = {
											id: locationsModel.model.get(usernameLogin.selectedIndex).id
										}

										rsApi.request("/control/login/", JSON.stringify(jsonData), function(){})
									}
									else
										passwordLogin.incorrect = true
								}
							}
						}

						Item {
							height: dp(1)
							width: parent.width

							RowLayout {
								anchors {
									left: parent.left
									leftMargin: dp(29)
								}

								y: passwordLogin.incorrect ? -dp(10) : -dp(25)
								spacing: -dp(10)

								CheckBox {
									id: checkBox

									darkBackground: false
									enabled: false
								}

								Label {
									text: "Remember me"
									color: checkBox.enabled ? Theme.light.iconColor : Theme.light.disabledColor

									MouseArea{
										anchors.fill: parent
										enabled: false

										onClicked: {
										  checkBox.checked = !checkBox.checked
										  checkBox.clicked()
										}
									}
								}
							}
						}
					}
				}

				Item {
					id: signUpContent

					width: parent.width
					height: parent.height

					Column {
						anchors {
							fill: parent
							leftMargin: -dp(8)
						}

						ListItem.Standard {
							margins: 0
							spacing: dp(5)
							action: Icon {
								anchors.centerIn: parent
								name: "awesome/user"
							}

							content: TextField {
								id: username
								property bool emptyName: false

								anchors.centerIn: parent
								anchors.verticalCenterOffset: emptyName ? -dp(5) : 0
								width: parent.width

								color: Theme.primaryColor
								placeholderText: "Username"
								focus: true

								helperText: emptyName ?  "Name is too short" : ""
								hasError: emptyName
							}
						}

						ListItem.Standard {
							margins: 0
							spacing: dp(5)
							action: Icon {
								anchors.centerIn: parent
								name: "awesome/unlock_alt"
							}

							content: TextField {
								id: password

								anchors.centerIn: parent
								width: parent.width

								color: Theme.primaryColor
								echoMode: TextInput.Password
								placeholderText: "Password"

								hasError: password2.different
							}
						}

						ListItem.Standard {
							margins: 0
							spacing: dp(5)
							action: Icon {
								anchors.centerIn: parent
								name: "awesome/unlock_alt"
							}

							content: TextField {
								id: password2

								property bool different: false
								anchors.centerIn: parent
								anchors.verticalCenterOffset: -dp(5)
								width: parent.width

								color: Theme.primaryColor
								placeholderText: "Repeat password"

								echoMode: TextInput.Password

								helperText: "Password cannot be recovered"
								hasError: different

								onAccepted: {
									username.emptyName = false
									password2.different = false
									password2.helperText = ""

									if(username.text.length >= 3 && password.text.length >= 3 && password.text === password2.text) {
										var jsonData = {
											pgp_name: username.text,
											ssl_name: node.text,
											pgp_password: password.text,
											hidden_adress: hiddenNode.checked ? hiddenAddress.text : "",
											hidden_port: hiddenNode.checked ? port.text : ""
										}

										rsApi.request("/control/create_location/", JSON.stringify(jsonData), function(){})
									}
									else {
										if(username.text.length < 3)
											username.emptyName = true

										if(password.text.length < 3) {
											password2.different = true
											password2.helperText = "Password is too short"
										}
										else if(password.text !== password2.text) {
											password2.different = true
											password2.helperText = "Passwords do not match"
										}
									}
								}
							}
						}
					}
				}
			}

			Item {
				id: buttonsRow
				anchors {
					left: parent.left
					right: parent.right
					bottom: parent.bottom

					bottomMargin: parent.height*0.25
				}

				height: 40
				state: "signIn"

				states: [
					State {
						name: "signIn";
						PropertyChanges { target: signIn; width: parent.width*0.75}
						PropertyChanges { target: signIn; opacityColor: 0.8}
						PropertyChanges { target: signIn; textColor: Qt.rgba(1,1,1,1)}
						PropertyChanges { target: signIn; letterSpacing: 2}
						PropertyChanges { target: signIn; backgroundColor: "white"}

						PropertyChanges { target: signUp; width: parent.width*0.25}
						PropertyChanges { target: signUp; opacityColor: 0}
						PropertyChanges { target: signUp; textColor: Theme.light.iconColor}
						PropertyChanges { target: signUp; letterSpacing: 0}
						PropertyChanges { target: signUp; backgroundColor: "transparent"}
					},
					State {
						name: "signUp";
						PropertyChanges { target: signIn; width: parent.width*0.25}
						PropertyChanges { target: signIn; opacityColor: 0}
						PropertyChanges { target: signIn; textColor: Theme.light.iconColor}
						PropertyChanges { target: signIn; letterSpacing: 0}
						PropertyChanges { target: signIn; backgroundColor: "transparent"}

						PropertyChanges { target: signUp; width: parent.width*0.75}
						PropertyChanges { target: signUp; opacityColor: 0.8}
						PropertyChanges { target: signUp; textColor: Qt.rgba(1,1,1,1)}
						PropertyChanges { target: signUp; letterSpacing: 2}
						PropertyChanges { target: signUp; backgroundColor: "white"}
					}
				]

				transitions: [
					Transition {
						from: "signIn"; to: "signUp"

						ParallelAnimation {
							NumberAnimation {
								target: signIn
								property: "width"
								easing.type: Easing.InOutQuad
								duration: 250
							}
							NumberAnimation {
								target: signIn
								property: "opacityColor"
								easing.type: Easing.InOutQuad
								duration: 250
							}
							ColorAnimation {
								target: signIn
								property: "textColor"
								easing.type: Easing.InOutQuad
								duration: 250
							}
							NumberAnimation {
								target: signIn
								property: "letterSpacing"
								easing.type: Easing.InOutQuad
								duration: 250
							}

							NumberAnimation {
								target: signUp
								property: "width"
								easing.type: Easing.InOutQuad
								duration: 250
							}
							NumberAnimation {
								target: signUp
								property: "opacityColor"
								easing.type: Easing.InOutQuad
								duration: 250
							}
							ColorAnimation {
								target: signUp
								property: "textColor"
								easing.type: Easing.InOutQuad
								duration: 250
							}
							NumberAnimation {
								target: signUp
								property: "letterSpacing"
								easing.type: Easing.InOutQuad
								duration: 250
							}
						}
					},
					Transition {
						from: "signUp"; to: "signIn"

						ParallelAnimation {
							NumberAnimation {
								target: signIn
								property: "width"
								easing.type: Easing.InOutQuad
								duration: 250
							}
							NumberAnimation {
								target: signIn
								property: "opacityColor"
								easing.type: Easing.InOutQuad
								duration: 250
							}
							ColorAnimation {
								target: signIn
								property: "textColor"
								easing.type: Easing.InOutQuad
								duration: 250
							}
							NumberAnimation {
								target: signIn
								property: "letterSpacing"
								easing.type: Easing.InOutQuad
								duration: 250
							}

							NumberAnimation {
								target: signUp
								property: "width"
								easing.type: Easing.InOutQuad
								duration: 250
							}
							NumberAnimation {
								target: signUp
								property: "opacityColor"
								easing.type: Easing.InOutQuad
								duration: 250
							}
							ColorAnimation {
								target: signUp
								property: "textColor"
								easing.type: Easing.InOutQuad
								duration: 250
							}
							NumberAnimation {
								target: signUp
								property: "letterSpacing"
								easing.type: Easing.InOutQuad
								duration: 250
							}
						}
					}
				]

				View {
					id: signIn

					property real opacityColor: 0.8
					property real letterSpacing: 0
					property color textColor: Qt.rgba(0,0,0,0)

					anchors {
						top: parent.top
						left: parent.left
						bottom: parent.bottom
					}

					radius: height/2

					Rectangle {
						id: circleMask
						anchors.fill: parent

						smooth: true
						visible: false

						radius: height/2
					}

					OpacityMask {
						anchors.fill: parent
						maskSource: circleMask
						source: colorfulSignIn

						opacity: signIn.opacityColor
					}

					Image {
						id: colorfulSignIn
						anchors.fill: parent

						source: "/colorful.png"
						fillMode: Image.PreserveAspectCrop
						mipmap: true
						smooth: true
						visible: false
					}

					Text {
						anchors.fill: parent

						horizontalAlignment: Text.AlignHCenter
						verticalAlignment: Text.AlignVCenter

						color: signIn.textColor
						text: "Sign in"
						font.family: "Roboto"
						font.weight: signIn.letterSpacing == 0 ? Font.Normal : Font.Black
						font.pixelSize: 12 + signIn.letterSpacing
						font.letterSpacing: signIn.letterSpacing
						font.capitalization: Font.AllUppercase

						wrapMode: Text.WordWrap
					}

					MouseArea {
						anchors.fill: parent
						hoverEnabled: true

						onClicked: {
							if(buttonsRow.state == "signUp") {
								buttonsRow.state = "signIn"
								loginContent.state = "signIn"
							}
							else if(buttonsRow.state == "signIn") {
								if(passwordLogin.text.length >= 3) {
									passwordLogin.incorrect = false
									main.attemptLogin = true
									var jsonData = {
										id: locationsModel.model.get(usernameLogin.selectedIndex).id
									}

									rsApi.request("/control/login/", JSON.stringify(jsonData), function(){})
								}
								else
									passwordLogin.incorrect = true
							}
						}

						onEntered: {
							if(buttonsRow.state != "signIn")
								signIn.textColor = "#4CAF50"
							else if(buttonsRow.state != "signUp")
								signIn.elevation = 1
						}
						onExited: {
							if(buttonsRow.state != "signIn")
								signIn.textColor = Theme.light.iconColor
							else if(buttonsRow.state != "signUp")
								signIn.elevation = 0
						}
					}
				}

				View {
					id: signUp

					property real opacityColor: 0
					property real letterSpacing: 0
					property color textColor: Theme.light.iconColor

					anchors {
						top: parent.top
						right: parent.right
						bottom: parent.bottom
					}

					radius: height/2

					Rectangle {
						id: circleMask2
						anchors.fill: parent

						smooth: true
						visible: false

						radius: height/2
					}

					OpacityMask {
						anchors.fill: parent
						maskSource: circleMask2
						source: colorfulSignUp

						opacity: signUp.opacityColor
					}

					Image {
						id: colorfulSignUp
						anchors.fill: parent

						source: "/colorful.png"
						fillMode: Image.PreserveAspectCrop
						mipmap: true
						smooth: true
						visible: false
					}

					Text {
						anchors.fill: parent

						horizontalAlignment: Text.AlignHCenter
						verticalAlignment: Text.AlignVCenter

						color: signUp.textColor
						text: "Sign up"
						font.family: "Roboto"
						font.weight: signUp.letterSpacing == 0 ? Font.Normal : Font.Black
						font.pixelSize: 12 + signUp.letterSpacing
						font.letterSpacing: signUp.letterSpacing
						font.capitalization: Font.AllUppercase

						wrapMode: Text.WordWrap
					}

					MouseArea {
						anchors.fill: parent
						hoverEnabled: true
						onClicked: {
							if(buttonsRow.state == "signIn") {
								buttonsRow.state = "signUp"
								loginContent.state = "signUp"
							}
							else if(buttonsRow.state == "signUp") {
								username.emptyName = false
								password2.different = false
								password2.helperText = ""

								if(username.text.length >= 3 && password.text.length >= 3 && password.text === password2.text) {
									var jsonData = {
										pgp_name: username.text,
										ssl_name: node.text,
										pgp_password: password.text,
										hidden_adress: hiddenNode.checked ? hiddenAddress.text : "",
										hidden_port: hiddenNode.checked ? port.text : ""
									}

									rsApi.request("/control/create_location/", JSON.stringify(jsonData), function(){})
								}
								else {
									if(username.text.length < 3)
										username.emptyName = true

									if(password.text.length < 3) {
										password2.different = true
										password2.helperText = "Password is too short"
									}
									else if(password.text !== password2.text) {
										password2.different = true
										password2.helperText = "Passwords do not match"
									}
								}
							}
						}

						onEntered: {
							if(buttonsRow.state != "signUp")
								signUp.textColor = "#4CAF50"
							else if(buttonsRow.state != "signIn")
								signUp.elevation = 1
						}
						onExited: {
							if(buttonsRow.state != "signUp")
								signUp.textColor = Theme.light.iconColor
							else if(buttonsRow.state != "signIn")
								signUp.elevation = 0
						}
					}
				}
			}
		}
	}

	Timer {
		interval: 1000
		running: true
		repeat: true

		onTriggered: {
			getRunState()

			if (main.attemptLogin)
				rsApi.request("/control/password/", "", function(){})
		}
	}

	OverlayLayer {
		id: dialogOverlayLayer

		objectName: "dialogOverlayLayer"
		z: 10
	}

	OverlayLayer {
		id: overlayLayer
	}

	// Units
	function dp(dp) {
		return dp * Units.dp
	}

	function gu(gu) {
		return units.gu(gu)
	}

	UnitsHelper {
		id: units
	}
}
