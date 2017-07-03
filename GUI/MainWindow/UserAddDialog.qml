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
import Material 0.3
import Material.Extras 0.1

Dialog {
	property string myKey

	positiveButtonText: "Cancel"
	negativeButtonText: "Add"

	positiveButtonSize: dp(13)
	negativeButtonSize: dp(13)

	onRejected: {
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

	Label {
		anchors.left: parent.left

		height: dp(50)
		verticalAlignment: Text.AlignVCenter

		wrapMode: Text.Wrap
		text: "Add Friend"
		style: "title"
		color: Theme.accentColor
	}

	Grid {
		width: main.width < dp(800) ? main.width - dp(100) : dp(700)
		height: main.width < dp(300) ? main.width - dp(100) : dp(300)
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
				color: Theme.light.textColor

				font {
					family: "Roboto"
					pixelSize: dp(16)
				}
			}

			TextArea {
				anchors {
					fill: parent
					topMargin: dp(35)
				}

				text: myKey.replace(/(\r\n|\n|\r)/gm,"")
				textFormat: Text.PlainText
				wrapMode: Text.WrapAnywhere
				font.pixelSize: dp(12)
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

				text: "Paste your friend's certificate here"
				textFormat: Text.PlainText
				wrapMode: Text.WordWrap

				font {
					family: "Roboto"
					pixelSize: dp(16)
				}
			}

			TextArea {
				id: friendCert

				anchors {
					fill: parent
					topMargin: dp(35)
				}

				placeholderText: myKey.replace(/(\r\n|\n|\r)/gm,"")
				textFormat: Text.PlainText
				wrapMode: Text.WrapAnywhere
				font.pixelSize: dp(12)
			}
		}
	}
}
