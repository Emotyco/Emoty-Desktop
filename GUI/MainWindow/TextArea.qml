/****************************************************************
 *  This file is part of Sonet.
 *  Sonet is distributed under the following license:
 *
 *  Copyright (C) 2017, Konrad Dębiec
 *
 *  Sonet is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU General Public License
 *  as published by the Free Software Foundation; either version 3
 *  of the License, or (at your option) any later version.
 *
 *  Sonet is distributed in the hope that it will be useful,
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
import QtQuick.Controls 1.4 as Controls
import Material 0.3

Controls.TextArea {
	id: textArea

	property color color: Theme.accentColor
	property color errorColor: Palette.colors["red"]["500"]
	property string placeholderText

	style: TextAreaStyle {}

	Text {
		id: fieldPlaceholder

		anchors {
			fill: parent
			margins: 3.3 * Units.dp
		}

		text: placeholderText
		color: Theme.light.hintColor

		font {
			pixelSize: textArea.font.pixelSize
			family: "Roboto"
		}

		wrapMode: Text.WrapAnywhere
		textFormat: textArea.textFormat

		states: [
			State {
				name: "hidden"; when: textArea.text.length > 0
				PropertyChanges {
					target: fieldPlaceholder
					visible: false
				}
			}
		]
	}
}
