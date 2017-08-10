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
import QtQuick.Controls 1.4 as QtControls

import Material 0.3
import Material.Extras 0.1
import Material.ListItems 0.1 as ListItem

Dialog {
	id: scrollingDialog

	property string gxs_name: ""
	property string gxs_id: ""

	property bool anonymous
	property bool bannned_node
	property int friends_negative_votes
	property int friends_positive_votes
	property int overall_reputation_level
	property bool own
	property int own_opinion
	property string pgp_id
	property bool pgp_id_known
	property string pgp_name
	property string type
	property var last_usage

	property bool mask_loading: true

	positiveButtonText: "Cancel"
	negativeButtonText: "Apply"

	contentMargins: dp(8)

	positiveButtonSize: dp(13)
	negativeButtonSize: dp(13)

	Behavior on opacity {
		NumberAnimation { easing.type: Easing.InOutQuad; duration: 200 }
	}

	function showIdentity(gxs_name, gxs_id) {
		scrollingDialog.gxs_name = gxs_name
		scrollingDialog.gxs_id = gxs_id
		show()
	}

	function getIdentityOptions() {
		var jsonData = {
			gxs_id: gxs_id
		}

		function callbackFn(par) {
			if(mask_loading)
				mask_loading = false

			usagesModel.json = par.response

			var json = JSON.parse(par.response)

			anonymous = json.data.anonymous
			bannned_node = json.data.bannned_node
			friends_negative_votes = json.data.friends_negative_votes
			friends_positive_votes = json.data.friends_positive_votes
			overall_reputation_level = json.data.overall_reputation_level
			own = json.data.own
			own_opinion = json.data.own_opinion
			pgp_id = json.data.pgp_id
			pgp_id_known = json.data.pgp_id_known
			pgp_name = json.data.pgp_name
			type = json.data.type

			last_usage = new Date(1000 * json.data.last_usage)
		}

		rsApi.request("/identity/get_identity_details", JSON.stringify(jsonData), callbackFn)
	}

	function setOwnOpinion() {
		var jsonData = {
			gxs_id: gxs_id,
			own_opinion: own_opinion,
		}

		rsApi.request("/identity/set_opinion", JSON.stringify(jsonData), function(){})
	}

	function setBanNode() {
		var jsonData = {
			pgp_id: pgp_id,
			bannned_node: bannned_node
		}

		rsApi.request("/identity/set_ban_node", JSON.stringify(jsonData), function(){})
	}

	onOpened: {
		mask_loading = true
		getIdentityOptions()
	}

	onRejected: {
		if(!own)
			setOwnOpinion()
		if(!anonymous)
			setBanNode()
	}

	JSONListModel {
		id: usagesModel
		query: "$.data.usages[*]"
	}

	Label {
		id: titleLabel

		anchors {
			left: parent.left
			leftMargin: dp(15)
		}

		height: dp(50)
		verticalAlignment: Text.AlignVCenter

		wrapMode: Text.Wrap
		text: gxs_name + "'s details"
		style: "title"
		color: Theme.accentColor
	}

	Item {
		width: main.width < dp(900) ? main.width - dp(100) : dp(600)
		height: main.width < dp(450) ? main.width - dp(100) : dp(300)

		Column {
			anchors {
				left: parent.left
				top: parent.top
				bottom: parent.bottom
			}

			width: parent.width/4

			ListItem.Standard {
				text: "General"
				selected: tabView.currentIndex === 0

				onClicked: tabView.currentIndex = 0
			}

			ListItem.Standard {
				text: "Usage"
				selected: tabView.currentIndex === 1

				onClicked: tabView.currentIndex = 1
			}
		}

		QtControls.TabView {
			id: tabView

			anchors {
				fill: parent
				leftMargin: parent.width/4
			}

			frameVisible: false
			tabsVisible: false

			LoadingMask {
				id: loadingMask
				anchors.fill: parent

				state: mask_loading ? "visible" : "non-visible"
			}

			QtControls.Tab {
				title: "General"

				Item {
					anchors.fill: parent

					Flickable {
						id: flick
						anchors.fill: parent

						clip: true
						contentHeight: pgpColumn.height

						pressDelay: 1000

						Column {
							id: pgpColumn
							width: parent.width

							Connections {
								target: scrollingDialog

								onOpened: {
									selection.selectedIndex = Qt.binding(function() {
										return own_opinion
									})

									switchAutoBan.checked = Qt.binding(function() {
										return bannned_node
									})
								}
							}

							ListItem.Subtitled {
								text: "Identity name"

								height: dp(48)
								interactive: false

								secondaryItem: Label {
									anchors.verticalCenter: parent.verticalCenter

									text: gxs_name
								}
							}

							ListItem.Subtitled {
								text: "Identity ID"

								height: dp(48)
								interactive: false

								secondaryItem: Label {
									anchors.verticalCenter: parent.verticalCenter

									text: gxs_id
								}
							}

							ListItem.Subtitled {
								text: "Your opinion"

								height: dp(48)
								interactive: false

								secondaryItem: MenuField {
									id: selection

									width: dp(100)
									z: 2
									enabled: !own

									model: ["Negative", "Neutral","Positive"]

									selectedIndex: own_opinion
									onItemSelected: own_opinion = index
								}
							}

							ListItem.Subtitled {
								text: "Friends opinions"

								height: dp(48)
								interactive: false

								secondaryItem: Label {
									anchors.verticalCenter: parent.verticalCenter

									text: friends_positive_votes != 0 ?
											  friends_negative_votes != 0 ?
												  friends_positive_votes + " positive, " + friends_negative_votes + " negative"
												: friends_positive_votes + " positive"
									        : friends_negative_votes != 0 ?
									              friends_negative_votes + " negative"
									            : "No votes from friends"
								}
							}

							ListItem.Subtitled {
								text: "Overall opinion"

								height: dp(48)
								interactive: false

								secondaryItem: Label {
									anchors.verticalCenter: parent.verticalCenter

									text: {
										switch(overall_reputation_level) {
										    case 0:
												return "Negative (Banned by you)"
											case 1:
												return "Negative (according to your friends)"
											case 2:
												return "Neutral"
											case 3:
												return "Positive (according to your friends)"
											case 4:
												return "Positive"
											case 5:
												return "Unknown"
										}
									}
								}
							}

							ListItem.Subtitled {
								text: "Last used"

								height: dp(48)
								interactive: false

								secondaryItem: Label {
									anchors.verticalCenter: parent.verticalCenter

									text: last_usage.toTimeString() + " " + last_usage.toDateString()
								}
							}

							ListItem.Subtitled {
								text: "Type"

								height: dp(48)
								interactive: false

								secondaryItem: Label {
									anchors.verticalCenter: parent.verticalCenter

									text: type
								}
							}

							ListItem.Subtitled {
								text: "Owner account name"

								height: dp(48)
								interactive: pgp_id_known
								enabled: !anonymous
								visible: !anonymous

								secondaryItem: Label {
									anchors.verticalCenter: parent.verticalCenter

									text: pgp_name + "@" + pgp_id
								}

								onClicked: {
									if(pgp_id_known) {
										scrollingDialog.close()
										pgpFriendDetailsDialog.showAccount(pgp_name, pgp_id)
									}
								}
							}

							ListItem.Subtitled {
								text: "Auto-ban all identites signed by the same node"

								height: dp(48)
								enabled: !anonymous || !own
								visible: !anonymous || !own

								secondaryItem: Switch {
									id: switchAutoBan

									anchors.verticalCenter: parent.verticalCenter
									checked: bannned_node

									onClicked: bannned_node = switchAutoBan.checked
								}

								onClicked: {
									switchAutoBan.checked = !switchAutoBan.checked
									bannned_node = switchAutoBan.checked
								}
							}
						}
					}

					Scrollbar {
						flickableItem: flick
					}
				}
			}

			QtControls.Tab {
				id: tab
				title: "Usage"

				Item {
					anchors.fill: parent

					ListView {
						id: usageListView
						anchors.fill: parent
						clip: true

						model: usagesModel.model
						delegate: ListItem.Subtitled {
							height: dp(48)
							interactive: false

							text: {
								switch(model.usage_case) {
								    case 0:
										return "[Unknown]"
									case 1:
										return "Admin signature in service"
									case 2:
										return "Admin signature verification in service"
									case 3:
										return "Creation of author signature in service"
									case 4:
										return ""
									case 5:
										return ""
									case 6:
										return ""
									case 7:
										return ""
									case 8:
										return ""
									case 9:
										return "Message in chat lobby"
									case 10:
										return "Distant message signature validation"
									case 11:
										return "Distant message signature creation"
									case 12:
										return "Signature validation in distant tunnel system"
									case 13:
										return "Signature in distant tunnel system"
									case 14:
										return "Update of identity data"
									case 15:
										return "Generic signature validation"
									case 16:
										return "Generic signature"
									case 17:
										return "Generic encryption"
									case 18:
										return "Generic decryption"
									case 19:
										return "Membership verification in circle"
								}
							}
							valueText: Date(1000 * model.usage_time).toTimeString() + " " + Date(1000 * model.usage_time).toDateString()
						}
					}

					Scrollbar {
						flickableItem: usageListView
					}
				}
			}
		}
	}
}
