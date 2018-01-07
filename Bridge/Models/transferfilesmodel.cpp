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
#include "transferfilesmodel.h"

#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonValue>
#include <QJsonArray>

void TransferFilesModel::loadJSONDownloadList(QString json)
{
	QJsonObject qJsonObject = QJsonDocument::fromJson(json.toUtf8()).object();

	if(transferStateToken == qJsonObject.value("statetoken").toInt())
		return;

	transferStateToken = qJsonObject.value("statetoken").toInt();

	QJsonValue jsData = qJsonObject.value("data");
	if(!jsData.isNull() && jsData.isArray())
	{
		QJsonArray jsDataArray = jsData.toArray();

		if(transferData.empty() && jsDataArray.count() != 0)
		{
			QModelIndex qModelIndex;
			beginInsertRows(qModelIndex, 0, jsDataArray.size()-1);
			for(QJsonArray::iterator it = jsDataArray.begin(); it != jsDataArray.end(); it++)
			{
				QJsonObject jsonTransfer = (*it).toObject();

				transferData.emplace_back(Transfer(
				                              jsonTransfer.value("hash").toString(),
				                              jsonTransfer.value("name").toString(),
				                              "",
				                              (int)jsonTransfer.value("size").toDouble(),
				                              (int)jsonTransfer.value("transferred").toDouble(),
				                              (int)jsonTransfer.value("transfer_rate").toDouble(),
				                              jsonTransfer.value("download_status").toString(),
				                              true
				                              ));
			}
			endInsertRows();
			emit dataCountChanged();
		}
		else
		{
			int i = 0;
			for(std::list<Transfer>::iterator vit = transferData.begin(); vit != transferData.end();)
			{
				bool found = false;
				for(QJsonArray::iterator it = jsDataArray.begin(); it != jsDataArray.end(); it++)
				{
					QJsonObject jsonTransfer = (*it).toObject();
					if((*vit).hash == jsonTransfer.value("hash").toString())
					{
						(*vit).transferred = (int)jsonTransfer.value("transferred").toDouble();
						(*vit).transfer_rate = (int)jsonTransfer.value("transfer_rate").toDouble();
						(*vit).download_status = jsonTransfer.value("download_status").toString();
						found = true;
						emit dataChanged(index(i),index(i));
					}
				}

				if(!found && (*vit).isDl)
				{
					QModelIndex qModelIndex;
					beginRemoveRows(qModelIndex, i, i);
					vit = transferData.erase(vit);
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
				QJsonObject jsonTransfer = (*it).toObject();

				bool found = false;
				for(std::list<Transfer>::iterator vit = transferData.begin(); vit != transferData.end(); ++vit)
				{
					if((*vit).hash == jsonTransfer.value("hash").toString())
						found = true;
				}

				if(!found)
				{
					QModelIndex qModelIndex;
					beginInsertRows(qModelIndex, transferData.size(), transferData.size());
					transferData.emplace_back(Transfer(
					                              jsonTransfer.value("hash").toString(),
					                              jsonTransfer.value("name").toString(),
					                              "",
					                              (int)jsonTransfer.value("size").toDouble(),
					                              (int)jsonTransfer.value("transferred").toDouble(),
					                              (int)jsonTransfer.value("transfer_rate").toDouble(),
					                              jsonTransfer.value("download_status").toString(),
					                              true
					                              ));
					endInsertRows();
					emit dataCountChanged();
				}
			}
		}
	}
}

void TransferFilesModel::loadJSONUploadList(QString json)
{
	QJsonObject qJsonObject = QJsonDocument::fromJson(json.toUtf8()).object();

	if(transferStateToken == qJsonObject.value("statetoken").toInt())
		return;

	transferStateToken = qJsonObject.value("statetoken").toInt();

	QJsonValue jsData = qJsonObject.value("data");
	if(!jsData.isNull() && jsData.isArray())
	{
		QJsonArray jsDataArray = jsData.toArray();

		if(transferData.empty()  && jsDataArray.count() != 0)
		{
			QModelIndex qModelIndex;
			beginInsertRows(qModelIndex, 0, jsDataArray.size()-1);
			for(QJsonArray::iterator it = jsDataArray.begin(); it != jsDataArray.end(); it++)
			{
				QJsonObject jsonTransfer = (*it).toObject();

				transferData.emplace_back(Transfer(
				                              jsonTransfer.value("hash").toString(),
				                              jsonTransfer.value("name").toString(),
				                              jsonTransfer.value("source").toString(),
				                              (int)jsonTransfer.value("size").toDouble(),
				                              (int)jsonTransfer.value("transferred").toDouble(),
				                              (int)jsonTransfer.value("transfer_rate").toDouble(),
				                              jsonTransfer.value("download_status").toString(),
				                              false
				                              ));
			}
			endInsertRows();
			emit dataCountChanged();
		}
		else
		{
			int i = 0;
			for(std::list<Transfer>::iterator vit = transferData.begin(); vit != transferData.end();)
			{
				bool found = false;
				for(QJsonArray::iterator it = jsDataArray.begin(); it != jsDataArray.end(); it++)
				{
					QJsonObject jsonTransfer = (*it).toObject();
					if((*vit).source == jsonTransfer.value("source").toString())
					{
						(*vit).transferred = (int)jsonTransfer.value("transferred").toDouble();
						(*vit).transfer_rate = (int)jsonTransfer.value("transfer_rate").toDouble();
						(*vit).download_status = jsonTransfer.value("download_status").toString();
						found = true;
						emit dataChanged(index(i),index(i));
					}
				}

				if(!found && !(*vit).isDl)
				{
					QModelIndex qModelIndex;
					beginRemoveRows(qModelIndex, i, i);
					vit = transferData.erase(vit);
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
				QJsonObject jsonTransfer = (*it).toObject();

				bool found = false;
				for(std::list<Transfer>::iterator vit = transferData.begin(); vit != transferData.end(); ++vit)
				{
					if((*vit).source == jsonTransfer.value("source").toString())
						found = true;
				}

				if(!found)
				{
					QModelIndex qModelIndex;
					beginInsertRows(qModelIndex, transferData.size(), transferData.size());
					transferData.emplace_back(Transfer(
					                              jsonTransfer.value("hash").toString(),
					                              jsonTransfer.value("name").toString(),
					                              jsonTransfer.value("source").toString(),
					                              (int)jsonTransfer.value("size").toDouble(),
					                              (int)jsonTransfer.value("transferred").toDouble(),
					                              (int)jsonTransfer.value("transfer_rate").toDouble(),
					                              jsonTransfer.value("download_status").toString(),
					                              false
					                              ));
					endInsertRows();
					emit dataCountChanged();
				}
			}
		}
	}
}

int TransferFilesModel::rowCount(const QModelIndex &) const
{
	return transferData.size();
}

QVariant TransferFilesModel::data(const QModelIndex & index, int role) const
{
	int idx = index.row();

	if(idx < 0 || idx >= transferData.size())
		return QVariant("Something went wrong...");

	std::list<Transfer>::const_iterator vit = transferData.begin();
	for(int i = 0; vit != transferData.end(); ++vit)
	{
		if ( idx == i)
			break;

	  ++i;
	}

	if(role == HashRole)
		return (*vit).hash;
	else if(role == NameRole)
		return (*vit).name;
	else if(role == SizeRole)
		return (*vit).size;
	else if(role == TransferredRole)
		return (*vit).transferred;
	else if(role == TransferRateRole)
		return (*vit).transfer_rate;
	else if(role == DownloadStatusRole)
		return (*vit).download_status;
	else if(role == IsDownloadRole)
		return (*vit).isDl;

	return QVariant();
}

QHash<int, QByteArray> TransferFilesModel::roleNames() const
{
	QHash<int, QByteArray> roles;

	roles[HashRole] = "hash";
	roles[NameRole] = "name";
	roles[SizeRole] = "size";
	roles[TransferredRole] = "transferred";
	roles[TransferRateRole] = "transfer_rate";
	roles[DownloadStatusRole] = "download_status";
	roles[IsDownloadRole] = "is_download";

	return roles;
}
