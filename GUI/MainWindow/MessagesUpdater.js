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

function parseJSONString(objectArray, jsonPathQuery) {
	if ( jsonPathQuery !== "" )
		objectArray = jsonPath(objectArray, jsonPathQuery)

	return objectArray
}

function parseMessages(message) {
	var messagesData = JSON.parse(message.response)

	if ( messagesData.data.count === 0 ) {
		message.model.clear()
		return;
	}

	if(message.model.count == 0) {
		var objectArray = parseJSONString(messagesData, message.query);
		for ( var key in objectArray ) {
			var jo = objectArray[key]
			message.model.append( jo )
		}
	}
	else {
		var jsonData = JSON.parse(message.response).data
		var dataLen = jsonData.length

		if(message.model.count != dataLen) {
			for ( var ii=0; ii<dataLen; ++ii) {
				var el = jsonData[ii]
				var append = true

				for(var i = 0; i < message.model.count; i++) {
					if(el.id == message.model.get(i).id) {
						append = false
						break
					}
				}

				if(append)
					message.model.append({
						"author_id": el.author_id,
						"author_name": el.author_name,
						"id": el.id,
						"incoming": el.incoming,
						"msg": el.msg,
						"recv_time": el.recv_time,
						"send_time": el.send_time,
						"was_send": el.was_send,
					})
			}
		}
	}
}

WorkerScript.onMessage = function(message) {
	if(message.action === "refreshMessages")
		parseMessages(message)

	message.model.sync()
	WorkerScript.sendMessage("Updated")
}
