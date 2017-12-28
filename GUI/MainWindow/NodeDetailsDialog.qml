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
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.2
import QtQuick.Controls 1.4 as QtControls

import Material 0.3 as Material
import Material.ListItems 0.1 as ListItem

Material.Dialog {
	id: scrollingDialog

	property string name_pgp: ""
	property string pgp: ""
	property string name_peer: ""
	property string peer_id: ""

	property var last_contact
	property string status_message: ""

	property string encryption: ""
	property bool is_hidden_node

	property string local_address: ""
	property int local_port
	property string ext_address: ""
	property int ext_port
	property string dyn_dns: ""

	property string connection_status: ""

	property string certificate: ""

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

	function showAccount(name_pgp, pgp, name_peer, peer_id) {
		scrollingDialog.name_pgp = name_pgp
		scrollingDialog.pgp = pgp
		scrollingDialog.name_peer = name_peer
		scrollingDialog.peer_id = peer_id
		show()
	}

	function getNodeOptions() {
		var jsonData = {
			peer_id: peer_id
		}

		function callbackFn(par) {
			addressesModel.json = par.response

			var json = JSON.parse(par.response)

			last_contact = new Date(1000 * json.data.last_contact)
			status_message = json.data.status_message

			encryption = json.data.encryption
			is_hidden_node = json.data.is_hidden_node

			local_address = json.data.local_address
			local_port = json.data.local_port
			ext_address = json.data.ext_address
			ext_port = json.data.ext_port
			dyn_dns = json.data.dyn_dns

			connection_status = json.data.connection_status

			certificate = json.data.certificate
		}

		rsApi.request("/peers/get_node_options", JSON.stringify(jsonData), callbackFn)
	}

	function setNodeOptions() {
		var jsonData = {
			peer_id: peer_id,
			local_address: local_address,
			local_port: local_port,
			ext_address: ext_address,
			ext_port: ext_port,
			dyn_dns: dyn_dns
		}

		rsApi.request("/peers/set_node_options", JSON.stringify(jsonData), function(){})
	}

	onOpened: {
		getNodeOptions()
	}

	onRejected: {
		setNodeOptions()
	}

	JSONListModel {
		id: addressesModel
		query: "$.data.ip_addresses[*]"
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
		text: name_peer + "'s details"
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
				text: "Connectivity"
				selected: tabView.currentIndex === 1

				onClicked: tabView.currentIndex = 1
			}

			ListItem.Standard {
				text: "Certificate"
				selected: tabView.currentIndex === 2

				onClicked: tabView.currentIndex = 2
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

					Flickable {
						id: flick
						anchors.fill: parent

						clip: true
						contentHeight: pgpColumn.height

						pressDelay: 1000

						Column {
							id: pgpColumn
							width: parent.width

							ListItem.Subtitled {
								text: "Account"

								height: dp(48)
								interactive: true

								secondaryItem: Material.Label {
									anchors.verticalCenter: parent.verticalCenter

									text: name_pgp + "@" + pgp
								}

								onClicked: {
									scrollingDialog.close()
									pgpFriendDetailsDialog.showAccount(name_pgp, pgp)
								}
							}

							ListItem.Subtitled {
								text: "Node name"

								height: dp(48)
								interactive: false

								secondaryItem: Material.Label {
									anchors.verticalCenter: parent.verticalCenter

									text: name_peer
								}
							}

							ListItem.Subtitled {
								text: "Node id"

								height: dp(48)
								interactive: false

								secondaryItem: Material.Label {
									anchors.verticalCenter: parent.verticalCenter

									text: peer_id
								}
							}

							ListItem.Subtitled {
								text: "Last contact"

								height: dp(48)
								interactive: false

								secondaryItem: Material.Label {
									anchors.verticalCenter: parent.verticalCenter

									text: last_contact.toTimeString() + " " + last_contact.toDateString()
								}
							}

							ListItem.Subtitled {
								text: "Status message"

								height: dp(48)
								interactive: false

								secondaryItem: Material.Label {
									anchors.verticalCenter: parent.verticalCenter

									text: status_message
								}
							}

							ListItem.Subtitled {
								text: "Connection status"

								height: dp(48)
								interactive: false

								secondaryItem: Material.Label {
									anchors.verticalCenter: parent.verticalCenter

									text: connection_status
								}
							}

							ListItem.Subtitled {
								text: "Hidden node"

								height: dp(48)
								interactive: false

								secondaryItem: Material.Label {
									anchors.verticalCenter: parent.verticalCenter

									text: is_hidden_node ? "Yes" : "No"
								}
							}

							ListItem.Subtitled {
								text: "Encryption"

								height: dp(48)
								interactive: false

								secondaryItem: Material.Label {
									anchors.verticalCenter: parent.verticalCenter

									text: encryption
								}
							}
						}
					}

					Material.Scrollbar {
						flickableItem: flick
					}
				}
			}

			QtControls.Tab {
				id: tab
				title: "Connectivity"

				Item {
					anchors.fill: parent

					ListView {
						id: connectivityListView
						anchors.fill: parent
						clip: true

						header: Column {
							height: 6*dp(48)
							width: parent.width

							Connections {
								target: scrollingDialog

								onOpened: {
									localAddressTF.text = Qt.binding(function() {
										return local_address
									})

									localPortTF.text = Qt.binding(function() {
										return local_port
									})

									extAddressTF.text = Qt.binding(function() {
										return ext_address
									})

									extPortTF.text = Qt.binding(function() {
										return ext_port
									})

									dynDNSTF.text = Qt.binding(function() {
										return dyn_dns
									})
								}
							}

							ListItem.Subtitled {
								text: "Node Local Address"

								height: dp(48)
								interactive: false

								secondaryItem: Material.TextField {
									id: localAddressTF
									anchors.verticalCenter: parent.verticalCenter

									text: local_address

									font.pixelSize: dp(14)
									placeholderPixelSize: dp(14)

									horizontalAlignment: TextInput.AlignRight

									onTextChanged: local_address = localAddressTF.text
								}
							}

							ListItem.Subtitled {
								text: "Node Local Port"

								height: dp(48)
								interactive: false

								secondaryItem: Material.TextField {
									id: localPortTF
									anchors.verticalCenter: parent.verticalCenter

									validator: IntValidator {bottom: 0}
									text: local_port

									font.pixelSize: dp(14)
									placeholderPixelSize: dp(14)

									horizontalAlignment: TextInput.AlignRight

									onTextChanged: local_port = parseInt(localPortTF.text)
								}
							}

							ListItem.Subtitled {
								text: "Node External Address"

								height: dp(48)
								interactive: false

								secondaryItem: Material.TextField {
									id: extAddressTF
									anchors.verticalCenter: parent.verticalCenter

									text: ext_address

									font.pixelSize: dp(14)
									placeholderPixelSize: dp(14)

									horizontalAlignment: TextInput.AlignRight

									onTextChanged: ext_address = extAddressTF.text
								}
							}

							ListItem.Subtitled {
								text: "Node External Port"

								height: dp(48)
								interactive: false

								secondaryItem: Material.TextField {
									id: extPortTF
									anchors.verticalCenter: parent.verticalCenter

									validator: IntValidator {bottom: 0}
									text: ext_port

									font.pixelSize: dp(14)
									placeholderPixelSize: dp(14)

									horizontalAlignment: TextInput.AlignRight

									onTextChanged: ext_port = parseInt(extPortTF.text)
								}
							}

							ListItem.Subtitled {
								text: "Node Dynamic DNS"

								height: dp(48)
								interactive: false

								secondaryItem: Material.TextField {
									id: dynDNSTF
									anchors.verticalCenter: parent.verticalCenter

									text: dyn_dns

									font.pixelSize: dp(14)
									placeholderPixelSize: dp(14)

									horizontalAlignment: TextInput.AlignRight

									onTextChanged: dyn_dns = dynDNSTF.text
								}
							}

							ListItem.Subtitled {
								text: "Addresses List"

								height: dp(48)
								interactive: false
							}
						}

						model: addressesModel.model
						delegate: ListItem.Subtitled {
							height: dp(48)
							interactive: false

							text: model.ip_address

							secondaryItem: ColumnLayout {
								Layout.fillWidth: true
								Layout.column: 2

								spacing: 3 * Units.dp

								Material.Label {
									Layout.alignment: Qt.AlignRight

									elide: Text.ElideRight
									horizontalAlignment: Qt.AlignRight

									style: "caption"
									color: Material.Theme.light.subTextColor
								}

								Material.Label {
									Layout.alignment: Qt.AlignRight

									elide: Text.ElideRight
									horizontalAlignment: Qt.AlignRight

									color: Material.Theme.light.textColor
								}
							}
						}
					}

					Material.Scrollbar {
						flickableItem: connectivityListView
					}
				}
			}

			QtControls.Tab {
				title: "Options"

				TextArea {
					anchors {
						fill: parent
						leftMargin: dp(16)
						rightMargin: dp(16)
					}
					readOnly: true

					text: certificate.replace(/(\r\n|\n|\r)/gm,"")
					textFormat: Text.PlainText
					wrapMode: Text.WrapAnywhere
					font.pixelSize: dp(12)
					font.family: "Roboto"

					selectedTextColor: "white"
					selectionColor: Material.Theme.accentColor
					selectByMouse: true
				}
			}
		}
	}
}
