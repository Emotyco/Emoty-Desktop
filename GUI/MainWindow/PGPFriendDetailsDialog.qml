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

import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Controls 1.4 as QtControls

import Material 0.3 as Material
import Material.ListItems 0.1 as ListItem

Material.Dialog {
	id: scrollingDialog

	property string name: ""
	property string pgp: ""

	property int stateToken_gxs: 0
	property int stateToken_pgp: 0

	Component.onDestruction: {
		mainGUIObject.unregisterToken(stateToken_gxs)
		mainGUIObject.unregisterToken(stateToken_pgp)
	}

	property string pgp_key
	property string pgp_fingerprint

	property bool direct_transfer
	property bool allow_push
	property bool require_WL

	property bool own_sign
	property bool own_sign_temp
	property int trustLvl

	property int maxUploadSpeed
	property int maxDownloadSpeed

	positiveButtonText: "Cancel"
	negativeButtonText: "Apply"

	contentMargins: dp(8)

	positiveButtonSize: dp(13)
	negativeButtonSize: dp(13)

	Behavior on opacity {
		NumberAnimation {
			easing.type: Easing.InOutQuad
			duration: 200
		}
	}

	function showAccount(name, pgp, nodesJson) {
		scrollingDialog.name = name
		scrollingDialog.pgp = pgp

		if(nodesJson != undefined)
			locationsModel.json = nodesJson
		else
			refreshPgpIdModel()

		show()
	}

	function refreshGxsIdModel() {
		function callbackFn(par) {
			gxsIdModel.json = par.response

			stateToken_gxs = JSON.parse(par.response).statetoken
			mainGUIObject.registerToken(stateToken_gxs, refreshGxsIdModel)
		}

		rsApi.request("/identity/*/", "", callbackFn)
	}

	function refreshPgpIdModel() {
		function callbackFn(par) {
			locationsModel.json = par.response

			stateToken_pgp = JSON.parse(par.response).statetoken
			mainGUIObject.registerToken(stateToken_pgp, refreshPgpIdModel)
		}

		rsApi.request("/peers/*", "", callbackFn)
	}

	function getPGPOptions() {
		var jsonData = {
			pgp_id: pgp
		}

		function callbackFn(par) {
			signersModel.json = par.response

			var json = JSON.parse(par.response)

			pgp_fingerprint = json.data.pgp_fingerprint
			pgp_key = json.data.pgp_key

			direct_transfer = json.data.direct_transfer
			allow_push = json.data.allow_push
			require_WL = json.data.require_WL

			own_sign = json.data.own_sign
			trustLvl = json.data.trustLvl

			maxUploadSpeed = json.data.maxUploadSpeed
			maxDownloadSpeed = json.data.maxDownloadSpeed
		}

		rsApi.request("/peers/get_pgp_options", JSON.stringify(jsonData), callbackFn)
	}

	function setPGPOptions() {
		var jsonData = {
			pgp_id: pgp,
			trustLvl: trustLvl,
			max_upload_speed: maxUploadSpeed,
			max_download_speed: maxDownloadSpeed,
			direct_transfer: direct_transfer,
			allow_push: allow_push,
			require_WL: require_WL
		}

		if(!own_sign)
			jsonData.own_sign = own_sign_temp

		rsApi.request("/peers/set_pgp_options", JSON.stringify(jsonData), function(){})
	}

	onOpened: {
		getPGPOptions()
	}

	onRejected: {
		setPGPOptions()
	}

	Component.onCompleted: refreshGxsIdModel()

	JSONListModel {
		id: locationsModel

		query: "$.data[?(@.pgp_id=='"+pgp+"')].locations[*]"
	}

	JSONListModel {
		id: gxsIdModel
		query: "$.data[?(@.pgp_id=='"+pgp+"')]"
	}

	JSONListModel {
		id: signersModel
		query: "$.data.gpg_signers[*]"
	}

	Material.Label {
		id: titleLabel

		anchors {
			left: parent.left
			leftMargin: dp(15)
		}

		height: dp(50)
		verticalAlignment: Text.AlignVCenter

		wrapMode: Text.Wrap
		text: name + "'s details"
		style: "title"
		color: Material.Theme.accentColor
	}

	Item {
		width: mainGUIObject.width < dp(900) ? mainGUIObject.width - dp(100) : dp(600)
		height: mainGUIObject.width < dp(450) ? mainGUIObject.width - dp(100) : dp(300)

		Column {
			anchors {
				left: parent.left
				top: parent.top
				bottom: parent.bottom
			}

			width: parent.width/4

			ListItem.Standard {
				text: "General"
				selected: tabView.currentIndex === 0

				onClicked: tabView.currentIndex = 0
			}

			ListItem.Standard {
				text: "PGP Key"
				selected: tabView.currentIndex === 1

				onClicked: tabView.currentIndex = 1
			}

			ListItem.Standard {
				text: "Options"
				selected: tabView.currentIndex === 2

				onClicked: tabView.currentIndex = 2
			}

			ListItem.Standard {
				text: "Nodes"
				selected: tabView.currentIndex === 3

				onClicked: tabView.currentIndex = 3
			}

			ListItem.Standard {
				text: "Identities"
				selected: tabView.currentIndex === 4

				onClicked: tabView.currentIndex = 4
			}
		}

		QtControls.TabView {
			id: tabView

			anchors {
				fill: parent
				leftMargin: parent.width/4
			}

			frameVisible: false
			tabsVisible: false

			QtControls.Tab {
				title: "General"

				Item {
					anchors.fill: parent

					ListView {
						id: generalListView
						anchors.fill: parent

						clip: true

						header: Column {
							height: 3*dp(48)
							width: parent.width

							Connections {
								target: scrollingDialog

								onOpened: {
									selection.selectedIndex = Qt.binding(function() {
										return trustLvl
									})
								}
							}

							ListItem.Subtitled {
								id: fingerprint
								text: "Fingerprint"

								height: dp(48)
								interactive: false

								secondaryItem: Material.TextField {
									anchors.verticalCenter: parent.verticalCenter
									width: fingerprint.width*0.7

									text: pgp_fingerprint
									readOnly: true

									font.pixelSize: dp(14)
									placeholderPixelSize: dp(14)
								}
							}

							ListItem.Subtitled {
								text: "Trustlevel"

								height: dp(48)
								interactive: false

								secondaryItem: Material.MenuField {
									id: selection
									z: 2
									model: ["Unset", "Unknown", "No trust", "Marginal", "Full", "Ultimate"]
									width: dp(150)

									selectedIndex: trustLvl

									onItemSelected: trustLvl = index
								}
							}

							ListItem.Standard {
								text: "This key is signed by"

								height: dp(48)
								interactive: false
							}
						}

						model: signersModel.model
						delegate: ListItem.Standard {
							height: dp(48)
							interactive: false
							text: model.name + "@" + model.pgp_id
						}
					}

					Material.Scrollbar {
						flickableItem: generalListView
					}
				}
			}

			QtControls.Tab {
				id: tab
				title: "PGP Key"

				Flickable {
					id: flick
					anchors.fill: parent

					clip: true
					contentHeight: pgpColumn.height

					pressDelay: 1000

					Column {
						id: pgpColumn
						width: parent.width

						Connections {
							target: scrollingDialog

							onOpened: {
								switchSignKey.checked = Qt.binding(function() {
									return own_sign
								})
							}
						}

						ListItem.Subtitled {
							text: "Sign this key"

							height: dp(48)
							interactive: !own_sign

							secondaryItem: Material.Switch {
								id: switchSignKey
								anchors.verticalCenter: parent.verticalCenter
								enabled: !own_sign

								checked: own_sign

								onClicked: own_sign_temp = switchSignKey.checked
							}

							onClicked: {
								switchSignKey.checked = !switchSignKey.checked
								own_sign_temp = switchSignKey.checked
							}
						}

						ListItem.Standard {
							text: "PGP key assigned to the displayed account"

							height: dp(48)
						}

						TextArea {
							id: pgpTextArea
							anchors {
								left: parent.left
								right: parent.right
								leftMargin: dp(16)
								rightMargin: dp(16)
							}
							readOnly: true

							text: pgp_key
							textFormat: Text.PlainText
							wrapMode: Text.WrapAnywhere
							font.pixelSize: dp(12)
							font.family: "Roboto"

							selectedTextColor: "white"
							selectionColor: Material.Theme.accentColor
							selectByMouse: true
							selectByKeyboard: true
						}
					}
				}
			}

			QtControls.Tab {
				title: "Options"

				Column {
					anchors.fill: parent

					Connections {
						target: scrollingDialog

						onOpened: {
							switchDirectTransfer.checked = Qt.binding(function() {
								return direct_transfer
							})

							switchAllowPush.checked = Qt.binding(function() {
								return allow_push
							})

							switchRequireWL.checked = Qt.binding(function() {
								return require_WL
							})

							maxUploadSpeedTF.text = Qt.binding(function() {
								return maxUploadSpeed
							})

							maxDownloadSpeedTF.text = Qt.binding(function() {
								return maxDownloadSpeed
							})
						}
					}

					ListItem.Standard {
						text: "This options apply to all nodes of displayed account"

						height: dp(48)
						interactive: false
					}

					ListItem.Subtitled {
						text: "Use as a direct source, when available"

						height: dp(48)

						secondaryItem: Material.Switch {
							id: switchDirectTransfer

							anchors.verticalCenter: parent.verticalCenter
							checked: direct_transfer

							onClicked: direct_transfer = switchDirectTransfer.checked
						}

						onClicked: {
							switchDirectTransfer.checked = !switchDirectTransfer.checked
							direct_transfer = switchDirectTransfer.checked
						}
					}

					ListItem.Subtitled {
						text: "Auto-download recommended files from this node"

						height: dp(48)

						secondaryItem: Material.Switch {
							id: switchAllowPush

							anchors.verticalCenter: parent.verticalCenter
							checked: allow_push

							onClicked: allow_push = switchAllowPush.checked
						}

						onClicked: {
							switchAllowPush.checked = !switchAllowPush.checked
							allow_push = switchAllowPush.checked
						}
					}

					ListItem.Subtitled {
						text: "Require white list clearance"

						height: dp(48)

						secondaryItem: Material.Switch {
							id: switchRequireWL

							anchors.verticalCenter: parent.verticalCenter
							checked: require_WL

							onClicked: require_WL = switchRequireWL.checked
						}

						onClicked: {
							switchRequireWL.checked = !switchRequireWL.checked
							require_WL = switchRequireWL.checked
						}
					}

					ListItem.Subtitled {
						text: "Max upload speed(0=unlimited)(kB/s)"

						height: dp(48)
						interactive: false

						secondaryItem: Material.TextField {
							id: maxUploadSpeedTF
							anchors.verticalCenter: parent.verticalCenter
							width: dp(100)

							horizontalAlignment: TextInput.AlignRight
							validator: IntValidator {bottom: 0}
							text: maxUploadSpeed

							font.pixelSize: dp(14)
							placeholderPixelSize: dp(14)

							onTextChanged: maxUploadSpeed = parseInt(maxUploadSpeedTF.text)
						}
					}

					ListItem.Subtitled {
						text: "Max download speed(0=unlimited)(kB/s)"

						height: dp(48)
						interactive: false

						secondaryItem: Material.TextField {
							id: maxDownloadSpeedTF
							anchors.verticalCenter: parent.verticalCenter
							width: dp(100)

							horizontalAlignment: TextInput.AlignRight
							validator: IntValidator {bottom: 0}
							text: maxDownloadSpeed

							font.pixelSize: dp(14)
							placeholderPixelSize: dp(14)

							onTextChanged: maxDownloadSpeed = parseInt(maxDownloadSpeedTF.text)
						}
					}
				}
			}

			QtControls.Tab {
				title: "Nodes"

				Item {
					anchors.fill: parent

					ListView {
						id: nodesListView
						anchors.fill: parent

						clip: true

						header: ListItem.Subtitled {
							text: "Nodes assigned to the displayed account"

							height: dp(48)
							interactive: false

							secondaryItem: Material.Label {
								anchors.centerIn: parent

								text: locationsModel.count

								elide: Text.ElideRight
								style: "subheading"
								color: Material.Theme.light.textColor
							}
						}

						model: locationsModel.model
						delegate: ListItem.Subtitled {
							id: nodeItem
							text: model.location
							subText: "PeerId: " + model.peer_id

							onClicked: {
								scrollingDialog.close()
								nodeDetailsDialog.showAccount(model.name, model.pgp_id, model.location, model.peer_id)
							}

							action: Material.Icon {
								anchors.centerIn: parent

								width: dp(32)
								height: dp(32)
								size: dp(32)

								name: "awesome/user"
								color: Material.Theme.light.iconColor
							}

							MouseArea {
								id: mA

								anchors.fill: parent
								acceptedButtons: Qt.RightButton

								onClicked: overflowMenu.open(nodeItem, mouse.x, mouse.y)
							}

							Material.Dropdown {
								id: overflowMenu
								objectName: "overflowMenu"
								width: dp(200)
								height: dp(2*30)
								enabled: true
								anchor: Item.TopLeft
								durationSlow: 300
								durationFast: 150

								onClosed: mA.preventStealing = true

								Column{
									anchors.fill: parent

									ListItem.Standard {
										height: dp(30)
										text: "Chat"
										itemLabel.style: "menu"
										onClicked: {
											overflowMenu.close()

											mainGUIObject.createChatPeerCard(model.name, model.location, model.peer_id, model.chat_id, "ChatPeerCard.qml")
											scrollingDialog.close()
										}
									}

									ListItem.Standard {
										height: dp(30)
										text: "Details"
										itemLabel.style: "menu"
										onClicked: {
											overflowMenu.close()
											scrollingDialog.close()

											nodeDetailsDialog.showAccount(model.name, model.pgp_id, model.location, model.peer_id)
										}
									}
								}
							}
						}
					}

					Material.Scrollbar {
						flickableItem: nodesListView
					}
				}
			}

			QtControls.Tab {
				title: "Identities"

				Item {
					anchors.fill: parent

					ListView {
						id: identitiesListView
						anchors.fill: parent

						clip: true

						header: ListItem.Subtitled {
							text: "Identities assigned to the displayed account"

							height: dp(48)
							interactive: false

							secondaryItem: Material.Label {
								anchors.centerIn: parent

								text: gxsIdModel.count

								elide: Text.ElideRight
								style: "subheading"
								color: Material.Theme.light.textColor
							}
						}

						model: gxsIdModel.model
						delegate: ListItem.Subtitled {
							id: identityItem

							text: model.name
							subText: "GxsId: " + model.gxs_id

							onClicked: {
								scrollingDialog.close()
								identityDetailsDialog.showIdentity(model.name, model.gxs_id)
							}

							action: Item {
								id: identityAvatar
								anchors.centerIn: parent
								width: dp(32)
								height: dp(32)

								property string avatar: (gxs_avatars.getAvatar(model.gxs_id) == "none"
														 || gxs_avatars.getAvatar(model.gxs_id) == "")
														? "none"
														: gxs_avatars.getAvatar(model.gxs_id)

								onAvatarChanged: canvas.loadImage(identityAvatar.avatar)

								Component.onCompleted: {
									if(gxs_avatars.getAvatar(model.gxs_id) == "")
										getIdentityAvatar()
								}

								function getIdentityAvatar() {
									var jsonData = {
										gxs_id: model.gxs_id
									}

									function callbackFn(par) {
										var json = JSON.parse(par.response)
										if(json.returncode == "fail") {
											getIdentityAvatar()
											return
										}

										gxs_avatars.storeAvatar(model.gxs_id, json.data.avatar)
										if(gxs_avatars.getAvatar(model.gxs_id) != "none")
											identityAvatar.avatar = gxs_avatars.getAvatar(model.gxs_id)
									}

									rsApi.request("/identity/get_avatar", JSON.stringify(jsonData), callbackFn)
								}

								Canvas {
									id: canvas

									anchors.centerIn: parent
									width: dp(32)
									height: dp(32)

									enabled: identityAvatar.avatar != "none"
									visible: identityAvatar.avatar != "none"

									onPaint: {
										var ctx = getContext("2d");
										if (canvas.isImageLoaded(identityAvatar.avatar)) {
											var profile = Qt.createQmlObject('
                                                import QtQuick 2.5
                                                Image {
                                                    source: identityAvatar.avatar
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

								Material.Icon {
									anchors.centerIn: parent

									width: dp(32)
									height: dp(32)
									size: dp(32)

									enabled: identityAvatar.avatar == "none"
									visible: identityAvatar.avatar == "none"

									name: "awesome/user_o"
									color: Material.Theme.light.iconColor
								}
							}

							MouseArea {
								anchors.fill: parent
								acceptedButtons: Qt.RightButton

								onClicked: overflowMenu2.open(identityItem, mouse.x, mouse.y)
							}

							Material.Dropdown {
								id: overflowMenu2
								objectName: "overflowMenu"
								width: dp(200)
								height: model.contact ? dp(2*30) : dp(3*30)
								enabled: true
								anchor: Item.TopLeft
								durationSlow: 300
								durationFast: 150

								Column{
									anchors.fill: parent

									ListItem.Standard {
										height: dp(30)
										enabled: !model.contact
										visible: !model.contact

										text: "Add to contacts"
										itemLabel.style: "menu"
										onClicked: {
											overflowMenu2.close()

											var jsonData = {
												gxs_id: model.gxs_id
											}

											rsApi.request("/identity/add_contact", JSON.stringify(jsonData), function(){})

											scrollingDialog.close()
										}
									}

									ListItem.Standard {
										height: dp(30)
										text: "Chat"
										itemLabel.style: "menu"
										onClicked: {
											overflowMenu2.close()

											mainGUIObject.createChatGxsCard(model.name, model.gxs_id, "ChatGxsCard.qml")

											scrollingDialog.close()
										}
									}

									ListItem.Standard {
										height: dp(30)
										text: "Details"
										itemLabel.style: "menu"
										onClicked: {
											overflowMenu2.close()
											scrollingDialog.close()

											identityDetailsDialog.showIdentity(model.name, model.gxs_id)
										}
									}
								}
							}
						}
					}

					Material.Scrollbar {
						flickableItem: identitiesListView
					}
				}
			}
		}
	}
}
