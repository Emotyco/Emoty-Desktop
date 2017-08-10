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
#ifndef ROOMPARTICIPANTSMODEL_H
#define ROOMPARTICIPANTSMODEL_H

//Qt
#include <QAbstractListModel>

class RoomParticipantsModel : public QAbstractListModel
{
	Q_OBJECT
public:
	enum IdentityRoles{
		NameRole,
		GxsIdRole,
		IsContactRole,
		IsOwnRole,
		AvatarRole
	};

	RoomParticipantsModel(QObject *parent = 0)
	    : QAbstractListModel(parent)
	{}

	virtual int rowCount(const QModelIndex & parent = QModelIndex()) const override;
	virtual QVariant data(const QModelIndex & index, int role = Qt::DisplayRole) const override;

public slots:
	void loadJSONParticipants(QString json);
	void loadJSONIdentities(QString json);
	void loadJSONAvatar(QString gxs_id, QString json);

protected:
	virtual QHash<int, QByteArray> roleNames() const override;

private:
	struct Identity {
		Identity(QString name, QString gxs_id, QString avatar,
		         bool is_contact, bool is_own)
		    : name(name), gxs_id(gxs_id), avatar(avatar),
		      is_contact(is_contact), is_own(is_own)
		{}

		QString name;
		QString gxs_id;
		QString avatar;

		bool is_contact;
		bool is_own;
	};

	int participantsStateToken;
	int identitiesStateToken;
	std::list<Identity> identitiesData;
};

#endif // ROOMPARTICIPANTSMODEL_H
