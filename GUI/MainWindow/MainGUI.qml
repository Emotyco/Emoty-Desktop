/****************************************************************
 *  This file is part of Emoty.
 *  Emoty is distributed under the following license:
 *
 *  Copyright (C) 2017, Konrad Dębiec
 *  Copyright (C) 2017, Gioacchino Mazzurco <gio@eigenlab.org>
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
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.2

import Material 0.3 as Material

import CardsModel 0.2

Rectangle {
	id: mainGUIObject

	property bool borderless: false
	property bool haveOwnIdFirstTime: true

	property bool advmode
	property bool flickablemode

	property bool loadMask: true

	property string defaultGxsName
	property string defaultGxsId
	property string defaultAvatar: "none"

	property int unreadMsgsLobbies: 0

	property int visibleRows: Math.round((mainGUIObject.height-dp(30))/(dp(50) + gridLayout.rowSpacing))
	property alias gridLayout: gridLayout
	property alias cardsModel: cardsModel

	signal gridChanged

	color: Material.Palette.colors["grey"]["200"]

	states:[
		State {
			name: "waiting_account_select"
			StateChangeScript {
				script: {
					runStateHelper.setRunState("waiting_account_select")
					Qt.quit()
				}
			}
		},
		State {
			name: "running_ok"
			StateChangeScript {
				script: {
					runStateHelper.setRunState("running_ok")
				}
			}
		},
		State {
			name: "running_ok_no_full_control"
			StateChangeScript {
				script: {
					runStateHelper.setRunState("running_ok_no_full_control")
				}
			}
		},
		State {
			name: "fatal_error"
			StateChangeScript {
				script: {
					runStateHelper.setRunState("fatal_error")
					Qt.quit()
				}
			}
		},
		State {
			name: "waiting_startup"
			StateChangeScript {
				script: {
					runStateHelper.setRunState("waiting_startup")
				}
			}
		},
		State {
			name: "waiting_init"
			StateChangeScript {
				script: {
					runStateHelper.setRunState("waiting_init")
					Qt.quit()
				}
			}
		}
	]

	Component.onCompleted: {
		updateVisibleRows()
		getOwnIdentities()
		getRunState()
		getAdvancedMode()
		getFlickableGridMode()
		getRoomInvitations()
		getUnreadedMessages()
	}

	onDefaultGxsIdChanged: mainGUIObject.getDefaultAvatar()

	// For handling tokens
	property int stateToken_ownGxs: 0
	property int stateToken_unreadMsgs: 0
	property int stateToken_invitations: 0

	function getUnreadedMessages() {
		function callbackFn(par) {
			var jsonResp = JSON.parse(par.response)
			stateToken_unreadMsgs = jsonResp.statetoken
			mainGUIObject.registerToken(stateToken_unreadMsgs, getUnreadedMessages)

			notifier.handleChatMessages(par.response)
		}

		rsApi.request("/chat/unread_msgs/", "", callbackFn)
	}

	function getOwnIdentities() {
		var jsonData = {
			callback_name: "maingui_identity_own_ids"
		};

		function callbackFn(par) {
			ownGxsIdModel.json = par.response; haveOwnId()

			stateToken_ownGxs = JSON.parse(par.response).statetoken
			mainGUIObject.registerToken(stateToken_ownGxs, getOwnIdentities)
		}

		rsApi.request("/identity/own_ids/", JSON.stringify(jsonData), callbackFn)
	}

	function getRunState() {
		var jsonData = {
			callback_name: "maingui_control_runstate"
		};

		function callbackFn(par) {
			mainGUIObject.state = String(JSON.parse(par.response).data.runstate)
		}

		var ret = rsApi.request("/control/runstate/", JSON.stringify(jsonData), callbackFn)
		if(ret < 1)
			mainGUIObject.state = "fatal_error"
	}

	function getAdvancedMode() {
		var jsonData = {
			callback_name: "maingui_get_advanced_mode"
		};

		function callbackFn(par) {
			mainGUIObject.advmode = Boolean(JSON.parse(par.response).data.advanced_mode)
			notifier.setAdvMode(Boolean(JSON.parse(par.response).data.advanced_mode))
		}

		rsApi.request("/settings/get_advanced_mode/", JSON.stringify(jsonData), callbackFn)
	}

	function getFlickableGridMode() {
		var jsonData = {
			callback_name: "maingui_get_flickable_grid_mode"
		};

		function callbackFn(par) {
			mainGUIObject.flickablemode = Boolean(JSON.parse(par.response).data.flickable_grid_mode)
		}

		rsApi.request("/settings/get_flickable_grid_mode/", JSON.stringify(jsonData), callbackFn)
	}

	function haveOwnId() {
		if (ownGxsIdModel.count === 0 && haveOwnIdFirstTime) {
			var component = Qt.createComponent("CreateIdentity.qml");
			if (component.status === Component.Ready) {
				var createId = component.createObject(mainGUIObject);
				createId.show();
			}
			haveOwnIdFirstTime = false;
		}
	}

	function getDefaultAvatar() {
		if(gxs_avatars.getAvatar(defaultGxsId) == "") {
			var jsonData = {
				gxs_id: defaultGxsId
			}

			function callbackFn(par) {
				var json = JSON.parse(par.response)
				if(json.returncode == "fail") {
					getDefaultAvatar()
					return
				}

				gxs_avatars.storeAvatar(defaultGxsId, json.data.avatar)
				defaultAvatar = gxs_avatars.getAvatar(defaultGxsId)
			}

			rsApi.request("/identity/get_avatar", JSON.stringify(jsonData), callbackFn)
		}
		else
			defaultAvatar = gxs_avatars.getAvatar(defaultGxsId)
	}

	function getRoomInvitations() {
		function callbackFn(par) {
			var jsonResp = JSON.parse(par.response)
			stateToken_invitations = jsonResp.statetoken
			mainGUIObject.registerToken(stateToken_invitations, getRoomInvitations)

			if(jsonResp.data.length > 0)
				for(var i = 0; i < jsonResp.data.length; i++)
				{
					var lobbyId = jsonResp.data[i].lobby_id
					confirmationDialog.show("You has been invited to room '"+ jsonResp.data[i].lobby_name + "'. Do you want to join?",
						function() {
							var jsonData = {
								lobby_id: lobbyId,
								join: true,
								gxs_id: defaultGxsId
							}

							rsApi.request("/chat/answer_to_invitation", JSON.stringify(jsonData), function(){})
						},function() {
							var jsonData = {
								lobby_id: lobbyId,
								join: false,
								gxs_id: defaultGxsId
							}

							rsApi.request("/chat/answer_to_invitation", JSON.stringify(jsonData), function(){})
						},
						"Join", "Ignore", false
					)
				}
		}

		rsApi.request("/chat/get_invitations_to_lobby", "", callbackFn)
	}

	function getDefaultIdentity() {
		function callbackFn(par) {
			var json = JSON.parse(par.response)
			if(json.returncode == "fail") {
				getDefaultIdentity()
				return
			}

			defaultGxsId = json.data.gxs_id
			for(var i = 0; i < ownGxsIdModel.count; i++) {
				if(ownGxsIdModel.model.get(i).own_gxs_id == defaultGxsId)
					defaultGxsName = ownGxsIdModel.model.get(i).name
			}

			getDefaultAvatar()
		}

		rsApi.request("/chat/get_default_identity_for_chat_lobby", "", callbackFn)
	}

	function setDefaultIdentity(gxs_id) {
		var jsonData = {
			gxs_id: gxs_id
		}

		function callbackFn(par) {
			getDefaultIdentity()
		}

		rsApi.request("/chat/set_default_identity_for_chat_lobby", JSON.stringify(jsonData), callbackFn)
	}

	Connections {
		target: view
		onHeightChanged: gridLayout.reorder()
		onWidthChanged: gridLayout.reorder()
	}

	Connections {
		target: gxsModel
		onChooseIdentities: identitiesSelectionDialog.showDialog(identities)
	}

	JSONListModel {
		id: ownGxsIdModel

		query: "$.data[*]"

		model.onCountChanged: {
			getDefaultIdentity()
		}
	}

	Material.AppTheme {
		primaryColor: Material.Palette.colors["green"]["500"]
		accentColor: Material.Palette.colors["deepOrange"]["500"]
		tabHighlightColor: "white"
	}

	Rectangle {
		id: loadingMask

		anchors.fill: parent

		color: Qt.rgba(0,0,0,0.4)
		z: 20

		state: mainGUIObject.loadMask ? "visible" : "invisible"

		states:[
			State {
				name: "visible"
				PropertyChanges {
					target: loadingMask
					enabled: true
					opacity: 1
				}
			},
			State {
				name: "invisible"
				PropertyChanges {
					target: loadingMask
					enabled: false
					opacity: 0
				}
			}
		]

		transitions: [
			Transition {
				NumberAnimation {
					property: "opacity"
					easing.type: Easing.InOutQuad
					duration: 250*2
				}
			}
		]

		MouseArea {
			anchors.fill: parent

			hoverEnabled: true
			onClicked: {
				if(mouse.button == Qt.LeftButton && borderless)
					qMainPanel.mouseLPressed()
			}
			onPressed: {
				if(mouse.button == Qt.LeftButton && borderless)
					qMainPanel.mouseLPressed()
			}
		}

		Rectangle {
			anchors.fill: parent

			color: Qt.rgba(1,1,1,0.85)

			Image {
				id: logoMask

				anchors.centerIn: parent
				height: parent.height*0.3
				width: parent.width*0.3

				source: "/logo.png"
				fillMode: Image.PreserveAspectFit
				mipmap: true
			}

			Material.ProgressCircle {
				anchors {
					top: logoMask.bottom
					horizontalCenter: parent.horizontalCenter
				}

				width: dp(35)
				height: dp(35)
				dashThickness: dp(5)

				color: Material.Theme.primaryColor
			}
		}
	}

	MouseArea {
		property bool controlPressed

		anchors.fill: parent

		z: -1
		focus: true
		acceptedButtons: Qt.MidButton | Qt.LeftButton

		Keys.onPressed: {
			if(event.key == Qt.Key_Control)
				controlPressed = true
		}

		Keys.onReleased: {
			if(event.key == Qt.Key_Control)
				controlPressed = false
		}

		onClicked: {
			mouse.accepted = false
			focus = true
		}

		onPressed: {
			mouse.accepted = false
			focus = true
		}

		onWheel: {
			wheel.accepted = false
			if(controlPressed)
				if(wheel.angleDelta.y > 0 && Units.multiplier < 2) {
					Units.setMultiplier(Units.multiplier+0.1)
					wheel.accepted = true
				}
				else if(wheel.angleDelta.y < 0 && Units.multiplier > 0.2) {
					Units.setMultiplier(Units.multiplier-0.1)
					wheel.accepted = true
				}
		}
	}

	Image {
		anchors {
			left: leftBar.right
			right: rightBar.left
			bottom: parent.bottom
			top: parent.top
		}

		asynchronous: true
		source: "/wallpaper_grey.jpg"
		fillMode: Image.PreserveAspectCrop
	}

	LeftBar {
		id: leftBar2
		z:1
	}

	Rectangle {
		id: mainGUImask

		anchors {
			left: leftBar2.right
			top: parent.top
			right: parent.right
			bottom: parent.bottom
		}

		color: Qt.rgba(0, 0, 0, 0.3)
		z: 3

		state: "non-visible"

		states: [
			State {
				name: "visible"; when: leftBar2.state === "wide"
				PropertyChanges {
					target: mainGUImask
					enabled: true
					opacity: 1
				}
			},
			State {
				name: "non-visible"; when: leftBar2.state !== "wide"
				PropertyChanges {
					target: mainGUImask
					enabled: false
					opacity: 0
				}
			}
		]

		transitions: [
			Transition {
				from: "visible"; to: "non-visible";
				SequentialAnimation {
					NumberAnimation {
						target: mainGUImask;
						property: "opacity";
						easing.type: Easing.InOutQuad;
						duration: Material.MaterialAnimation.pageTransitionDuration
					}
					PropertyAction {
						target: mainGUImask;
						property: "visible";
						value: false
					}
				}
			},
			Transition {
				from: "non-visible"; to: "visible";
				SequentialAnimation {
					PropertyAction {
						target: mainGUImask;
						property: "visible";
						value: true
					}
					NumberAnimation {
						target: mainGUImask;
						property: "opacity";
						easing.type: Easing.InOutQuad;
						duration: Material.MaterialAnimation.pageTransitionDuration
					}
				}
			}
		]

		MouseArea {
			anchors.fill: parent

			acceptedButtons: Qt.AllButtons
			hoverEnabled: true

			onClicked: leftBar2.state = "narrow"
			onPressAndHold: {}
			onEntered: {}
			onExited: {}
		}
	}

	Item {
		id: leftBar

		anchors {
			top: parent.top
			left: parent.left
			bottom: parent.bottom
		}

		width: dp(50)
	}

	RightBar {
		id: rightBar
		z:1
	}

	Flickable {
		id: flickable

		anchors {
			left: leftBar.right
			right: rightBar.left
			top: parent.top
			bottom: parent.bottom
		}

		clip: true
		interactive: flickablemode
		contentHeight: Math.max(gridLayout.implicitHeight + dp(40), height)

		GridLayout {
			id: gridLayout

			property int h: (mainGUIObject.height-dp(30))
			property int rowspace: parseInt(h/dp(50))

			property alias gridRepeater: gridRepeater

			function reorder() {
				for (var i=0;i<(children.length - 751);i++) {
					children[751 + i].refresh()
				}
			}

			anchors {
				fill: parent
				margins: dp(15)
			}

			columns: parseInt(gridLayout.width / dp(60))
			columnSpacing: dp(10)
			rowSpacing: h<dp(650) ? (h-((rowspace-1)*dp(50)))/(rowspace-2)
							  : (h-((rowspace-2)*dp(50)))/(rowspace-3)

			onColumnsChanged: mainGUIObject.gridChanged()

			Repeater {
				id: gridRepeater

				signal activeGrid
				signal nonActiveGrid

				model: 750
				delegate: DropTile {}

				Layout.alignment: Qt.AlignTop
			}
		}
	}

	Material.Scrollbar {
		flickableItem: flickable
	}

	Material.OverlayLayer {
		id: dialogOverlayLayer
		objectName: "dialogOverlayLayer"
		z: 10
	}

	Material.OverlayLayer {
		id: tooltipOverlayLayer
		objectName: "tooltipOverlayLayer"
		z:5
	}

	Material.OverlayLayer {
		id: overlayLayer
		z: 11
	}

	// Dialog Pop-ups

	DialogExit {
		id: exitDialog

		text: "Do you want to exit?"

		positiveButtonText: "Yes"
		negativeButtonText: "No"

		onAccepted: {
			function callbackFn(par) {
				Qt.quit()
			}

			rsApi.request("/control/shutdown/", "", callbackFn)
		}
	}

	ConfirmationDialog {
		id: confirmationDialog
	}

	SizeConfirmationDialog {
		id: sizeConfirmationDialog
	}

	PGPFriendDetailsDialog {
		id: pgpFriendDetailsDialog
	}

	NodeDetailsDialog {
		id: nodeDetailsDialog
	}

	IdentityDetailsDialog {
		id: identityDetailsDialog
	}

	SettingsDialog {
		id: settingsDialog
	}

	UserAddDialog {
		id: userAddDialog
	}

	IdentitiesSelectionDialog {
		id: identitiesSelectionDialog
	}

	function updateVisibleRows() {
		mainGUIObject.visibleRows = Qt.binding(function() {
			return Math.round((mainGUIObject.height-dp(30))/(dp(50) + gridLayout.rowSpacing))
		});
	}

	///////
	// Code made by Gioacchino Mazzurco
	// Github: https://github.com/G10h4ck

	property var tokens: ({})

	function registerToken(token, callback)
	{
		if (Array.isArray(tokens[token]))
			tokens[token].push(callback)
		else
			tokens[token] = [callback]
	}

	function isTokenValid(token) {
		return Array.isArray(tokens[token])
	}

	function checkTokens(par)
	{
		var jsonData = JSON.parse(par.response).data
		var arrayLength = jsonData.length;
		for (var i = 0; i < arrayLength; i++)
			mainGUIObject.tokenExpire(jsonData[i])
	}

	//
	//////

	function tokenExpire(token) {
		if(Array.isArray(tokens[token]))
		{
			tokens[token].forEach(function(tok) {
				if (typeof tok == 'function')
					tok()
				else {
					if(Array.isArray(tok)) {
						tok.forEach(function(cardFunc) {
							if (typeof cardFunc == 'function')
								cardFunc()
						});
					}
				}
			});
		}

		delete tokens[token]
	}

	function registerTokenWithIndex(token, callback, cardIndex) {
		if(!Array.isArray(tokens[token]))
			tokens[token] = new Array(cardIndex)

		if (Array.isArray(tokens[token][cardIndex]))
			tokens[token][cardIndex].push(callback)
		else
			tokens[token][cardIndex] = [callback]
	}

	function unregisterToken(token) {
		delete tokens[token]
	}

	function unregisterTokenWithIndex(token, cardIndex) {
		try {
			if(typeof tokens[token][cardIndex] !== 'undefined')
				delete tokens[token][cardIndex]
		} catch (e) {
			console.log(e.stack);
		}
	}

	/*
	  All new cards (panels) are instatiated in these fucntions,
	  becouse creation context is the QQmlContext in which Qt.createComponent method is called.
	  If it would be created e.g. in FriendListDelegate we could lost access to new created objects.
	  (We couldn't e.g. click on mousearea in new created objects)
	  */

	CardsModel {
		id: cardsModel
	}
	signal cardCreated

	function raiseCard(index) {
		for(var i = 0; i != cardsModel.rowCount(); i++)
		{
			var card = cardsModel.getCardByListIndex(i);
			if(card.cardIndex == index) {
				card.z = 20
				card.isRaised = true
			}
			else{
				card.z = card.z == 0 ? 0 : --card.z
				card.isRaised = false
			}
		}
	}

	function removeCard(index) {
		cardsModel.removeCard(index)

		if(cardsModel.rowCount() != 0) {
			var highestCard = cardsModel.getCardByListIndex(0)
			for(var i = 0; i != cardsModel.rowCount(); i++)
			{
				var card = cardsModel.getCardByListIndex(i);
				if(card.z > highestCard.z) {
					highestCard = card
				}
			}
			raiseCard(highestCard.cardIndex)
		}
	}

	function createRoomCard(roomName, chatId) {
		var component = Qt.createComponent("RoomCard.qml", gridLayout);
		if (component.status === Component.Ready) {
			var roomCard = component.createObject(gridLayout,
											  {"headerName": roomName,
												"chatId": chatId});

			roomCard.cardIndex = cardsModel.storeCard(roomCard, roomName, true, "awesome/comments_o", roomCard.indicatorNumber)
			raiseCard(roomCard.cardIndex)
			cardCreated()

			updateVisibleRows()
			gridLayout.reorder()
		}
	}

	function createFileSharingCard() {
		var component = Qt.createComponent("FileSharingCard.qml", gridLayout);
		if (component.status === Component.Ready) {
			var fsCard = component.createObject(gridLayout,
											  {"headerName": "File Sharing"});

			fsCard.cardIndex = cardsModel.storeCard(fsCard, "File Sharing", true, "awesome/folder_o", fsCard.indicatorNumber)
			raiseCard(fsCard.cardIndex)
			cardCreated()

			updateVisibleRows()
			gridLayout.reorder()
		}
	}

	function createChatGxsCard(chatId, friendname, gxsid, objectName) {
		var component = Qt.createComponent(objectName, gridLayout);
		if (component.status === Component.Ready) {
			var chat = component.createObject(gridLayout,
											  {"headerName": friendname,
												"gxsId": gxsid,
												"chatId": chatId});

			var avatar = gxs_avatars.getAvatar(gxsid)
			chat.cardIndex = cardsModel.storeCard(chat, friendname, avatar == "none", avatar == "none" ? "awesome/user_o" : avatar, chat.indicatorNumber)
			raiseCard(chat.cardIndex)
			cardCreated()

			updateVisibleRows()
			gridLayout.reorder()
		}
	}

	function createChatPeerCard(friendname, location, rspeerid, chat_id, objectName) {
		var component = Qt.createComponent(objectName, gridLayout);
		if (component.status === Component.Ready) {
			var chat = component.createObject(gridLayout,
											  {"headerName": friendname + "@" + location,
											   "chatId": chat_id,
											   "rsPeerId": rspeerid});

			chat.cardIndex = cardsModel.storeCard(chat, friendname + "@" + location, true, "awesome/user", chat.indicatorNumber)
			raiseCard(chat.cardIndex)
			cardCreated()

			updateVisibleRows()
			gridLayout.reorder()
		}
	}

	Timer {
		interval: 5000
		running: true
		repeat: true
		onTriggered: {
			getRunState()
		}
	}

	Timer {
		interval: 500
		running: true
		repeat: true
		onTriggered: {
			rsApi.request("/statetokenservice/*", '['+Object.keys(mainGUIObject.tokens)+']', checkTokens)
		}
	}

	// Units
	function dp(dp) {
		return dp * Material.Units.dp
	}

	function gu(gu) {
		return units.gu(gu)
	}

	Material.UnitsHelper {
		id: units
	}
}
