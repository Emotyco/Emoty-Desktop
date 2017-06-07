/*
 * libresapi local socket client
 * Copyright (C) 2016  Gioacchino Mazzurco <gio@eigenlab.org>
 * Copyright (C) 2016  Manu Pineda <manu@cooperativa.cat>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef LIBRESAPILOCALCLIENT_H
#define LIBRESAPILOCALCLIENT_H

#include <QLocalSocket>
#include <QQueue>
#include <QJSValue>

class LibresapiLocalClient : public QObject
{
	Q_OBJECT

public:
	LibresapiLocalClient() :
#ifdef QT_DEBUG
	    reqCount(0), ansCount(0), mDebug(false),
#endif // QT_DEBUG
	    mLocalSocket(this) {}

	Q_INVOKABLE int request( const QString& path, const QString& jsonData = "",
	                         QJSValue callback = QJSValue::NullValue );
	Q_INVOKABLE void openConnection(QString socketPath);

#ifdef QT_DEBUG
	Q_PROPERTY(bool debug READ debug WRITE setDebug NOTIFY debugChanged)

	bool debug() const { return mDebug; }
	void setDebug(bool v);

	uint64_t reqCount;
	uint64_t ansCount;
	bool mDebug;
#endif // QT_DEBUG

private:
	QLocalSocket mLocalSocket;

	struct PQRecord
	{
		PQRecord( const QString& path, const QString& jsonData,
		          const QJSValue& callback);

#ifdef QT_DEBUG
		QString mPath;
		QString mJsonData;
#endif //QT_DEBUG

		QJSValue mCallback;
	};
	QQueue<PQRecord> processingQueue;

private slots:
	void socketError(QLocalSocket::LocalSocketError error);
	void read();

signals:
	/// @deprecated @see LibresapiLocalClient::responseReceived instead
	void goodResponseReceived(const QString & msg);

	/**
	 * @brief responseReceived emitted when a response is received
	 * @param msg
	 */
	void responseReceived(const QString & msg);

#ifdef QT_DEBUG
	void debugChanged();
#endif //  QT_DEBUG
};

#endif // LIBRESAPILOCALCLIENT_H
