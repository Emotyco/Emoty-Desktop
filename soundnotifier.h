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
#ifndef SOUNDNOTIFIER_H
#define SOUNDNOTIFIER_H

//Qt
#include <QObject>
#include <QMap>
#include <QSound>

#define SOUND_MESSAGE_SENDED    "MessageSended"
#define SOUND_MESSAGE_RECEIVED  "MessageReceived"

class SoundNotifier : public QObject
{
	Q_OBJECT

public:
	static SoundNotifier *Create();
	static void Destroy();
	static SoundNotifier *getInstance();

	void play(const QString &sound);
	QSound* getSound(const QString &sound);

	bool isMute();

public slots:
	void setMute(bool mute);
	void playChatMessageReceived(QString chat_type);
	void playChatMessageSended();

private:
	SoundNotifier(QObject *parent = 0);
	static SoundNotifier *_instance;

	std::map<std::string, QSound*> soundsMap;
	bool muted;
};

#endif	//SOUNDNOTIFIER_H
