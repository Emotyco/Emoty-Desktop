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
#include "roomparticipantsmodel.h"

#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonValue>
#include <QJsonArray>

void RoomParticipantsModel::loadJSONParticipants(QString json)
{
	QJsonObject qJsonObject = QJsonDocument::fromJson(json.toUtf8()).object();

	if(participantsStateToken == qJsonObject.value("statetoken").toInt())
		return;

	participantsStateToken = qJsonObject.value("statetoken").toInt();

	QJsonValue jsData = qJsonObject.value("data");
	if(!jsData.isNull() && jsData.isArray())
	{
		QJsonArray jsDataArray = jsData.toArray();

		if(identitiesData.empty())
		{
			for(QJsonArray::iterator it = jsDataArray.begin(); it != jsDataArray.end(); it++)
			{
				QJsonObject jsonContact = (*it).toObject().value("identity").toObject();

				identitiesData.emplace_back(Identity(
				                              jsonContact.value("name").toString(),
				                              jsonContact.value("gxs_id").toString(),
				                              "",
				                              false,
				                              false
				                              ));
			}

			beginResetModel();
			endResetModel();
		}
		else
		{
			int i = 0;
			for(std::list<Identity>::iterator vit = identitiesData.begin(); vit != identitiesData.end(); ++vit)
			{
				bool found = false;
				for(QJsonArray::iterator it = jsDataArray.begin(); it != jsDataArray.end(); it++)
				{
					QJsonObject jsonContact = (*it).toObject().value("identity").toObject();
					if((*vit).gxs_id == jsonContact.value("gxs_id").toString())
						found = true;
				}

				if(!found)
				{
					QModelIndex qModelIndex;
					beginRemoveRows(qModelIndex, i, i);
					identitiesData.erase(vit);
					endRemoveRows();
				}
				i++;
			}

			for(QJsonArray::iterator it = jsDataArray.begin(); it != jsDataArray.end(); it++)
			{
				QJsonObject jsonContact = (*it).toObject().value("identity").toObject();

				bool found = false;
				for(std::list<Identity>::iterator vit = identitiesData.begin(); vit != identitiesData.end(); ++vit)
				{
					if((*vit).gxs_id == jsonContact.value("gxs_id").toString())
						found = true;
				}

				if(!found)
				{
					QModelIndex qModelIndex;
					beginInsertRows(qModelIndex, identitiesData.size(), identitiesData.size());
					identitiesData.emplace_back(Identity(
					                              jsonContact.value("name").toString(),
					                              jsonContact.value("gxs_id").toString(),
					                              "",
					                              false,
					                              false
					                              ));
					endInsertRows();
				}
			}
		}
	}
}

void RoomParticipantsModel::loadJSONIdentities(QString json)
{
	QJsonObject qJsonObject = QJsonDocument::fromJson(json.toUtf8()).object();

	if(identitiesStateToken == qJsonObject.value("statetoken").toInt())
		return;

	identitiesStateToken = qJsonObject.value("statetoken").toInt();

	QJsonValue jsData = qJsonObject.value("data");
	if(!jsData.isNull() && jsData.isArray())
	{
		QJsonArray jsDataArray = jsData.toArray();

		int i = 0;
		for(std::list<Identity>::iterator vit = identitiesData.begin(); vit != identitiesData.end(); ++vit)
		{
				for(QJsonArray::iterator it = jsDataArray.begin(); it != jsDataArray.end(); it++)
				{
					QJsonObject jsonIdentity = (*it).toObject();

					if ((*vit).gxs_id == jsonIdentity.value("gxs_id").toString())
					{
						(*vit).is_contact = jsonIdentity.value("is_contact").toBool();
						(*vit).is_own = jsonIdentity.value("own").toBool();
						emit dataChanged(index(i),index(i));
					}
				}
			i++;
		}
	}
}

void RoomParticipantsModel::loadJSONAvatar(QString gxs_id, QString json)
{
	QJsonObject qJsonObject = QJsonDocument::fromJson(json.toUtf8()).object();
	QJsonValue jsData = qJsonObject.value("data");

	if(!jsData.isNull())
	{
		QJsonObject jsDataObject = jsData.toObject();

		int i = 0;
		for(std::list<Identity>::iterator vit = identitiesData.begin(); vit != identitiesData.end(); ++vit)
		{
			if ((*vit).gxs_id == gxs_id)
			{
				(*vit).avatar = jsDataObject.value("avatar").toString();
				emit dataChanged(index(i),index(i));
			}
			i++;
		}
	}
}

int RoomParticipantsModel::rowCount(const QModelIndex & parent) const
{
	return identitiesData.size();
}

QVariant RoomParticipantsModel::data(const QModelIndex & index, int role) const
{
	int idx = index.row();

	if(idx < 0 || idx >= identitiesData.size())
		return QVariant("Something went wrong...");

	std::list<Identity>::const_iterator vit = identitiesData.begin();
	for(int i = 0; vit != identitiesData.end(); ++vit)
	{
		if ( idx == i)
			break;

	  ++i;
	}

	if(role == NameRole)
		return (*vit).name;
	else if(role == GxsIdRole)
		return (*vit).gxs_id;
	else if(role == IsContactRole)
		return (*vit).is_contact;
	else if(role == IsOwnRole)
		return (*vit).is_own;
	else if(role == AvatarRole)
		return (*vit).avatar;
}

QHash<int, QByteArray> RoomParticipantsModel::roleNames() const
{
	QHash<int, QByteArray> roles;

	roles[NameRole] = "name";
	roles[GxsIdRole] = "gxs_id";
	roles[IsContactRole] = "is_contact";
	roles[IsOwnRole] = "own";
	roles[AvatarRole] = "avatar";

	return roles;
}
