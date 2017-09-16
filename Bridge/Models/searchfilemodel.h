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
#ifndef SEARCHFILEMODEL_H
#define SEARCHFILEMODEL_H

//Qt
#include <QAbstractListModel>
#include <QQmlEngine>

class SearchFileModel : public QAbstractListModel
{
	Q_OBJECT
public:
	enum SearchFileRoles {
		NameRole,
		VirtualNameRole,
		PathRole,
		TypeRole,
		HashRole,
		PeerIdRole,
		SizeRole,
		RankRole,
		AgeRole
	};

	SearchFileModel(QObject *parent = 0)
	    : QAbstractListModel(parent)
	{}

	virtual int rowCount(const QModelIndex & parent = QModelIndex()) const override;
	virtual QVariant data(const QModelIndex & index, int role = Qt::DisplayRole) const override;

public slots:
	void loadJSONSearchFiles(QString json);

protected:
	virtual QHash<int, QByteArray> roleNames() const;

private:
	struct SearchFile {
		SearchFile(QString name, QString path,
		            QString type, QString hash,
		            QString peer_id, int size,
		            int rank, int age)
		    : name(name), path(path),
		      type(type), hash(hash),
		      peer_id(peer_id), size(size),
		      rank(rank), age(age)
		{}

		QString name;
		QString path;
		QString type;
		QString hash;
		QString peer_id;
		int size;
		int rank;
		int age;
	};

	std::list<SearchFile> searchFilesData;
};

static void registerSearchFileModelTypes() {
	qmlRegisterType<SearchFileModel>("SearchFileModel", 0, 2, "SearchFileModel");
}

#endif // SEARCHFILEMODEL_H
