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
#ifndef SHAREDFILESMODEL_H
#define SHAREDFILESMODEL_H

//Qt
#include <QAbstractListModel>
#include <QQmlEngine>

class SharedFilesModel : public QAbstractListModel
{
	Q_OBJECT
	Q_PROPERTY(int parent_reference READ getParent NOTIFY parentReferenceChanged)
	Q_PROPERTY(QString path READ getPath NOTIFY pathChanged)
public:
	enum ShareFilesRoles{
		NameRole,
		VirtualNameRole,
		PathRole,
		ParentReferenceRole,
		ReferenceRole,
		CountRole,
		TypeRole,
		BrowsableRole,
		AnonymousDownloadRole,
		AnonymousSearchRole,
		ContainFilesRole,
		ContainFoldersRole
	};

	SharedFilesModel(QObject *parent = 0)
	    : QAbstractListModel(parent),
	      parent_reference(0), path("")
	{}

	virtual int rowCount(const QModelIndex & parent = QModelIndex()) const override;
	virtual QVariant data(const QModelIndex & index, int role = Qt::DisplayRole) const override;

public slots:
	void loadJSONSharedFolders(QString json);

	int getParent() {return parent_reference;}
	QString getPath() {return path;}

signals:
	void parentReferenceChanged();
	void pathChanged();

protected:
	virtual QHash<int, QByteArray> roleNames() const;

private:
	struct SharedFiles {
		SharedFiles(QString name, QString virtualname,
		            QString path, int parent_reference,
		            int reference, int count, QString type,
		            bool browsable, bool anon_dl, bool anon_search,
		            int contain_files, int contain_folders)
		    : name(name), virtualname(virtualname),
		      path(path), parent_reference(parent_reference),
		      reference(reference), count(count), type(type),
		      browsable(browsable), anon_dl(anon_dl),
		      anon_search(anon_search),
		      contain_files(contain_files), contain_folders(contain_folders)
		{}

		QString name;
		QString virtualname;
		QString path;
		int parent_reference;
		int reference;
		int count;
		QString type;
		bool browsable;
		bool anon_dl;
		bool anon_search;
		int contain_files;
		int contain_folders;
	};

	std::list<SharedFiles> sharedFoldersData;
	int parent_reference;
	QString path;
};

static void registerSharedFilesModelTypes() {
	qmlRegisterType<SharedFilesModel>("SharedFilesModel", 0, 2, "SharedFilesModel");
}

#endif // SHAREDFILESMODEL_H
