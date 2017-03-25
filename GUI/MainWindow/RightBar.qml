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
import Material 0.3

View {
	id: rightBar

	property string custom_state_string: ""
	property string state_string: ""
	property color statuscolor: state_string === "online"   ? "#4caf50" :   // green
								state_string === "busy"	 ? "#FF5722" :   // red
								state_string === "away"	 ? "#FFEB3B" :   // yellow
														      "#9E9E9E"	 // grey

	anchors {
		top: parent.top
		right: parent.right
		bottom: parent.bottom
		topMargin: dp(50)
	}

	width: dp(210)

	backgroundColor: Theme.tabHighlightColor
	elevation: 3

	clipContent: true

	function refreshGxsIdModel() {
		var jsonData = {
			callback_name: "rightbar_identity_notown"
		}

		function callbackFn(par) {
			gxsIdModel.json = par.response
		}

		rsApi.request("/identity/notown/", JSON.stringify(jsonData), callbackFn)
	}

	function refreshPgpIdModel() {
		var jsonData = {
			callback_name: "rightbar_peers_*"
		}

		function callbackFn(par) {
			pgpIdModel.json = par.response
		}

		rsApi.request("/peers/*", JSON.stringify(jsonData), callbackFn)
	}

	function getStateString() {
		var jsonData = {
			callback_name: "rightbar_peers_get_state_string"
		}

		function callbackFn(par) {
			rightBar.state_string = String(JSON.parse(par.response).data.state_string)
		}

		rsApi.request("/peers/get_state_string/", JSON.stringify(jsonData), callbackFn)
	}

	function getCustomStateString() {
		var jsonData = {
			callback_name: "rightbar_peers_get_custom_state_string"
		}

		function callbackFn(par) {
			rightBar.custom_state_string = String(JSON.parse(par.response).data.custom_state_string)
		}

		rsApi.request("/peers/get_custom_state_string/", JSON.stringify(jsonData), callbackFn)
	}

	function setStateString(state_string) {
		var jsonData = {
			callback_name: "rightbar_peers_set_state_string",
			state_string: state_string
		}

		function callbackFn(par) {
			getStateString()
		}

		rsApi.request("/peers/set_state_string/", JSON.stringify(jsonData), callbackFn)
	}

	function setCustomStateString(custom_state_string) {
		var jsonData = {
			callback_name: "rightbar_peers_set_custom_state_string",
			custom_state_string: custom_state_string
		}

		function callbackFn(par) {
			getCustomStateString()
		}

		rsApi.request("/peers/set_custom_state_string/", JSON.stringify(jsonData), callbackFn)
	}

	Component.onCompleted: {
		refreshGxsIdModel()
		refreshPgpIdModel()
		getStateString()
		getCustomStateString()
	}

	JSONListModel {
		id: gxsIdModel
		query: "$.data[*]"
	}

	JSONListModel {
		id: pgpIdModel
		query: "$.data[*]"
	}

	Item {
		id: gxsBox

		anchors {
			top: parent.top
			bottom: parent.bottom
			left: parent.left
			right: parent.right
			rightMargin: dp(3)
		}

		state: "bigGxsBox"
		states: [
			State {
				name: "smallGxsBox"; when: main.advmode && pgpBox.state === "bigPgpBox"
				PropertyChanges {
					target: gxsBox
					anchors.bottomMargin: (parent.height/2)-dp(25)
				}
			},
			State {
				name: "bigGxsBox"; when: main.advmode && pgpBox.state === "smallPgpBox"
				PropertyChanges {
					target: gxsBox
					anchors.bottomMargin: dp(50)
				}
			},
			State{
				name: "normalMode"; when: !main.advmode
				PropertyChanges {
					target: gxsBox
					anchors.bottomMargin: 0
				}
			}
		]

		transitions: [
			Transition {
				NumberAnimation {
					target: gxsBox
					property: "anchors.bottomMargin"
					duration: MaterialAnimation.pageTransitionDuration/2
				}
			}
		]

		Item {
			anchors {
				top: parent.top
				left: parent.left
				right: parent.right
			}

			height: dp(50)

			TextField {
				id: statusm

				anchors {
					leftMargin: dp(10)
					rightMargin: dp(50)
					topMargin: dp(10)
					verticalCenter: parent.verticalCenter
					left: parent.left
					right: parent.right
				}

				placeholderText: "Set your status msg"
				text: custom_state_string.length > 0 ? custom_state_string : ""

				font {
					family: "Roboto"
					pixelSize: 16 * Units.dp
					capitalization: Font.MixedCase
				}

				showBorder: false

				onAccepted: {
					setCustomStateString(statusm.text)
				}
			}

			MouseArea {
				anchors {
					verticalCenter: parent.verticalCenter
					right: parent.right
				}

				width: dp(50)
				height: parent.height

				hoverEnabled: true

				onEntered: changeStatus.state = "big"
				onExited: changeStatus.state = "small"

				onClicked: {
					var str

					if(state_string === "online")
						str = "away"
					else if(state_string === "away")
						str = "busy"
					else if(state_string === "busy")
						str = "online"
					else if(state_string === "undefined")
						str = "online"

					setStateString(str)
				}
			}

			View {
				id: changeStatus

				anchors {
					verticalCenter: parent.verticalCenter
					right: parent.right
					rightMargin: dp(15)
				}

				width: dp(10)
				height: dp(10)

				radius: width/2
				elevation: 3/2
				backgroundColor: statuscolor

				states: [
					State {
						name: "small"
						PropertyChanges {
							target: changeStatus
							width: dp(10)
							height: dp(10)
							anchors.rightMargin: dp(15)
						}
					},
					State {
						name: "big"
						PropertyChanges {
							target: changeStatus
							width: dp(24)
							height: dp(24)
							anchors.rightMargin: dp(8)
						}
					}
				]

				transitions: [
					Transition {
						ParallelAnimation {
							NumberAnimation {
								target: changeStatus
								property: "height"
								duration: MaterialAnimation.pageTransitionDuration/3
							}
							NumberAnimation {
								target: changeStatus
								property: "width"
								duration: MaterialAnimation.pageTransitionDuration/3
							}
							NumberAnimation {
								target: changeStatus
								property: "anchors.rightMargin"
								duration: MaterialAnimation.pageTransitionDuration/3
							}
						}
					}
				]

				MouseArea {
					anchors.fill: parent

					hoverEnabled: true

					onEntered: changeStatus.state = "big"
					onExited: changeStatus.state = "small"

					onClicked: {
						var str

						if(state_string === "online")
							str = "away"
						else if(state_string === "away")
							str = "busy"
						else if(state_string === "busy")
							str = "online"
						else if(state_string === "undefined")
							str = "online"

						setStateString(str)
					}
				}
			}
		}

		ListView {
			id: listView

			anchors {
				fill: parent
				topMargin: dp(50)
			}

			clip: true

			model: gxsIdModel.model
			delegate: FriendListDelegate{}
		}

		Scrollbar {
			flickableItem: listView
		}
	}

	Item {
		id: pgpBox

		anchors {
			left:parent.left
			right: parent.right
			bottom: parent.bottom
		}

		height: dp(50)

		states: [
			State {
				name: "notvisible"; when: !main.advmode
				PropertyChanges {
					target: pgpBox
					visible: false
				}
			},
			State {
				name: "visible"; when: !main.advmode
				PropertyChanges {
					target: pgpBox
					visible: true
				}
			},
			State {
				name: "smallPgpBox"
				PropertyChanges {
					target: pgpBox
					height: dp(50)
				}
			},
			State {
				name: "bigPgpBox"
				PropertyChanges {
					target: pgpBox
					height: parent.height/2
				}
			}
		]

		transitions: [
			Transition {
				NumberAnimation {
					target: pgpBox;
					property: "height";
					duration: MaterialAnimation.pageTransitionDuration/2
				}
			}
		]

		Button {
			anchors {
				left:parent.left
				right: parent.right
				top: parent.top
			}

			height: dp(50)

			size: 13
			text: "PgpBox"
			textColor: "white"

			backgroundColor: Palette.colors["deepOrange"]["500"]
			elevation: 1

			onClicked: {
				pgpBox.state === "bigPgpBox" ? pgpBox.state = "smallPgpBox"
											 : pgpBox.state = "bigPgpBox"
			}

			Icon {
				id: pgpBoxIcon

				anchors {
					right: parent.right
					top: parent.top
					bottom: parent.bottom
				}

				width: height

				states: [
					State {
						name: "nonrotated"; when: pgpBox.height !== dp(50)
						PropertyChanges {
							target: pgpBoxIcon
							rotation: 0
						}
					},
					State {
						name: "rotated"; when: pgpBox.height === dp(50)
						PropertyChanges {
							target: pgpBoxIcon
							rotation: 90
						}
					}
				]

				name: "awesome/chevron_down"
				color: "white"

				size: 20 * Units.dp

				Behavior on rotation {
					NumberAnimation {
						duration: MaterialAnimation.pageTransitionDuration/2
					}
				}
			}
		}

		ListView {
			id: listView2

			anchors {
				fill: parent
				topMargin: dp(50)
				rightMargin: dp(3)
			}

			clip: true

			model: pgpIdModel.model
			delegate: PgpListDelegate{}
		}

		Scrollbar {
			flickableItem: listView2
		}
	}

	Timer {
		interval: 2000
		running: true
		repeat: true

		onTriggered: {
			refreshGxsIdModel()
			refreshPgpIdModel()
		}
	}

	ParallelAnimation {
		running: true
		NumberAnimation {
			target: rightBar
			property: "anchors.rightMargin"
			from: -50
			to: 0
			duration: MaterialAnimation.pageTransitionDuration
		}
		NumberAnimation {
			target: rightBar
			property: "opacity"
			from: 0
			to: 1
			duration: MaterialAnimation.pageTransitionDuration
		}
	}
}
