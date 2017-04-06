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

import Material 0.3
import Material.ListItems 0.1 as ListItem

Component {
	Item {
		id: pgpBaseItem

		property string msg: model.custom_state_string
		property string state_string: model.state_string
		property color statuscolor: state_string === "online"   ? "#4caf50" :   // green
									state_string === "busy"	 ? "#FF5722" :   // red
									state_string === "away"	 ? "#FFEB3B" :   // yellow
															      "#9E9E9E"	 // grey
		property string pgp

		width: parent.width
		height: dp(50)

		clip: true

		state: "hide_loc"
		states: [
			State {
				name: "hide_loc";
				PropertyChanges {
					target: pgpBaseItem
					height: dp(50)
				}
			},
			State {
				name: "show_loc";
				PropertyChanges {
					target: pgpBaseItem
					height: dp(50)+dp(locationsModel.count*50)
				}
			}
		]

		transitions: [
			Transition {
				from: "hide_loc"
				to: "show_loc"

				NumberAnimation {
					target: pgpBaseItem
					property: "height"
					duration: MaterialAnimation.pageTransitionDuration/2
					easing.type: Easing.InOutQuad
				}
			},
			Transition {
				from: "show_loc"
				to: "hide_loc"

				NumberAnimation {
					target: pgpBaseItem
					property: "height"
					duration: MaterialAnimation.pageTransitionDuration/2
					easing.type: Easing.InOutQuad
				}
			}
		]

		Component.onCompleted: pgp = model.pgp_id

		JSONListModel {
			id: locationsModel

			json: pgpIdModel.json
			query: "$.data[?(@.pgp_id=='"+pgp+"')].locations[*]"
		}

		MouseArea {
			anchors.fill: parent

			onClicked: {
				if(pgpBaseItem.state == "show_loc") {
					pgpBaseItem.state = "hide_loc"
					peerBoxIcon.state = "rotated"
				}
				else if(pgpBaseItem.state == "hide_loc") {
					pgpBaseItem.state = "show_loc"
					peerBoxIcon.state = "nonrotated"
				}
			}
		}

		Rectangle {
			id: friendroot

			property int unread_msgs: 0

			anchors.top: parent.top

			height: dp(50)
			width: parent.width

			clip: true

			states: [
				State {
					name: "hidden";
					PropertyChanges {
						target: friendroot
						color: "#ffffff"
					}
				},
				State {
					name: "entered";
					PropertyChanges {
						target: friendroot
						color: Qt.rgba(0,0,0,0.03)
					}
				}
			]

			MouseArea {
				anchors.fill: parent

				acceptedButtons: Qt.RightButton
				hoverEnabled: true

				onEntered: friendroot.state = "entered"
				onExited: friendroot.state = "hidden"
				onClicked: overflowMenu.open(friendroot, mouse.x, mouse.y);

				states: [
					State {
						name: "name"; when: msg === ""
						PropertyChanges {
							target: name
							height: friendroot.height
							verticalAlignment: Text.AlignVCenter
						}
					},
					State {
						name: "smsg"; when: msg != ""
						PropertyChanges {
							target: name
							height: friendroot.height/2
							verticalAlignment: Text.AlignBottom
						}
					}
				]

				Dropdown {
					id: overflowMenu
					objectName: "overflowMenu"
					overlayLayer: "dialogOverlayLayer"
					width: dp(200)
					height: dp(1*30)
					enabled: true
					anchor: Item.TopLeft
					durationSlow: 200
					durationFast: 100

					Column{
						anchors.fill: parent

						ListItem.Standard {
							height: dp(30)
							text: "Remove"
							itemLabel.style: "menu"
							onClicked: {
								rsApi.request("/peers/"+pgp+"/delete", "")
								overflowMenu.close()
							}
						}
					}
				}

				Icon {
					id: peerBoxIcon

					anchors.verticalCenter: parent.verticalCenter

					x: dp(10)
					width: dp(40)
					height: dp(40)

					name: "awesome/chevron_down"
					color: "#9E9E9E"

					size: dp(15)

					state: "rotated"
					states: [
						State {
							name: "nonrotated";
							PropertyChanges {
								target: peerBoxIcon
								rotation: 0
							}
						},
						State {
							name: "rotated";
							PropertyChanges {
								target: peerBoxIcon
								rotation: -90
							}
						}
					]


					Behavior on rotation {
						NumberAnimation { duration: MaterialAnimation.pageTransitionDuration/2 }
					}
				}

				Item{
					id: text

					x: dp(60)
					width: dp(151)
					height: parent.height

					Text {
						id: name

						height: parent.height

						text: model.name
						color: Theme.light.textColor

						font {
							family: "Roboto"
							pixelSize: dp(14)
						}

						verticalAlignment: Text.AlignVCenter
						horizontalAlignment: Text.AlignLeft
					}

					Text {
						id: smsg

						y: parent.height/2
						height: parent.height/2

						color: statuscolor
						text: msg

						font {
							family: "Roboto"
							pixelSize: dp(12)
						}

						verticalAlignment: Text.AlignTop
						horizontalAlignment: Text.AlignLeft
					}
				}

				Rectangle {
					anchors {
						verticalCenter: parent.verticalCenter
						right: parent.right
						rightMargin: friendroot.unread_msgs > 0 ? dp(10) : dp(15)
					}

					width: friendroot.unread_msgs > 0 ? dp(20) : dp(10)
					height: friendroot.unread_msgs > 0 ? dp(20) : dp(10)

					radius: width/2
					color: statuscolor

					Text {
						anchors.fill: parent

						text: friendroot.unread_msgs
						color: "white"
						visible: friendroot.unread_msgs > 0 ? true : false

						font.family: "Roboto"

						verticalAlignment: Text.AlignVCenter
						horizontalAlignment: Text.AlignHCenter
					}
				}
			}
		}

		ListView {
			anchors {
				top: friendroot.bottom
				bottom: pgpBaseItem.bottom
				left: pgpBaseItem.left
				right: pgpBaseItem.right
			}

			clip: true

			model: locationsModel.model
			delegate: PeerListDelegate{}
		}
	}
}
