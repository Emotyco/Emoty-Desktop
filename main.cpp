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

#include <QApplication>
#include <QSystemTrayIcon>
#include <QMenu>
#include <QAction>
#include <QQmlEngine>
#include <QQmlContext>

#ifndef QT_DEBUG
    #include <QProcess>
#endif

#include "libresapilocalclient.h"
#include "notifier.h"
#include "soundnotifier.h"
#include "Bridge/LoginWindow/loginwindow_main.h"
#include "Util/runstatehelper.h"
#include "Util/screensize.h"

#ifndef BORDERLESS_MAINWINDOW
    #include <QDir>

    #include "Util/cursorshape.h"
    #include "Util/qquickviewhelper.h"
#endif
#ifdef BORDERLESS_MAINWINDOW
    #include "Bridge/MainWindow/mainwindow.h"
#endif

int main(int argc, char *argv[])
{
	QApplication app(argc, argv);

	RunStateHelper::Create();
	Notifier::Create();
	SoundNotifier::Create();

#ifndef QT_DEBUG
	QProcess *process = new QProcess();
	QString file = QCoreApplication::applicationDirPath() + "/RS-Core.exe";
	process->start(file);
	QObject::connect(qApp, SIGNAL(aboutToQuit()), process, SLOT(kill()));
#endif

	loginwindow_main(argc, argv);

	if(RunStateHelper::getInstance()->getRunState() != "running_ok" && RunStateHelper::getInstance()->getRunState() != "waiting_startup")
	{
#ifndef QT_DEBUG
		process->kill();
#endif
		return 0;
	}

	QApplication::setQuitOnLastWindowClosed(false);

	QPixmap pixmap(32, 32);
	pixmap.fill(QColor("#4caf50"));
	QIcon icon(pixmap);

	/** Tray Icon Menu **/
	QMenu *trayMenu = new QMenu();
	QAction *quitAction = new QAction("Quit", trayMenu);
	QObject::connect(quitAction, &QAction::triggered, qApp, &QCoreApplication::quit);
	trayMenu->addAction(quitAction);

	/** End of Icon Menu **/

	QSystemTrayIcon trayIcon(icon);
	trayIcon.setContextMenu(trayMenu);

	trayIcon.show();

#ifndef BORDERLESS_MAINWINDOW
	QQuickView *view = new QQuickView;
	view->setResizeMode(QQuickView::SizeRootObjectToView);

	QQmlEngine *engine = view->engine();
	QObject::connect(engine,SIGNAL(quit()),qApp, SLOT(quit()));
	QPM_INIT((*engine));

	QQmlContext *ctxt = view->rootContext();
	ctxt->setContextProperty("view", view);

	QQuickViewHelper helper(view);
	QObject::connect(Notifier::getInstance(), SIGNAL(chatMessage(QString)), helper, SLOT(flashMessageReceived(QString)));

	CursorShape cursor(view);
	ctxt->setContextProperty("cursor", &cursor);

	QString sockPath = QDir::homePath() + "/.retroshare";
	sockPath.append("/libresapi.sock");

	LibresapiLocalClient rsApi;
	rsApi.openConnection(sockPath);

	ctxt->setContextProperty("notifier", Notifier::getInstance());
	ctxt->setContextProperty("soundNotifier", SoundNotifier::getInstance());
	ctxt->setContextProperty("rsApi", &rsApi);
	ctxt->setContextProperty("runStateHelper", RunStateHelper::getInstance());

	view->setSource(QUrl("qrc:/MainGUI.qml"));
	// Create window
	ScreenSize screenSize;
	view->setWidth(screenSize.width()/2);
	view->setHeight(screenSize.height()/2);
	view->setMinimumWidth(600);
	view->setMinimumHeight(300);
	view->show();

	QObject::connect(&trayIcon, SIGNAL(activated(QSystemTrayIcon::ActivationReason)), &helper, SLOT(showViaSystemTrayIcon(QSystemTrayIcon::ActivationReason)));
#endif
#ifdef BORDERLESS_MAINWINDOW
	// Background color
	HBRUSH windowBackground = CreateSolidBrush( RGB( 255, 255, 255 ) );

	// Create window
	ScreenSize screenSize;
	MainWindow window( windowBackground, screenSize.width()/4, screenSize.height()/4, screenSize.width()/2, screenSize.height()/2 );
	window.setMinimumSize(600, 300);

	QObject::connect(&trayIcon, SIGNAL(activated(QSystemTrayIcon::ActivationReason)), &window, SLOT(showViaSystemTrayIcon(QSystemTrayIcon::ActivationReason)));
#endif

	return app.exec();
}
