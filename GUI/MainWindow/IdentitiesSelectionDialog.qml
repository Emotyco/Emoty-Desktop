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
import Material.ListItems 0.1 as ListItem

Dialog {
	id: identitiesSelectionDialog

	positiveButtonText: "Cancel"
	negativeButtonText: "Add"

	positiveButtonSize: dp(13)
	negativeButtonSize: dp(13)

	contentMargins: 0

	onRejected: selectedList.forEach(addContact)
	onClosed: selectedList = []

	property var selectedList: []
	property var identitiesModel: ListModel { id: identities }

	function addContact(gxs) {
		var jsonData = {
			gxs_id: gxs
		}

		rsApi.request("/identity/add_contact", JSON.stringify(jsonData), function(){})
	}

	function showDialog(identities) {
		if(!showing) {
			identitiesModel.clear()
			identities.forEach(function(item) {
				identitiesModel.append({"gxs_id": item[0], "name": item[1]})
			})
			open()
		}
	}

	Item {
		width: dp(300)
		height: listViewItem.height + dp(50) + dp(50) + dp(10)

		Label {
			anchors {
				top: parent.top
				left: parent.left
				leftMargin: dp(24)
			}

			height: dp(50)
			verticalAlignment: Text.AlignVCenter

			wrapMode: Text.Wrap
			text: "Add as contact"
			style: "title"
			color: Theme.accentColor
		}

		Label {
			anchors {
				top: parent.top
				topMargin: dp(50)
				left: parent.left
				leftMargin: dp(24)
				right: parent.right
				rightMargin: dp(24)
			}

			height: dp(50)

			wrapMode: Text.WordWrap
			text: "Your friend have more than one identity. Choose which ones you want to add as a contact."
			style: "tooltip"
			color: Theme.light.iconColor
		}

		Item {
			id: listViewItem

			anchors {
				top: parent.top
				topMargin: dp(110)
				left: parent.left
				leftMargin: dp(24)
				right: parent.right
				rightMargin: dp(24)
			}

			height: dp(48)*identitiesModel.count > dp(320)
					? dp(320)
					: dp(48)*identitiesModel.count

			ListView {
				id: identitiesListView

				anchors.fill: parent
				clip: true
				snapMode: ListView.NoSnap
				flickableDirection: Flickable.AutoFlickDirection

				model: identitiesModel
				delegate: RoomFriend {
					property string avatar: "avatar.png"

					width: parent.width

					text: model.name
					textColor: selected ? Theme.primaryColor : Theme.light.textColor
					itemLabel.style: "body1"

					imageSource: avatar
					isIcon: false

					Connections {
						target: identitiesSelectionDialog
						onOpened: getIdentityAvatar()
						onClosed: selected = false
					}

					Component.onCompleted: getIdentityAvatar()

					function getIdentityAvatar() {
						var jsonData = {
							gxs_id: model.gxs_id
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

					onClicked: {
						if(selected)
							selectedList.splice(selectedList.indexOf(model.gxs_id), 1)
						else
							selectedList.push(model.gxs_id)

						selected = !selected
					}
				}

				/*header: Item {
					height: dp(15)
					width: parent.width
				}*/
			}

			Scrollbar {
				anchors.margins: 0
				flickableItem: identitiesListView
			}
		}
	}
}
