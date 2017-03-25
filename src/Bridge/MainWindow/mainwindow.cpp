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
#include "MainWindow.h"

#include <dwmapi.h>
#include <windowsx.h>

//std
#include <stdexcept>

//Qt
#include <QFile>

HWND winId = 0;

MainWindowPanel *MainWindow::mainPanel;

MainWindow::MainWindow(HBRUSH windowBackground, const int x, const int y, const int width, const int height, QObject *parent)
:	QObject(parent),
    hWnd(0),
    hInstance(GetModuleHandle(NULL)),
    borderless(false),
    borderlessResizeable(true),
    aeroShadow(false),
    closed(false),
    visible(false)
{
	WNDCLASSEX wcx = {0};
	wcx.cbSize = sizeof(WNDCLASSEX);
	wcx.style = CS_HREDRAW | CS_VREDRAW;
	wcx.hInstance = hInstance;
	wcx.lpfnWndProc = WndProc;
	wcx.cbClsExtra = 0;
	wcx.cbWndExtra = 0;
	wcx.lpszClassName = L"MainWindowClass";
	wcx.hbrBackground = windowBackground;
	wcx.hCursor = LoadCursor(hInstance, IDC_ARROW);
	RegisterClassEx(&wcx);
	if(FAILED(RegisterClassEx(&wcx)))
		throw std::runtime_error("Couldn't register window class");

	hWnd = CreateWindow(L"MainWindowClass", L"Sonet", static_cast<DWORD>(Style::windowed), x, y, width, height, 0, 0, hInstance, nullptr);

	if(!hWnd)
		throw std::runtime_error("Couldn't create window because of reasons");

	SetWindowLongPtr(hWnd, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(this));

	mainPanel = new MainWindowPanel(hWnd);
	winId = (HWND)mainPanel->winId();

	show();

	toggleBorderless();
}

MainWindow::~MainWindow()
{
	hide();
	DestroyWindow(hWnd);
}

LRESULT CALLBACK MainWindow::WndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
	MainWindow *window = reinterpret_cast<MainWindow*>(GetWindowLongPtr(hWnd, GWLP_USERDATA));
	if(!window)
	  return DefWindowProc(hWnd, message, wParam, lParam);

	switch(message)
	{
	case WM_KEYDOWN:
	{
		if(wParam != VK_TAB)
			return DefWindowProc(hWnd, message, wParam, lParam);

		SetFocus(winId);
		break;
	}

	// ALT + SPACE
	case WM_SYSKEYDOWN:
	{
		if(wParam == VK_SPACE)
		{
			HMENU hMenu = GetSystemMenu(hWnd, FALSE);
			if(hMenu)
			{
				MENUITEMINFO mii;
				mii.cbSize = sizeof(MENUITEMINFO);
				mii.fMask = MIIM_STATE;
				mii.fType = 0;

				mii.fState = MF_ENABLED;
				SetMenuItemInfo(hMenu, SC_RESTORE, FALSE, &mii);
				SetMenuItemInfo(hMenu, SC_SIZE, FALSE, &mii);
				SetMenuItemInfo(hMenu, SC_MOVE, FALSE, &mii);
				SetMenuItemInfo(hMenu, SC_MAXIMIZE, FALSE, &mii);
				SetMenuItemInfo(hMenu, SC_MINIMIZE, FALSE, &mii);

				mii.fState = MF_GRAYED;

				WINDOWPLACEMENT wp;
				GetWindowPlacement(hWnd, &wp);

				switch(wp.showCmd)
				{
				case SW_SHOWMAXIMIZED:
					SetMenuItemInfo(hMenu, SC_SIZE, FALSE, &mii);
					SetMenuItemInfo(hMenu, SC_MOVE, FALSE, &mii);
					SetMenuItemInfo(hMenu, SC_MAXIMIZE, FALSE, &mii);
					SetMenuDefaultItem(hMenu, SC_CLOSE, FALSE);
					break;
				case SW_SHOWMINIMIZED:
					SetMenuItemInfo(hMenu, SC_MINIMIZE, FALSE, &mii);
					SetMenuDefaultItem(hMenu, SC_RESTORE, FALSE);
					break;
				case SW_SHOWNORMAL:
					SetMenuItemInfo(hMenu, SC_RESTORE, FALSE, &mii);
					SetMenuDefaultItem(hMenu, SC_CLOSE, FALSE);
					break;
				}

				RECT winrect;
				GetWindowRect(hWnd, &winrect);

				LPARAM cmd = TrackPopupMenu(hMenu, (TPM_RIGHTBUTTON | TPM_NONOTIFY | TPM_RETURNCMD),
				                            winrect.left, winrect.top, NULL, hWnd, NULL);

				if(cmd)
					PostMessage(hWnd, WM_SYSCOMMAND, cmd, 0);
			}
			return 0;
		}
		return DefWindowProc(hWnd, message, wParam, lParam);
	}

	case WM_COMMAND:
	{
		SendMessage(hWnd, WM_SYSCOMMAND, wParam, lParam);
		return DefWindowProc(hWnd, message, wParam, lParam);
	}

	case WM_SETFOCUS:
	{
		SetFocus(winId);
		break;
	}

	case WM_NCCALCSIZE:
	{
		//this kills the window frame and title bar we added with
		//WS_THICKFRAME and WS_CAPTION
		if(window->borderless)
			return 0;

		break;
	}

	case WM_DESTROY:
	{
		delete(mainPanel);
		PostQuitMessage(0);

		break;
	}

	case WM_NCHITTEST:
	{
		if(window->borderless)
		{
			if(window->borderlessResizeable)
			{
				const LONG borderWidth = 8; //in pixels
				RECT winrect;
				GetWindowRect(hWnd, &winrect);
				long x = GET_X_LPARAM(lParam);
				long y = GET_Y_LPARAM(lParam);

				//bottom left corner
				if(x >= winrect.left && x < winrect.left + borderWidth &&
				    y < winrect.bottom && y >= winrect.bottom - borderWidth)
				{
					return HTBOTTOMLEFT;
				}
				//bottom right corner
				if(x < winrect.right && x >= winrect.right - borderWidth &&
				    y < winrect.bottom && y >= winrect.bottom - borderWidth)
				{
					return HTBOTTOMRIGHT;
				}
				//top left corner
				if(x >= winrect.left && x < winrect.left + borderWidth &&
				    y >= winrect.top && y < winrect.top + borderWidth)
				{
					return HTTOPLEFT;
				}
				//top right corner
				if(x < winrect.right && x >= winrect.right - borderWidth &&
				    y >= winrect.top && y < winrect.top + borderWidth)
				{
					return HTTOPRIGHT;
				}
				//left border
				if(x >= winrect.left && x < winrect.left + borderWidth)
				{
					return HTLEFT;
				}
				//right border
				if(x < winrect.right && x >= winrect.right - borderWidth)
				{
					return HTRIGHT;
				}
				//bottom border
				if(y < winrect.bottom && y >= winrect.bottom - borderWidth)
				{
					return HTBOTTOM;
				}
				//top border
				if(y >= winrect.top && y < winrect.top + borderWidth)
				{
					return HTTOP;
				}
			}
			return HTCAPTION;
		}
		break;
	}

	case WM_SIZE:
	{
		RECT winrect;
		GetClientRect(hWnd, &winrect);

		WINDOWPLACEMENT wp;
		wp.length = sizeof(WINDOWPLACEMENT);
		GetWindowPlacement(hWnd, &wp);
		if(wp.showCmd == SW_MAXIMIZE)
			mainPanel->setGeometry( 8,8,winrect.right-16,winrect.bottom-16);
		else
			mainPanel->setGeometry( 0,0,winrect.right,winrect.bottom);

		return DefWindowProc(hWnd, message, wParam, lParam);
	}

	case WM_GETMINMAXINFO:
	{
		MINMAXINFO* minMaxInfo = (MINMAXINFO*)lParam;
		if(window->minimumSize.required)
		{
			minMaxInfo->ptMinTrackSize.x = window->getMinimumWidth();
			minMaxInfo->ptMinTrackSize.y = window->getMinimumHeight();
		}

		if(window->maximumSize.required)
		{
			minMaxInfo->ptMaxTrackSize.x = window->getMaximumWidth();
			minMaxInfo->ptMaxTrackSize.y = window->getMaximumHeight();
		}
		return 0;
	}

	case WM_CLOSE:
	{
		window->hide();
		return 0;
	}
	}
	return DefWindowProc(hWnd, message, wParam, lParam);
}

