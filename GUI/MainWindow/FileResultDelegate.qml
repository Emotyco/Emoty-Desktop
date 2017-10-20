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

Component {
	Item {
		property string modelName: GridView.view.model.objectName

		width: GridView.view.cellWidth
		height: GridView.view.cellHeight

		Item {
			anchors.centerIn: parent
			width: parent.GridView.view.idealCellWidth - 10
			height: parent.height - 10

			clip: true

			MouseArea {
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
					if(model.type == "file" && (modelName == "friendsFiles" || modelName == "friendsSearchResult" || modelName == "distantSearchResult")) {
						var downloadData = {
							action: "begin",
							hash: model.hash,
							name: model.name,
							size: model.count
						}

						rsApi.request("/transfers/control_download/", JSON.stringify(downloadData), function(){})
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

				name: "awesome/file_o"
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
					if(model.virtual_name.length > 48)
						return model.virtual_name.slice(0, 41) + "(...)"
					else
						return model.virtual_name
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
