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
#ifndef SEARCHFILESORTMODEL_H
#define SEARCHFILESORTMODEL_H

//Qt
#include <QSortFilterProxyModel>
#include <QQmlEngine>

//Emoty-Desktop
#include "Bridge/Models/searchfilemodel.h"

class SearchFileSortModel : public QSortFilterProxyModel
{
	Q_OBJECT
	Q_PROPERTY(bool isOwn READ getIsOwn WRITE setIsOwn)
	Q_PROPERTY(bool isFriends READ getIsFriends WRITE setIsFriends)
	Q_PROPERTY(QAbstractListModel* baseModel WRITE setBaseModel)
	Q_PROPERTY(int count READ getCount NOTIFY countChanged)

public:
	SearchFileSortModel(QObject *parent = 0)
	    : QSortFilterProxyModel(parent), is_own(false), is_friends(false)
	{}

	bool getIsOwn() {return is_own;}
	void setIsOwn(bool isOwn) {is_own = isOwn;}

	bool getIsFriends() {return is_friends;}
	void setIsFriends(bool isFriends) {is_friends = isFriends;}

	void setBaseModel(QAbstractListModel* baseModel);

	int getCount() {return rowCount();}

signals:
	void countChanged();

protected:
	bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const override;

private:
	//SearchFileModel *searchFileModel;
	bool is_own;
	bool is_friends;
};

static void registerSearchFileSortModelTypes() {
	qmlRegisterType<SearchFileSortModel>("SearchFileSortModel", 0, 2, "SearchFileSortModel");
}

#endif // SEARCHFILESORTMODEL_H
