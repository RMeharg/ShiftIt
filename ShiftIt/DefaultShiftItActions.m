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

#import "DefaultShiftItActions.h"
#import "FMTDefines.h"

BOOL CloseTo(float a, float b) {
	return fabs(a - b) < 20;
}

BOOL Wide(NSRect screenRect) {
	return screenRect.size.width >= screenRect.size.height;
}

NSRect ShiftIt_Left(NSRect screenRect, NSRect windowRect) {
	NSRect r;
	
	r.origin.x = 0;
	r.origin.y = 0;
	
	r.size.width = screenRect.size.width / 2;
	r.size.height = screenRect.size.height;
	
	float w = windowRect.size.width;
	float h = windowRect.size.height;
	float x = windowRect.origin.x;
	float y = windowRect.origin.y;
	float sw = screenRect.size.width;
	float sh = screenRect.size.height;
	float sx = screenRect.origin.x;
	float sy = screenRect.origin.y;
	
	if (Wide(screenRect)) {
		if (CloseTo(y, sy) && CloseTo(x, sx) && CloseTo(h, sh)) {
			if (CloseTo(w, sw / 2)) {
				r.size.width = floor(sw / 3.0);
			} else if (CloseTo(w, floor(sw / 3.0))) {
				r.size.width = floor(sw * 2.0 / 3.0);
			}		
		}
	} else {
		if (CloseTo(y, screenRect.origin.y + floor((sh - h) / 2)) && CloseTo(x, sx) && CloseTo(h, sh)) {
			if (CloseTo(h, sh)) {
				r.size.height = floor(sh / 3.0);
			}
			r.origin.y = floor((sh - r.size.height) / 2);
		}		
	}
	
	return r;
}

NSRect ShiftIt_Right(NSRect screenRect, NSRect windowRect) {
	NSRect r;
	
	r.origin.y = 0;
	
	r.size.width = screenRect.size.width / 2;
	r.size.height = screenRect.size.height;
	
	float w = windowRect.size.width;
	float h = windowRect.size.height;
	float x = windowRect.origin.x;
	float y = windowRect.origin.y;
	float sw = screenRect.size.width;
	float sh = screenRect.size.height;
	float sx = screenRect.origin.x;
	float sy = screenRect.origin.y;

	if (Wide(screenRect)) {
		if (CloseTo(y, sy) && CloseTo(x, sx + sw - w) && CloseTo(h, sh)) {
			if (CloseTo(w, sw / 2)) {
				r.size.width = floor(sw / 3.0);
			} else if (CloseTo(w, floor(sw / 3.0))) {
				r.size.width = floor(sw * 2.0 / 3.0);
			}
		}
	} else {
		if (CloseTo(y, sy + floor((sh - h) / 2)) && CloseTo(x, sx + sw - w) && CloseTo(h, sh)) {
			if (CloseTo(h, sh)) {
				r.size.height = floor(sh / 3.0);
			}
			r.origin.y = floor((sh - r.size.height) / 2);
		}				
	}
	
	r.origin.x = sw - r.size.width;

	return r;
}

NSRect ShiftIt_Top(NSRect screenRect, NSRect windowRect) {
	NSRect r;
	
	r.origin.y = 0;
	r.origin.x = 0;
	
	r.size.width = screenRect.size.width;
	r.size.height = screenRect.size.height / 2;
	
	float w = windowRect.size.width;
	float h = windowRect.size.height;
	float x = windowRect.origin.x;
	float y = windowRect.origin.y;
	float sw = screenRect.size.width;
	float sh = screenRect.size.height;
	float sx = screenRect.origin.x;
	float sy = screenRect.origin.y;
	
	if (Wide(screenRect)) {
		if (CloseTo(y, sy) && CloseTo(x, sx + floor((sw - w) / 2)) && CloseTo(h, sh / 2)) {
			if (CloseTo(w, sw)) {
				r.size.width = floor(sw / 3.0);
			}
		}
		r.origin.x = floor((sw - r.size.width) / 2);
	} else {
		if (CloseTo(y, sy) && CloseTo(x, sx) && CloseTo(w, sw)) {
			if (CloseTo(h, sh / 2)) {
				r.size.height = floor(sh / 3.0);
			} else if (CloseTo(h, floor(sh / 3.0))) {
				r.size.height = floor(sh * 2.0 / 3.0);
			}		
		}		
	}
	
	return r;
}

NSRect ShiftIt_Bottom(NSRect screenRect, NSRect windowRect) {
	NSRect r;
	
	r.origin.y = screenRect.size.height / 2;
	r.origin.x = 0;
	
	r.size.width = screenRect.size.width;
	r.size.height = screenRect.size.height / 2;
	
	float w = windowRect.size.width;
	float h = windowRect.size.height;
	float x = windowRect.origin.x;
	float y = windowRect.origin.y;
	float sw = screenRect.size.width;
	float sh = screenRect.size.height;
	float sx = screenRect.origin.x;
	float sy = screenRect.origin.y;	
	
	if (Wide(screenRect)) {
		if (CloseTo(y, sy + sh / 2) && CloseTo(x, sx + floor((sw - w) / 2)) && CloseTo(h, sh / 2)) {
			if (CloseTo(w,sw)) {
				r.size.width = floor(sw / 3.0);
			}
		}
		r.origin.x = floor((sw - r.size.width) / 2);
	} else {
		if (CloseTo(y, sy + sh - h) && CloseTo(x, sx) && CloseTo(w, sw)) {
			if (CloseTo(h, sh / 2)) {
				r.size.height = floor(sh / 3.0);
			} else if (CloseTo(h, floor(sh / 3.0))) {
				r.size.height = floor(sh * 2.0 / 3.0);
			}		
		}
		r.origin.y = sh - r.size.height;
	}
	
	return r;
}

NSRect ShiftIt_FullScreen(NSRect screenRect, NSRect windowRect) {
	NSRect r;
	
	r.origin.x = 0;
	r.origin.y = 0;
	
	r.size.width = screenRect.size.width;
	r.size.height = screenRect.size.height;
	
	return r;
}

NSRect ShiftIt_Center(NSRect screenRect, NSRect windowRect) {
	NSRect r;
	
	float w = floor(screenRect.size.width * 0.85);
	float h = floor(screenRect.size.height * 0.85);
	
	if (CloseTo(w, windowRect.size.width) && CloseTo(h, windowRect.size.height)) {
		w = floor(screenRect.size.width * 0.6);
		h = floor(screenRect.size.height * 0.6);
	}

	
	r.origin.x = (screenRect.size.width / 2) - (w / 2);
	r.origin.y = (screenRect.size.height / 2) - (h / 2);	
	
	r.size.width = w;
	r.size.height = h;
	
	return r;
}
