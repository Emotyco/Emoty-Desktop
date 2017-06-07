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
#ifndef NOTIFIER_H
#define NOTIFIER_H

#include <QObject>

class Notifier : public QObject
{
	Q_OBJECT
public:
	enum ChatType
	{
		BROADCAST_CHAT,
		DISTANT_CHAT,
		DIRECT_CHAT,
		LOBBY
	};

	static Notifier *Create ();
	static void Destroy();
	static Notifier *getInstance ();

signals:
	void chatMessage(QString chat_type);

public slots:
	void handleChatMessages(QString receivedMsg);

	void setAdvMode(bool advmode);
	bool getAdvMode();

public:
	Notifier(QObject *parent = 0) :
	    QObject(parent), advmode(false), msgStateToken(0) {}

	static Notifier *_instance;

	bool advmode;
	int msgStateToken;
	std::map<ChatType, int> unreaded_msgs;
};

#endif // NOTIFIER_H
