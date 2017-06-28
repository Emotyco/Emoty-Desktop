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
	return ( left < right ? -1 : ( left > right ? 1:0 ))
}


function cntcmp(left, right) {
	if(left.identity.name.toLowerCase() !== right.identity.name.toLowerCase())
		return strcmp(left.identity.name.toLowerCase(), right.identity.name.toLowerCase())

	return strcmp(left.identity.gxs_id, right.identity.gxs_id)
}

function parseJSONString(objectArray, jsonPathQuery) {
	if ( jsonPathQuery !== "" )
		objectArray = jsonPath(objectArray, jsonPathQuery)

	return objectArray
}

function parseParticipants(message) {
	var participantsData = JSON.parse(message.response)

	if ( participantsData.data.count === 0 ) {
		message.model.clear()
		return;
	}

	if(message.model.count == 0) {
		participantsData.data.sort(cntcmp)
		var objectArray = parseJSONString(participantsData, message.query);
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
				if(message.model.get(i).identity.gxs_id == el.identity.gxs_id)
					remove = false
			}

			if(remove)
				message.model.remove(i)
		}

		if(message.model.count != dataLen) {
			for ( var ii=0; ii<dataLen; ++ii) {
				var el = jsonData[ii]
				var append = true
				var i

				for(i = 0; i < message.model.count; i++) {
					if(i == 0 && el.identity.name <= message.model.get(i).identity.name) {
						if(el.identity.gxs_id == message.model.get(i).identity.gxs_id)
							append = false

						break
					}
					else if(el.identity.name == message.model.get(i).identity.name) {
						if(el.identity.gxs_id == message.model.get(i).identity.gxs_id)
							append = false

						break
					}
					else if(el.identity.name < message.model.get(i).identity.name
							&& el.identity.name > message.model.get(i-1).identity.name)
						break
				}

				if(append)
					message.model.insert(i, { "identity" : {
						"gxs_id": el.identity.gxs_id,
						"name": el.identity.name
					}})
			}
		}
	}
}

WorkerScript.onMessage = function(message) {
	if(message.action === "refreshParticipants")
		parseParticipants(message)

	message.model.sync()
}
