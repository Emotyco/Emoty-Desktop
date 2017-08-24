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
#include "roominvitationmodel.h"

#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonValue>
#include <QJsonArray>

void RoomInvitationModel::loadJSONInvitations(QString json)
{
	QJsonObject qJsonObject = QJsonDocument::fromJson(json.toUtf8()).object();

	if(invitationsStateToken == qJsonObject.value("statetoken").toInt())
		return;

	invitationsStateToken = qJsonObject.value("statetoken").toInt();

	QJsonValue jsData = qJsonObject.value("data");
	if(!jsData.isNull() && jsData.isArray())
	{
		QJsonArray jsDataArray = jsData.toArray();

		if(invitationData.empty())
		{
			for(QJsonArray::iterator it = jsDataArray.begin(); it != jsDataArray.end(); it++)
			{
				QJsonObject jsonInvitation = (*it).toObject();

				if(jsonInvitation.value("is_contact").toBool()
				        && !jsonInvitation.value("own").toBool()
				        && jsonInvitation.value("pgp_linked").toBool())
				{
					invitationData.emplace_back(Invitation(
					                              jsonInvitation.value("name").toString(),
					                              jsonInvitation.value("gxs_id").toString(),
					                              jsonInvitation.value("pgp_id").toString(),
					                              "",
					                              jsonInvitation.value("pgp_linked").toBool()
					                              ));
				}
			}

			beginResetModel();
			endResetModel();
		}
		else
		{
			int n = 0;
			for(std::list<Invitation>::iterator vit = invitationData.begin(); vit != invitationData.end();)
			{
				bool found = false;
				for(QJsonArray::iterator it = jsDataArray.begin(); it != jsDataArray.end(); it++)
				{
					QJsonObject jsonInvitation = (*it).toObject();
					if((*vit).gxs_id == jsonInvitation.value("gxs_id").toString()
					        && jsonInvitation.value("is_contact").toBool()
					        && !jsonInvitation.value("own").toBool()
					        && jsonInvitation.value("pgp_linked").toBool())
						found = true;
				}

				if(!found)
				{
					QModelIndex qModelIndex;
					beginRemoveRows(qModelIndex, n, n);
					vit = invitationData.erase(vit);
					endRemoveRows();
				}
				else
				{
					++vit;
					n++;
				}
			}

			for(QJsonArray::iterator it = jsDataArray.begin(); it != jsDataArray.end(); it++)
			{
				QJsonObject jsonInvitation = (*it).toObject();

				bool found = false;
				for(std::list<Invitation>::iterator vit = invitationData.begin(); vit != invitationData.end(); ++vit)
				{
					if((*vit).gxs_id == jsonInvitation.value("gxs_id").toString())
						found = true;
				}

				if(!found)
				{
					QModelIndex qModelIndex;
					beginInsertRows(qModelIndex, invitationData.size(), invitationData.size());
					invitationData.emplace_back(Invitation(
					                              jsonInvitation.value("name").toString(),
					                              jsonInvitation.value("gxs_id").toString(),
					                              jsonInvitation.value("pgp_id").toString(),
					                              "",
					                              jsonInvitation.value("pgp_linked").toBool()
					                              ));
					endInsertRows();
				}
			}
		}
		loadJSONParticipants();
	}
}

void RoomInvitationModel::loadJSONParticipants(QString json)
{
	if(json == "" && jsonParticipants == "")
		return;

	if(json != "")
		jsonParticipants = json;

	if(!invitationData.empty())
	{
		QJsonObject qJsonObject = QJsonDocument::fromJson(jsonParticipants.toUtf8()).object();

		if(participantsStateToken == qJsonObject.value("statetoken").toInt())
			return;

		participantsStateToken = qJsonObject.value("statetoken").toInt();

		QJsonValue jsData = qJsonObject.value("data");
		if(!jsData.isNull() && jsData.isArray())
		{
			QJsonArray jsDataArray = jsData.toArray();

			for(QJsonArray::iterator it = jsDataArray.begin(); it != jsDataArray.end(); it++)
			{
				QJsonObject jsonInvitation = (*it).toObject().value("identity").toObject();

				int i = 0;
				for(std::list<Invitation>::iterator vit = invitationData.begin(); vit != invitationData.end(); ++vit)
				{
					if(jsonInvitation.value("gxs_id") == (*vit).gxs_id)
					{
						QModelIndex qModelIndex;
						beginRemoveRows(qModelIndex, i, i);
						invitationData.erase(vit);
						endRemoveRows();
						break;
					}
					i++;
				}
			}
		}
	}
}

void RoomInvitationModel::loadJSONAvatar(QString gxs_id, QString json)
{
	QJsonObject qJsonObject = QJsonDocument::fromJson(json.toUtf8()).object();
	QJsonValue jsData = qJsonObject.value("data");

	if(!jsData.isNull())
	{
		QJsonObject jsDataObject = jsData.toObject();

		int i = 0;
		for(std::list<Invitation>::iterator vit = invitationData.begin(); vit != invitationData.end(); ++vit)
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

int RoomInvitationModel::rowCount(const QModelIndex &) const
{
	return invitationData.size();
}

QVariant RoomInvitationModel::data(const QModelIndex & index, int role) const
{
	int idx = index.row();

	if(idx < 0 || idx >= invitationData.size())
		return QVariant("Something went wrong...");

	std::list<Invitation>::const_iterator vit = invitationData.begin();
	for(int i = 0; vit != invitationData.end(); ++vit)
	{
		if ( idx == i)
			break;

	  ++i;
	}

	if(role == NameRole)
		return (*vit).name;
	else if(role == GxsIdRole)
		return (*vit).gxs_id;
	else if(role == PgpIdRole)
		return (*vit).pgp_id;
	else if(role == PgpLinkedRole)
		return (*vit).pgp_linked;
	else if(role == AvatarRole)
		return (*vit).avatar;

	return QVariant();
}

QHash<int, QByteArray> RoomInvitationModel::roleNames() const
{
	QHash<int, QByteArray> roles;

	roles[NameRole] = "name";
	roles[GxsIdRole] = "gxs_id";
	roles[PgpIdRole] = "pgp_id";
	roles[PgpLinkedRole] = "pgp_linked";
	roles[AvatarRole] = "avatar";

	return roles;
}
