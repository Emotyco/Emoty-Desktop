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
#ifndef CARDSMODEL_H
#define CARDSMODEL_H

//Qt
#include <QAbstractListModel>
#include <QQmlEngine>
#include <QJSValue>
#include <QMap>

class CardsModel : public QAbstractListModel
{
	Q_OBJECT
public:
	enum IvitationRoles{
		CardObjectRole,
		NameRole,
		IsIconRole,
		SourceRole,
		IndexRole
	};

	CardsModel(QObject *parent = 0)
	    : QAbstractListModel(parent), counter(0)
	{}

	virtual int rowCount(const QModelIndex & parent = QModelIndex()) const override;
	virtual QVariant data(const QModelIndex & index, int role = Qt::DisplayRole) const override;

public slots:
	int storeCard(QJSValue cardObject, QString name, bool isIcon, QString source);
	bool removeCard(int index);
	QJSValue getCard(int index);
	QJSValue getCardByListIndex(int index);

protected:
	virtual QHash<int, QByteArray> roleNames() const;

private:
	struct Card {
		Card(QJSValue cardObject, QString name,
		     bool isIcon, QString source, int index)
		    : cardObject(cardObject), name(name),
		      isIcon(isIcon), source(source), index(index)
		{}

		QJSValue cardObject;
		QString name;
		bool isIcon;
		QString source;
		int index;
	};

	int counter;
	std::list<Card> cardsList;
};

static void registerCardsModelTypes() {
	qmlRegisterType<CardsModel>("CardsModel", 0, 2, "CardsModel");
}

#endif // CARDSMODEL_H
