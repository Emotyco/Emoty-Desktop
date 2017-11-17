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
import QtQuick.Layouts 1.3

import Material 0.3
import Material.Extras 0.1 as Circle
import Material.ListItems 0.1 as ListItem

Component {
	Rectangle {
		id: friendroot

		property bool entered: false
		property string msg: ""

		property bool isEmpty: model.gxs_id == ""
		property string state_string: model.state_string
		property color statuscolor: state_string === "online"   ? "#4caf50" :   // green
									state_string === "busy"		? "#FF5722" :   // red
									state_string === "away"		? "#FFEB3B" :   // yellow
																  "#9E9E9E"		// grey

		property string avatar: model.avatar == ""
								? "avatar.png"
								: "data:image/png;base64," + model.avatar

		onAvatarChanged: canvas.loadImage(avatar)

		width: parent.width
		height: dp(50)

		states: [
			State {
				name: "hidden"; when: entered === false
				PropertyChanges { target: friendroot; color: "#ffffff" }
			},
			State {
				name: "entered"; when: entered === true
				PropertyChanges { target: friendroot; color: Qt.rgba(0,0,0,0.04) }
			}
		]

		Component.onCompleted: {
			if(model.avatar == "")
				getIdentityAvatar()
		}

		function getIdentityAvatar() {
			var jsonData = {
				gxs_id: model.gxs_id
			}

			function callbackFn(par) {
				var json = JSON.parse(par.response)
				if(json.data.avatar.length > 0)
					gxsModel.loadJSONAvatar(model.gxs_id, par.response)

				if(json.returncode == "fail")
					getIdentityAvatar()
			}

			rsApi.request("/identity/get_avatar", JSON.stringify(jsonData), callbackFn)
		}

		MouseArea {
			anchors.fill: parent

			acceptedButtons: Qt.RightButton | Qt.LeftButton
			hoverEnabled: !isEmpty
			enabled: !isEmpty

			onEntered: {
				friendroot.entered = true
			}
			onExited: {
				friendroot.entered = false
			}
			onClicked: {
				if(mouse.button == Qt.RightButton)
					overflowMenu.open(friendroot, mouse.x, mouse.y)
				else if(mouse.button == Qt.LeftButton)
					main.createChatGxsCard(model.name, model.gxs_id, "ChatGxsCard.qml")
			}

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
				height: isEmpty ? 0 : main.advmode ? dp(3*30) : dp(2*30)
				enabled: true
				anchor: Item.TopLeft
				durationSlow: 300
				durationFast: 150

				Column{
					anchors.fill: parent

					ListItem.Standard {
						height: dp(30)
						text: "Add to contacts"
						itemLabel.style: "menu"

						visible: !model.is_contact && !isEmpty
						enabled: !model.is_contact && !isEmpty

						onClicked: {
							overflowMenu.close()

							var jsonData = {
								gxs_id: model.gxs_id
							}

							rsApi.request("/identity/add_contact", JSON.stringify(jsonData), function(){})
						}
					}

					ListItem.Standard {
						height: dp(30)
						text: "Chat"
						itemLabel.style: "menu"

						visible: !isEmpty
						enabled: !isEmpty

						onClicked: {
							overflowMenu.close()
							main.createChatGxsCard(model.name, model.gxs_id, "ChatGxsCard.qml")
						}
					}

					ListItem.Standard {
						height: dp(30)
						enabled: main.advmode && !isEmpty
						visible: main.advmode && !isEmpty

						text: "Details"
						itemLabel.style: "menu"
						onClicked: {
							overflowMenu.close()
							identityDetailsDialog.showIdentity(model.name, model.gxs_id)
						}
					}

					ListItem.Standard {
						height: dp(30)
						text: "Remove"
						itemLabel.style: "menu"

						visible: model.is_contact && !isEmpty
						enabled: model.is_contact && !isEmpty

						onClicked: {
							overflowMenu.close()

							if(!main.advmode && model.is_only && model.pgp_linked) {
								confirmationDialog.show("Do you want to remove contact?
(It will remove all connections.)", function() {
	                                var jsonData = {
		                                gxs_id: model.gxs_id
	                                }

	                                rsApi.request("/peers/"+model.pgp_id+"/delete", "", function(){})
	                                rsApi.request("/identity/remove_contact", JSON.stringify(jsonData), function(){})
                                })
							}
							else {
								confirmationDialog.show("Do you want to remove contact?", function() {
									var jsonData = {
										gxs_id: model.gxs_id
									}

									rsApi.request("/identity/remove_contact", JSON.stringify(jsonData), function(){})
								})
							}
						}
					}
				}
			}

			Canvas {
				id: canvas

				anchors.verticalCenter: parent.verticalCenter

				x: dp(14)
				width: dp(32)
				height: dp(32)

				Component.onCompleted: loadImage(friendroot.avatar)
				onPaint: {
					var ctx = getContext("2d");
					if (canvas.isImageLoaded(friendroot.avatar)) {
						var profile = Qt.createQmlObject('
                            import QtQuick 2.5
                            Image {
                                source: friendroot.avatar
                                visible:false
                            }', canvas);
						var centreX = width/2;
						var centreY = height/2;

						ctx.save()
						ctx.beginPath();
						ctx.moveTo(centreX, centreY);
						ctx.arc(centreX, centreY, width / 2, 0, Math.PI * 2, false);
						ctx.clip();
						ctx.drawImage(profile, 0, 0, canvas.width, canvas.height);
						ctx.restore()
					}
				}
				onImageLoaded:requestPaint()
			}

			Item {
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
					color: Theme.primaryColor
					text: msg
					font.family: "Roboto"
					verticalAlignment: Text.AlignTop
					horizontalAlignment: Text.AlignLeft
					font.pixelSize: dp(12)
				}
			}

			View {
				anchors {
					verticalCenter: parent.verticalCenter
					right: parent.right
					rightMargin: model.unread_count > 0 ? dp(10) : dp(15)
				}

				width: model.unread_count > 0 ? dp(20) : dp(10)
				height: model.unread_count > 0 ? dp(20) : dp(10)
				radius: width/2

				elevation: model.unread_count > 0 ? 1 : 0
				backgroundColor: statuscolor

				visible: model.unread_count > 0 ? true
												: (!model.own && model.pgp_linked)

				Text {
					anchors.fill: parent

					text: model.unread_count
					color: "white"

					font.family: "Roboto"
					font.pixelSize: dp(12)
					visible: model.unread_count > 0 ? true : false

					verticalAlignment: Text.AlignVCenter
					horizontalAlignment: Text.AlignHCenter
				}
			}
		}
	}
}
