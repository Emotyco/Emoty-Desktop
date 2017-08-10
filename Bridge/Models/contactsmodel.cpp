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
#include "contactsmodel.h"

#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonValue>
#include <QJsonArray>

/*static*/ ContactsModel *ContactsModel::_instance = NULL;

/*static*/ ContactsModel *ContactsModel::Create()
{
	if (_instance == NULL)
		_instance = new ContactsModel();

	return _instance;
}

/*static*/ void ContactsModel::Destroy()
{
	if(_instance != NULL)
		delete _instance ;

	_instance = NULL ;
}

/*static*/ ContactsModel *ContactsModel::getInstance()
{
	return _instance;
}

ContactsModel::ContactsModel(QObject *parent)
 : QAbstractListModel(parent)
{
	QString sockPath = QDir::homePath() + "/.retroshare";
	sockPath.append("/libresapi.sock");

	rsApi = new LibresapiLocalClient();
	rsApi->openConnection(sockPath);
}

ContactsModel::~ContactsModel()
{
	if(rsApi != NULL)
		delete rsApi;
	rsApi = NULL;
}

void ContactsModel::loadJSONContacts(QString json)
{
	QJsonObject qJsonObject = QJsonDocument::fromJson(json.toUtf8()).object();

	if(contactsStateToken == qJsonObject.value("statetoken").toInt())
		return;

	contactsStateToken = qJsonObject.value("statetoken").toInt();

	QJsonValue jsData = qJsonObject.value("data");
	if(!jsData.isNull() && jsData.isArray())
	{
		QJsonArray jsDataArray = jsData.toArray();

		if(contactsData.empty())
		{
			QModelIndex qModelIndex;
			beginInsertRows(qModelIndex, 0, jsDataArray.size()-1);
			for(QJsonArray::iterator it = jsDataArray.begin(); it != jsDataArray.end(); it++)
			{
				QJsonObject jsonContact = (*it).toObject();

				contactsData.emplace_back(Contact(
				                              jsonContact.value("name").toString(),
				                              jsonContact.value("gxs_id").toString(),
				                              jsonContact.value("pgp_id").toString(),
				                              "undefined",
				                              "0",
				                              "",
				                              jsonContact.value("is_contact").toBool(),
				                              jsonContact.value("pgp_linked").toBool(),
				                              false
				                              ));
			}
			endInsertRows();
		}
		else
		{
			int i = 0;
			for(QJsonArray::iterator it = jsDataArray.begin(); it != jsDataArray.end(); it++)
			{
				QJsonObject jsonContact = (*it).toObject();

				bool found = false;
				for(std::list<Contact>::iterator vit = contactsData.begin(); vit != contactsData.end(); ++vit)
				{
					if((*vit).gxs_id == jsonContact.value("gxs_id").toString())
					{
						if((*vit).is_contact != jsonContact.value("is_contact").toBool())
						{
							(*vit).is_contact = jsonContact.value("is_contact").toBool();
							emit dataChanged(index(i),index(i));
						}

						if((*vit).pgp_linked && (*vit).pgp_id != jsonContact.value("pgp_id").toString())
						{
							(*vit).pgp_id = jsonContact.value("pgp_id").toString();
							emit dataChanged(index(i),index(i));
						}

						found = true;
					}
				}

				if(!found)
				{
					QModelIndex qModelIndex;
					beginInsertRows(qModelIndex, contactsData.size(), contactsData.size());
					contactsData.emplace_back(Contact(
					                              jsonContact.value("name").toString(),
					                              jsonContact.value("gxs_id").toString(),
					                              jsonContact.value("pgp_id").toString(),
					                              "undefined",
					                              "0",
					                              "",
					                              jsonContact.value("is_contact").toBool(),
					                              jsonContact.value("pgp_linked").toBool(),
					                              false
					                              ));
					endInsertRows();
				}
				i++;
			}
		}
	}
}

