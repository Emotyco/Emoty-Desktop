import QtQuick 2.5
import QtQuick.Controls 1.4
import QtGraphicalEffects 1.0

import Material 0.3
import Material.Extras 0.1 as Circle
import Material.ListItems 0.1 as ListItem

Rectangle {
	color: "#f2f2f2"

	ListView {
		anchors.fill: parent

		header: Item {
			height: avatarRect.height + parent.width*0.1 + name.height
					+ parent.width*0.1 + header.height + parent.width*0.2
			width: parent.width

			Rectangle {
				id: avatarRect

				anchors {
					horizontalCenter: parent.horizontalCenter
					verticalCenter: parent.top
					verticalCenterOffset: parent.width*0.4
				}

				width: parent.width*0.6
				height: parent.width*0.6

				radius: width/2

				Canvas {
					id: canvas

					anchors.fill: parent

					Component.onCompleted:loadImage("avatar.png")
					onPaint: {
						var ctx = getContext("2d");
						if (canvas.isImageLoaded("avatar.png")) {
							var profile = Qt.createQmlObject('
                                import QtQuick 2.5;
                                Image{
                                    source: "avatar.png"
                                    visible:false
                                }', canvas);

							var centreX = width/2;
							var centreY = height/2;

							ctx.save()
							ctx.beginPath();
							ctx.moveTo(centreX, centreY);
							ctx.arc(centreX, centreY, width / 2, 0, Math.PI * 2, false);
							ctx.clip();
							ctx.drawImage(profile, 0, 0, canvas.width, canvas.height)
							ctx.restore()
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

						onClicked: overlayView.open(canvas)
					}
				}
			}

			DropShadow {
				anchors.fill: avatarRect

				verticalOffset: dp(2)
				radius: 6
				samples: 8

				color: "#80000000"
				source: avatarRect
			}

			Text {
				id: name

				anchors {
					top: avatarRect.bottom
					topMargin: parent.width*0.1
					horizontalCenter: parent.horizontalCenter
				}

				text: main.defaultGxsName
				color: Theme.light.textColor

				font {
					family: "Roboto"
					pixelSize: dp(17)
				}

				verticalAlignment: Text.AlignVCenter
				horizontalAlignment: Text.AlignHCenter
			}

			ListItem.Subheader {
				id: header

				anchors {
					top: name.bottom
					topMargin: parent.width*0.2
				}

				width: parent.width

				text: "Choose identity"
				textColor: Theme.primaryColor
			}
		}

		model: ownGxsIdModel.model
		delegate: ListItem.Standard {
			id: identityDelegate

			width: parent.width

			text: model.name
			textColor: selected ? Theme.primaryColor : Theme.light.textColor

			selected: main.defaultGxsId === model.own_gxs_id
			itemLabel.style: "body1"

			onClicked: {
				main.defaultGxsName = model.name
				main.defaultGxsId = model.own_gxs_id
			}

			MouseArea {
				anchors.fill: parent
				acceptedButtons: Qt.RightButton

				onClicked: overflowMenu.open(identityDelegate, mouse.x, mouse.y)
			}

			Dropdown {
				id: overflowMenu
				objectName: "overflowMenu"
				width: dp(200)
				height: main.advmode ? dp(2*30) : dp(1*30)
				enabled: true
				anchor: Item.TopLeft
				durationSlow: 300
				durationFast: 150

				Column{
					anchors.fill: parent

					ListItem.Standard {
						height: dp(30)
						enabled: main.advmode
						visible: main.advmode

						text: "Details"
						itemLabel.style: "menu"
						onClicked: {
							overflowMenu.close()

							identityDetailsDialog.showIdentity(model.name, model.own_gxs_id)

							leftBar.state = "narrow"
						}
					}

					ListItem.Standard {
						height: dp(30)
						text: "Delete"
						itemLabel.style: "menu"
						onClicked: {
							overflowMenu.close()

							removeDialog.show("Do you want to delete your identity?", function() {
								var jsonData = {
									gxs_id: model.own_gxs_id
								}

								rsApi.request("/identity/delete_identity", JSON.stringify(jsonData), function(){})
							})
						}
					}
				}
			}
		}

		footer: ListItem_Button {
			width: parent.width

			text: "Create identity"
			textColor: Theme.light.textColor

			itemLabel.style: "body1"
			iconName: "awesome/plus"

			onClicked: {
				leftBar.state = "narrow"
				var component = Qt.createComponent("CreateIdentity.qml");
				if (component.status === Component.Ready) {
					var createId = component.createObject(main);
					createId.enableHiding = true;
					createId.show();
				}
			}
		}
	}

	OverlayView {
		id: overlayView

		width: main.width < main.height ? (dp(700)+main.width*0.3 < main.width ? dp(700)
																			   : main.width*0.7)
										: (dp(700)+main.height*0.3 < main.height ? dp(700)
																				 : main.height*0.7)
		height: main.width < main.height ? (dp(700)+main.width*0.3 < main.width ? dp(700)
																				: main.width*0.7)
										 : (dp(700)+main.height*0.3 < main.height ? dp(700)
																				  : main.height*0.7)

		radiusOnStart: overlayView.width/2

		onOpened: contentImage.radius = 0
		onClosed: contentImage.radius = 150

		Circle.CircleImage {
			id: contentImage

			anchors.fill: parent

			source: Qt.resolvedUrl("avatar.png")
			fillMode: Image.PreserveAspectCrop

			Behavior on radius {
				NumberAnimation {
					duration: 300
					easing.type: Easing.InOutQuad
				}
			}

			IconButton {
				anchors {
					top: parent.top
					right: parent.right
					rightMargin: dp(16)
				}

				height: dp(60)
				opacity: overlayView.transitionOpacity

				iconName: "awesome/edit"

				color: Theme.dark.iconColor
				size: dp(40)
			}
		}
	}
}
