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
import QtQuick 2.7
import QtQuick.Controls 1.4
import QtQuick.Dialogs 1.0
import QtQuick.Layouts 1.3

import Material 0.3 as Material
import Material.ListItems 0.1 as ListItem

import TransferFilesSortModel 0.2
import SharedFilesModel 0.2
import SearchFileModel 0.2
import SearchFileSortModel 0.2

Card {
	// For handling tokens
	property int downloadStateToken: 0
	property int uploadStateToken: 0
	property int searchStateToken: 0

	property string search_id: ""

	Component.onDestruction: {
		main.unregisterToken(downloadStateToken)
		main.unregisterToken(uploadStateToken)
		main.unregisterToken(searchStateToken)
	}

	function getDownloads() {
		function callbackFn(par) {
			downloadStateToken = JSON.parse(par.response).statetoken
			main.registerToken(downloadStateToken, getDownloads)

			transferSortModel.sourceModel.loadJSONDownloadList(par.response)
		}

		rsApi.request("/transfers/downloads/", "", callbackFn)
	}
	function getUploads() {
		function callbackFn(par) {
			uploadStateToken = JSON.parse(par.response).statetoken
			main.registerToken(uploadStateToken, getUploads)

			transferSortModel.sourceModel.loadJSONUploadList(par.response)
		}

		rsApi.request("/transfers/uploads/", "", callbackFn)
	}
	function getSharedDirs() {
		var jsonData = {
			remote: false,
			local: true
		}

		function callbackFn(par) {
			ownFilesModel.loadJSONSharedFolders(par.response)
		}

		rsApi.request("filesharing/get_dir_childs", JSON.stringify(jsonData), callbackFn)
	}
	function getFriendsSharedDirs() {
		var jsonData = {
			remote: true,
			local: false
		}

		function callbackFn(par) {
			friendsFilesModel.loadJSONSharedFolders(par.response)
		}

		rsApi.request("filesharing/get_dir_childs", JSON.stringify(jsonData), callbackFn)
	}
	function getSearchResult() {
		var jsonData = {
			search_id: search_id
		}

		function callbackFn(par) {
			searchStateToken = JSON.parse(par.response).statetoken
			main.registerToken(searchStateToken, getSearchResult)

			resultModel.loadJSONSearchFiles(par.response)
		}

		rsApi.request("/filesearch/get_search_result/", JSON.stringify(jsonData), callbackFn)
	}

	Component.onCompleted: {
		getDownloads()
		getUploads()
		getSharedDirs()
		getFriendsSharedDirs()
		getSearchResult()
	}

	TransferFilesSortModel {
		id: transferSortModel
	}

	SharedFilesModel {
		id: ownFilesModel
		objectName: "ownFiles"
	}

	SharedFilesModel {
		id: friendsFilesModel
		objectName: "friendsFiles"
	}

	SearchFileModel {
		id: resultModel
	}

	SearchFileSortModel {
		id: ownResultModel
		objectName: "ownSearchResult"
		baseModel: resultModel
		isOwn: true
		isFriends: false
	}

	SearchFileSortModel {
		id: friendsResultModel
		objectName: "friendsSearchResult"
		baseModel: resultModel
		isOwn: false
		isFriends: true
	}

	SearchFileSortModel {
		id: distantResultModel
		objectName: "distantSearchResult"
		baseModel: resultModel
		isOwn: false
		isFriends: false
	}

	Item {
		anchors.fill: parent

		Item {
			id: searcher

			anchors {
				left: parent.left
				top: parent.top
			}

			z: 2

			state: "small"
			states: [
				State {
					name: "small"
					PropertyChanges { target: searcher; width: dp(250) }
					PropertyChanges { target: searcher; height: dp(70) }
				},
				State {
					name: "large"
					PropertyChanges { target: searcher; width: parent.width }
					PropertyChanges { target: searcher; height: parent.height }
				}
			]

			transitions: [
				Transition {
					from: "small"; to: "large"

					ParallelAnimation {
						NumberAnimation {
							target: searcher
							property: "width"
							easing.type: Easing.InOutQuad;
							duration: Material.MaterialAnimation.pageTransitionDuration
						}
						NumberAnimation {
							target: searcher
							property: "height"
							easing.type: Easing.InOutQuad;
							duration: Material.MaterialAnimation.pageTransitionDuration
						}
					}
				},
				Transition {
					from: "large"; to: "small"


					ParallelAnimation {
						NumberAnimation {
							target: searcher
							property: "width"
							easing.type: Easing.InOutQuad;
							duration: Material.MaterialAnimation.pageTransitionDuration
						}
						NumberAnimation {
							target: searcher
							property: "height"
							easing.type: Easing.InOutQuad;
							duration: Material.MaterialAnimation.pageTransitionDuration
						}
					}
				}
			]

			Item {
				id: searcherBoxItem
				anchors {
					top: parent.top
					left: parent.left
					right: parent.right
				}

				height: dp(70)
				z: 2

				Material.View {
					id: searcherBoxView

					anchors {
						fill: parent
						leftMargin: dp(15)
						rightMargin: dp(15)
						bottomMargin: dp(17)
						topMargin: dp(17)
					}

					radius: 10
					elevation: 1
					backgroundColor: "white"

					states: [
						State {
							name: "small"; when: searcher.state == "small"
							PropertyChanges { target: searcherBoxView; anchors.leftMargin: dp(15) }
							PropertyChanges { target: searcherBoxView; anchors.rightMargin: dp(15) }
							PropertyChanges { target: searcherBoxView; anchors.bottomMargin: dp(17) }
						},
						State {
							name: "large"; when: searcher.state == "large"
							PropertyChanges { target: searcherBoxView; anchors.leftMargin: parent.width*0.2 }
							PropertyChanges { target: searcherBoxView; anchors.rightMargin: parent.width*0.2 }
							PropertyChanges { target: searcherBoxView; anchors.bottomMargin: dp(12) }
						}
					]

					Behavior on anchors.leftMargin {
						NumberAnimation {
							easing.type: Easing.InOutQuad
							duration: Material.MaterialAnimation.pageTransitionDuration
						}
					}

					Behavior on anchors.rightMargin {
						NumberAnimation {
							easing.type: Easing.InOutQuad
							duration: Material.MaterialAnimation.pageTransitionDuration
						}
					}

					Behavior on anchors.bottomMargin {
						NumberAnimation {
							easing.type: Easing.InOutQuad
							duration: Material.MaterialAnimation.pageTransitionDuration
						}
					}

					Behavior on anchors.rightMargin {
						NumberAnimation {
							easing.type: Easing.InOutQuad
							duration: Material.MaterialAnimation.pageTransitionDuration
						}
					}

					Material.TextField {
						id: searchText
						anchors {
							top: parent.top
							left: parent.left
							right: searchIcon.left
							bottom: parent.bottom
							topMargin: dp(5)
							bottomMargin: dp(5)
							leftMargin: dp(18)
							rightMargin: dp(18)
						}

						placeholderText: "Search for files"
						placeholderPixelSize: dp(15)
						font.pixelSize: dp(15)

						showBorder: false
						focus: true
						clip: true

						onActiveFocusChanged: {
							if(activeFocus) {
								searcherBoxView.elevation = 2
							}
							else
								searcherBoxView.elevation = 1
						}

						onTextChanged: {
							if(searcher.state == "small")
								searcher.state = "large"
						}

						onAccepted: {
							var jsonData = {
								search_string: searchText.text
							}

							function callbackFn(par) {
								var json = JSON.parse(par.response)
								search_id = json.data.search_id
								getSearchResult()
							}

							rsApi.request("/filesearch/create_search/", JSON.stringify(jsonData), callbackFn)
						}

						Keys.onPressed: {
						}
					}

					MouseArea {
						id: searchHoverMA
						anchors.fill: parent
						hoverEnabled: true

						onEntered: {
							searchIcon.color = Material.Theme.light.iconColor
							searcherBoxView.elevation = 2
						}
						onExited: {
							searchIcon.color = Material.Theme.light.hintColor

							if(searchText.activeFocus == false)
								searcherBoxView.elevation = 1
						}
						onClicked: searchText.forceActiveFocus()
					}

					Material.IconButton {
						id: searchIcon

						anchors {
							top: parent.top
							right: parent.right
							bottom: parent.bottom
							topMargin: dp(5)
							bottomMargin: dp(5)
							rightMargin: dp(10)
						}

						iconName: "awesome/search"

						size: dp(24)
						color: Material.Theme.light.hintColor

						onEntered: {
							searchIcon.color = Material.Theme.light.iconColor
							searcherBoxView.elevation = 2
						}

						onExited: {
							searchIcon.color = Material.Theme.light.hintColor

							if(searchText.activeFocus == false)
								searcherBoxView.elevation = 1
						}

						onClicked: {
							var jsonData = {
								search_string: searchText.text
							}

							function callbackFn(par) {
								var json = JSON.parse(par.response)
								search_id = json.data.search_id
								getSearchResult()
							}

							rsApi.request("/filesearch/create_search/", JSON.stringify(jsonData), callbackFn)
						}
					}
				}

				Material.IconButton {
					id: closeSearcher

					anchors {
						top: parent.top
						right: parent.right
						bottom: parent.bottom
						topMargin: dp(17)
						bottomMargin: dp(12)
						rightMargin: dp(25)
					}

					iconName: "awesome/times_circle"
					size: dp(36)
					color: Material.Theme.light.hintColor

					opacity: searcher.state == "small" ? 0 : 1
					enabled: searcher.state == "small" ? false : true

					Behavior on opacity {
						NumberAnimation {
							easing.type: Easing.InOutQuad
							duration: Material.MaterialAnimation.pageTransitionDuration
						}
					}

					onClicked: {
						if(searcher.state == "large") {
							searchText.text = ""
							searcher.state = "small"
						}
					}
					onEntered: closeSearcher.color = Material.Theme.light.iconColor
					onExited:  closeSearcher.color = Material.Theme.light.hintColor
				}
			}

			Item {
				id: searcherLayout

				anchors {
					top: searcherBoxItem.bottom
					left: parent.left
					right: parent.right
				}

				z: 2
				height: dp(20)

				opacity: searcher.state == "small" ? 0 : 1
				enabled: searcher.state == "small" ? false : true

				Behavior on opacity {
					NumberAnimation {
						easing.type: Easing.InOutQuad
						duration: Material.MaterialAnimation.pageTransitionDuration
					}
				}

				Material.Slider {
					id: slider

					anchors {
						fill: parent
						leftMargin: parent.width*0.25
						rightMargin: parent.width*0.25
					}

					height: parent.height

					value: 100

					numericValueLabel: false
					stepSize: 10
					minimumValue: 50
					maximumValue: 150

					color: Material.Palette.colors["grey"]["500"]

					onPressedChanged: {
						if(pressed)
							color = Material.Theme.primaryColor
						else if(!pressed)
							color = Material.Palette.colors["grey"]["500"]
					}
				}
			}

			Rectangle {
				anchors.fill: parent
				color: Material.Palette.colors["grey"]["50"]

				radius: searcher.state == "small" ? width/2 : 0
				Behavior on radius {
					NumberAnimation {
						easing.type: Easing.InOutQuad
						duration: Material.MaterialAnimation.pageTransitionDuration
					}
				}

				opacity: searcher.state == "small" ? 0 : 1
				Behavior on opacity {
					NumberAnimation {
						easing.type: Easing.InOutQuad
						duration: Material.MaterialAnimation.pageTransitionDuration
					}
				}
			}

			MouseArea {
				anchors.fill: parent
				hoverEnabled: true
				onClicked: {}
				onEntered: {}
				onExited: {}
			}

			ListModel {
				id: gridModel

				ListElement {
					index: 0
					titleString: "Your files"
				}
				ListElement {
					index: 1
					titleString: "Friends' files"
				}
				ListElement {
					index: 2
					titleString: "Global"
				}
			}

			ListView {
				id: searcherFilesListView
				anchors {
					top: searcherLayout.bottom
					left: parent.left
					right: parent.right
					bottom: parent.bottom
					leftMargin: dp(23)
					rightMargin: dp(23)
				}

				visible: searcher.state == "small" ? 0 : 1
				enabled: searcher.state == "small" ? 0 : 1

				clip: true

				model: gridModel
				delegate: Component {
					Item {
						height: Math.ceil(gridView.model.count/
										  Math.floor(gridView.width / (gridView.width / Math.floor(gridView.width / gridView.idealCellWidth)))
										  )*gridView.cellHeight
						width: parent.width

						GridView {
							id: gridView
							anchors.fill: parent

							interactive: false
							property int idealCellHeight: dp(150)*slider.value/100
							property int idealCellWidth: dp(150)*slider.value/100

							cellHeight: idealCellHeight
							cellWidth: width / Math.floor(width / idealCellWidth)

							visible: searcher.state == "small" ? 0 : 1
							enabled: searcher.state == "small" ? 0 : 1

							clip: true

							model: {
								if(index == 0)
									return ownResultModel
								else if(index == 1)
									return friendsResultModel
								else if(index == 2)
									return distantResultModel
							}
							delegate: FileResultDelegate {}
						}
					}
				}

				section.property: "titleString"
				section.criteria: ViewSection.FullString
				section.delegate: Item {
					width: dp(100)
					height: dp(25)

					Material.Label {
						anchors {
							left: parent.left
							leftMargin: dp(10)
							right: parent.right
							rightMargin: dp(10)
							verticalCenter: parent.verticalCenter
						}

						clip: true
						text: section
						color: Material.Theme.light.iconColor
						verticalAlignment: Text.AlignVCenter
					}
				}
			}

			Material.Scrollbar {
				flickableItem: searcherFilesListView
				opacity: searcher.state == "small" ? 0 : 1
			}
		}

		Item {
			id: leftTabsSelect
			anchors {
				top: parent.top
				left: parent.left
				bottom: parent.bottom
				topMargin: dp(75)
				leftMargin: dp(15)
			}

			width: dp(250)

			Item {
				anchors {
					fill: parent
					rightMargin: dp(30)
				}

				ListItem.Standard {
					id: sharedBy
					width: parent.width
					text: "Shared by you"

					selected: tabView.currentIndex == 0
					tintColor: "transparent"

					onClicked: transitionMask.fire(0)
				}
				ListItem.Standard {
					id: sharedWith
					anchors.top: sharedBy.bottom

					width: parent.width
					text: "Shared with you"

					selected: tabView.currentIndex == 1
					tintColor: "transparent"

					onClicked: transitionMask.fire(1)
				}
				ListItem.Standard {
					id: transferring
					anchors.top: sharedWith.bottom

					width: parent.width
					text: "Transferring"

					selected: tabView.currentIndex == 2
					tintColor: "transparent"

					onClicked: transitionMask.fire(2)

					Material.View {
						anchors {
							verticalCenter: parent.verticalCenter
							right: parent.right
							rightMargin: dp(10)
						}

						width: dp(20)
						height: dp(20)

						elevation: 1
						radius: width/2
						visible: transferSortModel.sourceModel.dataCount > 0 ? true : false

						backgroundColor: Material.Theme.primaryColor

						Text {
							anchors.fill: parent

							text: transferSortModel.sourceModel.dataCount
							color: "white"

							font.family: "Roboto"
							font.pixelSize: dp(12)

							verticalAlignment: Text.AlignVCenter
							horizontalAlignment: Text.AlignHCenter
						}
					}
				}
			}
		}

		Item {
			anchors {
				top: parent.top
				left: leftTabsSelect.right
				bottom: parent.bottom
				right: parent.right
			}

			Rectangle {
				id: transitionMask

				property int index: 0

				anchors.fill: parent
				z:1
				opacity: 0

				color: Material.Palette.colors["grey"]["50"]

				SequentialAnimation {
					id: sequentialAnimation
					NumberAnimation {
						target: transitionMask
						property: "opacity"
						from: 0
						to: 1
						easing.type: Easing.InOutQuad;
						duration: Material.MaterialAnimation.pageTransitionDuration
					}

					ScriptAction {
						script: {
							tabView.currentIndex = transitionMask.index
						}
					}

					NumberAnimation {
						target: transitionMask
						property: "opacity"
						from: 1
						to: 0
						easing.type: Easing.InOutQuad;
						duration: Material.MaterialAnimation.pageTransitionDuration
					}
				}

				function fire(index) {
					transitionMask.index = index
					sequentialAnimation.start()
				}
			}

			TabView {
				id: tabView

				anchors.fill: parent

				frameVisible: false
				tabsVisible: false

				Tab {
					title: "Shared by you"

					Item {
						anchors.fill: parent

						Item {
							id: topBar
							anchors {
								top: parent.top
								left: parent.left
								right: parent.right
							}
							height: dp(70)

							states: [
								State {
									name: "hidden"; when: ownFilesModel.parent_reference == 0
									PropertyChanges { target: backButton; opacity: 0 }
									PropertyChanges { target: pathLabel; opacity: 0 }
									PropertyChanges { target: forceCheckButton; opacity: 1 }
								},
								State {
									name: "visible"; when: ownFilesModel.parent_reference != 0
									PropertyChanges { target: backButton; opacity: 1 }
									PropertyChanges { target: pathLabel; opacity: 1 }
									PropertyChanges { target: forceCheckButton; opacity: 0 }
								}
							]

							Material.IconButton {
								id: backButton
								anchors {
									verticalCenter: parent.verticalCenter
									left: parent.left
								}

								iconName: "awesome/arrow_circle_left"
								size: dp(36)
								color: Material.Theme.light.hintColor

								Behavior on opacity {
									NumberAnimation {
										target: backButton
										property: "opacity"
										easing.type: Easing.InOutQuad;
										duration: Material.MaterialAnimation.pageTransitionDuration
									}
								}

								onEntered: color = Material.Theme.light.iconColor
								onExited:  color = Material.Theme.light.hintColor
								onClicked: {
									var jsonData = {
										reference: ownFilesModel.getParent(),
										remote: false,
										local: true
									}

									function callbackFn(par) {
										ownFilesModel.loadJSONSharedFolders(par.response)
									}

									rsApi.request("/filesharing/get_dir_parent/", JSON.stringify(jsonData), callbackFn)
								}
							}

							Material.Label {
								id: pathLabel
								anchors {
									left: backButton.right
									leftMargin: dp(10)
									right: shareFolderButton.left
									rightMargin: dp(10)
									verticalCenter: parent.verticalCenter
								}

								Behavior on opacity {
									NumberAnimation {
										target: pathLabel
										property: "opacity"
										easing.type: Easing.InOutQuad;
										duration: Material.MaterialAnimation.pageTransitionDuration
									}
								}

								text: ownFilesModel.path

								clip: true

								color: Material.Theme.light.iconColor
								verticalAlignment: Text.AlignVCenter
								horizontalAlignment: Text.AlignRight
							}

							Material.View {
								id: forceCheckButton
								anchors {
									verticalCenter: parent.verticalCenter
									right: shareFolderButton.left
									rightMargin: dp(35)
								}

								Behavior on opacity {
									NumberAnimation {
										target: forceCheckButton
										property: "opacity"
										easing.type: Easing.InOutQuad;
										duration: Material.MaterialAnimation.pageTransitionDuration
									}
								}

								height: dp(36)
								width: dp(120)

								radius: dp(10)
								elevation: 0
								backgroundColor: Material.Theme.primaryColor

								Material.Label {
									anchors.fill: parent

									style: "button"
									text: "Force check"
									font.pixelSize: dp(13)
									color: "white"

									horizontalAlignment: Text.AlignHCenter
									verticalAlignment: Text.AlignVCenter
								}

								MouseArea {
									anchors.fill: parent
									hoverEnabled: true
									onEntered: forceCheckButton.elevation = 2
									onExited: forceCheckButton.elevation = 0
									onClicked: rsApi.request("/filesharing/force_check/", "", function(){})
								}
							}

							Material.View {
								id: shareFolderButton
								anchors {
									verticalCenter: parent.verticalCenter
									right: parent.right
									rightMargin: dp(35)
								}

								height: dp(36)
								width: dp(150)

								radius: dp(10)
								elevation: 0
								backgroundColor: Material.Theme.primaryColor

								Material.Label {
									anchors.fill: parent

									style: "button"
									text: "Share folder"
									font.pixelSize: dp(13)
									color: "white"

									horizontalAlignment: Text.AlignHCenter
									verticalAlignment: Text.AlignVCenter
								}

								MouseArea {
									anchors.fill: parent
									hoverEnabled: true
									onEntered: shareFolderButton.elevation = 2
									onExited: shareFolderButton.elevation = 0
									onClicked: fileDialog.open()
								}

								FileDialog {
									id: fileDialog
									title: "Choose folder to share"
									selectMultiple: false
									selectFolder: true
									onAccepted: {
										var jsonData = {
											directory: String(fileDialog.fileUrl).substr(7)
										}

										rsApi.request("/filesharing/set_shared_dir/", JSON.stringify(jsonData), function(){})
										getSharedDirs()
									}
								}
							}
						}

						Item {
							anchors.fill: parent
							anchors.topMargin: dp(70)

							GridView {
								id: ownFiles
								anchors {
									fill: parent
									rightMargin: dp(23)
								}

								property int idealCellHeight: dp(170)
								property int idealCellWidth: dp(170)

								cellHeight: idealCellHeight
								cellWidth: width / Math.floor(width / idealCellWidth)

								clip: true
								model: ownFilesModel
								delegate: FileDelegate {}
							}

							Material.Scrollbar {
								flickableItem: ownFiles
							}
						}
					}
				}
				Tab {
					title: "Shared with you"

					Item {
						anchors.fill: parent

						Item {
							id: topBarSharedWU
							anchors {
								top: parent.top
								left: parent.left
								right: parent.right
							}
							height: dp(70)

							states: [
								State {
									name: "hidden"; when: friendsFilesModel.parent_reference == 0
									PropertyChanges { target: friendBackButton; opacity: 0 }
									PropertyChanges { target: friendPathLabel; opacity: 0 }
								},
								State {
									name: "visible"; when: friendsFilesModel.parent_reference != 0
									PropertyChanges { target: friendBackButton; opacity: 1 }
									PropertyChanges { target: friendPathLabel; opacity: 1 }
								}
							]

							Material.IconButton {
								id: friendBackButton
								anchors {
									verticalCenter: parent.verticalCenter
									left: parent.left
								}

								iconName: "awesome/arrow_circle_left"
								size: dp(36)
								color: Material.Theme.light.hintColor

								Behavior on opacity {
									NumberAnimation {
										target: friendBackButton
										property: "opacity"
										easing.type: Easing.InOutQuad;
										duration: Material.MaterialAnimation.pageTransitionDuration
									}
								}

								onEntered: color = Material.Theme.light.iconColor
								onExited:  color = Material.Theme.light.hintColor
								onClicked: {
									var jsonData = {
										reference: friendsFilesModel.getParent(),
										remote: true,
										local: false
									}

									function callbackFn(par) {
										friendsFilesModel.loadJSONSharedFolders(par.response)
									}

									rsApi.request("/filesharing/get_dir_parent/", JSON.stringify(jsonData), callbackFn)
								}
							}

							Material.Label {
								id: friendPathLabel
								anchors {
									left: friendBackButton.right
									leftMargin: dp(10)
									right: parent.right
									rightMargin: dp(10)
									verticalCenter: parent.verticalCenter
								}

								Behavior on opacity {
									NumberAnimation {
										target: friendPathLabel
										property: "opacity"
										easing.type: Easing.InOutQuad;
										duration: Material.MaterialAnimation.pageTransitionDuration
									}
								}

								clip: true

								text: friendsFilesModel.path
								color: Material.Theme.light.iconColor

								verticalAlignment: Text.AlignVCenter
								horizontalAlignment: Text.AlignRight
							}
						}

						Item {
							anchors.fill: parent
							anchors.topMargin: dp(70)

							GridView {
								id: friendsFiles
								anchors {
									fill: parent
									rightMargin: dp(23)
								}

								property int idealCellHeight: dp(170)
								property int idealCellWidth: dp(170)

								cellHeight: idealCellHeight
								cellWidth: width / Math.floor(width / idealCellWidth)

								clip: true
								model: friendsFilesModel
								delegate: FileDelegate {}
							}

							Material.Scrollbar {
								flickableItem: friendsFiles
							}
						}
					}
				}
				Tab {
					title: "Transferring"

					Item {
						anchors.fill: parent

						Item {
							anchors {
								top: parent.top
								left: parent.left
								right: parent.right
							}
							height: dp(70)

							Material.IconButton {
								id: uploadsOnly

								anchors {
									verticalCenter: parent.verticalCenter
									right: parent.right
									rightMargin: dp(32)
								}

								property bool selected: false
								property bool hovered: false

								iconName: "awesome/arrow_circle_up"
								size: dp(32)

								color: selected ? Material.Theme.primaryColor
												: hovered ? Material.Theme.light.iconColor
														  : Material.Theme.light.hintColor

								onClicked: {
									transferSortModel.setFilter(2)
									selected = true
									everythingInk.selected = false
									downloadsOnly.selected = false
								}
								onEntered: hovered = true
								onExited:  hovered = false
							}

							Material.IconButton {
								id: downloadsOnly

								anchors {
									verticalCenter: parent.verticalCenter
									right: uploadsOnly.left
									rightMargin: dp(12)
								}

								property bool selected: false
								property bool hovered: false

								iconName: "awesome/arrow_circle_down"
								size: dp(32)

								color: selected ? Material.Theme.primaryColor
												: hovered ? Material.Theme.light.iconColor
														  : Material.Theme.light.hintColor

								onClicked: {
									transferSortModel.setFilter(1)
									selected = true
									everythingInk.selected = false
									uploadsOnly.selected = false
								}
								onEntered: hovered = true
								onExited:  hovered = false
							}

							Item {
								anchors {
									verticalCenter: parent.verticalCenter
									right: downloadsOnly.left
									rightMargin: dp(12)
								}

								width: dp(36)
								height: dp(36)

								Material.Ink {
									id: everythingInk

									property bool selected: false
									property bool hovered: false

									anchors.centerIn: parent
									centered: true
									circular: true
									clip: false

									width: dp(56)
									height: dp(56)

									onClicked: {
										transferSortModel.setFilter(0)
										selected = true
										downloadsOnly.selected = false
										uploadsOnly.selected = false
									}
									onEntered: hovered = true
									onExited:  hovered = false

									Label {
										id: everythingLabel
										anchors.centerIn: parent
										text: "ALL"

										color: everythingInk.selected ?
												   Material.Theme.primaryColor
												 : (everythingInk.hovered ?
													   Material.Theme.light.iconColor
													 : Material.Theme.light.hintColor)
									}
								}
							}
						}

						Item {
							anchors.fill: parent
							anchors.topMargin: dp(70)

							ListView {
								id: transferList
								anchors {
									fill: parent
									rightMargin: dp(23)
								}

								clip: true
								spacing: dp(15)

								model: transferSortModel
								delegate: TransferDelegate {}
								header: Item{
									width: 1
									height: dp(10)
								}
								footer: Item {
									width: 1
									height: dp(10)
								}
							}

							Material.Scrollbar {
								flickableItem: transferList
							}
						}
					}
				}
			}
		}
	}
}
