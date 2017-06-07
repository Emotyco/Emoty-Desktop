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
#include "soundnotifier.h"

//Qt
#include <QApplication>
#include <QFile>
#include <QDir>

#include "notifier.h"

/*static*/ SoundNotifier *SoundNotifier::_instance = NULL;

/*static*/ SoundNotifier *SoundNotifier::Create()
{
	if (_instance == NULL)
		_instance = new SoundNotifier();

	return _instance;
}

/*static*/ void SoundNotifier::Destroy()
{
	if(_instance != NULL)
		delete _instance;

	_instance = NULL;
}

/*static*/ SoundNotifier *SoundNotifier::getInstance()
{
	return _instance;
}

SoundNotifier::SoundNotifier(QObject *parent) : QObject(parent)
{
	QDir baseDir = QDir(qApp->applicationDirPath());
	soundsMap.emplace(SOUND_MESSAGE_SENDED, new QSound(QFileInfo(baseDir, "Sounds\\msgsended.wav").absoluteFilePath()));
	soundsMap.emplace(SOUND_MESSAGE_RECEIVED, new QSound(QFileInfo(baseDir, "Sounds\\msgreceived.wav").absoluteFilePath()));

	QObject::connect(Notifier::getInstance(), SIGNAL(chatMessage(QString)), this, SLOT(playChatMessageReceived(QString)));
}

bool SoundNotifier::isMute()
{
	return muted;
}

void SoundNotifier::setMute(bool mute)
{
	muted = mute;
}

void SoundNotifier::play(const QString &sound)
{
	soundsMap.at(sound.toStdString())->play();
}

QSound* SoundNotifier::getSound(const QString &sound)
{
	return soundsMap.at(sound.toStdString());
}

void SoundNotifier::playChatMessageReceived(QString chat_type)
{
	if(chat_type == "distant_chat" || chat_type == "lobby")
		play(SOUND_MESSAGE_RECEIVED);
	else if(chat_type == "direct_chat" && Notifier::getInstance()->getAdvMode())
		play(SOUND_MESSAGE_RECEIVED);
}

void SoundNotifier::playChatMessageSended()
{
	play(SOUND_MESSAGE_SENDED);
}
