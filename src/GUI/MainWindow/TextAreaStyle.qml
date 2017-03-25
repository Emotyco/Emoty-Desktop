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
import QtQuick.Controls.Styles 1.3
import Material 0.3

TextAreaStyle {
	padding {
		left: 0
		right: 0
		top: 0
		bottom: 0
	}

	font {
		family: "Roboto"
		pixelSize: 16 * Units.dp
	}

	textColor: Theme.light.textColor
	renderType: Text.QtRendering

	selectedTextColor: "white"
	selectionColor: control.hasOwnProperty("color") ? control.color : Theme.accentColor
}
