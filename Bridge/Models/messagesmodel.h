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
#ifndef MESSAGESMODEL_H
#define MESSAGESMODEL_H

//Qt
#include <QAbstractListModel>
#include <QQmlEngine>

class MessagesModel : public QAbstractListModel
{
	Q_OBJECT
public:
	enum MessageRoles {
		AuthorIdRole,
		AuthorNameRole,
		MsgIdRole,
		IncomingRole,
		MsgContentRole,
		RecvTimeRole,
		SendTimeRole,
		WasSendRole,
		AuthorIdPreviousRole,
		AuthorAvatarRole
	};

	MessagesModel(QObject *parent = 0)
	    : QAbstractListModel(parent)
	{}

	virtual int rowCount(const QModelIndex & parent = QModelIndex()) const override;
	virtual QVariant data(const QModelIndex & index, int role = Qt::DisplayRole) const override;

public slots:
	void loadJSONMessages(QString json);
	void storeAuthorAvatar(QString json, QString author_id);

protected:
	virtual QHash<int, QByteArray> roleNames() const;

private:
	struct Message {
		Message(QString author_id, QString author_name,
		           QString msg_id, bool incoming,
		           QString msg_content, QString recv_time,
		           QString send_time, bool was_send,
		           QString author_id_previous, QString author_avatar)
		    : author_id(author_id), author_name(author_name),
		      msg_id(msg_id), incoming(incoming),
		      msg_content(msg_content), recv_time(recv_time),
		      send_time(send_time), was_send(was_send),
		      author_id_previous(author_id_previous), author_avatar(author_avatar)
		{}

		QString author_id;
		QString author_name;
		QString msg_id;
		bool incoming;
		QString msg_content;
		QString recv_time;
		QString send_time;
		bool was_send;
		QString author_id_previous;
		QString author_avatar;
	};

	std::list<Message> messageData;
};

static void registerMessagesModelTypes() {
	qmlRegisterType<MessagesModel>("MessagesModel", 0, 2, "MessagesModel");
}

#endif // MESSAGESMODEL_H