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

Qt.include("jsonpath.js")

var status
var unread
var gxsModel

function parseJSONString(jsonString, jsonPathQuery) {
	var objectArray = JSON.parse(jsonString)
	if ( jsonPathQuery !== "" )
		objectArray = jsonPath(objectArray, jsonPathQuery)

	return objectArray
}

function parseContacts(message) {
	gxsModel = message.model
	var contactsData = message.response

	if ( contactsData === "" ) {
		message.model.clear()
		return;
	}

	if(message.model.count == 0) {
		var objectArray = parseJSONString(contactsData, message.query);
		for ( var key in objectArray ) {
			var jo = objectArray[key]
			message.model.append( jo )
			message.model.setProperty(message.model.count-1, "state_string", "undefined")
			message.model.setProperty(message.model.count-1, "unread_count", "0")
		}
	}
	else {
		var jsonData = JSON.parse(message.response).data
		var dataLen = jsonData.length

		for(var i = 0; i < message.model.count; i++) {
			var remove = true

			for ( var ii=0; ii<dataLen; ++ii) {
				var el = jsonData[ii]
				if(message.model.get(i).gxs_id == el.gxs_id && el.is_contact)
					remove = false
			}

			if(remove)
				message.model.remove(i)
		}

		if(message.model.count != dataLen) {
			for ( var ii=0; ii<dataLen; ++ii) {
				var el = jsonData[ii]

				if(!el.is_contact)
					continue

				var append = true
				for(var i = 0; i < message.model.count; i++) {
					if(message.model.get(i).gxs_id == el.gxs_id)
						append = false
				}

				if(append)
					message.model.append({
						"gxs_id": el.gxs_id,
						"is_contact": el.is_contact,
						"name": el.name,
						"pgp_id": el.pgp_id,
						"pgp_linked": el.pgp_linked,
						"state_string": "undefined",
						"unread_count": "0"
					})
			}
			parseStatus(status)
			parseUnread(unread)
		}
	}
}

function parseStatus(message) {
	gxsModel = message.model
	status = message

	var jsonData = JSON.parse(message.response).data
	var dataLen = jsonData.length

	for(var i = 0; i < message.model.count; i++) {
		var item = message.model.get(i)

		if(item.pgp_linked) {
			for ( var ii=0; ii<dataLen; ++ii) {
				var el = jsonData[ii]

				if(item.pgp_id == el.pgp_id)
					item.state_string = el.state_string
			}
		}
	}
}

function parseUnread(message) {
	gxsModel = message.model
	unread = message

	var jsonData = JSON.parse(message.response).data
	var dataLen = jsonData.length

	for(var i = 0; i < message.model.count; i++) {
		var item = message.model.get(i)

		var clear = true
		for ( var ii=0; ii<dataLen; ++ii) {
			var el = jsonData[ii]

			if(el.is_distant_chat_id && el.remote_author_id == item.gxs_id) {
				item.unread_count = el.unread_count
				clear = false
			}
		}

		if(clear)
			item.unread_count = "0"
	}
}

function sortContacts() {
	for (var n=0; n < gxsModel.count; n++) {
		for (var i=n+1; i < gxsModel.count; i++) {
			if(gxsModel.get(n).unread_count != gxsModel.get(i).unread_count) {
				if (parseInt(gxsModel.get(n).unread_count) < parseInt(gxsModel.get(i).unread_count)) {
					gxsModel.move(i, n, 1);
					n=0;
					continue
				}
			}
			else if(gxsModel.get(n).pgp_linked != gxsModel.get(i).pgp_linked) {
				if (Boolean(gxsModel.get(n).pgp_linked) < Boolean(gxsModel.get(i).pgp_linked)) {
					gxsModel.move(i, n, 1);
					n=0;
					continue
				}
			}
			else if(gxsModel.get(n).name != gxsModel.get(i).name) {
				if (gxsModel.get(n).name > gxsModel.get(i).name) {
					gxsModel.move(i, n, 1);
					n=0;
				}
			}
		}
	}
}

WorkerScript.onMessage = function(message) {

	if(message.action === "refreshContacts")
		parseContacts(message)
	else if(message.action === "refreshStatus")
		parseStatus(message)
	else if(message.action === "refreshUnread")
		parseUnread(message)

	gxsModel.sync()
	sortContacts()
	gxsModel.sync()
}
