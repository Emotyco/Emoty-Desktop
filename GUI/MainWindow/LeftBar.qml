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
import QtQuick.Controls 1.4

import Material 0.3
import Material.ListItems 0.1 as ListItem

View {
	id: leftBar

	anchors {
		top: parent.top
		left: parent.left
		bottom: parent.bottom
	}

	width: dp(50)

	backgroundColor: "transparent"
	elevation: 2

	clipContent: true

	state: "narrow"
	states: [
		State {
			name: "wide"
			PropertyChanges {
				target: leftBar
				width: dp(300)
				elevation: 3
			}
		},
		State {
			name: "narrow"
			PropertyChanges {
				target: leftBar
				width: dp(50)
				elevation: 2
			}
		}
	]

	transitions: [
		Transition {
			from: "wide"; to: "narrow";
			SequentialAnimation {
				NumberAnimation {
					target: leftBar
					property: "width"
					easing.type: Easing.InOutQuad
					duration: MaterialAnimation.pageTransitionDuration
				}
			}
		},
		Transition {
			from: "narrow"; to: "wide";
			NumberAnimation {
				target: leftBar
				property: "width"
				easing.type: Easing.InOutQuad
				duration: MaterialAnimation.pageTransitionDuration
			}
		}
	]

	Rectangle {
		id: tabs

		anchors {
			top: parent.top
			right: parent.right
			bottom: parent.bottom
		}

		width: dp(250)
		z: 1

		color: "#f2f2f2"

		MouseArea {
			anchors.fill: parent

			acceptedButtons: Qt.AllButtons
			hoverEnabled: true

			onClicked: {}
			onPressAndHold: {}
			onEntered: {}
			onExited: {}

			TabView {
				id: tabView

				anchors.fill: parent

				frameVisible: false
				tabsVisible: false

				currentIndex: 2

				Tab {
					title: "General"

					Item {
						anchors.fill: parent
					}
				}
				Tab {
					title: "Profile"

					LeftBar_Identites {
						anchors.fill: parent
					}
				}
				Tab {
					title: "Rooms"

					LeftBar_Rooms {
						anchors.fill: parent
					}
				}
				Tab {
					title: "File Sharing"

					Item {
						anchors.fill: parent
					}
				}
			}
		}
	}

	View {
		anchors {
			top: parent.top
			left: parent.left
			bottom: parent.bottom
		}

		width: dp(50)
		elevation: 1
		z: 2

		Column {
			id: upperColumn

			anchors.left: parent.left
			width: parent.width

			Item {
				width: dp(48)
				height: dp(48)

				Image {
					id: image

					anchors.fill: parent
					anchors.margins: dp(10)
					source: "favicon-194x194.png"
					smooth: true
					mipmap: true
				}
			}

			Connections {
				target: mainGUIObject
				onDefaultAvatarChanged: sideModel.setProperty(0, "src", mainGUIObject.defaultAvatar)
			}

			ListModel {
				id: sideModel

				Component.onCompleted: {
					append({"src": mainGUIObject.defaultAvatar,
							   "icon": false,
							   "helperName": "Profile",
							   "protruding": true
						   });
					append({"src": "awesome/comments_o",
							   "icon": true,
							   "helperName": "Rooms",
							   "protruding": true
						   });
					append({"src": "awesome/folder_o",
							   "icon": true,
							   "helperName": "Files Sharing",
							   "protruding": false
						   });
				}
			}

			Repeater {
				model: sideModel
				delegate: SideImg {
					name: helperName

					Connections {
						target: mainGUIObject
						onDefaultAvatarChanged: {
							if(helperName == "Profile") {
								if(mainGUIObject.defaultAvatar == "none" || mainGUIObject.defaultAvatar == "") {
									srcIcon = "awesome/user_o"
									isIcon = true
								}
								else {
									srcIcon = mainGUIObject.defaultAvatar
									isIcon = false
								}
							}
						}
					}

					srcIcon: {
						if(src == "none" || src == "")
							return "awesome/user_o"

						return src
					}
					isIcon: {
						if(src == "none" || src == "")
							return true

						return icon
					}

					margins: 0
					selected: false

					onClicked: {
						if(helperName === "Files Sharing")
							mainGUIObject.createFileSharingCard()
						else {
							if(leftBar.state === "narrow") {
								tabView.currentIndex = model.index+1
								leftBar.state = "wide"
							}
							else if(leftBar.state !== "narrow" && tabView.currentIndex === model.index+1)
								leftBar.state = "narrow"
							else if(leftBar.state !== "narrow" && tabView.currentIndex !== model.index+1)
								tabView.currentIndex = model.index+1
						}
					}
					onPressAndHold: {
						if(leftBar.state === "narrow" && protruding) {
							tabView.currentIndex = model.index+1
							leftBar.state = "wide"
						}
						else if(leftBar.state !== "narrow" && tabView.currentIndex === model.index+1)
							leftBar.state = "narrow"
						else if(leftBar.state !== "narrow" && tabView.currentIndex !== model.index+1 && protruding)
							tabView.currentIndex = model.index+1
					}

					View {
						anchors {
							top: parent.top
							right: parent.right
							topMargin: dp(7)
							rightMargin: dp(7)
						}

						width: dp(14)
						height: dp(14)
						radius: width/2

						backgroundColor: Theme.primaryColor
						elevation: 1

						visible: helperName == "Rooms" ?
									mainGUIObject.unreadMsgsLobbies > 0 ? true : false
						          : false

						Text {
							anchors.fill: parent
							text: helperName == "Rooms" ? mainGUIObject.unreadMsgsLobbies : ""
							color: "white"
							font.family: "Roboto"
							font.pixelSize: dp(11)
							verticalAlignment: Text.AlignVCenter
							horizontalAlignment: Text.AlignHCenter
						}
					}
				}
			}
		}

		Rectangle {
			id: upperLine

			anchors {
				horizontalCenter: parent.horizontalCenter
				top: upperColumn.bottom
				topMargin: dp(2)
			}

			height: dp(2)
			width: parent.width*0.4

			color: Theme.light.hintColor

			states: [
				State {
					name: "hide"; when: cardsIcons.count == 0
					PropertyChanges {
						target: upperLine
						width: 0
					}
				},
				State {
					name: "show"; when: cardsIcons.count != 0
					PropertyChanges {
						target: upperLine
						width: parent.width*0.4
					}
				}
			]

			transitions: [
				Transition {
					from: "hide"; to: "show"

					ParallelAnimation {
						NumberAnimation {
							target: upperLine
							property: "opacity"
							from: 0
							to: 1
							easing.type: Easing.InOutQuad;
							duration: MaterialAnimation.pageTransitionDuration
						}
						NumberAnimation {
							target: upperLine
							property: "width"
							easing.type: Easing.OutBounce;
							duration: MaterialAnimation.pageTransitionDuration*4
						}
					}
				},
				Transition {
					from: "show"; to: "hide"

					ParallelAnimation {
						NumberAnimation {
							target: upperLine
							property: "width"
							easing.type: Easing.InBounce;
							duration: MaterialAnimation.pageTransitionDuration*2
						}
					}
				}
			]
		}

		ListView {
			id: cardsIcons
			anchors{
				top: upperLine.bottom
				bottom: bottomColumn.top
			}

			width: parent.width

			clip: true
			model: cardsModel
			delegate: SideImg {
				id: sideImg

				property real k: 1
				name: model.name
				srcIcon: model.source
				isIcon: model.isIcon

				margins: 0
				selected: false

				state: "nentered"
				states: [
					State {
						name: "entered"; when: ink.containsMouse
						PropertyChanges {
							target: sideImg
							iconSize: dp(30)
							imageSize: dp(36)
						}
						PropertyChanges {
							target: numberNotification
							anchors.rightMargin: dp(3)
							anchors.topMargin: dp(3)
						}
					},
					State {
						name: "nentered"; when: !ink.containsMouse
						PropertyChanges {
							target: sideImg
							iconSize: dp(26)
							imageSize: dp(32)
						}
						PropertyChanges {
							target: numberNotification
							anchors.rightMargin: dp(7)
							anchors.topMargin: dp(7)
						}
					}
				]

				transitions: [
					Transition {
						from: "nentered"; to: "entered"

						ParallelAnimation {
							NumberAnimation {
								property: "iconSize"
								easing.type: Easing.OutQuad
								duration: MaterialAnimation.pageTransitionDuration/2
							}

							NumberAnimation {
								property: "imageSize"
								easing.type: Easing.OutQuad
								duration: MaterialAnimation.pageTransitionDuration/2
							}

							NumberAnimation {
								target: numberNotification
								properties: "anchors.rightMargin, anchors.topMargin"
								easing.type: Easing.OutQuad
								duration: MaterialAnimation.pageTransitionDuration/2
							}
						}
					},
					Transition {
						from: "entered"; to: "nentered"

						ParallelAnimation {
							NumberAnimation {
								property: "iconSize"
								easing.type: Easing.OutQuad
								duration: MaterialAnimation.pageTransitionDuration/4
							}

							NumberAnimation {
								property: "imageSize"
								easing.type: Easing.OutQuad
								duration: MaterialAnimation.pageTransitionDuration/4
							}

							NumberAnimation {
								target: numberNotification
								properties: "anchors.rightMargin, anchors.topMargin"
								easing.type: Easing.OutQuad
								duration: MaterialAnimation.pageTransitionDuration/2
							}
						}
					}
				]

				Ink {
					id: ink

					anchors.fill: parent
					z: -1

					acceptedButtons: Qt.RightButton | Qt.LeftButton
					onClicked: {
						if(mouse.button == Qt.LeftButton)
							raiseCard(model.cardIndex)
						else if(mouse.button == Qt.RightButton)
							overflowMenu.open(sideImg, mouse.x, mouse.y)
					}
				}

				Tooltip {
					id: toolTip
					text: model.name === "" ? toolTip.visible = false : model.name
					mouseArea: ink
				}

				Dropdown {
					id: overflowMenu
					objectName: "overflowMenu"
					overlayLayer: "dialogOverlayLayer"
					width: dp(200)
					height: dp(2*30)
					enabled: true
					anchor: Item.TopLeft
					durationSlow: 300
					durationFast: 150

					Column{
						anchors.fill: parent

						ListItem.Standard {
							height: dp(30)
							text: "Show"
							itemLabel.style: "menu"

							onClicked: {
								overflowMenu.close()
								raiseCard(model.cardIndex)
							}
						}

						ListItem.Standard {
							height: dp(30)
							text: "Close"
							itemLabel.style: "menu"

							onClicked: {
								overflowMenu.close()
								cardsModel.getCard(model.cardIndex).destroy()
							}
						}
					}
				}

				View {
					id: numberNotification
					anchors {
						top: parent.top
						right: parent.right
						topMargin: dp(7)
						rightMargin: dp(7)
					}

					width: textNotification.text.length > 1 ? dp(20)*k : dp(14)*k
					height: textNotification.text.length > 1 ? dp(16)*k : dp(14)*k
					radius: width/2

					backgroundColor: Theme.primaryColor
					elevation: 1
					visible: model.indicator != 0

					Text {
						id: textNotification
						anchors.fill: parent
						text: model.indicator
						color: "white"
						font.family: "Roboto"
						font.pixelSize: text.length > 2 ? dp(9)*k : dp(11)*k
						verticalAlignment: Text.AlignVCenter
						horizontalAlignment: Text.AlignHCenter
					}
				}
			}

			add: Transition {
				ParallelAnimation {
					NumberAnimation {
						property: "iconSize"
						from: dp(10)
						to: dp(26)
						easing.type: Easing.OutBounce;
						duration: MaterialAnimation.pageTransitionDuration*4
					}

					NumberAnimation {
						property: "imageSize"
						from: dp(22)
						to: dp(32)
						easing.type: Easing.OutBounce;
						duration: MaterialAnimation.pageTransitionDuration*4
					}

					NumberAnimation {
						property: "opacity"
						from: 0
						to: 1
						easing.type: Easing.OutBounce;
						duration: MaterialAnimation.pageTransitionDuration*4
					}

					NumberAnimation {
						property: "k"
						from: 0.5
						to: 1
						easing.type: Easing.OutBounce;
						duration: MaterialAnimation.pageTransitionDuration*4
					}
				}
			}

			remove: Transition {
				ParallelAnimation {
					NumberAnimation {
						property: "iconSize"
						from: dp(26)
						to: dp(10)
						easing.type: Easing.InBounce;
						duration: MaterialAnimation.pageTransitionDuration*2
					}

					NumberAnimation {
						property: "imageSize"
						from: dp(32)
						to: dp(22)
						easing.type: Easing.InBounce;
						duration: MaterialAnimation.pageTransitionDuration*2
					}

					NumberAnimation {
						property: "opacity"
						from: 1
						to: 0
						easing.type: Easing.InBounce;
						duration: MaterialAnimation.pageTransitionDuration*2
					}

					NumberAnimation {
						property: "k"
						from: 1
						to: 0.5
						easing.type: Easing.InBounce;
						duration: MaterialAnimation.pageTransitionDuration*2
					}
				}
			}

			displaced: Transition {
				NumberAnimation {
					property: "y"
					easing.type: Easing.InBounce
					duration: MaterialAnimation.pageTransitionDuration*2
				}
			}
		}

		Column {
			id: bottomColumn
			anchors.bottom: parent.bottom

			width: parent.width

			ListModel {
				id: sideModel2

				ListElement {
					src: "awesome/user_plus"
					icon: true
					helperName: "Add Friend"
				}
				ListElement {
					src: "awesome/cog"
					icon: true
					rt: true
					helperName: "Settings"
				}
				ListElement {
					src: "awesome/sign_out"
					icon: true
					helperName: "Exit"
				}
			}

			Repeater {
				model: sideModel2
				delegate: SideImg {
					name: helperName

					srcIcon: src
					isIcon: icon

					margins: 0
					rotate: rt

					onClicked: {
						switch(model.index) {
						    case 0:
								userAddDialog.show()
								break;
							case 1:
								settingsDialog.show()
								break;
							case 2:
								exitDialog.show()
								break;
						}
					}
				}
			}
		}
	}

	SequentialAnimation {
		running: true
		ParallelAnimation {
			NumberAnimation {
				target: leftBar
				property: "anchors.leftMargin"
				from: -dp(50)
				to: 0
				duration: MaterialAnimation.pageTransitionDuration
			}
			NumberAnimation {
				target: leftBar
				property: "opacity"
				from: 0
				to: 1
				duration: MaterialAnimation.pageTransitionDuration
			}
		}
	}
}
