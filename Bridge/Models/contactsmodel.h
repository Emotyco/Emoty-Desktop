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
#ifndef CONTACTSMODEL_H
#define CONTACTSMODEL_H

//Qt
#include <QAbstractListModel>
#include <QDir>

//Emoty-GUI
#include "libresapilocalclient.h"

class ContactsModel : public QAbstractListModel
{
	Q_OBJECT
public:
	enum ContactRoles{
		NameRole,
		GxsIdRole,
		PgpIdRole,
		StateStringRole,
		UnreadCountRole,
		IsContactRole,
		PgpLinkedRole,
		AvatarRole
	};
	static ContactsModel *Create ();
	static void Destroy();
	static ContactsModel *getInstance ();
	    ~ContactsModel();

	virtual int rowCount(const QModelIndex & parent = QModelIndex()) const;
	virtual QVariant data(const QModelIndex & index, int role = Qt::DisplayRole) const;

public slots:
	void loadJSONContacts(QString json);
	void loadJSONStatus(QString json);
	void loadJSONUnread(QString json);
	void loadJSONAvatar(QString gxs_id, QString json);

protected:
	virtual QHash<int, QByteArray> roleNames() const;

private:
	struct Contact {
		Contact(QString name, QString gxs_id, QString pgp_id,
		        QString state_string, QString unread_count, QString avatar,
		        bool is_contact, bool pgp_linked)
		    : name(name), gxs_id(gxs_id), pgp_id(pgp_id),
		      state_string(state_string), unread_count(unread_count),
		      avatar(avatar), is_contact(is_contact), pgp_linked(pgp_linked)
		{}

		QString name;
		QString gxs_id;
		QString pgp_id;
		QString state_string;
		QString unread_count;
		QString avatar;

		bool is_contact;
		bool pgp_linked;
	};

	ContactsModel(QObject *parent = 0);

	static ContactsModel *_instance;
	LibresapiLocalClient *rsApi;

	int contactsStateToken;
	int statusStateToken;
	int unreadStateToken;
	std::list<Contact> contactsData;
};

#endif // CONTACTSMODEL_H
