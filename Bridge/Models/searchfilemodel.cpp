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
#include "searchfilemodel.h"

#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonValue>
#include <QJsonArray>

void SearchFileModel::loadJSONSearchFiles(QString json)
{
	QJsonObject qJsonObject = QJsonDocument::fromJson(json.toUtf8()).object();
	QJsonValue jsData = qJsonObject.value("data");

	if(!jsData.isNull() && jsData.isArray())
	{
		QJsonArray jsDataArray = jsData.toArray();

		if(searchFilesData.empty())
		{
			QModelIndex qModelIndex;
			beginInsertRows(qModelIndex, 0, jsDataArray.size()-1);
			for(QJsonArray::iterator it = jsDataArray.begin(); it != jsDataArray.end(); it++)
			{
				QJsonObject jsonSearchFile = (*it).toObject();

				searchFilesData.emplace_back(SearchFile(
				                                jsonSearchFile.value("name").toString(),
				                                jsonSearchFile.value("path").toString(),
				                                "file",
				                                jsonSearchFile.value("hash").toString(),
				                                jsonSearchFile.value("peer_id").toString(),
				                                jsonSearchFile.value("is_friends").toBool(),
				                                jsonSearchFile.value("is_own").toBool(),
				                                jsonSearchFile.value("size").toInt(),
				                                jsonSearchFile.value("rank").toInt(),
				                                jsonSearchFile.value("age").toInt()
				                              ));
			}
			endInsertRows();
			emit dataCountChanged();
		}
		else
		{
			int i = 0;
			for(std::list<SearchFile>::iterator vit = searchFilesData.begin(); vit != searchFilesData.end();)
			{
				bool found = false;
				for(QJsonArray::iterator it = jsDataArray.begin(); it != jsDataArray.end(); it++)
				{
					QJsonObject jsonSearchFile = (*it).toObject();
					if((*vit).hash == jsonSearchFile.value("hash").toString())
					{
						(*vit).size = jsonSearchFile.value("size").toInt();
						(*vit).rank = jsonSearchFile.value("rank").toInt();
						(*vit).age = jsonSearchFile.value("age").toInt();

						found = true;
						emit dataChanged(index(i),index(i));
					}
				}

				if(!found)
				{
					QModelIndex qModelIndex;
					beginRemoveRows(qModelIndex, i, i);
					vit = searchFilesData.erase(vit);
					endRemoveRows();
					emit dataCountChanged();
				}
				else
				{
					++vit;
					i++;
				}
			}

			for(QJsonArray::iterator it = jsDataArray.begin(); it != jsDataArray.end(); it++)
			{
				QJsonObject jsonSearchFile = (*it).toObject();

				bool found = false;
				for(std::list<SearchFile>::iterator vit = searchFilesData.begin(); vit != searchFilesData.end(); ++vit)
				{
					if((*vit).hash == jsonSearchFile.value("hash").toString())
						found = true;
				}

				if(!found)
				{
					QModelIndex qModelIndex;
					beginInsertRows(qModelIndex, searchFilesData.size(), searchFilesData.size());
					searchFilesData.emplace_back(SearchFile(
					                               jsonSearchFile.value("name").toString(),
					                               jsonSearchFile.value("path").toString(),
					                               "file",
					                               jsonSearchFile.value("hash").toString(),
					                               jsonSearchFile.value("peer_id").toString(),
					                               jsonSearchFile.value("is_friends").toBool(),
					                               jsonSearchFile.value("is_own").toBool(),
					                               jsonSearchFile.value("size").toInt(),
					                               jsonSearchFile.value("rank").toInt(),
					                               jsonSearchFile.value("age").toInt()
					                              ));
					endInsertRows();
					emit dataCountChanged();
				}
			}
		}
	}
	else if(jsData.isNull())
	{
		beginResetModel();
		searchFilesData.clear();
		endResetModel();
		emit dataCountChanged();
	}
}

int SearchFileModel::rowCount(const QModelIndex &) const
{
	return searchFilesData.size();
}

QVariant SearchFileModel::data(const QModelIndex & index, int role) const
{
	int idx = index.row();

	if(idx < 0 || idx >= searchFilesData.size())
		return QVariant("Something went wrong...");

	std::list<SearchFile>::const_iterator vit = searchFilesData.begin();
	for(int i = 0; vit != searchFilesData.end(); ++vit)
	{
		if ( idx == i)
			break;

		++i;
	}

	if(role == NameRole)
		return (*vit).name;
	else if(role == VirtualNameRole)
		return (*vit).name;
	else if(role == PathRole)
		return (*vit).path;
	else if(role == TypeRole)
		return (*vit).type;
	else if(role == HashRole)
		return (*vit).hash;
	else if(role == PeerIdRole)
		return (*vit).peer_id;
	else if(role == FriendRole)
		return (*vit).is_friend;
	else if(role == OwnRole)
		return (*vit).is_own;
	else if(role == SizeRole)
		return (*vit).size;
	else if(role == RankRole)
		return (*vit).rank;
	else if(role == AgeRole)
		return (*vit).age;

	return QVariant();
}

QHash<int, QByteArray> SearchFileModel::roleNames() const
{
	QHash<int, QByteArray> roles;

	roles[NameRole] = "name";
	roles[VirtualNameRole] = "virtual_name";
	roles[PathRole] = "path";
	roles[TypeRole] = "type";
	roles[HashRole] = "hash";
	roles[PeerIdRole] = "peer_id";
	roles[FriendRole] = "is_friend";
	roles[OwnRole] = "is_own";
	roles[SizeRole] = "count";
	roles[RankRole] = "rank";
	roles[AgeRole] = "age";

	return roles;
}
