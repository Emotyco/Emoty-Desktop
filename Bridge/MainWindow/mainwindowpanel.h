/****************************************************************
 *  This file is part of Sonet.
 *  Sonet is distributed under the following license:
 *
 *  Copyright (c) 2015: Deimos
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
/* File is originally from https://github.com/deimos1877/BorderlessWindow */
#ifndef MainWindowPanel_H
#define MainWindowPanel_H

//Sonet-GUI
#include "Bridge/Windows/qwinview.h"
#include "libresapilocalclient.h"

class MainWindowPanel : public QWinView
{
	Q_OBJECT

public:
	MainWindowPanel(HWND hWnd);

public slots:
	void pushButtonMinimizeClicked();
	void pushButtonMaximizeClicked();
	void pushButtonCloseClicked();
	void mouseLPressed();
	void changeCursor(int cursorShape);

	void resizeWin(int x, int y, bool changeposx, bool changeposy);
	void hide();

	void windowAlert();

private:
	HWND windowHandle;
	LibresapiLocalClient *rsApi;
};

#endif // MainWindowPanel_H