void MainWindow::toggleBorderless()
{
	if(visible)
	{
		Style newStyle = (borderless) ? Style::windowed : Style::aero_borderless;
		SetWindowLongPtr(hWnd, GWL_STYLE, static_cast<LONG>(newStyle));

		borderless = !borderless;
		if(newStyle == Style::aero_borderless)
		{
			toggleShadow();
		}
		//redraw frame
		SetWindowPos(hWnd, 0, 0, 0, 0, 0, SWP_FRAMECHANGED | SWP_NOMOVE | SWP_NOSIZE);
		show();
	}
}

void MainWindow::toggleShadow()
{
	if(borderless)
	{
		aeroShadow = !aeroShadow;
		const MARGINS shadow_on = {1, 1, 1, 1};
		const MARGINS shadow_off = {0, 0, 0, 0};
		DwmExtendFrameIntoClientArea(hWnd, (aeroShadow) ? (&shadow_on) : (&shadow_off));
	}
}

void MainWindow::toggleResizeable()
{
	borderlessResizeable = borderlessResizeable ? false : true;
}

bool MainWindow::isResizeable()
{
	return borderlessResizeable ? true : false;
}

void MainWindow::showViaSystemTrayIcon(QSystemTrayIcon::ActivationReason reason)
{
	if(reason == QSystemTrayIcon::Trigger)
	{
		ShowWindow(hWnd, SW_SHOW);
		visible = true;
	}
}

void MainWindow::show()
{
	ShowWindow(hWnd, SW_SHOW);
	visible = true;
}

void MainWindow::hide()
{
	ShowWindow(hWnd, SW_HIDE);
	visible = false;
}

bool MainWindow::isVisible()
{
	return visible ? true : false;
}

// Minimum size
void MainWindow::setMinimumSize(const int width, const int height)
{
	this->minimumSize.required = true;
	this->minimumSize.width = width;
	this->minimumSize.height = height;
}

bool MainWindow::isSetMinimumSize()
{
	return this->minimumSize.required;
}

void MainWindow::removeMinimumSize()
{
	this->minimumSize.required = false;
	this->minimumSize.width = 0;
	this->minimumSize.height = 0;
}

int MainWindow::getMinimumWidth()
{
	return minimumSize.width;
}

int MainWindow::getMinimumHeight()
{
	return minimumSize.height;
}

// Maximum size
void MainWindow::setMaximumSize(const int width, const int height)
{
	this->maximumSize.required = true;
	this->maximumSize.width = width;
	this->maximumSize.height = height;
}

bool MainWindow::isSetMaximumSize()
{
	return this->maximumSize.required;
}

void MainWindow::removeMaximumSize()
{
	this->maximumSize.required = false;
	this->maximumSize.width = 0;
	this->maximumSize.height = 0;
}

int MainWindow::getMaximumWidth()
{
	return maximumSize.width;
}

int MainWindow::getMaximumHeight()
{
	return maximumSize.height;
}
