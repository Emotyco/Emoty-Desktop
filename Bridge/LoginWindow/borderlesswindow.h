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
#ifndef BORDERLESSWINDOW_H
#define BORDERLESSWINDOW_H

#include <windows.h>

//Qt
#include <QApplication>

//Emoty-GUI
#include "Bridge/LoginWindow/QMainPanel.h"
#include "Bridge/Windows/qwinview.h"

class BorderlessWindow
{
	enum class Style : DWORD
	{
		windowed = (WS_OVERLAPPEDWINDOW | WS_CAPTION | WS_SYSMENU | WS_MINIMIZEBOX | WS_MAXIMIZEBOX | WS_THICKFRAME | WS_CLIPCHILDREN | WS_SYSMENU),
		aero_borderless = (WS_POPUP | WS_CAPTION | WS_SYSMENU | WS_MINIMIZEBOX | WS_MAXIMIZEBOX | WS_THICKFRAME | WS_CLIPCHILDREN)
	};

public:
	HWND hWnd;
	HINSTANCE hInstance;

	BorderlessWindow(HBRUSH windowBackground, const int x, const int y, const int width, const int height);
	    ~BorderlessWindow();

	static LRESULT CALLBACK WndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam);
	void show();
	void hide();
	bool isVisible();

	void toggleBorderless();
	void toggleShadow();
	void toggleResizeable();
	bool isResizeable();

	void setMinimumSize(const int width, const int height);
	bool isSetMinimumSize();
	void removeMinimumSize();
	int getMinimumHeight();
	int getMinimumWidth();

	void setMaximumSize(const int width, const int height);
	bool isSetMaximumSize();
	int getMaximumHeight();
	int getMaximumWidth();
	void removeMaximumSize();

private:
	static QMainPanel *mainPanel;

	bool closed;
	bool visible;

	bool borderless;
	bool aeroShadow;
	bool borderlessResizeable;

	struct sizeType
	{
		sizeType() : required(false), width(0), height(0) {}
		bool required;
		int width;
		int height;
	};

	sizeType minimumSize;
	sizeType maximumSize;
};

#endif // BORDERLESSWINDOW_H
