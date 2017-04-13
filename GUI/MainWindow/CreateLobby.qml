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
import QtQuick.Layouts 1.1

import Material 0.3

PopupBase {
	id: dialog

	property bool isPrivate

	anchors {
		centerIn: parent
		verticalCenterOffset: showing ? 0 : -(dialog.height/3)

		Behavior on verticalCenterOffset {
			NumberAnimation { duration: 200 }
		}
	}

	overlayLayer: "dialogOverlayLayer"
	overlayColor: Qt.rgba(0, 0, 0, 0.3)

	opacity: showing ? 1 : 0
	visible: opacity > 0

	width: main.width
	height: main.height

	globalMouseAreaEnabled: true

	Behavior on opacity {
		NumberAnimation { duration: 200 }
	}

	function show() {
		open()
	}

	View {
		id: dialogContainer

		anchors {
			centerIn: parent
		}

		width: dp(350)
		height: main.advmode ? dp(165) : dp(130)

		elevation: 5
		radius: dp(2)
		backgroundColor: "white"

		MouseArea {
			anchors.fill: parent
			onClicked: {}
		}

		TextField {
			id: name

			anchors {
				top: parent.top
				topMargin: dp(30)
				horizontalCenter: parent.horizontalCenter
			}

			width: parent.width*0.67

			color: Theme.primaryColor

			horizontalAlignment: TextInput.AlignHCenter

			placeholderHorizontalCenter: true
			placeholderText: "Room name"
			placeholderPixelSize: dp(18)

			font {
				family: "Roboto"
				pixelSize: dp(18)
				capitalization: Font.MixedCase
			}

			onAccepted: {
				var jsonData = {
					lobby_name: name.text,
					gxs_id: main.defaultGxsId,
					lobby_public: !isPrivate,
					pgp_signed: main.advmode ? checkBox.checked : true
				}

				rsApi.request("/chat/create_lobby", JSON.stringify(jsonData))

				dialog.close()
			}
		}

		Item {
			anchors {
				top: name.bottom
				horizontalCenter: parent.horizontalCenter
			}

			height: dp(50)
			width: parent.width*0.67

			visible: main.advmode
			enabled: main.advmode
			clip: true

			RowLayout {
				anchors {
					fill: parent
					leftMargin: -dp(15)
				}

				spacing: 0

				CheckBox {
					id: checkBox
					darkBackground: false
				}

				Label {
					text: "Require identities to be PGP-signed"
					color: Theme.light.textColor

					MouseArea{
						anchors.fill: parent

						onClicked: {
						  checkBox.checked = !checkBox.checked
						  checkBox.clicked()
						}
					}
				}
			}
		}

		Button {
			id: positiveButton

			text: isPrivate ? "CREATE PRIVATE ROOM" : "CREATE PUBLIC ROOM"
			textColor: Theme.accentColor

			context: "dialog"
			size: dp(15)

			anchors {
				horizontalCenter: parent.horizontalCenter
				bottomMargin: dp(25)
				bottom: parent.bottom
			}

			onClicked: {
				var jsonData = {
					lobby_name: name.text,
					gxs_id: main.defaultGxsId,
					lobby_public: !isPrivate,
					pgp_signed: main.advmode ? checkBox.checked : true
				}

				rsApi.request("/chat/create_lobby", JSON.stringify(jsonData))

				dialog.close()
			}
		}
	}
}
