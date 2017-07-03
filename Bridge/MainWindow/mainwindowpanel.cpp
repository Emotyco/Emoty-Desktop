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
#include "mainwindowpanel.h"

#include <windows.h>
#include <windowsx.h>

//Qt
#include <QApplication>
#include <QQmlEngine>
#include <QQmlContext>
#include <QDir>

//Emoty-GUI
#include "notifier.h"
#include "soundnotifier.h"
#include "Util/runstatehelper.h"
#include "Bridge/Models/contactsmodel.h"

MainWindowPanel::MainWindowPanel(HWND hWnd) : QWinView(hWnd)
{
	windowHandle = hWnd;
	setObjectName("mainWindowPanel");

	this->setResizeMode(QQuickView::SizeRootObjectToView);

	QObject::connect(Notifier::getInstance(), SIGNAL(chatMessage(QString)),
	                 this, SLOT(windowFlashMessageReceived(QString)));

	QQmlEngine *engine = this->engine();
	QObject::connect(engine,SIGNAL(quit()),qApp, SLOT(quit()));
	QPM_INIT((*engine));

	QString sockPath = QDir::homePath() + "/.retroshare";
	sockPath.append("/libresapi.sock");

	rsApi = new LibresapiLocalClient();
	rsApi->openConnection(sockPath);

	base64 = new Base64();
	QQmlContext *ctxt = this->rootContext();
	ctxt->setContextProperty("view", this);
	ctxt->setContextProperty("qMainPanel", this);
	ctxt->setContextProperty("cursor", this);
	ctxt->setContextProperty("control", this);

	ctxt->setContextProperty("notifier", Notifier::getInstance());
	ctxt->setContextProperty("soundNotifier", SoundNotifier::getInstance());
	ctxt->setContextProperty("rsApi", rsApi);
	ctxt->setContextProperty("runStateHelper", RunStateHelper::getInstance());
	ctxt->setContextProperty("base64", base64);

	ctxt->setContextProperty("gxsModel", ContactsModel::getInstance());

	contactsModel = new ContactsSortModel();
	contactsModel->setSourceModel(ContactsModel::getInstance());
	ctxt->setContextProperty("contactsModel", contactsModel);

	identitiesModel = new IdentitiesSortModel();
	identitiesModel->setSourceModel(ContactsModel::getInstance());
	ctxt->setContextProperty("identitiesModel", identitiesModel);

	this->setSource(QUrl("qrc:/Borderless.qml"));
	show();
}

MainWindowPanel::~MainWindowPanel()
{
	if(base64 != NULL)
		delete base64;
	base64 = NULL;

	if(contactsModel != NULL)
		delete contactsModel;
	contactsModel = NULL;

	if(identitiesModel != NULL)
		delete identitiesModel;
	identitiesModel = NULL;
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

void MainWindowPanel::windowFlash()
{
	if((GetActiveWindow() != windowHandle))
		FlashWindow(windowHandle, true);
}

void MainWindowPanel::windowFlashMessageReceived(QString chat_type)
{
	if(chat_type == "distant_chat" || chat_type == "lobby")
	{
		if((GetActiveWindow() != windowHandle))
			FlashWindow(windowHandle, true);
	}
	else if(chat_type == "direct_chat" && Notifier::getInstance()->getAdvMode())
	{
		if((GetActiveWindow() != windowHandle))
			FlashWindow(windowHandle, true);
	}
}
