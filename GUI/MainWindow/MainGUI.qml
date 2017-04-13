/****************************************************************
 *  This file is part of Sonet.
 *  Sonet is distributed under the following license:
 *
 *  Copyright (C) 2017, Konrad Dębiec
 *  Copyright (C) 2017, Gioacchino Mazzurco <gio@eigenlab.org>
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

import Material 0.3
import Material.Extras 0.1

import QtQuick.Controls 1.3 as Controls

Rectangle {
	id: main

	property bool borderless: false
	property bool haveOwnIdFirstTime: true

	property bool advmode
	property bool flickablemode

	property string defaultGxsName
	property string defaultGxsId

	property Item controls: controlView

	property int visibleRows: Math.round((main.height-dp(30))/(dp(50) + gridLayout.rowSpacing))

	property alias pageStack: __pageStack
	property alias gridLayout: gridLayout
	property alias content: content

	signal gridChanged

	color: Palette.colors["grey"]["200"]

	states:[
		State {
			name: "waiting_account_select"
			StateChangeScript {
				script: {
					runStateHelper.setRunState("waiting_account_select")
					Qt.quit()
				}
			}
		},
		State {
			name: "running_ok"
			StateChangeScript {
				script: {
					runStateHelper.setRunState("running_ok")
				}
			}
		},
		State {
			name: "running_ok_no_full_control"
			StateChangeScript {
				script: {
					runStateHelper.setRunState("running_ok_no_full_control")
				}
			}
		},
		State {
			name: "fatal_error"
			StateChangeScript {
				script: {
					runStateHelper.setRunState("fatal_error")
					Qt.quit()
				}
			}
		},
		State {
			name: "waiting_startup"
			StateChangeScript {
				script: {
					runStateHelper.setRunState("waiting_startup")
				}
			}
		},
		State {
			name: "waiting_init"
			StateChangeScript {
				script: {
					runStateHelper.setRunState("waiting_init")
					Qt.quit()
				}
			}
		}
	]

	Component.onCompleted: {
		updateVisibleRows()
		getOwnIdentities()
		getRunState()
		getAdvancedMode()
		getFlickableGridMode()
	}

	property int stateToken_ownGxs: 0

	function getOwnIdentities() {
		var jsonData = {
			callback_name: "maingui_identity_own_ids"
		};

		function callbackFn(par) {
			ownGxsIdModel.json = par.response; haveOwnId()

			stateToken_ownGxs = JSON.parse(par.response).statetoken
			main.registerToken(stateToken_ownGxs, getOwnIdentities)
		}

		rsApi.request("/identity/own_ids/", JSON.stringify(jsonData), callbackFn)
	}

	function getRunState() {
		var jsonData = {
			callback_name: "maingui_control_runstate"
		};

		function callbackFn(par) {
			main.state = String(JSON.parse(par.response).data.runstate)
		}

		var ret = rsApi.request("/control/runstate/", JSON.stringify(jsonData), callbackFn)
		if(ret < 1)
			main.state = "fatal_error"
	}

	function getAdvancedMode() {
		var jsonData = {
			callback_name: "maingui_get_advanced_mode"
		};

		function callbackFn(par) {
			main.advmode = Boolean(JSON.parse(par.response).data.advanced_mode)
		}

		rsApi.request("/settings/get_advanced_mode/", JSON.stringify(jsonData), callbackFn)
	}

	function getFlickableGridMode() {
		var jsonData = {
			callback_name: "maingui_get_flickable_grid_mode"
		};

		function callbackFn(par) {
			main.flickablemode = Boolean(JSON.parse(par.response).data.flickable_grid_mode)
		}

		rsApi.request("/settings/get_flickable_grid_mode/", JSON.stringify(jsonData), callbackFn)
	}

	function haveOwnId() {
		if (ownGxsIdModel.count === 0 && haveOwnIdFirstTime) {
			var component = Qt.createComponent("CreateIdentity.qml");
			if (component.status === Component.Ready) {
				var createId = component.createObject(main);
				createId.show();
			}
			haveOwnIdFirstTime = false;
		}
	}

	Connections {
		target: view
		onHeightChanged: gridLayout.reorder()
		onWidthChanged: gridLayout.reorder()
	}

	JSONListModel {
		id: ownGxsIdModel

		query: "$.data[*]"

		model.onCountChanged: {
			defaultGxsName = ownGxsIdModel.model.get(0).name
			defaultGxsId = ownGxsIdModel.model.get(0).own_gxs_id
		}
	}

	AppTheme {
		primaryColor: Palette.colors["green"]["500"]
		accentColor: Palette.colors["deepOrange"]["500"]
		tabHighlightColor: "white"
	}

	MouseArea {
		property bool controlPressed

		anchors.fill: parent

		z: -1
		focus: true
		acceptedButtons: Qt.MidButton | Qt.LeftButton

		Keys.onPressed: {
			if(event.key == Qt.Key_Control)
				controlPressed = true
		}

		Keys.onReleased: {
			if(event.key == Qt.Key_Control)
				controlPressed = false
		}

		onClicked: {
			mouse.accepted = false
			focus = true
		}

		onPressed: {
			mouse.accepted = false
		}

		onWheel: {
			wheel.accepted = false
			if(controlPressed)
				if(wheel.angleDelta.y > 0 && Units.multiplier < 2) {
					Units.setMultiplier(Units.multiplier+0.1)
					wheel.accepted = true
				}
				else if(wheel.angleDelta.y < 0 && Units.multiplier > 0.2) {
					Units.setMultiplier(Units.multiplier-0.1)
					wheel.accepted = true
				}
		}
	}

	Image {
		anchors {
			left: leftBar.right
			right: rightBar.left
			bottom: parent.bottom
			top: parent.top
		}

		asynchronous: true
		source: "/wallpaper_grey.jpg"
		fillMode: Image.PreserveAspectCrop
	}

	LeftBar {
		id: leftBar2
		z:1
	}

	Rectangle {
		id: mainGUImask

		anchors {
			left: leftBar2.right
			top: parent.top
			right: parent.right
			bottom: parent.bottom
		}

		color: Qt.rgba(0, 0, 0, 0.3)
		z: 3

		state: "non-visible"

		states: [
			State {
				name: "visible"; when: leftBar2.state === "wide"
				PropertyChanges {
					target: mainGUImask
					enabled: true
					opacity: 1
				}
			},
			State {
				name: "non-visible"; when: leftBar2.state !== "wide"
				PropertyChanges {
					target: mainGUImask
					enabled: false
					opacity: 0
				}
			}
		]

		transitions: [
			Transition {
				from: "visible"; to: "non-visible";
				SequentialAnimation {
					NumberAnimation {
						target: mainGUImask;
						property: "opacity";
						easing.type: Easing.InOutQuad;
						duration: MaterialAnimation.pageTransitionDuration
					}
					PropertyAction {
						target: mainGUImask;
						property: "visible";
						value: false
					}
				}
			},
			Transition {
				from: "non-visible"; to: "visible";
				SequentialAnimation {
					PropertyAction {
						target: mainGUImask;
						property: "visible";
						value: true
					}
					NumberAnimation {
						target: mainGUImask;
						property: "opacity";
						easing.type: Easing.InOutQuad;
						duration: MaterialAnimation.pageTransitionDuration
					}
				}
			}
		]

		MouseArea {
			anchors.fill: parent

			acceptedButtons: Qt.AllButtons
			hoverEnabled: true

			onClicked: leftBar2.state = "narrow"
			onPressAndHold: {}
			onEntered: {}
			onExited: {}
		}
	}

	Item {
		id: leftBar

		anchors {
			top: parent.top
			left: parent.left
			bottom: parent.bottom
		}

		width: dp(50)
	}

	View {
		id: controlView

		anchors {
			top: parent.top
			right: parent.right
		}

		height: dp(50)
		width: dp(210)

		backgroundColor: "white"
		elevation: 3
		z: 1

		ParallelAnimation {
			running: true
			NumberAnimation {
				target: controlView;
				property: "anchors.rightMargin";
				from: -dp(50);
				to: 0;
				duration: MaterialAnimation.pageTransitionDuration
			}
			NumberAnimation {
				target: controlView;
				property: "opacity";
				from: 0;
				to: 1;
				duration: MaterialAnimation.pageTransitionDuration
			}
		}

		Component.onCompleted: {
			if(borderless)
				Qt.createQmlObject('
                import QtQuick 2.5
                import Material 0.3
                import QtQuick.Layouts 1.3

                Row {
                    anchors {
                        top: parent.top
                        right: parent.right
                        rightMargin: dp(10)
                        topMargin: dp(12)
                    }

                    spacing: dp(5)

                    Item {
                        width: dp(26)
                        height: dp(26)

                        Rectangle {
                            id: minimizeButton

                            anchors {
                                bottom: parent.bottom
                                margins: dp(4)
                            }

                            width: parent.width-dp(8)
                            height: dp(2)

                            color: Palette.colors["grey"]["500"]
                        }

                        MouseArea {
                            anchors.fill: parent

                            hoverEnabled: true

                            onEntered: minimizeButton.color = Theme.accentColor
                            onExited: minimizeButton.color = Palette.colors["grey"]["500"]
                            onClicked: qMainPanel.pushButtonMinimizeClicked();
                        }
                    }

                    Item {
                        width: dp(26)
                        height: dp(26)

                        Rectangle {
                            id: maximizeButton

                            anchors {
                                fill: parent
                                margins: dp(4)
                            }

                            color: Palette.colors["grey"]["500"]

                            Rectangle {
                                anchors {
                                    fill: parent
                                    margins: dp(2)
                                }

                                color: "white"
                            }
                        }

                        MouseArea {
                            anchors.fill: parent

                            hoverEnabled: true

                            onEntered: maximizeButton.color = Theme.accentColor
                            onExited: maximizeButton.color = Palette.colors["grey"]["500"]
                            onClicked: qMainPanel.pushButtonMaximizeClicked()
                        }
                    }

                    Item {
                        width: dp(26)
                        height: dp(26)

                        Rectangle {
                            id: closeButton

                            anchors.centerIn: parent

                            width: dp(24)
                            height: dp(2.5)

                            rotation: 45
                            color: Palette.colors["grey"]["500"]
                        }

                        Rectangle {
                            id: closeButton2

                            anchors.centerIn: parent

                            width: dp(24)
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
                            onClicked: view.hide()
                        }
                    }
                }
                ', controlView);
		}
	}

	RightBar {
		id: rightBar
		z:1
	}

	Flickable {
		id: flickable

		anchors {
			left: leftBar.right
			right: rightBar.left
			top: parent.top
			bottom: parent.bottom
		}

		clip: true
		interactive: flickablemode
		contentHeight: Math.max(gridLayout.implicitHeight + dp(40), height)

		GridLayout {
			id: gridLayout

			property int h: (main.height-dp(30))
			property int rowspace: parseInt(h/dp(50))

			property alias gridRepeater: gridRepeater

			function reorder() {
				for (var i=0;i<(children.length - 751);i++) {
					children[751 + i].refresh()
				}
			}

			anchors {
				fill: parent
				margins: dp(15)
			}

			columns: parseInt(gridLayout.width / dp(60))
			columnSpacing: dp(10)
			rowSpacing: h<dp(650) ? (h-((rowspace-1)*dp(50)))/(rowspace-2)
							  : (h-((rowspace-2)*dp(50)))/(rowspace-3)

			onColumnsChanged: main.gridChanged()

			Repeater {
				id: gridRepeater

				signal activeGrid
				signal nonActiveGrid

				model: 750
				delegate: DropTile {}

				Layout.alignment: Qt.AlignTop
			}

			DragTile {
				id: content

				Layout.alignment: Qt.AlignBottom
				Layout.maximumWidth: 0
				Layout.maximumHeight: 0

				width: 0
				height: 0

				col: parseInt(gridLayout.width / (dp(50) + gridLayout.columnSpacing))>= 14
					    ? 14
						: parseInt(gridLayout.width / (dp(50) + gridLayout.columnSpacing))

				row: main.visibleRows

				gridX: Math.floor(((parseInt(gridLayout.width / (dp(50) + gridLayout.columnSpacing)))-content.col)/2)

				Behavior on col {
					ScriptAction {
						script: {
							content.refresh()
							gridLayout.reorder()
						}
					}
				}

				Behavior on row {
					ScriptAction { script: {content.refresh()} }
				}

				Controls.StackView {
					id: __pageStack
					anchors.fill: parent

					initialItem:	Content{}
				}
			}
		}
	}

	Scrollbar {
		flickableItem: flickable
	}

	OverlayLayer {
		id: dialogOverlayLayer
		objectName: "dialogOverlayLayer"
		z: 10
	}

	OverlayLayer {
		id: tooltipOverlayLayer
		objectName: "tooltipOverlayLayer"
		z:5
	}

	OverlayLayer {
		id: overlayLayer
		z: 11
	}

	// Dialog Pop-ups

	DialogExit {
		id: exitDialog

		text: "Do you want to exit?"

		positiveButtonText: "Yes"
		negativeButtonText: "No"

		onAccepted: {
			function callbackFn(par) {
				Qt.quit()
			}

			rsApi.request("/control/shutdown/", "", callbackFn)
		}
	}

	PGPFriendDetailsDialog {
		id: pgpFriendDetailsDialog
	}

	SettingsDialog {
		id: settingsDialog
	}

	UserAddDialog {
		id: userAddDialog
	}

	function updateVisibleRows() {
		main.visibleRows = Qt.binding(function() {
			return Math.round((main.height-dp(30))/(dp(50) + gridLayout.rowSpacing))
		});
	}

	///////
	// Code made by Gioacchino Mazzurco
	// Github: https://github.com/G10h4ck

	property var tokens: ({})

	function registerToken(token, callback)
	{
		if (Array.isArray(tokens[token]))
			tokens[token].push(callback)
		else
			tokens[token] = [callback]
	}

	function tokenExpire(token)
	{
		if(Array.isArray(tokens[token]))
		{
			var arrLen = tokens[token].length
			for(var i=0; i<arrLen; ++i)
			{
				var tokCallback = tokens[token][i]
				if (typeof tokCallback == 'function')
					tokCallback()
			}
		}

		delete tokens[token]
	}

	function isTokenValid(token) {
		return Array.isArray(tokens[token])
	}

	function checkTokens(par)
	{
		var jsonData = JSON.parse(par.response).data
		var arrayLength = jsonData.length;
		for (var i = 0; i < arrayLength; i++)
			main.tokenExpire(jsonData[i])
	}

	//
	//////

	/*
	  All new cards (panels) are instatiated in these fucntions,
	  becouse creation context is the QQmlContext in which Qt.createComponent method is called.
	  If it would be created e.g. in FriendListDelegate we could lost access to new created objects.
	  (We couldn't e.g. click on mousearea in new created objects)
	  */

	function createChatGxsCard(friendname, gxsid, objectName) {
		var component = Qt.createComponent(objectName, gridLayout);
		if (component.status === Component.Ready) {
			var chat = component.createObject(gridLayout,
											  {"name": friendname,
												"gxsId": gxsid});
			updateVisibleRows()

			chat.col = Qt.binding(function() {
				return parseInt(gridLayout.width / (dp(50) + gridLayout.columnSpacing))>= 11
						? 11
						: parseInt(gridLayout.width / (dp(50) + gridLayout.columnSpacing)) || 1
			})
			chat.row = Qt.binding(function() {
				return main.visibleRows
			})
			chat.gridY = 0
			chat.gridX = Qt.binding(function() {
				return Math.floor(
							((parseInt(gridLayout.width / (dp(50) + gridLayout.columnSpacing)))-chat.col)/2
						)
			})

			gridLayout.reorder()
		}
	}

	function createChatCardPeer(friendname, rspeerid, chat_id, objectName) {
		var component = Qt.createComponent(objectName, gridLayout);
		if (component.status === Component.Ready) {
			var chat = component.createObject(gridLayout,
											  {"name": friendname,
											   "chatId": chat_id,
											   "rsPeerId": rspeerid});
			updateVisibleRows()

			chat.col = Qt.binding(function() {
				return parseInt(gridLayout.width / (dp(50) + gridLayout.columnSpacing))>= 11
						? 11
						: parseInt(gridLayout.width / (dp(50) + gridLayout.columnSpacing)) || 1
			})
			chat.row = Qt.binding(function() {
				return main.visibleRows
			})
			chat.gridY = 0
			chat.gridX = Qt.binding(function() {
				return Math.floor(
							((parseInt(gridLayout.width / (dp(50) + gridLayout.columnSpacing)))-chat.col)/2
						)
			})

			gridLayout.reorder()
		}
	}

	Timer {
		interval: 5000
		running: true
		repeat: true
		onTriggered: {
			getRunState()
		}
	}

	Timer {
		interval: 500
		running: true
		repeat: true
		onTriggered: {
			rsApi.request("/statetokenservice/*", '['+Object.keys(main.tokens)+']', checkTokens)
		}
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
