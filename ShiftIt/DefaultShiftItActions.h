/*
 ShiftIt: Resize windows with Hotkeys
 Copyright (C) 2010  Filip Krikava
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 
 */

#import <Foundation/Foundation.h>

BOOL CloseTo(float a, float b);
BOOL Wide(NSRect screenRect);

NSRect ShiftIt_Left(NSRect screenRect, NSRect windowRect);
NSRect ShiftIt_Right(NSRect screenRect, NSRect windowRect);
NSRect ShiftIt_Top(NSRect screenRect, NSRect windowRect);
NSRect ShiftIt_Bottom(NSRect screenRect, NSRect windowRect);
NSRect ShiftIt_FullScreen(NSRect screenRect, NSRect windowRect);
NSRect ShiftIt_Center(NSRect screenRect, NSRect windowRect);
NSRect ShiftIt_SwapScreen(NSRect screenRect, NSRect windowRect);
