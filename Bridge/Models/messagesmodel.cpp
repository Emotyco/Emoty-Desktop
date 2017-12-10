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
#include "messagesmodel.h"

#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonValue>
#include <QJsonArray>

void MessagesModel::loadJSONMessages(QString json)
{
	QJsonObject qJsonObject = QJsonDocument::fromJson(json.toUtf8()).object();
	QJsonValue jsData = qJsonObject.value("data");

	if(!jsData.isNull() && jsData.isArray() && !jsData.toArray().isEmpty())
	{
		QJsonArray jsDataArray = jsData.toArray();

		if(messageData.empty())
		{
			QString author_id_previous = "";
			QModelIndex qModelIndex;
			beginInsertRows(qModelIndex, 0, jsDataArray.size()-1);
			for(QJsonArray::iterator it = jsDataArray.begin(); it != jsDataArray.end(); it++)
			{
				QJsonObject jsonMessage = (*it).toObject();

				if(!messageData.empty()
				        && messageData.back().author_id == jsonMessage.value("author_id").toString())
					messageData.back().last_from_author = false;

				messageData.emplace_back(Message(
				                            jsonMessage.value("author_id").toString(),
				                            jsonMessage.value("author_name").toString(),
				                            jsonMessage.value("id").toString(),
				                            jsonMessage.value("incoming").toBool(),
				                            jsonMessage.value("msg").toString(),
				                            jsonMessage.value("recv_time").toString(),
				                            jsonMessage.value("send_time").toString(),
				                            jsonMessage.value("was_send").toBool(),
				                            author_id_previous,
				                            true
				                        ));
				author_id_previous = jsonMessage.value("author_id").toString();
			}
			endInsertRows();
		}
		else
		{
			int i = 0;
			for(std::list<Message>::iterator vit = messageData.begin(); vit != messageData.end(); vit++)
			{
				for(QJsonArray::iterator it = jsDataArray.begin(); it != jsDataArray.end(); it++)
				{
					QJsonObject jsonMessage = (*it).toObject();
					if((*vit).msg_id == jsonMessage.value("id").toString()
					        && (*vit).was_send != jsonMessage.value("was_send").toBool())
					{
						(*vit).was_send = jsonMessage.value("was_send").toBool();
						(*vit).send_time = jsonMessage.value("send_time").toString();
						emit dataChanged(index(i),index(i));
					}
				}
				i++;
			}

			for(QJsonArray::iterator it = jsDataArray.begin(); it != jsDataArray.end(); it++)
			{
				QJsonObject jsonMessage = (*it).toObject();

				bool found = false;
				for(std::list<Message>::iterator vit = messageData.begin(); vit != messageData.end(); ++vit)
				{
					if((*vit).msg_id == jsonMessage.value("id").toString()) {
						found = true;
						break;
					}
				}

				if(!found)
				{
					if(!messageData.empty()
					        && messageData.back().author_id == jsonMessage.value("author_id").toString())
					{
						messageData.back().last_from_author = false;
						emit dataChanged(index(messageData.size()-1),index(messageData.size()-1));
					}

					QModelIndex qModelIndex;
					beginInsertRows(qModelIndex, messageData.size(), messageData.size());
					messageData.emplace_back(Message(
					                            jsonMessage.value("author_id").toString(),
					                            jsonMessage.value("author_name").toString(),
					                            jsonMessage.value("id").toString(),
					                            jsonMessage.value("incoming").toBool(),
					                            jsonMessage.value("msg").toString(),
					                            jsonMessage.value("recv_time").toString(),
					                            jsonMessage.value("send_time").toString(),
					                            jsonMessage.value("was_send").toBool(),
					                            messageData.rbegin()->author_id,
					                            true
					                          ));
					endInsertRows();
				}
			}
		}
	}
}

int MessagesModel::rowCount(const QModelIndex &) const
{
	return messageData.size();
}

QVariant MessagesModel::data(const QModelIndex & index, int role) const
{
	int idx = index.row();

	if(idx < 0 || idx >= messageData.size())
		return QVariant("Something went wrong...");

	std::list<Message>::const_iterator vit = messageData.begin();
	for(int i = 0; vit != messageData.end(); ++vit)
	{
		if ( idx == i)
			break;

		++i;
	}

	if(role == AuthorIdRole)
		return (*vit).author_id;
	else if(role == AuthorNameRole)
		return (*vit).author_name;
	else if(role == MsgIdRole)
		return (*vit).msg_id;
	else if(role == IncomingRole)
		return (*vit).incoming;
	else if(role == MsgContentRole)
		return (*vit).msg_content;
	else if(role == RecvTimeRole)
		return (*vit).recv_time;
	else if(role == SendTimeRole)
		return (*vit).send_time;
	else if(role == WasSendRole)
		return (*vit).was_send;
	else if(role == AuthorIdPreviousRole)
		return (*vit).author_id_previous;
	else if(role == LastFromAuthor)
		return (*vit).last_from_author;

	return QVariant();
}

QHash<int, QByteArray> MessagesModel::roleNames() const
{
	QHash<int, QByteArray> roles;

	roles[AuthorIdRole] = "author_id";
	roles[AuthorNameRole] = "author_name";
	roles[MsgIdRole] = "msg_id";
	roles[IncomingRole] = "incoming";
	roles[MsgContentRole] = "msg_content";
	roles[RecvTimeRole] = "recv_time";
	roles[SendTimeRole] = "send_time";
	roles[WasSendRole] = "was_send";
	roles[AuthorIdPreviousRole] = "author_id_previous";
	roles[LastFromAuthor] = "last_from_author";

	return roles;
}
