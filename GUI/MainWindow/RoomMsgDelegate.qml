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

Component {
	Item {
		property string avatar: "avatar.png"

		width: parent.width
		height: model.incoming ? view.height + dp(15) + label.height : view.height + dp(15)

		Component.onCompleted: getIdentityAvatar()

		function getIdentityAvatar() {
			var jsonData = {
				gxs_id: model.author_id
			}

			function callbackFn(par) {
				var json = JSON.parse(par.response)
				if(json.data.avatar.length > 0)
					avatar = "data:image/png;base64," + json.data.avatar

				if(json.returncode == "fail")
					getIdentityAvatar()
			}

			rsApi.request("/identity/get_avatar", JSON.stringify(jsonData), callbackFn)
		}

		Canvas {
			id: image

			anchors {
				left: parent.left
				bottom: view.bottom
			}

			width: dp(32)
			height: dp(32)

			visible: model.incoming
			enabled: model.incoming

			Component.onCompleted:loadImage(avatar)
			onPaint: {
				var ctx = getContext("2d");
				if (image.isImageLoaded(avatar)) {
					var profile = Qt.createQmlObject('
                        import QtQuick 2.5;
                        Image{
                            source: avatar;
                            visible:false;
                            fillMode: Image.PreserveAspectCrop
                        }', image);

					var centreX = width/2;
					var centreY = height/2;

					ctx.save()
					ctx.beginPath();
					ctx.moveTo(centreX, centreY);
					ctx.arc(centreX, centreY, width / 2, 0, Math.PI * 2, false);
					ctx.clip();
					ctx.drawImage(profile, 0, 0, image.width, image.height);
					ctx.restore()
				}
			}
			onImageLoaded:requestPaint()
		}

		Label {
			id: label
			anchors {
				top: parent.top
				left: image.right
				leftMargin: parent.width*0.03 + dp(10)
			}

			visible: model.incoming
			enabled: model.incoming

			style: "caption"
			text: model.author_name

			color: Theme.light.subTextColor
		}

		View {
			id: view

			anchors {
				top: model.incoming ? label.bottom : undefined
				right: model.incoming === false ? parent.right : undefined
				left: model.incoming === false ?  undefined : image.right
				rightMargin: parent.width*0.03
				leftMargin: parent.width*0.03
				topMargin: dp(3)
			}

			height: textMsg.implicitHeight + dp(12)
			width: (textMsg.implicitWidth + dp(20)) > (parent.width*0.8)
				    ? (parent.width*0.8)
					: textMsg.implicitWidth + dp(20)

			backgroundColor: model.incoming === false ? Theme.primaryColor : "white"
			elevation: 1
			radius: 10

			TextEdit {
				id: textMsg

				anchors {
					top: parent.top
					topMargin: dp(6)
					left: parent.left
					right: parent.right
				}

				text: model.msg
				textFormat: Text.RichText
				wrapMode: Text.WordWrap

				color: model.incoming === false ? "white" : Theme.light.textColor
				readOnly: true

				selectByMouse: true
				selectionColor: Theme.accentColor

				horizontalAlignment: TextEdit.AlignHCenter

				font {
					family: "Roboto"
					pixelSize: dp(13)
				}
			}
		}
	}
}
