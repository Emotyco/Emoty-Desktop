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
import QtQuick.Controls 1.4 as QtControls

import Material 0.3
import Material.Extras 0.1
import Material.ListItems 0.1 as ListItem

Dialog {
	id: scrollingDialog

	property bool advmode: main.advmode
	property bool flickablemode: main.flickablemode

	property real approximationSize: Units.multiplier

	property int networkMode: 0
	property int natMode: 0

	property string localAddress: ""
	property int localPort
	property string extAddress: ""
	property int extPort
	property string dynDNS: ""

	property int uploadLimit
	property int downloadLimit

	property bool checkIP

	property string torAddress: ""
	property int torPort
	property string i2pAddress: ""
	property int i2pPort

	positiveButtonText: "Cancel"
	negativeButtonText: "Apply"

	contentMargins: dp(8)

	positiveButtonSize: dp(13)
	negativeButtonSize: dp(13)

	onRejected: {
		setNetworkOptions()

		var jsonData = {
			advanced_mode: advmode
		}

		rsApi.request("/settings/set_advanced_mode/", JSON.stringify(jsonData), function(){})

		var jsonData2 = {
			flickable_grid_mode: flickablemode
		}

		rsApi.request("/settings/set_flickable_grid_mode/", JSON.stringify(jsonData2), function(){})

		main.advmode = scrollingDialog.advmode
		main.flickablemode = scrollingDialog.flickablemode
		notifier.setAdvMode(scrollingDialog.advmode)

		Units.setMultiplier(approximationSize)
	}

	onOpened: {
		scrollingDialog.advmode = main.advmode
		scrollingDialog.flickablemode = main.flickablemode
		scrollingDialog.approximationSize = Units.multiplier
	}

	Behavior on opacity {
		NumberAnimation { duration: 200 }
	}

	Component.onCompleted: {
		getAdvancedMode()
		getFlickableGridMode()
		getNetworkOptions()
	}

	function getAdvancedMode() {
		function callbackFn(par) {
			scrollingDialog.advmode = Boolean(JSON.parse(par.response).data.advanced_mode)
		}

		rsApi.request("/settings/get_advanced_mode/", "", callbackFn)
	}

	function getFlickableGridMode() {
		function callbackFn(par) {
			scrollingDialog.flickablemode = Boolean(JSON.parse(par.response).data.flickable_grid_mode)
		}

		rsApi.request("/settings/get_flickable_grid_mode/", "", callbackFn)
	}

	function getNetworkOptions() {
		function callbackFn(par) {
			websitesModel.json = par.response
			ipAddressesModel.json = par.response

			var json = JSON.parse(par.response)

			networkMode = json.data.discovery_mode
			natMode = json.data.nat_mode

			localAddress = json.data.local_address
			localPort = json.data.local_port
			extAddress = json.data.external_address
			extPort = json.data.external_port
			dynDNS = json.data.dyn_dns

			uploadLimit = json.data.upload_limit
			downloadLimit = json.data.download_limit

			checkIP = json.data.check_ip

			torAddress = json.data.tor_address
			torPort = json.data.tor_port
			i2pAddress = json.data.i2p_address
			i2pPort = json.data.i2p_port
		}

		rsApi.request("/peers/get_network_options/", "", callbackFn)
	}

	function setNetworkOptions() {
		var jsonData = {
			discovery_mode: networkMode,
			nat_mode: natMode,
			dyn_dns: dynDNS,
			upload_limit: uploadLimit,
			download_limit: downloadLimit,
			check_ip: checkIP,
			tor_address: torAddress,
			tor_port: torPort,
			i2p_address: i2pAddress,
			i2p_port: i2pPort
		}

		if(natMode != 0) {
			jsonData.local_address = localAddress
			jsonData.local_port = localPort
			jsonData.external_address = extAddress
			jsonData.external_port = extPort
		}

		rsApi.request("/peers/set_network_options", JSON.stringify(jsonData), function(){})
	}

	JSONListModel {
		id: websitesModel
		query: "$.data.websites[*]"
	}

	JSONListModel {
		id: ipAddressesModel
		query: "$.data.previous_ips[*]"
	}

	Label {
		id: titleLabel

		anchors {
			left: parent.left
			leftMargin: dp(15)
		}

		height: dp(50)
		verticalAlignment: Text.AlignVCenter

		wrapMode: Text.Wrap
		text: "Settings"
		style: "title"
		color: Theme.accentColor
	}

	Item {
		width: main.width < dp(900) ? main.width - dp(100) : dp(600)
		height: main.width < dp(450) ? main.width - dp(100) : dp(300)

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
				text: "Network"
				visible: advmode
				selected: tabView.currentIndex === 1

				onClicked: tabView.currentIndex = 1
			}

			ListItem.Standard {
				text: "Hidden Service"
				visible: advmode
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
				Column {
					anchors.fill: parent

					ListItem.Subtitled {
						text: "Start Emoty on system start"

						height: dp(48)
						interactive: false

						secondaryItem: Switch {
							id: switch2
							anchors.verticalCenter: parent.verticalCenter
							enabled: false
						}
					}

					ListItem.Subtitled {
						text: "Scrollable desktop"
						height: dp(48)

						secondaryItem: Switch {
							id: switch4

							anchors.verticalCenter: parent.verticalCenter
							checked: scrollingDialog.flickablemode

							onClicked: {
								scrollingDialog.flickablemode = switch4.checked
								switch4.checked = Qt.binding(function() {
									return scrollingDialog.flickablemode
								})
							}
						}

						onClicked: {
							switch4.checked = !switch4.checked
							scrollingDialog.flickablemode = switch4.checked
							switch4.checked = Qt.binding(function() {
								return scrollingDialog.flickablemode
							})
						}
					}

					ListItem.Subtitled {
						text: "Advanced mode"
						height: dp(48)
						secondaryItem: Switch {
							id: switch3

							anchors.verticalCenter: parent.verticalCenter
							checked: scrollingDialog.advmode

							onClicked: {
								scrollingDialog.advmode = switch3.checked
								switch3.checked = Qt.binding(function() {
									return scrollingDialog.advmode
								})
							}
						}

						onClicked: {
							switch3.checked = !switch3.checked
							scrollingDialog.advmode = switch3.checked
							switch3.checked = Qt.binding(function() {
								return scrollingDialog.advmode
							})
						}
					}

					Rectangle {
						height: dp(48)
						width: parent.width
						clip: false

						color: mA.containsMouse ? Qt.rgba(0,0,0,0.03) : Qt.rgba(0,0,0,0)

						MouseArea {
							id: mA
							anchors.fill: parent

							hoverEnabled: Device.hoverEnabled
						}

						Label {
							anchors {
								left: parent.left
								top: parent.top
								bottom: parent.bottom
								margins: dp(16)
							}

							text: "Approximation size"
							elide: Text.ElideRight
							style: "subheading"
							color: Theme.light.textColor
						}

						Slider {
							id: slider

							anchors {
								right: parent.right
								bottom: parent.bottom
								rightMargin: dp(16)
								bottomMargin: parent.height/2-dp(8)
							}

							height: parent.height

							value: approximationSize*100

							numericValueLabel: true
							stepSize: 10
							minimumValue: 10
							maximumValue: 200
							knobLabel: value + "%"
							knobDiameter: dp(35)

							Behavior on knobLabel{
								ScriptAction {
									script: {
										approximationSize = slider.value/100
									}
								}
							}
						}
					}
				}
			}

			QtControls.Tab {
				title: "Network"

				Flickable {
					id: flick
					anchors.fill: parent

					clip: true
					contentHeight: networkColumn.height

					pressDelay: 1000

					Column {
						id: networkColumn
						width: parent.width

						ListItem.Subtitled {
							text: "Network mode"

							height: dp(48)
							interactive: false

							secondaryItem: MenuField {
								id: networkModeSelection
								z: 2
								model: ["Public: DHT & Discovery", "Private: Discovery Only", "Inverted: DHT Only", "DarkNet: None"]
								width: dp(200)

								selectedIndex: networkMode

								onItemSelected: networkMode = index
							}
						}

						ListItem.Subtitled {
							text: "NAT"

							height: dp(48)
							interactive: false

							secondaryItem: MenuField {
								id: natSelection
								z: 2
								model: ["Automatic - UPNP", "Firewalled", "Manually Forwarded Port"]
								width: dp(200)

								selectedIndex: natMode

								onItemSelected: natMode = index
							}
						}

						ListItem.Subtitled {
							text: "Local address"

							height: dp(48)
							interactive: false

							secondaryItem: TextField {
								id: localAddressTF
								anchors.verticalCenter: parent.verticalCenter
								width: dp(100)

								horizontalAlignment: TextInput.AlignRight
								validator: IntValidator {bottom: 0}
								text: localAddress
								readOnly: natMode == 0

								font.pixelSize: dp(14)
								placeholderPixelSize: dp(14)

								onTextChanged: localAddress = parseInt(localAddressTF.text)
							}
						}

						ListItem.Subtitled {
							text: "Local port"

							height: dp(48)
							interactive: false

							secondaryItem: TextField {
								id: localPortTF
								anchors.verticalCenter: parent.verticalCenter
								width: dp(100)

								horizontalAlignment: TextInput.AlignRight
								validator: IntValidator {bottom: 0}
								text: localPort
								readOnly: natMode == 0

								font.pixelSize: dp(14)
								placeholderPixelSize: dp(14)

								onTextChanged: localPort = parseInt(localPortTF.text)
							}
						}

						ListItem.Subtitled {
							text: "External address"

							height: dp(48)
							interactive: false

							secondaryItem: TextField {
								id: externalAddressTF
								anchors.verticalCenter: parent.verticalCenter
								width: dp(100)

								horizontalAlignment: TextInput.AlignRight
								validator: IntValidator {bottom: 0}
								text: extAddress
								readOnly: natMode == 0

								font.pixelSize: dp(14)
								placeholderPixelSize: dp(14)

								onTextChanged: extAddress = parseInt(externalAddressTF.text)
							}
						}

						ListItem.Subtitled {
							text: "External port"

							height: dp(48)
							interactive: false

							secondaryItem: TextField {
								id: externalPortTF
								anchors.verticalCenter: parent.verticalCenter
								width: dp(100)

								horizontalAlignment: TextInput.AlignRight
								validator: IntValidator {bottom: 0}
								text: extPort
								readOnly: natMode == 0

								font.pixelSize: dp(14)
								placeholderPixelSize: dp(14)

								onTextChanged: extPort = parseInt(externalPortTF.text)
							}
						}

						ListItem.Subtitled {
							text: "Dynamic DNS"

							height: dp(48)
							interactive: false

							secondaryItem: TextField {
								id: dynamicDNSTF
								anchors.verticalCenter: parent.verticalCenter
								width: dp(100)

								horizontalAlignment: TextInput.AlignRight
								validator: IntValidator {bottom: 0}
								text: dynDNS

								font.pixelSize: dp(14)
								placeholderPixelSize: dp(14)

								onTextChanged: dynDNS = parseInt(dynamicDNSTF.text)
							}
						}

						ListItem.Subtitled {
							text: "Download limit (kB/s)"

							height: dp(48)
							interactive: false

							secondaryItem: TextField {
								id: downloadLimitTF
								anchors.verticalCenter: parent.verticalCenter
								width: dp(100)

								horizontalAlignment: TextInput.AlignRight
								validator: IntValidator {bottom: 0}
								text: downloadLimit

								font.pixelSize: dp(14)
								placeholderPixelSize: dp(14)

								onTextChanged: downloadLimit = parseInt(downloadLimitTF.text)
							}
						}

						ListItem.Subtitled {
							text: "Upload limit (kB/s)"

							height: dp(48)
							interactive: false

							secondaryItem: TextField {
								id: uploadLimitTF
								anchors.verticalCenter: parent.verticalCenter
								width: dp(100)

								horizontalAlignment: TextInput.AlignRight
								validator: IntValidator {bottom: 0}
								text: uploadLimit

								font.pixelSize: dp(14)
								placeholderPixelSize: dp(14)

								onTextChanged: uploadLimit = parseInt(uploadLimitTF.text)
							}
						}

						ListItem.Subtitled {
							text: "Check your IP on these websites:"
							height: dp(48)
							secondaryItem: Switch {
								id: checkingIPSwitch

								anchors.verticalCenter: parent.verticalCenter
								checked: checkIP

								onClicked: {
									scrollingDialog.checkIP = checkingIPSwitch.checked
									checkingIPSwitch.checked = Qt.binding(function() {
										return scrollingDialog.checkIP
									})
								}
							}

							onClicked: {
								checkingIPSwitch.checked = !checkingIPSwitch.checked
								scrollingDialog.checkIP = checkingIPSwitch.checked
								checkingIPSwitch.checked = Qt.binding(function() {
									return scrollingDialog.checkIP
								})
							}
						}

						Repeater {
							model: websitesModel.model
							delegate: ListItem.Standard {
								height: dp(36)
								interactive: false
								text: model.website
							}
						}

						ListItem.Subtitled {
							text: "Known/Previous IPs:"
							height: dp(48)
						}

						Repeater {
							model: ipAddressesModel.model
							delegate: ListItem.Standard {
								height: dp(36)
								interactive: false
								text: model.ip_address
							}
						}
					}
				}
			}

			QtControls.Tab {
				title: "Hidden Service"
				Column {
					anchors.fill: parent

					Connections {
						target: scrollingDialog

						onOpened: {
							torProxyTF.text = Qt.binding(function() {
								return torAddress
							})

							torPortTF.text = Qt.binding(function() {
								return torPort
							})

							i2pProxyTF.text = Qt.binding(function() {
								return i2pAddress
							})

							i2pPortTF.text = Qt.binding(function() {
								return i2pPort
							})
						}
					}

					ListItem.Subtitled {
						text: "Tor Socks Proxy Address"

						height: dp(48)
						interactive: false

						secondaryItem: TextField {
							id: torProxyTF
							anchors.verticalCenter: parent.verticalCenter

							text: torAddress

							font.pixelSize: dp(14)
							placeholderPixelSize: dp(14)

							horizontalAlignment: TextInput.AlignRight

							onTextChanged: torAddress = torProxyTF.text
						}
					}

					ListItem.Subtitled {
						text: "Tor Socks Proxy Port"

						height: dp(48)
						interactive: false

						secondaryItem: TextField {
							id: torPortTF
							anchors.verticalCenter: parent.verticalCenter

							validator: IntValidator {bottom: 0}
							text: torPort

							font.pixelSize: dp(14)
							placeholderPixelSize: dp(14)

							horizontalAlignment: TextInput.AlignRight

							onTextChanged: torPort = parseInt(torPortTF.text)
						}
					}

					ListItem.Subtitled {
						text: "I2P Socks Proxy Address"

						height: dp(48)
						interactive: false

						secondaryItem: TextField {
							id: i2pProxyTF
							anchors.verticalCenter: parent.verticalCenter

							text: i2pAddress

							font.pixelSize: dp(14)
							placeholderPixelSize: dp(14)

							horizontalAlignment: TextInput.AlignRight

							onTextChanged: i2pAddress = i2pProxyTF.text
						}
					}

					ListItem.Subtitled {
						text: "I2P Socks Proxy Port"

						height: dp(48)
						interactive: false

						secondaryItem: TextField {
							id: i2pPortTF
							anchors.verticalCenter: parent.verticalCenter

							validator: IntValidator {bottom: 0}
							text: i2pPort

							font.pixelSize: dp(14)
							placeholderPixelSize: dp(14)

							horizontalAlignment: TextInput.AlignRight

							onTextChanged: i2pPort = parseInt(i2pPortTF.text)
						}
					}

				}
			}
		}
	}
}
