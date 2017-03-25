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
#ifndef LIBRESAPILOCALCLIENT_H
#define LIBRESAPILOCALCLIENT_H

#include <QLocalSocket>
#include <QJSValue>
#include <QMap>

class LibresapiLocalClient : public QObject
{
	Q_OBJECT

public:
	LibresapiLocalClient(QObject *parent = 0);

	Q_INVOKABLE int request( const QString& path, const QString& jsonData = "",
	                            QJSValue callback = QJSValue::NullValue);
	Q_INVOKABLE void openConnection(QString socketPath);

signals:
	/**
		* @brief responseReceived emitted when a response is received
		* @param msg
	*/
	void responseReceived(const QString & msg);

private slots:
	void socketError(QLocalSocket::LocalSocketError error);
	void read();

private:
	QLocalSocket *mLocalSocket;
	QMap<QString, QJSValue> callbackMap;
};

#endif // LIBRESAPILOCALCLIENT_H
