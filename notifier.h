/****************************************************************
 *  This file is part of Sonet.
 *  Sonet is distributed under the following license:
 *
 *  Copyright (C) 2017, Konrad Dębiec
 *
 *  Sonet is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU General Public License
 *  as published by the Free Software Foundation; either version 3
 *  of the License, or (at your option) any later version.
 *
 *  Sonet is distributed in the hope that it will be useful,
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
#include <QTimer>

#include "libresapilocalclient.h"

class Notifier : public QObject
{
	Q_OBJECT
public:
	enum NotificationType{
		LIST_PRE_CHANGE,
		LIST_CHANGE,
		ERROR_MSG,
		CHAT_MESSAGE,
		CHAT_STATUS,
		CHAT_CLEARED,
		CHAT_LOBBY_EVENT,
		CHAT_LOBBY_TIME_SHIFT,
		CUSTOM_STATE,
		HASHING_INFO,
		TURTLE_SEARCH_RESULT,
		PEER_HAS_NEW_AVATAR,
		OWN_AVATAR_CHANGED,
		OWN_STATUS_MESSAGE_CHANGED,
		DISK_FULL,
		PEER_STATUS_CHANGED,
		GXS_CHANGE,
		PEER_STATUS_CHANGED_SUMMARY,
		DISC_INFO_CHANGED,
		DOWNLOAD_COMPLETE,
		DOWNLOAD_COMPLETE_COUNT,
		HISTORY_CHANGED
	};

	static Notifier *Create ();
	static void Destroy();
	static Notifier *getInstance ();

signals:
	void listPreChange();
	void listChange();
	void errorMsg();
	void chatMessage();
	void chatMessage(QString chat_id, QString chat_type, bool incoming);
	void chatStatus();
	void chatCleared();
	void chatLobbyEvent();
	void chatLobbyTimeShift();
	void customState();
	void hashingInfo();
	void turtleSearchResult();
	void peerHasNewAvatar();
	void ownAvatarChanged();
	void ownStatusMessageChanged();
	void diskFull();
	void peerStatusChanged();
	void gxsChange();

	void peerStatusChangedSummary();
	void discInfoChanged();

	void downloadComplete();
	void downloadCompleteCount();
	void historyChanged();

public slots:
	void requestNotifications();
	void handleNotifications(QString receivedMsg);

	void setAdvMode(bool advmode);
	bool getAdvMode();

public:
	Notifier(QObject *parent = 0);
	    ~Notifier();
	static Notifier *_instance;

	LibresapiLocalClient *rsApi;
	QTimer *_timer;

	bool advmode;
};

#endif // NOTIFIER_H
