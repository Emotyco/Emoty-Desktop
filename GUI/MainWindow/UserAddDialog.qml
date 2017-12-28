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
import QtQuick.Controls 2.3

import Material 0.3 as Material

Material.Dialog {
	property string myKey

	positiveButtonText: "Cancel"
	negativeButtonText: "Add"

	positiveButtonSize: dp(13)
	negativeButtonSize: dp(13)

	onRejected: {
		if(friendCert.text != "")
		{
			var jsonData = {
				cert_string: friendCert.text,
				flags: {
					allow_direct_download: true,
					allow_push: false,
					require_whitelist: false
				}
			}

			rsApi.request("PUT /peers", JSON.stringify(jsonData), function(){})
		}
	}

	Behavior on opacity {
		NumberAnimation {
			easing.type: Easing.InOutQuad
			duration: 200
		}
	}

	Component.onCompleted: getSelfCert()

	function getSelfCert() {
		function callbackFn(par) {
			myKey = JSON.parse(par.response).data.cert_string
		}

		rsApi.request("/peers/self/certificate/", "", callbackFn)
	}

	Material.Label {
		anchors.left: parent.left

		height: dp(50)
		verticalAlignment: Text.AlignVCenter

		wrapMode: Text.Wrap
		text: "Add Friend"
		style: "title"
		color: Material.Theme.accentColor
	}

	Grid {
		width: mainGUIObject.width < dp(800) ? mainGUIObject.width - dp(100) : dp(750)
		height: mainGUIObject.width < dp(400) ? mainGUIObject.width - dp(100) : dp(300)
		spacing: dp(8)

		Item {
			width: parent.width/2
			height: parent.height

			Text {
				anchors {
					left: parent.left
					right: parent.right
				}

				height: dp(35)

				text: "It's your certificate. Share it with friends."
				textFormat: Text.PlainText
				wrapMode: Text.WordWrap
				color: Material.Theme.light.textColor

				font {
					family: "Roboto"
					pixelSize: dp(16)
				}
			}

			ScrollView {
				anchors {
					fill: parent
					topMargin: dp(35)
				}

				TextArea {
					text: myKey.replace(/(\r\n|\n|\r)/gm,"")
					textFormat: Text.PlainText
					wrapMode: Text.WrapAnywhere
					font.pixelSize: dp(12)
					font.family: "Roboto"

					readOnly: true
					selectedTextColor: "white"
					selectionColor: Material.Theme.accentColor
					selectByMouse: true
					selectByKeyboard: true
				}
			}
		}

		Item {
			width: parent.width/2
			height: parent.height

			Text {
				anchors {
					left: parent.left
					right: parent.right
				}

				height: dp(35)

				text: "Paste your friend's certificate here:"
				textFormat: Text.PlainText
				wrapMode: Text.WordWrap
				color: Material.Theme.light.textColor

				font {
					family: "Roboto"
					pixelSize: dp(16)
				}
			}

			ScrollView {
				id: scrollView
				anchors {
					fill: parent
					topMargin: dp(35)
				}

				contentHeight: friendCert.height

				TextArea {
					id: friendCert

					textFormat: Text.PlainText
					wrapMode: Text.WrapAnywhere
					font.pixelSize: dp(12)
					font.family: "Roboto"

					onTextChanged: friendCert.text = friendCert.text.replace(/(\r\n|\n|\r)/gm,"")

					selectedTextColor: "white"
					selectionColor: Material.Theme.accentColor
					selectByMouse: true
					focus: true

					background: TextArea {
						anchors.fill: parent
						text: myKey.replace(/(\r\n|\n|\r)/gm,"")
						textFormat: Text.PlainText
						wrapMode: Text.WrapAnywhere
						font.pixelSize: dp(12)
						font.family: "Roboto"
						readOnly: true
						focus: false
						color: "#a0a1a2"

						visible: friendCert.text.length == 0
					}
				}
			}
		}
	}
}