void ContactsModel::loadJSONStatus(QString json)
{
	QJsonObject qJsonObject = QJsonDocument::fromJson(json.toUtf8()).object();

	QJsonValue jsData = qJsonObject.value("data");
	if(!jsData.isNull() && jsData.isArray())
	{
		QJsonArray jsDataArray = jsData.toArray();

		for(QJsonArray::iterator it = jsDataArray.begin(); it != jsDataArray.end(); it++)
		{
			QJsonObject jsonPGP = (*it).toObject();

			bool emplaceEmpty = true;
			bool addOrRemove = false;

			int count = 0;
			int countContact = 0;
			for(std::list<Contact>::iterator vit = contactsData.begin(); vit != contactsData.end(); ++vit)
			{
				if((*vit).pgp_linked && (*vit).pgp_id == jsonPGP.value("pgp_id").toString())
				{
					count++;
					if ((*vit).is_contact)
					{
						emplaceEmpty = false;

						if((*vit).gxs_id != "")
						{
							countContact++;
							addOrRemove = true;
						}
					}
				}
			}

			QVariantList identitiesToAdd;
			int n = 0;
			for(std::list<Contact>::iterator vit = contactsData.begin(); vit != contactsData.end();)
			{
				if((*vit).pgp_linked && (*vit).pgp_id == jsonPGP.value("pgp_id").toString())
				{
					if(countContact == 1 && !(*vit).is_only && (*vit).is_contact)
					{
						(*vit).is_only = true;
						emit dataChanged(index(n),index(n));
					}
					else if(countContact > 1 && (*vit).is_only && (*vit).is_contact)
					{
						(*vit).is_only = false;
						emit dataChanged(index(n),index(n));
					}

					if(!addOrRemove)
					{
						if (!(*vit).is_contact)
						{
							if(count == 1)
							{
								QString jsonData = "{\"gxs_id\":\"" + (*vit).gxs_id + "\"}";
								rsApi->request("/identity/add_contact", jsonData);
								emplaceEmpty = false;
							}
							else if(count > 1)
								identitiesToAdd.push_back(QVariantList{
								                           (*vit).gxs_id,
								                           (*vit).name
								                       });
						}

						vit++;
						n++;
					}
					else if(addOrRemove)
					{
						if ((*vit).gxs_id == "" && (*vit).is_contact)
						{
							QModelIndex qModelIndex;
							beginRemoveRows(qModelIndex, n, n);
							vit = contactsData.erase(vit);
							endRemoveRows();
						}
						else
						{
							vit++;
							n++;
						}
					}
				}
				else
				{
					vit++;
					n++;
				}
			}

			if(identitiesToAdd.length() > 0 && count >= 1)
				emit chooseIdentities(identitiesToAdd);

			if(emplaceEmpty)
			{
				QModelIndex qModelIndex;
				beginInsertRows(qModelIndex, contactsData.size(), contactsData.size());
				contactsData.emplace_back(Contact(
				                              jsonPGP.value("name").toString(),
				                              "",
				                              jsonPGP.value("pgp_id").toString(),
				                              "undefined",
				                              "0",
				                              "",
				                              true,
				                              true,
				                              false
				                              ));
				endInsertRows();
			}
		}

		int i = 0;
		for(std::list<Contact>::iterator vit = contactsData.begin(); vit != contactsData.end(); ++vit)
		{
			if ((*vit).pgp_linked)
			{
				bool found = false;
				for(QJsonArray::iterator it = jsDataArray.begin(); it != jsDataArray.end(); it++)
				{
					QJsonObject jsonStatus = (*it).toObject();

					if((*vit).pgp_id == jsonStatus.value("pgp_id").toString())
					{
						(*vit).state_string = jsonStatus.value("state_string").toString();
						emit dataChanged(index(i),index(i));
						found = true;
					}
				}
				if(!found)
				{
					(*vit).state_string = "undefined";
					emit dataChanged(index(i),index(i));
				}
			}
			i++;
		}
	}
}

void ContactsModel::loadJSONUnread(QString json)
{
	QJsonObject qJsonObject = QJsonDocument::fromJson(json.toUtf8()).object();

	if(unreadStateToken == qJsonObject.value("statetoken").toInt())
		return;

	unreadStateToken = qJsonObject.value("statetoken").toInt();

	QJsonValue jsData = qJsonObject.value("data");
	if(!jsData.isNull() && jsData.isArray())
	{
		QJsonArray jsDataArray = jsData.toArray();

		int i = 0;
		for(std::list<Contact>::iterator vit = contactsData.begin(); vit != contactsData.end(); ++vit)
		{
			bool clear = true;
			for(QJsonArray::iterator it = jsDataArray.begin(); it != jsDataArray.end(); it++)
			{
				QJsonObject jsonStatus = (*it).toObject();

				if(jsonStatus.value("is_distant_chat_id").toBool()
				        && (*vit).gxs_id == jsonStatus.value("remote_author_id").toString())
				{
					(*vit).unread_count = jsonStatus.value("unread_count").toString();
					clear = false;
				}
			}

			if(clear)
				(*vit).unread_count = "0";

			emit dataChanged(index(i),index(i));
			i++;
		}
	}
}

void ContactsModel::loadJSONAvatar(QString gxs_id, QString json)
{
	QJsonObject qJsonObject = QJsonDocument::fromJson(json.toUtf8()).object();
	QJsonValue jsData = qJsonObject.value("data");

	if(!jsData.isNull())
	{
		QJsonObject jsDataObject = jsData.toObject();

		int i = 0;
		for(std::list<Contact>::iterator vit = contactsData.begin(); vit != contactsData.end(); ++vit)
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

int ContactsModel::rowCount(const QModelIndex & parent) const
{
	return contactsData.size();
}

QVariant ContactsModel::data(const QModelIndex & index, int role) const
{
	int idx = index.row();

	if(idx < 0 || idx >= contactsData.size())
		return QVariant("Something went wrong...");

	std::list<Contact>::const_iterator vit = contactsData.begin();
	for(int i = 0; vit != contactsData.end(); ++vit)
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
	else if(role == StateStringRole)
		return (*vit).state_string;
	else if(role == UnreadCountRole)
		return (*vit).unread_count;
	else if(role == IsContactRole)
		return (*vit).is_contact;
	else if(role == PgpLinkedRole)
		return (*vit).pgp_linked;
	else if(role == AvatarRole)
		return (*vit).avatar;
	else if(role == IsOnlyOneRole)
		return (*vit).is_only;
}

QHash<int, QByteArray> ContactsModel::roleNames() const
{
	QHash<int, QByteArray> roles;

	roles[NameRole] = "name";
	roles[GxsIdRole] = "gxs_id";
	roles[PgpIdRole] = "pgp_id";
	roles[StateStringRole] = "state_string";
	roles[UnreadCountRole] = "unread_count";
	roles[IsContactRole] = "is_contact";
	roles[PgpLinkedRole] = "pgp_linked";
	roles[AvatarRole] = "avatar";
	roles[IsOnlyOneRole] = "is_only";

	return roles;
}
