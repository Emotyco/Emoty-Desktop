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
#include "qwinview.h"

//Qt
#include <qevent.h>
#include <QApplication>
#include <qpa/qplatformnativeinterface.h>

QWinView::QWinView(HWND hParentWnd, QObject *parent)
:	QQuickView(),
    hParent(hParentWnd)
{
	if (parent)
		QObject::setParent(parent);

	Q_ASSERT(hParent);
	if(hParent)
		this->setParent(QWindow::fromWinId((WId)hParent));
}

HWND QWinView::parentWindow() const
{
	return hParent;
}
