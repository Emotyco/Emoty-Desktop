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
#ifndef ROOMINVITATIONMODEL_H
#define ROOMINVITATIONMODEL_H

//Qt
#include <QAbstractListModel>

class RoomInvitationModel : public QAbstractListModel
{
	Q_OBJECT
public:
	enum IvitationRoles{
		NameRole,
		GxsIdRole,
		PgpIdRole,
		PgpLinkedRole,
		AvatarRole
	};

	RoomInvitationModel(QObject *parent = 0)
	    : QAbstractListModel(parent), jsonParticipants("")
	{}

	virtual int rowCount(const QModelIndex & parent = QModelIndex()) const override;
	virtual QVariant data(const QModelIndex & index, int role = Qt::DisplayRole) const override;

public slots:
	void loadJSONInvitations(QString json);
	void loadJSONParticipants(QString json = "");
	void loadJSONAvatar(QString gxs_id, QString json);

protected:
	virtual QHash<int, QByteArray> roleNames() const;

private:
	struct Invitation {
		Invitation(QString name, QString gxs_id, QString pgp_id,
		        QString avatar, bool pgp_linked)
		    : name(name), gxs_id(gxs_id), pgp_id(pgp_id),
		      avatar(avatar), pgp_linked(pgp_linked)
		{}

		QString name;
		QString gxs_id;
		QString pgp_id;
		QString avatar;

		bool pgp_linked;
	};

	int participantsStateToken;
	int invitationsStateToken;
	std::list<Invitation> invitationData;
	QString jsonParticipants;
};

#endif // ROOMINVITATIONMODEL_H
