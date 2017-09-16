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

import Material 0.3 as Material

Component {
	Item {
		width: parent.width
		height: dp(70)

		Material.View {
			anchors {
				fill: parent
				leftMargin: dp(10)
				rightMargin: dp(10)
			}

			elevation: 1
			radius: 10
			clipContent: true

			Rectangle {
				id: cancelMask
				anchors.fill: parent

				color: Qt.rgba(1,1,1,0.85)
				z: 20
				radius: 10

				state: "invisible"
				states:[
					State {
						name: "visible"
						PropertyChanges {
							target: cancelMask
							enabled: true
							opacity: 1
						}
					},
					State {
						name: "invisible"
						PropertyChanges {
							target: cancelMask
							enabled: false
							opacity: 0
						}
					}
				]

				transitions: [
					Transition {
						NumberAnimation {
							property: "opacity"
							easing.type: Easing.InOutQuad
							duration: 250*2
						}
					}
				]

				MouseArea {
					anchors.fill: parent

					hoverEnabled: true
					onClicked: {}
					onPressed: {}
				}
			}

			Material.Icon {
				id: fileIcon
				anchors {
					left: parent.left
					top: parent.top
					bottom: parent.bottom
				}

				width: fileIcon.height
				name: "awesome/file_o"

				size: dp(44)
				color: Material.Theme.light.iconColor
			}

			Item {
				id: contentLabels
				anchors {
					left: fileIcon.right
					right: model.is_download ?
							   pausePlayTransfer.left
							 : parent.right
					rightMargin: dp(25)
					top: parent.top
					bottom: parent.bottom
				}

				Material.Label {
					id: nameLabel
					anchors {
						left: parent.left
						right: parent.right
						top: parent.top
						topMargin: dp(12)
					}

					style: "body2"

					text: model.name
					color: Material.Theme.light.iconColor
				}

				Material.ProgressBar {
					id: progressBar
					anchors {
						left: parent.left
						right: parent.right
						top: nameLabel.bottom
						topMargin: dp(3)
					}

					minimumValue: 0
					maximumValue: 100
					value: parseInt(model.transferred/model.size*100)
				}

				Item {
					anchors {
						left: parent.left
						right: parent.right
						top: progressBar.bottom
						bottom: parent.bottom
						bottomMargin: dp(12)
					}

					Material.Icon {
						id: upDownIcon
						anchors {
							left: parent.left
							top: parent.top
							bottom: parent.bottom
						}

						name: model.is_download ?
								  "awesome/arrow_circle_down"
								: "awesome/arrow_circle_up"
						size: dp(16)
						color: Material.Theme.light.iconColor
					}

					Material.Label {
						id: trLabel
						anchors {
							left: upDownIcon.right
							leftMargin: dp(6)
							top: parent.top
							topMargin: dp(3)
							bottom: parent.bottom
						}

						font.weight: Font.DemiBold
						font.pixelSize: dp(12)

						text: model.download_status == "complete" ?
								  ( model.is_download ?
									   "Downloaded"
									 : "Uploaded")
								: ( model.download_status == "paused" ?
									   "0 KB/s"
									 : model.transfer_rate + " KB/s")
						color: Material.Theme.light.iconColor
					}

					Material.Label {
						anchors {
							left: trLabel.right
							leftMargin: dp(6)
							top: parent.top
							topMargin: dp(3)
							bottom: parent.bottom
						}

						font.weight: Font.DemiBold
						font.pixelSize: dp(12)

						text: "(" + model.transferred + " B/" + model.size + " B)"
						color: Material.Theme.light.iconColor
					}

					Material.Label {
						anchors {
							right: parent.right
							top: parent.top
							topMargin: dp(3)
							bottom: parent.bottom
						}

						font.weight: Font.DemiBold
						font.pixelSize: dp(12)

						text: parseInt(model.transferred/model.size*100) + "%"
						color: Material.Theme.light.iconColor
					}
				}
			}

			Material.IconButton {
				id: pausePlayTransfer

				anchors {
					right: cancelTransfer.left
					rightMargin: dp(25)
					top: parent.top
					bottom: parent.bottom
				}

				width: dp(16)

				iconName: model.download_status == "paused" ?
							  "awesome/play_circle_o"
							: "awesome/pause_circle_o"
				size: dp(32)

				visible: model.is_download
				enabled: model.is_download

				onClicked: {
					if(model.download_status == "paused") {
						var startData = {
							action: "start",
							id: model.hash
						}

						rsApi.request("/transfers/control_download/", JSON.stringify(startData), function(){})
					}
					else {
						var pauseData = {
							action: "pause",
							id: model.hash
						}

						rsApi.request("/transfers/control_download/", JSON.stringify(pauseData), function(){})
					}
				}

				onEntered: pausePlayTransfer.color = Material.Theme.primaryColor
				onExited:  pausePlayTransfer.color = Material.Theme.light.iconColor
			}

			Material.IconButton {
				id: cancelTransfer

				anchors {
					right: parent.right
					rightMargin: dp(30)
					top: parent.top
					bottom: parent.bottom
				}

				width: dp(16)

				iconName: "awesome/times_circle_o"
				size: dp(32)

				visible: model.is_download
				enabled: model.is_download

				onClicked: {
					cancelMask.state = "visible"
					var jsonData = {
						action: "cancel",
						id: model.hash
					}

					function callbackFn(par) {
						console.log(par.response)
					}

					rsApi.request("/transfers/control_download/", JSON.stringify(jsonData), callbackFn)
				}

				onEntered: cancelTransfer.color = Material.Theme.primaryColor
				onExited:  cancelTransfer.color = Material.Theme.light.iconColor
			}
		}
	}
}
