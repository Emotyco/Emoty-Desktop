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
#include "cardsmodel.h"

int CardsModel::storeCard(QJSValue cardObject, QString name, bool isIcon, QString source, int indicatorNumber)
{
	beginInsertRows(QModelIndex(), cardsList.size(), cardsList.size());
	counter++;
	cardsList.push_back(Card(cardObject, name, isIcon, source, counter, 0));
	endInsertRows();

	return counter;
}

bool CardsModel::removeCard(int index)
{
	std::list<Card>::iterator vit = cardsList.begin();
	for(int i = 0; vit != cardsList.end(); ++vit)
	{
		if ( index == (*vit).index)
		{
			beginRemoveRows(QModelIndex(), i, i);
			cardsList.erase(vit);
			endRemoveRows();
			return true;
		}

		++i;
	}

	return false;
}

QJSValue CardsModel::getCard(int index)
{
	std::list<Card>::iterator vit = cardsList.begin();
	for(int i = 0; vit != cardsList.end(); ++vit)
	{
		if ( index == (*vit).index)
		{
			return (*vit).cardObject;
		}

		++i;
	}
}

QJSValue CardsModel::getCardByListIndex(int index)
{
	std::list<Card>::iterator vit = cardsList.begin();
	for(int i = 0; vit != cardsList.end(); ++vit)
	{
		if ( index == i)
		{
			return (*vit).cardObject;
		}

		++i;
	}
}

bool CardsModel::setIndicatorNumber(int cardIndex, int indicatorNumber)
{
	std::list<Card>::iterator vit = cardsList.begin();
	for(int i = 0; vit != cardsList.end(); ++vit)
	{
		if ( cardIndex == (*vit).index)
		{
			(*vit).indicator = indicatorNumber;
			emit dataChanged(index(i),index(i));

			return true;
		}

		++i;
	}

	return false;
}

int CardsModel::rowCount(const QModelIndex &) const
{
	return cardsList.size();
}

QVariant CardsModel::data(const QModelIndex & index, int role) const
{
	int idx = index.row();

	if(idx < 0 || idx >= cardsList.size())
		return QVariant("Something went wrong...");

	std::list<Card>::const_iterator vit = cardsList.begin();
	for(int i = 0; vit != cardsList.end(); ++vit)
	{
		if(idx == i)
			break;

	  ++i;
	}

	if(role == NameRole)
		return (*vit).name;
	else if(role == IsIconRole)
		return (*vit).isIcon;
	else if(role == SourceRole)
		return (*vit).source;
	else if(role == IndexRole)
		return (*vit).index;
	else if(role == IndicatorRole)
		return (*vit).indicator;

	return QVariant();
}

QHash<int, QByteArray> CardsModel::roleNames() const
{
	QHash<int, QByteArray> roles;

	roles[CardObjectRole] = "cardObject";
	roles[NameRole] = "name";
	roles[IsIconRole] = "isIcon";
	roles[SourceRole] = "source";
	roles[IndexRole] = "cardIndex";
	roles[IndicatorRole] = "indicator";

	return roles;
}
