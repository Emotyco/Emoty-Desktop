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
#include "sharedfilesmodel.h"

#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonValue>
#include <QJsonArray>

void SharedFilesModel::loadJSONSharedFolders(QString json)
{
	QJsonObject qJsonObject = QJsonDocument::fromJson(json.toUtf8()).object();
	QJsonValue jsData = qJsonObject.value("data");

	parent_reference = jsData.toObject().value("parent_reference").toInt();
	path =  jsData.toObject().value("path").toString();
	emit parentReferenceChanged();
	emit pathChanged();

	if(!jsData.toObject().value("childs").isNull() && jsData.toObject().value("childs").isArray())
	{
		QJsonArray jsDataArray = jsData.toObject().value("childs").toArray();

		if(sharedFoldersData.empty())
		{
			QModelIndex qModelIndex;
			beginInsertRows(qModelIndex, 0, jsDataArray.size()-1);
			for(QJsonArray::iterator it = jsDataArray.begin(); it != jsDataArray.end(); it++)
			{
				QJsonObject jsonSharedFolder = (*it).toObject();

				sharedFoldersData.emplace_back(SharedFiles(
				                                jsonSharedFolder.value("name").toString(),
				                                jsonSharedFolder.value("name").toString().section('/', -1),
				                                jsonSharedFolder.value("path").toString(),
				                                jsonSharedFolder.value("parent_reference").toInt(),
				                                jsonSharedFolder.value("reference").toInt(),
				                                jsonSharedFolder.value("count").toInt(),
				                                jsonSharedFolder.value("type").toString(),
				                                jsonSharedFolder.value("browsable").toBool(),
				                                jsonSharedFolder.value("anon_dl").toBool(),
				                                jsonSharedFolder.value("anon_search").toBool(),
				                                jsonSharedFolder.value("contain_files").toInt(),
				                                jsonSharedFolder.value("contain_folders").toInt()
				                              ));
			}
			endInsertRows();
		}
		else
		{
			int i = 0;
			for(std::list<SharedFiles>::iterator vit = sharedFoldersData.begin(); vit != sharedFoldersData.end();)
			{
				bool found = false;
				for(QJsonArray::iterator it = jsDataArray.begin(); it != jsDataArray.end(); it++)
				{
					QJsonObject jsonSharedFolder = (*it).toObject();
					if((*vit).reference == jsonSharedFolder.value("reference").toInt())
					{
						(*vit).count = jsonSharedFolder.value("count").toInt();
						(*vit).browsable = jsonSharedFolder.value("browsable").toBool();
						(*vit).anon_dl = jsonSharedFolder.value("anon_dl").toBool();
						(*vit).anon_search = jsonSharedFolder.value("anon_search").toBool();
						(*vit).contain_files = jsonSharedFolder.value("contain_files").toInt();
						(*vit).contain_folders = jsonSharedFolder.value("contain_folders").toInt();

						found = true;
						emit dataChanged(index(i),index(i));
					}
				}

				if(!found)
				{
					QModelIndex qModelIndex;
					beginRemoveRows(qModelIndex, i, i);
					vit = sharedFoldersData.erase(vit);
					endRemoveRows();
				}
				else
				{
					++vit;
					i++;
				}
			}

			for(QJsonArray::iterator it = jsDataArray.begin(); it != jsDataArray.end(); it++)
			{
				QJsonObject jsonSharedFolder = (*it).toObject();

				bool found = false;
				for(std::list<SharedFiles>::iterator vit = sharedFoldersData.begin(); vit != sharedFoldersData.end(); ++vit)
				{
					if((*vit).reference == jsonSharedFolder.value("reference").toInt())
						found = true;
				}

				if(!found)
				{
					QModelIndex qModelIndex;
					beginInsertRows(qModelIndex, sharedFoldersData.size(), sharedFoldersData.size());
					sharedFoldersData.emplace_back(SharedFiles(
					                               jsonSharedFolder.value("name").toString(),
					                               jsonSharedFolder.value("name").toString().section('/', -1),
					                               jsonSharedFolder.value("path").toString(),
					                               jsonSharedFolder.value("parent_reference").toInt(),
					                               jsonSharedFolder.value("reference").toInt(),
					                               jsonSharedFolder.value("count").toInt(),
					                               jsonSharedFolder.value("type").toString(),
					                               jsonSharedFolder.value("browsable").toBool(),
					                               jsonSharedFolder.value("anon_dl").toBool(),
					                               jsonSharedFolder.value("anon_search").toBool(),
					                               jsonSharedFolder.value("contain_files").toInt(),
					                               jsonSharedFolder.value("contain_folders").toInt()
					                              ));
					endInsertRows();
				}
			}
		}
	}
	else if(jsData.toObject().value("childs").isNull())
	{
		beginResetModel();
		sharedFoldersData.clear();
		endResetModel();
	}
}

int SharedFilesModel::rowCount(const QModelIndex &) const
{
	return sharedFoldersData.size();
}

QVariant SharedFilesModel::data(const QModelIndex & index, int role) const
{
	int idx = index.row();

	if(idx < 0 || idx >= sharedFoldersData.size())
		return QVariant("Something went wrong...");

	std::list<SharedFiles>::const_iterator vit = sharedFoldersData.begin();
	for(int i = 0; vit != sharedFoldersData.end(); ++vit)
	{
		if ( idx == i)
			break;

		++i;
	}

	if(role == NameRole)
		return (*vit).name;
	else if(role == VirtualNameRole)
		return (*vit).virtualname;
	else if(role == PathRole)
		return (*vit).path;
	else if(role == ParentReferenceRole)
		return (*vit).parent_reference;
	else if(role == ReferenceRole)
		return (*vit).reference;
	else if(role == CountRole)
		return (*vit).count;
	else if(role == TypeRole)
		return (*vit).type;
	else if(role == BrowsableRole)
		return (*vit).browsable;
	else if(role == AnonymousDownloadRole)
		return (*vit).anon_dl;
	else if(role == AnonymousSearchRole)
		return (*vit).anon_search;
	else if(role == ContainFilesRole)
		return (*vit).contain_files;
	else if(role == ContainFoldersRole)
		return (*vit).contain_folders;

	return QVariant();
}

QHash<int, QByteArray> SharedFilesModel::roleNames() const
{
	QHash<int, QByteArray> roles;

	roles[NameRole] = "name";
	roles[VirtualNameRole] = "virtual_name";
	roles[PathRole] = "path";
	roles[ParentReferenceRole] = "parent_reference";
	roles[ReferenceRole] = "reference";
	roles[CountRole] = "count";
	roles[TypeRole] = "type";
	roles[BrowsableRole] = "browsable";
	roles[AnonymousDownloadRole] = "anonymous_download";
	roles[AnonymousSearchRole] = "anonymous_search";
	roles[ContainFilesRole] = "contain_files";
	roles[ContainFoldersRole] = "contain_folders";

	return roles;
}
