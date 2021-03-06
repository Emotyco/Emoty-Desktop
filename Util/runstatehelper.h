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
#ifndef RUNSTATEHELPER_H
#define RUNSTATEHELPER_H

#include <QObject>

class RunStateHelper : public QObject
{
	Q_OBJECT
public:
	static RunStateHelper *Create ();
	static void Destroy();
	static RunStateHelper *getInstance ();

public slots:
	void setRunState(QString runState);
	QString getRunState();

private:
	RunStateHelper(QObject *parent = 0) : QObject(parent){}
	static RunStateHelper *_instance;
	QString mRunState;
};

#endif // RUNSTATEHELPER_H
