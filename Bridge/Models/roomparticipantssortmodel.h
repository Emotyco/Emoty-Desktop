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
#ifndef ROOMPARTICIPANTSSORTMODEL_H
#define ROOMPARTICIPANTSSORTMODEL_H

//Qt
#include <QSortFilterProxyModel>
#include <QQmlEngine>

//Emoty-Desktop
#include "Bridge/Models/roomparticipantsmodel.h"

class RoomParticipantsSortModel : public QSortFilterProxyModel
{
	Q_OBJECT
public:
	RoomParticipantsSortModel(QObject *parent = 0);
	    ~RoomParticipantsSortModel();

public slots:
	void setSearchText(QString search);

protected:
	bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const override;
	bool lessThan(const QModelIndex &left, const QModelIndex &right) const override;

private:
	RoomParticipantsModel *roomParticipantsModel;
	QString searchText;
};

static void registerRoomParticipantsSortModelTypes() {
	qmlRegisterType<RoomParticipantsSortModel>("RoomParticipantsSortModel", 0, 2, "RoomParticipantsSortModel");
}

#endif // ROOMPARTICIPANTSSORTMODEL_H
