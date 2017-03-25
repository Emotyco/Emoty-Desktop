/****************************************************************
 *  This file is part of Sonet.
 *  Sonet is distributed under the following license:
 *
 *  Copyright (C) 2016  Gioacchino Mazzurco <gio@eigenlab.org>
 *  Copyright (C) 2016  Manu Pineda <manu@cooperativa.cat>
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
#include "libresapilocalclient.h"

#include <QJSEngine>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonValue>

LibresapiLocalClient::LibresapiLocalClient(QObject *parent) : QObject(parent)
{
	mLocalSocket = new QLocalSocket();
}

void LibresapiLocalClient::openConnection(QString socketPath)
{
	connect(mLocalSocket, SIGNAL(error(QLocalSocket::LocalSocketError)),
	        this, SLOT(socketError(QLocalSocket::LocalSocketError)));
	connect(mLocalSocket, SIGNAL(readyRead()),
	        this, SLOT(read()));
	mLocalSocket->connectToServer(socketPath);
}

int LibresapiLocalClient::request( const QString& path, const QString& jsonData,
                                   QJSValue callback )
{
	QByteArray data;
	data.append(path); data.append('\n');
	data.append(jsonData); data.append('\n');

	QJsonObject qJsonObject = QJsonDocument::fromJson(jsonData.toUtf8()).object();
	QJsonValue jsValue = qJsonObject.value("callback_name");

	callbackMap.insert(jsValue.toString(), callback);
	mLocalSocket->write(data);

	return 1;
}

void LibresapiLocalClient::socketError(QLocalSocket::LocalSocketError)
{
	qDebug() << "Socket Eerror!!" << mLocalSocket->errorString();
}

void LibresapiLocalClient::read()
{
	QString receivedMsg(mLocalSocket->readLine());

	if(!callbackMap.isEmpty())
	{
		QJsonObject qJsonObject = QJsonDocument::fromJson(receivedMsg.toUtf8()).object();
		QJsonValue jsValue = qJsonObject.value("callback_name");

		if(callbackMap.contains(jsValue.toString()))
		{
			QJSValue callback(callbackMap.take(jsValue.toString()));
			if(callback.isCallable())
			{
				QJSValue params = callback.engine()->newObject();
				params.setProperty("response", receivedMsg);

				callback.call(QJSValueList { params });
			}
			else
				emit responseReceived(receivedMsg);
		}
		else
			emit responseReceived(receivedMsg);
	}
	else
		emit responseReceived(receivedMsg);
}
