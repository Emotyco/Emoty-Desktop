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
//import QtQuick.Dialogs 1.0

import Material 0.3

PopupBase {
	id: dialog

	property string src: "avatar.png";
	property bool enableHiding: false

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

	globalMouseAreaEnabled: mask.visible ? false : enableHiding

	Behavior on opacity {
		NumberAnimation { duration: 200 }
	}

	Behavior on src {
		ScriptAction {
			script: {
				canvas.loadImage(dialog.src)
				canvas.requestPaint()
			}
		}
	}

	function show() {
		open()
	}

	function createIdentity(name) {
		var isNotAnonymous = main.advmode ? !checkBox.checked : true

		var jsonData = {
			name: name,
			pgp_linked: isNotAnonymous
		}

		function callbackFn(par) {
			if(JSON.parse(par.response).data.name === name) {
				dialog.close()
			}
		}

		rsApi.request("/identity/create_identity", JSON.stringify(jsonData), callbackFn)
	}

	MouseArea {
		anchors.fill: parent

		enabled: !enableHiding
		onClicked: {}
	}

	View {
		id: dialogContainer

		anchors {
			centerIn: parent
		}

		width: dp(350)
		height: main.advmode ? dp(430) : dp(400)

		elevation: 5
		radius: dp(2)
		backgroundColor: "white"
		clip: true

		MouseArea {
			anchors.fill: parent
			onClicked: {}
		}

		Rectangle {
			id: mask

			anchors.fill: parent

			enabled: false
			visible: false

			color: Qt.rgba(255,255,255,0.8)
			z: 5

			Behavior on visible {
				NumberAnimation {
					target: mask
					property: "opacity"
					from: 0
					to: 1
					duration: MaterialAnimation.pageTransitionDuration
				}
			}

			MouseArea {
				anchors.fill: parent

				hoverEnabled: true

				onClicked: {}
				onEntered: {}
				onExited: {}
			}

			ProgressCircle {
				id: progressCircle

				anchors.centerIn: parent

				width: dp(48)
				height: dp(48)

				color: Theme.accentColor

				dashThickness: dp(7)
			}
		}

		Canvas {
			id: canvas

			anchors {
				top: parent.top
				topMargin: parent.height*0.1
				horizontalCenter: parent.horizontalCenter
			}

			width: parent.width < parent.height ? parent.width*0.63 : parent.height*0.63
			height: parent.width < parent.height ? parent.width*0.63 : parent.height*0.63

			Component.onCompleted: loadImage(dialog.src)

			onPaint: {
				var ctx = getContext("2d");
				if (canvas.isImageLoaded(dialog.src)) {
					var profile = Qt.createQmlObject('import QtQuick 2.5; Image{source: dialog.src;  visible:false}', canvas);
					var centreX = width/2;
					var centreY = height/2;

					ctx.save();
					    ctx.beginPath();
					        ctx.arc(centreX, centreY, width / 2, 0, Math.PI*2, true);
					    ctx.closePath();
					    ctx.clip();
					    ctx.drawImage(profile, 0, 0, canvas.width, canvas.height);
					ctx.restore();

				}
			}

			onImageLoaded:requestPaint()

			Ink {
				id: circleInk

				anchors.fill: parent
				circular:true

				Rectangle {
					anchors.fill: parent

					color: "black"

					opacity: circleInk.containsMouse ? 0.1 : 0
					radius: width/2
				}
				Icon {
					anchors.centerIn: parent

					name: "awesome/upload"
					color: "white"

					size: parent.width/3
					opacity: circleInk.containsMouse ? 0.9 : 0
				}
/*
				FileDialog {
					id: fileDialog
					title: "Please choose an avatar"
					folder: shortcuts.pictures
					selectMultiple: false
					onAccepted: {
						dialog.src = fileDialog.fileUrl
						canvas.loadImage(dialog.src)
					}
				}
				onClicked: fileDialog.open()*/
			}
		}

		TextField {
			id: name

			property bool emptyName: false

			anchors {
				top: canvas.bottom
				topMargin: dp(30)
				horizontalCenter: parent.horizontalCenter
			}

			width: parent.width < parent.height ? parent.width*0.63 : parent.height*0.63

			color: Theme.primaryColor

			horizontalAlignment: TextInput.AlignHCenter
			focus: true

			placeholderHorizontalCenter: true
			placeholderText: "Joe Smith"
			placeholderPixelSize: dp(18)

			font {
				family: "Roboto"
				pixelSize: dp(18)
				capitalization: Font.MixedCase
			}

			helperText: emptyName ?  "Name is too short" : ""
			hasError: emptyName

			onAccepted: {
				if(name.text.length > 3) {
					mask.enabled = true
					mask.visible = true
					createIdentity(name.text)
				}
				else if(name.text.length < 3)
					name.emptyName = true
			}
		}

		Item {
			anchors {
				top: name.bottom
				topMargin: name.emptyName ? dp(5) : 0
				horizontalCenter: parent.horizontalCenter
			}

			height: dp(50)
			width: parent.width*0.63

			visible: main.advmode
			enabled: main.advmode
			clip: true

			CheckBox {
				id: checkBox
				anchors {
					left: parent.left
					verticalCenter: parent.verticalCenter
					leftMargin: -dp(15)
				}

				darkBackground: false
			}

			Label {
				anchors {
					left: checkBox.right
					verticalCenter: parent.verticalCenter
				}

				text: "Anonymous"
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

		Button {
			id: positiveButton

			text: "CREATE IDENTITY"
			textColor: Theme.accentColor

			context: "dialog"
			size: dp(15)

			anchors {
				horizontalCenter: parent.horizontalCenter
				bottomMargin: dp(25)
				bottom: parent.bottom
			}

			onClicked: {
				if(name.text.length > 3) {
					mask.enabled = true
					mask.visible = true
					createIdentity(name.text)
				}
				else if(name.text.length < 3)
					name.emptyName = true
			}
		}
	}
}
