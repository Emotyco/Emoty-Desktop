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
				width: dp(260)
				elevation: 3
			}
			PropertyChanges {
				target: tabs
				visible: true
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
				PropertyAction {
					target: tabs
					property: "visible"
					value: false
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

		width: dp(210)
		z: 1

		color: "#f2f2f2"
		visible: false

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
			anchors.left: parent.left

			width: parent.width
			height: parent.height*0.7

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
				target: main
				onDefaultAvatarChanged: sideModel.setProperty(0, "src", main.defaultAvatar)
			}

			ListModel {
				id: sideModel

				Component.onCompleted: {
					append({"src": main.defaultAvatar,
							   "icon": false,
							   "helperName": "Profile",
							   "protruding": true
						   });
					append({"src": "awesome/comments",
							   "icon": true,
							   "helperName": "Rooms",
							   "protruding": true
						   });
					append({"src": "awesome/share_alt",
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

					srcIcon: src
					isIcon: icon

					margins: 0
					selected: false

					onClicked: {
						if(helperName === "Rooms") {
							if(leftBar.state === "narrow") {
								tabView.currentIndex = model.index+1
								leftBar.state = "wide"
							}
							else if(leftBar.state !== "narrow" && tabView.currentIndex === model.index+1)
								leftBar.state = "narrow"
							else if(leftBar.state !== "narrow" && tabView.currentIndex !== model.index+1)
								tabView.currentIndex = model.index+1
						}
						if(helperName === "Files Sharing")
							main.createFileSharingCard()
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
									main.unreadMsgsLobbies > 0 ? true : false
						          : false

						Text {
							anchors.fill: parent
							text: helperName == "Rooms" ? main.unreadMsgsLobbies : ""
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

		Column {
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
