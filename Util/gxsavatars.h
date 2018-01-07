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
#ifndef GXSAVATARS_H
#define GXSAVATARS_H

#include <QObject>
#include <QString>
#include <QMap>

class GXSAvatars: public QObject
{
	Q_OBJECT
public:
	GXSAvatars(QObject *parent = 0)
	 : QObject(parent)
	{}

public slots:
	bool storeAvatar(QString gxs_id, QString avatar);
	QString getAvatar(QString gxs_id);

private:
	QMap<QString, QString> gxs_avatars;
};

#endif // GXSAVATARS_H
