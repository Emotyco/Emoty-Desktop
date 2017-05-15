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
import QtQuick.Controls 1.4

import Material 0.3
import Material.ListItems 0.1 as ListItem

View {
	id: rightBar

	property string custom_state_string: ""
	property string state_string: ""
	property color statuscolor: state_string === "online"   ? "#4caf50" :   // green
								state_string === "busy"	 ? "#FF5722" :   // red
								state_string === "away"	 ? "#FFEB3B" :   // yellow
														      "#9E9E9E"	 // grey

	property int pgp_unread_msgs: 0

	// For handling tokens
	property int stateToken_gxsContacts: 0
	property int stateToken_gxsAll: 0
	property int stateToken_pgp: 0
	property int stateToken_unreadedMsgs: 0

	property bool firstTime_gxsContacts: true
	property bool firstTime_gxsAll: true
	property bool firstTime_pgp: true

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
		function callbackFn(par) {
			if(firstTime_gxsContacts)
				firstTime_gxsContacts = false

			stateToken_gxsContacts = JSON.parse(par.response).statetoken
			main.registerToken(stateToken_gxsContacts, refreshGxsIdModel)

			knownContactsWorker.sendMessage({
				'action': 'refreshContacts',
				'response': par.response
			})
		}

		rsApi.request("/identity/notown_ids/", "", callbackFn)
	}

	function refreshAllGxsIdModel() {
		function callbackFn(par) {
			if(firstTime_gxsAll)
				firstTime_gxsAll = false

			stateToken_gxsAll = JSON.parse(par.response).statetoken
			main.registerToken(stateToken_gxsAll, refreshAllGxsIdModel)

			allContactsWorker.sendMessage({
				'action': 'refreshContacts',
				'response': par.response
			})
		}

		rsApi.request("/identity/*", "", callbackFn)
	}

	function refreshPgpIdModel() {
		function callbackFn(par) {
			if(firstTime_pgp)
				firstTime_pgp = false

			pgpIdModel.json = par.response

			var jsonResp = JSON.parse(par.response)

			var count = 0
			for (var i = 0; i<jsonResp.data.length; i++) {
				for (var ii = 0; ii<jsonResp.data[i].locations.length; ii++) {
					if(jsonResp.data[i].locations[ii].unread_msgs != 0)
						count++
				}
			}
			pgp_unread_msgs = count

			stateToken_pgp = jsonResp.statetoken
			main.registerToken(stateToken_pgp, refreshPgpIdModel)
		}

		rsApi.request("/peers/*", "", callbackFn)
	}

	function getUnreadedMsgs() {
		function callbackFn(par) {
			var jsonResp = JSON.parse(par.response)
			stateToken_unreadedMsgs = jsonResp.statetoken
			main.registerToken(stateToken_unreadedMsgs, getUnreadedMsgs)

			knownContactsWorker.sendMessage({
				'action': 'refreshUnread',
				'response': par.response
			})
			allContactsWorker.sendMessage({
				'action': 'refreshUnread',
				'response': par.response
			})
		}

		rsApi.request("/chat/unread_msgs/", "", callbackFn)
	}

	function getStateString() {
		function callbackFn(par) {
			rightBar.state_string = String(JSON.parse(par.response).data.state_string)
		}

		rsApi.request("/peers/get_state_string/", "", callbackFn)
	}

	function getCustomStateString() {
		function callbackFn(par) {
			rightBar.custom_state_string = String(JSON.parse(par.response).data.custom_state_string)
		}

		rsApi.request("/peers/get_custom_state_string/", "", callbackFn)
	}

	function setStateString(state_string) {
		var jsonData = {
			state_string: state_string
		}

		function callbackFn(par) {
			getStateString()
		}

		rsApi.request("/peers/set_state_string/", JSON.stringify(jsonData), callbackFn)
	}

	function setCustomStateString(custom_state_string) {
		var jsonData = {
			custom_state_string: custom_state_string
		}

		function callbackFn(par) {
			getCustomStateString()
		}

		rsApi.request("/peers/set_custom_state_string/", JSON.stringify(jsonData), callbackFn)
	}

	Component.onCompleted: {
		refreshGxsIdModel()
		refreshAllGxsIdModel()
		refreshPgpIdModel()
		getUnreadedMsgs()
		getStateString()
		getCustomStateString()
	}

	Component.onDestruction: {
		main.unregisterToken(stateToken_gxsContacts)
		main.unregisterToken(stateToken_gxsAll)
		main.unregisterToken(stateToken_pgp)
	}

	WorkerScript {
		id: knownContactsWorker
		source: "qrc:/ContactSort.js"
		onMessage: gxsIdModel.json = JSON.stringify(messageObject)
	}

	WorkerScript {
		id: allContactsWorker
		source: "qrc:/ContactSort.js"
		onMessage: allGxsIdModel.json = JSON.stringify(messageObject)
	}

	JSONListModel {
		id: gxsIdModel
		query: "$.data[*]"
	}

	JSONListModel {
		id: allGxsIdModel
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
			left: parent.left
			right: parent.right
		}

		state: "bigGxsBox"
		states: [
			State {
				name: "smallGxsBox"; when: main.advmode
				AnchorChanges {
					target: gxsBox
					anchors.bottom: pgpBox.top
				}
			},
			State{
				name: "normalMode"; when: !main.advmode
				AnchorChanges {
					target: gxsBox
					anchors.bottom: parent.bottom
				}
			}
		]

		Item {
			id: header
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
					pixelSize: dp(16)
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

		Item {
			id: tabButtons

			anchors {
				top: header.bottom
				left: parent.left
				right: parent.right
			}

			height: dp(25)

			Component.onCompleted: {
				visible = main.advmode
			}

			states: [
				State {
					name: "show"; when: main.advmode
					PropertyChanges {
						target: tabButtons
						enabled: true
					}
				},
				State{
					name: "hide"; when: !main.advmode
					PropertyChanges {
						target: tabButtons
						anchors.topMargin: -tabButtons.height
						enabled: false
					}
				}
			]

			transitions: [
				Transition {
					from: "hide"; to: "show"

					SequentialAnimation {
						PropertyAction {
							target: tabButtons
							property: "visible"
							value: true
						}
						ParallelAnimation {
							NumberAnimation {
								target: tabButtons
								property: "opacity"
								from: 0
								to: 1
								easing.type: Easing.InOutQuad;
								duration: MaterialAnimation.pageTransitionDuration
							}
							NumberAnimation {
								target: tabButtons
								property: "anchors.topMargin"
								from: -tabButtons.height
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
						ParallelAnimation {
							NumberAnimation {
								target: tabButtons
								property: "opacity"
								from: 1
								to: 0
								easing.type: Easing.InOutQuad
								duration: MaterialAnimation.pageTransitionDuration
							}
							NumberAnimation {
								target: tabButtons
								property: "anchors.topMargin"
								from: 0
								to: -tabButtons.height
								easing.type: Easing.InOutQuad
								duration: MaterialAnimation.pageTransitionDuration
							}
						}
						PropertyAction {
							target: tabButtons;
							property: "visible";
							value: false
						}
					}
				}
			]

			Row {
				anchors.fill: parent

				Button {
					property bool selected: tabView.currentIndex === 0
					height: parent.height
					width: parent.width/2

					text: "Contacts"
					textColor: selected ? Theme.primaryColor : Theme.light.textColor

					onClicked: tabView.currentIndex = 0
				}

				Button {
					property bool selected: tabView.currentIndex === 1
					height: parent.height
					width: parent.width/2

					text: "All"
					textColor: selected ? Theme.primaryColor : Theme.light.textColor

					onClicked: tabView.currentIndex = 1
				}
			}
		}

		TabView {
			id: tabView

			anchors {
				top: tabButtons.bottom
				left: parent.left
				right: parent.right
				bottom: parent.bottom
			}

			frameVisible: false
			tabsVisible: false

			states: [
				State {
					when: main.advmode
					PropertyChanges {
						target: tabView
						currentIndex: 0
					}
				}
			]

			Tab {
				title: "Contacts"

				Item{
					ListView {
						id: listView

						anchors.fill: parent

						clip: true

						model: gxsIdModel.model
						delegate: FriendListDelegate{}

						LoadingMask {
							id: loadingMask
							anchors.fill: parent

							state: firstTime_gxsContacts ? "visible" : "non-visible"
						}
					}

					Scrollbar {
						flickableItem: listView
					}
				}
			}

			Tab {
				title: "All"

				Item{
					ListView {
						id: listView2

						anchors.fill: parent

						clip: true

						model: allGxsIdModel.model
						delegate: FriendListDelegate{}

						LoadingMask {
							id: loadingMask2
							anchors.fill: parent

							state: firstTime_gxsAll ? "visible" : "non-visible"
						}
					}

					Scrollbar {
						flickableItem: listView2
					}
				}
			}
		}
	}

	Item {
		id: pgpBox

		property int previousHeight: parent.height/2
		anchors {
			left:parent.left
			right: parent.right
			bottom: parent.bottom
		}

		height: dp(50)

		Drag.hotSpot.x: 0
		Drag.hotSpot.y: 0

		Component.onCompleted: {
			visible = main.advmode
		}

		states: [
			State {
				name: "hide"; when: !main.advmode
				PropertyChanges {
					target: pgpBox
					enabled: false
				}
			},
			State {
				name: "show"; when: main.advmode
				PropertyChanges {
					target: pgpBox
					enabled: true
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
					height: previousHeight
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
			},
			Transition {
				from: "hide"; to: "show"

				SequentialAnimation {
					PropertyAction {
						target: pgpBox
						property: "visible"
						value: true
					}
					ParallelAnimation {
						NumberAnimation {
							target: pgpBox
							property: "opacity"
							from: 0
							to: 1
							easing.type: Easing.InOutQuad;
							duration: MaterialAnimation.pageTransitionDuration
						}
						NumberAnimation {
							target: pgpBox
							property: "anchors.bottomMargin"
							from: -pgpBox.height
							to: 0
							easing.type: Easing.InOutQuad;
							duration: MaterialAnimation.pageTransitionDuration
						}
					}
				}
			},
			Transition {
				to: "hide"

				SequentialAnimation {
					ParallelAnimation {
						NumberAnimation {
							target: pgpBox
							property: "opacity"
							from: 1
							to: 0
							easing.type: Easing.InOutQuad
							duration: MaterialAnimation.pageTransitionDuration
						}
						NumberAnimation {
							target: pgpBox
							property: "anchors.bottomMargin"
							from: 0
							to: -pgpBox.height
							easing.type: Easing.InOutQuad
							duration: MaterialAnimation.pageTransitionDuration
						}
					}
					PropertyAction {
						target: pgpBox;
						property: "visible";
						value: false
					}
				}
			}
		]

		View {
			id: button
			anchors {
				left:parent.left
				right: parent.right
				top: parent.top
			}

			height: dp(50)

			backgroundColor: Palette.colors["deepOrange"]["500"]
			elevation: 1

			View {
				anchors {
					verticalCenter: parent.verticalCenter
					left: parent.left
					leftMargin: dp(15)
				}

				width: dp(20)
				height: dp(20)
				radius: width/2

				elevation: 1
				visible: pgp_unread_msgs > 0 ? true : false

				Text {
					anchors.fill: parent
					text: pgp_unread_msgs
					font.family: "Roboto"
					verticalAlignment: Text.AlignVCenter
					horizontalAlignment: Text.AlignHCenter
				}
			}

			Label {
				anchors {
					horizontalCenter: parent.horizontalCenter
					verticalCenter: parent.verticalCenter
				}

				text: "direct"
				color: "white"
				style: "button"
			}

			MouseArea {
				anchors.fill: parent

				drag {
					target: pgpBox
					axis: Drag.YAxis
				}

				onClicked: {
					pgpBox.state === "bigPgpBox" ? pgpBox.state = "smallPgpBox"
												 : pgpBox.state = "bigPgpBox"
				}

				onMouseXChanged: {
					if(drag.active) {
						pgpBox.height = pgpBox.height - mouseY

						if(pgpBox.height < dp(50))
							pgpBox.height = dp(50)
						else if(pgpBox.height > rightBar.height-dp(50))
							pgpBox.height = rightBar.height-dp(50)

						pgpBox.previousHeight = pgpBox.height
					}
				}
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

				size: dp(20)

				Behavior on rotation {
					NumberAnimation {
						duration: MaterialAnimation.pageTransitionDuration/2
					}
				}
			}
		}

		ListView {
			id: listView3

			LoadingMask {
				id: loadingMask3
				anchors.fill: parent

				state: firstTime_pgp ? "visible" : "non-visible"
			}

			anchors {
				fill: parent
				topMargin: dp(50)
			}

			clip: true

			model: pgpIdModel.model
			delegate: PgpListDelegate{}
		}

		Scrollbar {
			flickableItem: listView3
		}
	}

	ParallelAnimation {
		running: true
		NumberAnimation {
			target: rightBar
			property: "anchors.rightMargin"
			from: -dp(50)
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
