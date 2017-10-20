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
#ifndef TRANSFERFILESSORTMODEL_H
#define TRANSFERFILESSORTMODEL_H

//Qt
#include <QSortFilterProxyModel>
#include <QQmlEngine>

//Emoty-Desktop
#include "Bridge/Models/transferfilesmodel.h"

class TransferFilesSortModel : public QSortFilterProxyModel
{
	Q_OBJECT
public:
	enum Filter {
		All,
		Downloads,
		Uploads
	};

	TransferFilesSortModel(QObject *parent = 0);
	    ~TransferFilesSortModel();

public slots:
	void setFilter(int filterTransfer);

protected:
	bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const override;

private:
	TransferFilesModel *transferFilesModel;
	Filter filter;
};

static void registerTransferFilesSortModelTypes() {
	qmlRegisterType<TransferFilesSortModel>("TransferFilesSortModel", 0, 2, "TransferFilesSortModel");
}

#endif // TRANSFERFILESSORTMODEL_H
