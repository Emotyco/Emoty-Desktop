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
		property string avatar: (gxs_avatars.getAvatar(model.author_id) == "none"
								 || gxs_avatars.getAvatar(model.author_id) == "")
								? "none"
								: gxs_avatars.getAvatar(model.author_id)

		onAvatarChanged: {
			image.loadImage(avatar)
		}

		property bool previous_author_same: model.author_id == author_id_previous

		width: parent.width
		height: model.incoming ?
					(previous_author_same ? view.height + dp(5) : view.height + dp(20) + label.height)
				  : (previous_author_same ? view.height + dp(5) : view.height + dp(20))

		Component.onCompleted: {
			if(gxs_avatars.getAvatar(model.author_id) == "" && model.incoming == true)
				getIdentityAvatar()
		}

		function getIdentityAvatar() {
			var jsonData = {
				gxs_id: model.author_id
			}

			function callbackFn(par) {
				var json = JSON.parse(par.response)
				if(json.returncode == "fail") {
					getIdentityAvatar()
					return
				}

				gxs_avatars.storeAvatar(model.author_id, json.data.avatar)
				if(gxs_avatars.getAvatar(model.author_id) != "none")
					avatar = gxs_avatars.getAvatar(model.author_id)
			}

			rsApi.request("/identity/get_avatar", JSON.stringify(jsonData), callbackFn)
		}

		Canvas {
			id: image

			anchors {
				left: parent.left
				bottom: view.bottom
			}

			width: dp(36)
			height: dp(36)

			visible: model.incoming && !previous_author_same && avatar != "none"
			enabled: model.incoming && !previous_author_same && avatar != "none"

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

		Icon {
			id: icon

			anchors {
				left: parent.left
				bottom: view.bottom
			}

			width: dp(36)
			height: dp(36)

			name: "awesome/user_o"
			visible: model.incoming && !previous_author_same && avatar == "none"
			color: Theme.light.iconColor

			size: dp(30)
		}

		Label {
			id: label
			anchors {
				left: image.right
				leftMargin: dp(24)
				topMargin: dp(5)
				bottom: view.top
				bottomMargin: dp(3)
			}

			visible: model.incoming && !previous_author_same
			enabled: model.incoming && !previous_author_same

			style: "caption"
			text: model.author_name

			color: Theme.light.subTextColor
		}

		View {
			id: view

			anchors {
				right: model.incoming === false ? parent.right : undefined
				left: model.incoming === false ?  undefined : image.right
				rightMargin: parent.width*0.03
				leftMargin: dp(17)
				bottom: parent.bottom
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
					leftMargin: dp(10)
					right: parent.right
					rightMargin: dp(10)
				}

				text: model.msg_content
				textFormat: Text.RichText
				wrapMode: Text.WordWrap

				color: model.incoming === false ? "white" : Theme.light.textColor
				readOnly: true

				selectByMouse: true
				selectionColor: Theme.accentColor

				horizontalAlignment: TextEdit.AlignLeft//AlignHCenter

				font {
					family: "Roboto"
					pixelSize: dp(13)
				}
			}
		}
	}
}
