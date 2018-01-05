#include "notifier.h"

#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonValue>
#include <QJsonArray>

/*static*/ Notifier *Notifier::_instance = NULL;

/*static*/ Notifier *Notifier::Create()
{
	if (_instance == NULL)
		_instance = new Notifier();

	return _instance;
}

/*static*/ void Notifier::Destroy()
{
	if(_instance != NULL)
		delete _instance;

	_instance = NULL;
}

/*static*/ Notifier *Notifier::getInstance()
{
	return _instance;
}

void Notifier::setAdvMode(bool advmode)
{
	this->advmode = advmode;
}

bool Notifier::getAdvMode()
{
	return advmode;
}

void Notifier::handleChatMessages(QString receivedMsg)
{
	QJsonObject qJsonObject = QJsonDocument::fromJson(receivedMsg.toUtf8()).object();

	if(msgStateToken == qJsonObject.value("statetoken").toInt())
		return;

	msgStateToken = qJsonObject.value("statetoken").toInt();

	QJsonValue jsData = qJsonObject.value("data");
	if(!jsData.isNull() && jsData.isArray())
	{
		QJsonArray jsDataArray = jsData.toArray();
		int broadcast_msgs = 0;
		int distant_msgs = 0;
		int lobby_msgs = 0;
		int direct_msgs = 0;

		for(QJsonArray::iterator it = jsDataArray.begin(); it != jsDataArray.end(); it++)
		{
			if((*it).toObject().value("is_broadcast").toBool())
			{
				broadcast_msgs += (*it).toObject().value("unread_count").toString().toInt();
			}
			else if((*it).toObject().value("is_distant_chat_id").toBool())
			{
				distant_msgs += (*it).toObject().value("unread_count").toString().toInt();
			}
			else if((*it).toObject().value("is_peer").toBool())
			{
				direct_msgs += (*it).toObject().value("unread_count").toString().toInt();
			}
			else if((*it).toObject().value("is_lobby").toBool())
			{
				lobby_msgs += (*it).toObject().value("unread_count").toString().toInt();
			}
		}

		if(unreaded_msgs.empty())
		{
			unreaded_msgs.insert(std::pair<ChatType, int>(BROADCAST_CHAT, broadcast_msgs));
			unreaded_msgs.insert(std::pair<ChatType, int>(DISTANT_CHAT, distant_msgs));
			unreaded_msgs.insert(std::pair<ChatType, int>(DIRECT_CHAT, direct_msgs));
			unreaded_msgs.insert(std::pair<ChatType, int>(LOBBY, lobby_msgs));
		}
		else
		{
			if(broadcast_msgs != unreaded_msgs[BROADCAST_CHAT])
			{
				if(broadcast_msgs > unreaded_msgs[BROADCAST_CHAT])
					emit chatMessage("broadcast");
				unreaded_msgs[BROADCAST_CHAT] = broadcast_msgs;
			}
			else if(distant_msgs != unreaded_msgs[DISTANT_CHAT])
			{
				if(distant_msgs > unreaded_msgs[DISTANT_CHAT])
					emit chatMessage("distant_chat");
				unreaded_msgs[DISTANT_CHAT] = distant_msgs;
			}
			else if(direct_msgs != unreaded_msgs[DIRECT_CHAT])
			{
				if(direct_msgs > unreaded_msgs[DIRECT_CHAT])
					emit chatMessage("direct_chat");
				unreaded_msgs[DIRECT_CHAT] = direct_msgs;
			}
			else if(lobby_msgs != unreaded_msgs[LOBBY])
			{
				if(lobby_msgs > unreaded_msgs[LOBBY])
					emit chatMessage("lobby");
				unreaded_msgs[LOBBY] = lobby_msgs;
			}
		}
	}
}
