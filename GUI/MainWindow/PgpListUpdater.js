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

function strcmp(left, right) {
	return ( left.name.toLowerCase() < right.name.toLowerCase()
			? -1
			: ( left.name.toLowerCase() > right.name.toLowerCase() ? 1:0 ))
}

function parseJSONString(objectArray, jsonPathQuery) {
	if ( jsonPathQuery !== "" )
		objectArray = jsonPath(objectArray, jsonPathQuery)

	return objectArray
}

function parsePgpList(message) {
	var pgpListData = JSON.parse(message.response)

	if ( pgpListData.data.count === 0 ) {
		message.model.clear()
		return;
	}

	if(message.model.count == 0) {
		pgpListData.data.sort(strcmp)
		var objectArray = parseJSONString(pgpListData, message.query);
		for ( var key in objectArray ) {
			var jo = objectArray[key]
			message.model.append( jo )
		}
	}
	else {
		var jsonData = JSON.parse(message.response).data
		var dataLen = jsonData.length

		for(var i = 0; i < message.model.count; i++) {
			var remove = true

			for ( var ii=0; ii<dataLen; ++ii) {
				var el = jsonData[ii]
				if(message.model.get(i).pgp_id == el.pgp_id) {
					remove = false

					var pgp = message.model.get(i)
					pgp.custom_state_string = el.custom_state_string
					pgp.state_string = el.state_string

					for(var n = 0; n < pgp.locations.count; n++) {
						var removeLoc = true

						for(var nn = 0; nn < el.locations.length; nn++) {
							var loc = el.locations[nn]

							if(pgp.locations.get(n).peer_id == loc.peer_id) {
								removeLoc = false

								var pgpLoc = pgp.locations.get(n)
								pgpLoc.avatar_address = loc.avatar_address
								pgpLoc.chat_id = loc.chat_id
								pgpLoc.custom_state_string = loc.custom_state_string
								pgpLoc.groups = loc.groups
								pgpLoc.is_online = loc.is_online
								pgpLoc.location = loc.location
								pgpLoc.state_string = loc.state_string
								pgpLoc.unread_msgs = loc.unread_msgs

								break
							}
						}

						if(removeLoc)
							pgp.locations.remove(n)
					}

					if(pgp.locations.count != el.locations.length) {
						for ( var nn=0; nn<el.locations.length; ++nn) {
							var loc = el.locations[nn]
							var appendLoc = true

							for(var n = 0; n < pgp.locations.count; n++) {
								if(pgp.locations.get(n).peer_id == loc.peer_id) {
									appendLoc = false
									break
								}
							}

							if(appendLoc)
								pgp.locations.append({
									"avatar_address": loc.avatar_address,
									"chat_id": loc.chat_id,
									"custom_state_string": loc.custom_state_string,
									"groups": loc.groups,
									"is_online": loc.is_online,
									"location": loc.location,
									"state_string": loc.state_string,
									"unread_msgs": loc.unread_msgs,
									"name": loc.name,
									"peer_id": loc.peer_id,
									"pgp_id": loc.pgp_id
								})
						}
					}

					break
				}
			}

			if(remove)
				message.model.remove(i)
		}

		if(message.model.count != dataLen) {
			for ( var ii=0; ii<dataLen; ++ii) {
				var el = jsonData[ii]
				var append = true

				for(var i = 0; i < message.model.count; i++) {
					if(message.model.get(i).pgp_id == el.pgp_id) {
						append = false
						break
					}
				}

				if(append)
					message.model.append({
						"custom_state_string": el.custom_state_string,
						"is_own": el.is_own,
						"name": el.name,
						"pgp_id": el.pgp_id,
						"state_string": el.state_string,
						"locations": []
					})
			}
		}
	}
}

WorkerScript.onMessage = function(message) {
	if(message.action === "refreshPgpList")
		parsePgpList(message)

	message.model.sync()
}
