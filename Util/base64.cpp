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
#include "base64.h"

#include <QByteArray>
#include <QPixmap>
#include <QBuffer>
#include <QDir>

QString Base64::encode(QString string)
{
	QByteArray ba;
	ba.append(string);
	return ba.toBase64();
}

QString Base64::decode(QString string)
{
	QByteArray ba;
	ba.append(string);
	return QByteArray::fromBase64(ba);
}

QString Base64::encode_avatar(QString path)
{
	QPixmap avatar = QPixmap(QDir::fromNativeSeparators(path).remove(0, 8)).scaledToHeight(128, Qt::SmoothTransformation).copy( 0, 0, 128, 128);
	QByteArray ba;
	QBuffer buffer(&ba);
	buffer.open(QIODevice::WriteOnly);
	avatar.save(&buffer, "PNG");
	return QString(ba.toBase64());
}
