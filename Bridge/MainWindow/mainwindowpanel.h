/****************************************************************
 *  This file is part of Emoty.
 *  Emoty is distributed under the following license:
 *
 *  Copyright (c) 2015: Deimos
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
/* File is originally from https://github.com/deimos1877/BorderlessWindow */
#ifndef MainWindowPanel_H
#define MainWindowPanel_H

//Emoty-GUI
#include "Bridge/Windows/qwinview.h"
#include "libresapilocalclient.h"
#include "Util/base64.h"
#include "Util/gxsavatars.h"
#include "Bridge/Models/contactssortmodel.h"
#include "Bridge/Models/identitiessortmodel.h"

class MainWindowPanel : public QWinView
{
	Q_OBJECT

public:
	MainWindowPanel(HWND hWnd);
	~MainWindowPanel();

public slots:
	void pushButtonMinimizeClicked();
	void pushButtonMaximizeClicked();
	void pushButtonCloseClicked();
	void mouseLPressed();
	void changeCursor(int cursorShape);

	void resizeWin(int x, int y, bool changeposx, bool changeposy);
	void hide();

	void windowFlash();
	void windowFlashMessageReceived(QString chat_type);

private:
	HWND windowHandle;
	LibresapiLocalClient *rsApi;
	Base64 *base64;
	GXSAvatars *gxs_avatars;

	ContactsSortModel *contactsModel;
	IdentitiesSortModel *identitiesModel;
};

#endif // MainWindowPanel_H
