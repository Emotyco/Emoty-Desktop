#include "notifier.h"

#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonValue>
#include <QJsonArray>

#include <iostream>

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

Notifier::Notifier(QObject *parent) : QObject(parent), advmode(false)
{
	QString sockPath;

#ifdef QT_DEBUG
	sockPath = "RS/";
#else
	sockPath = QCoreApplication::applicationDirPath();
#endif

	sockPath.append("/libresapi.sock");

	rsApi = new LibresapiLocalClient();
	rsApi->openConnection(sockPath);

	_timer = new QTimer;
	_timer->setInterval(500);
	_timer->setSingleShot(true);

	QObject::connect(_timer, SIGNAL(timeout()), this, SLOT(requestNotifications()));
	QObject::connect(rsApi, SIGNAL(responseReceived(QString)), this, SLOT(handleNotifications(QString)));

	_timer->start();
}

Notifier::~Notifier()
{
	if(rsApi != NULL)
		delete rsApi;

	rsApi = NULL;
}

void Notifier::setAdvMode(bool advmode)
{
	this->advmode = advmode;
}

bool Notifier::getAdvMode()
{
	return advmode;
}

void Notifier::requestNotifications()
{
	rsApi->request("notification/*");
	_timer->start();
}

void Notifier::handleNotifications(QString receivedMsg)
{
	QJsonObject qJsonObject = QJsonDocument::fromJson(receivedMsg.toUtf8()).object();
	QJsonValue jsData = qJsonObject.value("data");
	if(!jsData.isNull())
	{
		QJsonValue jsEvents = jsData.toObject().value("events");

		if(!jsEvents.isNull() && jsEvents.isArray())
		{
			QJsonArray jsEventsArray = jsEvents.toArray();
			for(QJsonArray::iterator it = jsEventsArray.begin(); it != jsEventsArray.end(); it++)
			{
				QJsonValue jsEventType = (*it).toObject().value("eventType");

				switch (jsEventType.toInt())
				{
				case LIST_PRE_CHANGE:
					emit listPreChange();
					break;
				case LIST_CHANGE:
					emit listChange();
					break;
				case ERROR_MSG:
					emit errorMsg();

					break;
				case CHAT_MESSAGE:
				{
					QString chat_id = (*it).toObject().value("chat_id").toString();
					QString chat_type = (*it).toObject().value("chat_type").toString();
					bool incoming = (*it).toObject().value("incoming").toString().toInt();

					emit chatMessage();
					emit chatMessage(chat_id, chat_type, incoming);
					break;
				}
				case CHAT_STATUS:
					emit chatStatus();

					break;
				case CHAT_CLEARED:
					emit chatCleared();

					break;
				case CHAT_LOBBY_EVENT:
					emit chatLobbyEvent();

					break;
				case CHAT_LOBBY_TIME_SHIFT:
					emit chatLobbyTimeShift();

					break;
				case CUSTOM_STATE:
					emit customState();

					break;
				case HASHING_INFO:
					emit hashingInfo();

					break;
				case TURTLE_SEARCH_RESULT:
					emit turtleSearchResult();

					break;
				case PEER_HAS_NEW_AVATAR:
					emit peerHasNewAvatar();

					break;
				case OWN_AVATAR_CHANGED:
					emit ownAvatarChanged();

					break;
				case OWN_STATUS_MESSAGE_CHANGED:
					emit ownStatusMessageChanged();

					break;
				case DISK_FULL:
					emit diskFull();

					break;
				case PEER_STATUS_CHANGED:
					emit peerStatusChanged();

					break;
				case GXS_CHANGE:
					emit gxsChange();

					break;
				case PEER_STATUS_CHANGED_SUMMARY:
					emit peerStatusChangedSummary();

					break;
				case DISC_INFO_CHANGED:
					emit discInfoChanged();

					break;
				case DOWNLOAD_COMPLETE:
					emit downloadComplete();

					break;
				case DOWNLOAD_COMPLETE_COUNT:
					emit downloadCompleteCount();

					break;
				case HISTORY_CHANGED:
					emit peerStatusChanged();

					break;
				default:
					break;
				}
			}
		}
	}
}
