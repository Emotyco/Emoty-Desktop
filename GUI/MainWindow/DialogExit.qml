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

import QtQuick 2.4
import QtQuick.Layouts 1.1

import Material 0.3
import Material.Extras 0.1

PopupBase {
	id: dialog

	property int contentMargins: 24 * Units.dp

	property int minimumWidth: Device.isMobile ? 200 * Units.dp : 250 * Units.dp

	property alias title: titleLabel.text
	property alias text: textLabel.text

	property alias positiveButtonEnabled: positiveButton.enabled
	property alias negativeButton: negativeButton
	property alias positiveButton: positiveButton

	property string negativeButtonText: "Cancel"
	property string positiveButtonText: "Ok"

	property bool hasActions: true
	property bool floatingActions: false

	default property alias dialogContent: column.data

	property bool autoLogin: false

	signal accepted()
	signal rejected()

	anchors {
		centerIn: parent
		verticalCenterOffset: showing ? 0 : -(dialog.height/3)

		Behavior on verticalCenterOffset {
			NumberAnimation { easing.type: Easing.InOutQuad; duration: 200 }
		}
	}

	overlayLayer: "dialogOverlayLayer"
	overlayColor: Qt.rgba(0, 0, 0, 0.3)

	opacity: showing ? 1 : 0
	visible: opacity > 0

	width: Math.max(minimumWidth,
					content.contentWidth + 2 * contentMargins)

	height: Math.min(parent.height - 64 * Units.dp,
					 headerView.height +
					 content.contentHeight +
					 (floatingActions ? 0 : buttonContainer.height))

	Behavior on opacity {
		NumberAnimation { easing.type: Easing.InOutQuad; duration: 200 }
	}

	Keys.onPressed: {
		if (event.key === Qt.Key_Escape) {
			closeKeyPressed(event)
		}
	}

	Keys.onReleased: {
		if (event.key === Qt.Key_Back) {
			closeKeyPressed(event)
		}
	}

	function closeKeyPressed(event) {
		if (dialog.showing) {
			if (dialog.dismissOnTap) {
				dialog.close()
			}
			event.accepted = true
		}
	}

	function show() {
		open()
	}

	Component.onCompleted: {
		getAutoLogin()
	}

	function getAutoLogin() {
		function callbackFn(par) {
			dialog.autoLogin = Boolean(JSON.parse(par.response).data.auto_login)
		}

		rsApi.request("/settings/get_auto_login/", "", callbackFn)
	}

	View {
		id: dialogContainer

		anchors.fill: parent

		z: 2
		elevation: 5
		radius: dp(2)
		backgroundColor: "white"

		MouseArea {
			anchors.fill: parent
			propagateComposedEvents: false

			onClicked: {
				mouse.accepted = false
			}
		}

		Rectangle {
			anchors.fill: content
		}

		Flickable {
			id: content

			anchors {
				left: parent.left
				right: parent.right
				top: headerView.bottom
				bottom: floatingActions ? parent.bottom : buttonContainer.top
			}

			contentWidth: column.implicitWidth
			contentHeight: column.height + (column.height > 0 ? contentMargins : 0)

			clip: true
			interactive: contentHeight > height

			onContentXChanged: {
				if(contentX != 0 && contentWidth <= width)
					contentX = 0
			}

			onContentYChanged: {
				if(contentY != 0 && contentHeight <= height)
					contentY = 0
			}

			Column {
				id: column

				anchors {
					left: parent.left
					leftMargin: contentMargins
				}

				width: content.width - 2 * contentMargins
				spacing: 8 * Units.dp
			}
		}

		Scrollbar {
			flickableItem: content
		}

		Item {
			anchors {
				left: parent.left
				right: parent.right
				top: parent.top
			}

			height: headerView.height

			View {
				anchors {
					left: parent.left
					right: parent.right
					top: parent.top
				}

				backgroundColor: "white"
				elevation: content.atYBeginning ? 0 : 1
				fullWidth: true
				radius: dialogContainer.radius

				height: parent.height
			}
		}


		Column {
			id: headerView

			anchors {
				left: parent.left
				right: parent.right
				top: parent.top

				leftMargin: contentMargins
				rightMargin: contentMargins
			}

			spacing: 0

			Item {
				width: parent.width
				height: contentMargins

				visible: titleLabel.visible || textLabel.visible
			}

			Label {
				id: titleLabel

				width: parent.width
				wrapMode: Text.Wrap
				style: "title"
				visible: title != ""
			}

			Item {
				width: parent.width
				height: dp(20)

				visible: titleLabel.visible
			}

			Label {
				id: textLabel

				horizontalAlignment: Text.AlignHCenter
				width: parent.width
				wrapMode: Text.Wrap
				style: "dialog"
				color: Theme.light.subTextColor
				visible: text != ""
			}

			Item {
				height: dp(5)
				width: parent.width

				z: 2
				visible: dialog.autoLogin

				RowLayout {
					anchors {
						left: parent.left
						leftMargin: dp(9)
					}

					y: -dp(7)
					spacing: -dp(10)

					CheckBox {
						id: checkBox
						darkBackground: false
						checked: dialog.autoLogin

						onClicked: {
							var jsonData = {
								auto_login: checkBox.checked,
							}
							rsApi.request("/settings/set_auto_login/", JSON.stringify(jsonData), function(){})
						}
					}

					Label {
						text: "Automatically log in"
						color: Theme.light.subTextColor

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

			Item {
				width: parent.width
				height: dialog.autoLogin ? contentMargins+dp(10) : contentMargins/2

				visible: textLabel.visible
			}
		}

		Item {
			id: buttonContainer

			anchors {
				bottom: parent.bottom
				right: parent.right
				left: parent.left
			}

			height: hasActions ? (dialog.autoLogin ? 42 * Units.dp : 52 * Units.dp)
							   : 2 * Units.dp

			View {
				id: buttonView

				anchors {
					bottom: parent.bottom
					right: parent.right
					left: parent.left
				}

				height: parent.height
				fullWidth: true

				backgroundColor: floatingActions ? "transparent" : "white"
				radius: dialogContainer.radius

				elevationInverted: true
				elevation: content.atYEnd ? 0 : 1

				Button {
					id: negativeButton

					anchors {
						verticalCenter: dialog.autoLogin ? undefined : parent.verticalCenter
						top: dialog.autoLogin ? parent.top : undefined
						left: positiveButton.visible ? positiveButton.right : parent.left
						leftMargin: 4 * Units.dp
						rightMargin: 8 * Units.dp
						right: parent.right
					}

					visible: hasActions
					text: negativeButtonText
					textColor: Theme.accentColor
					context: "dialog"
					size: dp(13)

					onClicked: {
						close();
						rejected();
					}
				}

				Button {
					id: positiveButton

					anchors {
						verticalCenter: dialog.autoLogin ? undefined : parent.verticalCenter
						top: dialog.autoLogin ? parent.top : undefined
						right: parent.horizontalCenter
						rightMargin: 4 * Units.dp
						leftMargin: 8 * Units.dp
						left: parent.left
					}

					visible: hasActions
					text: positiveButtonText
					textColor: Theme.accentColor
					context: "dialog"
					size: dp(13)

					onClicked: {
						close()
						accepted();
					}
				}
			}
		}
	}
}
