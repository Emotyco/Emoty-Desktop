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
#include "mainwindowpanel.h"

#include <windows.h>
#include <windowsx.h>

//Qt
#include <QApplication>
#include <QQmlEngine>
#include <QQmlContext>

//Sonet-GUI
//#include "retroshare/rsinit.h"
#include "Util/runstatehelper.h"

MainWindowPanel::MainWindowPanel(HWND hWnd) : QWinView(hWnd)
{
	windowHandle = hWnd;
	setObjectName("mainWindowPanel");

	this->setResizeMode(QQuickView::SizeRootObjectToView);

	QQmlEngine *engine = this->engine();
	QObject::connect(engine,SIGNAL(quit()),qApp, SLOT(quit()));
	QPM_INIT((*engine));

	QString sockPath;

#ifdef QT_DEBUG
	sockPath = "RS/";
#else
	sockPath = QCoreApplication::applicationDirPath();
#endif

	sockPath.append("/libresapi.sock");

	rsApi = new LibresapiLocalClient();
	rsApi->openConnection(sockPath);

	QQmlContext *ctxt = this->rootContext();
	ctxt->setContextProperty("view", this);
	ctxt->setContextProperty("qMainPanel", this);
	ctxt->setContextProperty("cursor", this);
	ctxt->setContextProperty("control", this);

	ctxt->setContextProperty("rsApi", rsApi);
	ctxt->setContextProperty("runStateHelper", RunStateHelper::getInstance());
	this->setSource(QUrl("qrc:/Borderless.qml"));
	show();
}

// Button events
void MainWindowPanel::pushButtonMinimizeClicked()
{
	ShowWindow(parentWindow(), SW_MINIMIZE);
}

void MainWindowPanel::pushButtonMaximizeClicked()
{
	WINDOWPLACEMENT wp;
	wp.length = sizeof(WINDOWPLACEMENT);
	GetWindowPlacement(parentWindow(), &wp);

	if(wp.showCmd == SW_MAXIMIZE)
		ShowWindow(parentWindow(), SW_RESTORE);
	else
		ShowWindow(parentWindow(), SW_MAXIMIZE);
}

void MainWindowPanel::pushButtonCloseClicked()
{
	PostQuitMessage(0);
}

void MainWindowPanel::mouseLPressed()
{
	ReleaseCapture();
	SendMessage(windowHandle, WM_NCLBUTTONDOWN, HTCAPTION, 0);
}

void MainWindowPanel::hide()
{
	ShowWindow(parentWindow(), SW_HIDE);
}

void MainWindowPanel::changeCursor(int cursorShape)
{
	this->setCursor(Qt::CursorShape(cursorShape));
}

void MainWindowPanel::resizeWin(int x, int y, bool changeposx, bool changeposy)
{
	WINDOWPLACEMENT wp;
	wp.length = sizeof(WINDOWPLACEMENT);
	GetWindowPlacement(windowHandle, &wp);
	if(wp.showCmd != SW_MAXIMIZE)
	{
		RECT winrect;
		GetWindowRect(windowHandle, &winrect);
		long width = winrect.right - winrect.left;
		long height = winrect.bottom - winrect.top;

		if(changeposx && changeposy)
			SetWindowPos(windowHandle, 0, (winrect.left+x), (winrect.top+y), (width-x), (height-y), SWP_NOREDRAW);
		else if(changeposx && !changeposy)
			SetWindowPos(windowHandle, 0, (winrect.left+x), winrect.top, (width-x), (height+y), SWP_NOREDRAW);
		else if(!changeposx && changeposy)
			SetWindowPos(windowHandle, 0, winrect.left, (winrect.top+y), (width+x), (height-y), SWP_NOREDRAW);
		else if(!changeposx && !changeposy)
			SetWindowPos(windowHandle, 0, winrect.left, winrect.top, (width+x), (height+y), SWP_NOREDRAW);
	}
}

void MainWindowPanel::windowAlert(bool incoming)
{
	if(incoming && (GetActiveWindow() != windowHandle))
		FlashWindow(windowHandle, true);
}
