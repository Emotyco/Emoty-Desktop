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
import QtQuick.Layouts 1.3

import Material 0.3 as Material
import Material.ListItems 0.1 as ListItem

Component {
	Item {
		id: fileItem
		property string modelName: GridView.view.model.objectName
		property var modelObject: GridView.view.model

		property string location: model.virtual_name
		property string ext: location.substring(location.lastIndexOf('.'))

		width: GridView.view.cellWidth
		height: GridView.view.cellHeight

		Component.onCompleted: {
			if(model.parent_reference == "") {
				location = ""
				var jsonData = {
					peer_id: model.name
				}

				function callbackFn(par) {
					var json = JSON.parse(par.response)
					location = json.data.location
				}

				rsApi.request("/peers/get_node_name", JSON.stringify(jsonData), callbackFn)
			}
		}

		Item {
			anchors.centerIn: parent
			width: parent.GridView.view.idealCellWidth - 10
			height: parent.height - 10

			clip: true

			MouseArea {
				id: mouseArea
				anchors.fill: parent
				acceptedButtons: Qt.LeftButton | Qt.RightButton
				hoverEnabled: true

				onEntered: {
					fileIcon.color = Material.Theme.primaryColor
					fileName.color = Material.Theme.primaryColor
					fileSize.color = Material.Theme.primaryColor
				}

				onExited: {
					fileIcon.color = Material.Theme.light.iconColor
					fileName.color = Material.Theme.light.iconColor
					fileSize.color = Material.Theme.light.iconColor
				}

				onClicked: {
					if(mouse.button == Qt.LeftButton) {
						if(model.type == "folder" || model.type == "person") {
							if(modelName == "ownFiles") {
								getSharedDirs(model.reference)
							}

							if(modelName == "friendsFiles") {
								getFriendsSharedDirs(model.reference)
							}
						}
						else if(model.type == "file" && (modelName == "friendsFiles" || modelName == "friendsSearchResult" || modelName == "distantSearchResult")) {
							var downloadData = {
								action: "begin",
								hash: model.hash,
								name: model.name,
								size: model.count
							}

							rsApi.request("/transfers/control_download/", JSON.stringify(downloadData), function(){})
						}
					}
					else if(mouse.button == Qt.RightButton && modelName == "ownFiles" && model.type != "person"){
						overflowMenu.open(fileItem, mouse.x, mouse.y)
					}
				}
			}

			Material.Tooltip {
				text: "Name: " + model.virtual_name + "\n"
					+ (model.type == "file" ? "Size: " : "Contain: ") + fileSize.text
				mouseArea: mouseArea
			}

			Material.Dropdown {
				id: overflowMenu
				objectName: "overflowMenu"
				overlayLayer: "dialogOverlayLayer"
				width: dp(270)
				height: model.name.startsWith(":/", 1) || model.name.startsWith("/") ?  dp(4*30+15) : dp(3*30)
				enabled: true
				anchor: Item.TopLeft
				durationSlow: 300
				durationFast: 150

				Column {
					anchors.fill: parent

					ListItem.Standard {
						height: dp(30)
						text: "Browsable"
						itemLabel.style: "body1"

						secondaryItem: Material.CheckBox {
							id: browsableCB
							anchors.verticalCenter: parent.verticalCenter
							enabled: model.name.startsWith(":/", 1) || model.name.startsWith("/") ? true : false
							checked: model.browsable
						}

						onClicked: {
							if(browsableCB.enabled){
								browsableCB.checked = !browsableCB.checked

								var jsonData = {
									directory: model.name,
									virtualname: model.virtual_name,
									browsable: browsableCB.checked,
									anon_dl: downloadableCB.checked,
									anon_search: searchableCB.checked
								}

								rsApi.request("/filesharing/update_shared_dir/", JSON.stringify(jsonData), function(){})
							}
						}
					}

					ListItem.Standard {
						height: dp(30)
						text: "Anonymously downloadable"
						itemLabel.style: "body1"

						secondaryItem: Material.CheckBox {
							id: downloadableCB
							anchors.verticalCenter: parent.verticalCenter
							enabled: model.name.startsWith(":/", 1) || model.name.startsWith("/") ? true : false
							checked: model.anonymous_download
						}

						onClicked: {
							if(downloadableCB.enabled){
								downloadableCB.checked = !downloadableCB.checked

								var jsonData = {
									directory: model.name,
									virtualname: model.virtual_name,
									browsable: browsableCB.checked,
									anon_dl: downloadableCB.checked,
									anon_search: searchableCB.checked
								}

								rsApi.request("/filesharing/update_shared_dir/", JSON.stringify(jsonData), function(){})
							}
						}
					}

					ListItem.Standard {
						height: dp(30)
						text: "Anonymously searchable"
						itemLabel.style: "body1"

						secondaryItem: Material.CheckBox {
							id: searchableCB
							anchors.verticalCenter: parent.verticalCenter
							enabled: model.name.startsWith(":/", 1) || model.name.startsWith("/") ? true : false
							checked: model.anonymous_search
						}

						onClicked: {
							if(searchableCB.enabled){
								searchableCB.checked = !searchableCB.checked

								var jsonData = {
									directory: model.name,
									virtualname: model.virtual_name,
									browsable: browsableCB.checked,
									anon_dl: downloadableCB.checked,
									anon_search: searchableCB.checked
								}

								rsApi.request("/filesharing/update_shared_dir/", JSON.stringify(jsonData), function(){})
							}
						}
					}

					Item {
						width: parent.width
						height: dp(15)

						visible: model.name.startsWith(":/", 1) || model.name.startsWith("/") ? true : false
						enabled: model.name.startsWith(":/", 1) || model.name.startsWith("/") ? true : false

						Rectangle {
							anchors {
								verticalCenter: parent.verticalCenter
								horizontalCenter: parent.horizontalCenter
							}

							width: parent.width*0.8
							height: dp(1)
							color: Material.Palette.colors["grey"]["200"]
						}
					}

					ListItem.Standard {
						height: dp(30)
						text: "Unshare folder"
						itemLabel.style: "body1"

						visible: model.name.startsWith(":/", 1) || model.name.startsWith("/") ? true : false
						enabled: model.name.startsWith(":/", 1) || model.name.startsWith("/") ? true : false

						onClicked: {
							var jsonData = {
								directory: model.name
							}

							rsApi.request("/filesharing/remove_shared_dir/", JSON.stringify(jsonData), function(){})
							overflowMenu.close()
						}
					}
				}
			}

			Material.Icon {
				id: fileIcon
				anchors {
					top: parent.top
					left: parent.left
					right: parent.right
					topMargin: dp(10)
				}

				name: {
					if(model.type == "folder")
						return "awesome/folder_o"
					else if(model.type == "file"){
						if(ext == ".cpp" || ext == ".h" || ext == ".js" || ext == ".qml" || ext == ".css" || ext == ".html")
							return "awesome/file_code_o"
						else if(ext == ".avi" || ext == ".flv" || ext == ".wmv" || ext == ".mov" || ext == ".mp4")
							return "awesome/file_video_o"
						else if(ext == ".mp3" || ext == ".wma" || ext == ".wav" || ext == ".ogg")
							return "awesome/file_audio_o"
						else if(ext == ".7z" || ext == ".bz2" || ext == ".gz" || ext == ".rar" || ext == ".zip" || ext == ".zipx" || ext == ".tgz")
							return "awesome/file_archive_o"
						else if(ext == ".jpeg" || ext == ".gif" || ext == ".bmp" || ext == ".tiff" || ext == ".png")
							return "awesome/file_image_o"
						else if(ext == ".pptx" || ext == ".ppt")
							return "awesome/file_powerpoint_o"
						else if(ext == ".xlsx")
							return "awesome/file_excel_o"
						else if(ext == ".docx")
							return "awesome/file_word_o"
						else if(ext == ".pdf")
							return "awesome/file_pdf_o"
						else if(ext == ".txt")
							return "awesome/file_text_o"
						else if(ext == ".rscollection")
							return "awesome/files_o"
						else
							return "awesome/file_o"
					}
					else if(model.type == "person")
						return "awesome/user_o"
					else
						return "awesome/question"
				}

				size: parent.height*0.45
			}

			Text {
				id: fileName
				anchors {
					top: fileIcon.bottom
					left: parent.left
					right: parent.right
					topMargin: dp(7)
				}

				clip: true
				color: Material.Theme.light.iconColor
				text: {
					if(location.length > 48)
						return location.slice(0, 41) + "(...)"
					else
						return location
				}

				font.weight: Font.DemiBold
				font.family: "Roboto"
				font.pixelSize: dp(14)*parent.height/170

				wrapMode: TextEdit.WrapAnywhere
				horizontalAlignment: Text.AlignHCenter

				Behavior on color {
					ColorAnimation {
						easing.type: Easing.InOutQuad;
						duration: Material.MaterialAnimation.pageTransitionDuration/2
					}
				}
			}

			Text {
				id: fileSize
				anchors {
					top: fileName.bottom
					left: parent.left
					right: parent.right
					topMargin: dp(3)
				}

				clip: true
				color: Material.Theme.light.iconColor
				text: {
					if(model.type == "folder" || model.type == "person") {
						if(model.contain_folders == 0 && model.contain_files == 0)
							return "empty"
						else if(model.contain_folders == 1 && model.contain_files == 0)
							return "1 folder"
						else if(model.contain_folders > 1 && model.contain_files == 0)
							return model.contain_folders + " folders"
						else if(model.contain_folders == 0 && model.contain_files == 1)
							return "1 file"
						else if(model.contain_folders == 0 && model.contain_files > 1)
							return model.contain_files + " files"
						else if(model.contain_folders == 1 && model.contain_files > 1)
							return "1 folder, " + model.contain_files + " files"
						else if(model.contain_folders > 1 && model.contain_files == 1)
							return model.contain_folders + " folders, " + "1 file"
						else if(model.contain_folders == 1 && model.contain_files == 1)
							return "1 folder, 1 file"
						else if(model.contain_folders > 1 && model.contain_files > 1)
							return model.contain_folders + " folders, " + model.contain_files + " files"
					}
					else if(model.type == "file") {
						if(model.count < 1000)
							return model.count + " B"
						else if(model.count >= 1000 && model.count < 1000000)
							return Math.round(model.count/1000) + " KB"
						else if(model.count >= 1000000 && model.count < 1000000000)
							return Math.round(model.count/1000000) + " MB"
						else if(model.count >= 1000000000 && model.count < 1000000000000)
							return Math.round(model.count/1000000000) + " GB"
					}
				}

				font.weight: Font.DemiBold
				font.family: "Roboto"
				font.pixelSize: dp(12)*parent.height/170

				horizontalAlignment: Text.AlignHCenter

				Behavior on color {
					ColorAnimation {
						easing.type: Easing.InOutQuad;
						duration: Material.MaterialAnimation.pageTransitionDuration/2
					}
				}
			}
		}
	}
}
