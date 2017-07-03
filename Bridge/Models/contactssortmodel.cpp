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
#include "contactssortmodel.h"

ContactsSortModel::ContactsSortModel(QObject *parent)
 : QSortFilterProxyModel(parent)
{
	setDynamicSortFilter(true);
	sort(0);
}

bool ContactsSortModel::filterAcceptsRow(int sourceRow,
        const QModelIndex &sourceParent) const
{
	QModelIndex index = sourceModel()->index(sourceRow, 0, sourceParent);

	if(searchText == "")
		return sourceModel()->data(index, 5).toBool();
	else
		return (sourceModel()->data(index, 5).toBool()
		        && sourceModel()->data(index, 0).toString().contains(searchText, Qt::CaseInsensitive));
}

bool ContactsSortModel::lessThan(const QModelIndex &left,
                                      const QModelIndex &right) const
{
	QString leftUnreadCount = sourceModel()->data(left, 4).toString();
	QString rightUnreadCount = sourceModel()->data(right, 4).toString();

	if(leftUnreadCount != rightUnreadCount)
		return QString::compare(leftUnreadCount, rightUnreadCount) > 0;

	bool leftLinked = sourceModel()->data(left, 6).toBool();
	bool rightLinked = sourceModel()->data(right, 6).toBool();

	if(leftLinked != rightLinked)
		return leftLinked;

	QString leftName = sourceModel()->data(left, 0).toString();
	QString rightName = sourceModel()->data(right, 0).toString();

	return QString::localeAwareCompare(leftName, rightName) < 0;
}

void ContactsSortModel::setSearchText(QString search)
{
	searchText = search;
	invalidateFilter();
}
