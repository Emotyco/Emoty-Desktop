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
//Qt
#include <QApplication>
#include <QEventLoop>

//Emoty-GUI
#include "loginwindow_main.h"

#ifdef BORDERLESS_LOGIN
    //Emoty-GUI
    #include "borderlesswindow.h"
    #include "../../util/screensize.h"
#endif
#ifndef BORDERLESS_LOGIN
    //Qt
    #include <QQmlContext>
    #include <QQuickView>
    #include <QQmlEngine>
    #include <QSize>

    //Emoty-GUI
    #include "libresapilocalclient.h"
//    #include "retroshare/rsinit.h"
    #include "Util/runstatehelper.h"
#endif

int loginwindow_main(int argc, char **argv)
{
	QEventLoop app;

#ifndef BORDERLESS_LOGIN
	QQuickView view;
	view.setResizeMode(QQuickView::SizeRootObjectToView);

	view.setMaximumSize(QSize(400, 470));
	view.setMinimumSize(QSize(400, 470));

	QQmlEngine *engine = view.engine();
	QObject::connect(engine,SIGNAL(quit()),&view, SLOT(close()));
	QObject::connect(engine,SIGNAL(quit()),qApp, SLOT(quit()));
	QPM_INIT((*engine));

	QString sockPath;

#ifdef QT_DEBUG
	sockPath = "RS/";
#else
	sockPath = QCoreApplication::applicationDirPath();
#endif

	sockPath.append("/libresapi.sock");

	LibresapiLocalClient rsApi;
	rsApi.openConnection(sockPath);


	QQmlContext *ctxt = view.rootContext();

	ctxt->setContextProperty("rsApi", &rsApi);
	ctxt->setContextProperty("runStateHelper", RunStateHelper::getInstance());
	view.setSource(QUrl("qrc:/Bordered.qml"));
	view.show();
#endif
#ifdef BORDERLESS_LOGIN
	// Background color
	HBRUSH windowBackground = CreateSolidBrush(RGB(255, 255, 255));

	// Create window
	ScreenSize screenSize;
	BorderlessWindow window(windowBackground, (screenSize.width()-400)/2, (screenSize.height()-470)/2, 400, 470);
#endif

	return app.exec();
}
