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

#import "ShiftComputer.h"
#import "NSScreen+Coordinates.h"
#import "FMTDefines.h"

#define NSStringFromCGRect(rect) [NSString stringWithFormat:@"[%f, %f] [%f, %f]", (rect).origin.x, (rect).origin.y, (rect).size.width, (rect).size.height]
#define CGPointCenterOfCGRect(rect) CGPointMake((rect).origin.x + (rect).size.width / 2, (rect).origin.y + (rect).size.height / 2)

BOOL AreClose(float a, float b) {
	return fabs(a - b) < 20;
}

BOOL SizesAreClose(CGSize a, CGSize b) {
	return AreClose(a.width, b.width) && AreClose(a.height, b.height);
}


CGRect lastWindowRect = {{0,0},{0,0}};

typedef enum {
    topLeft,
    topRight,
    bottomRight,
    bottomLeft,
    center
} Origin;

@interface ShiftComputer ()

@property (nonatomic, assign) AXUIElementRef window;
@property (nonatomic, assign) CGRect windowRect;
@property (nonatomic, retain) NSScreen *currentScreen;
@property (nonatomic, assign) BOOL isWide;

- (AXUIElementRef)identifyFocusedWindowAndMetrics;
- (CGRect)measureWindowRectangle;
- (NSScreen *)identifyCurrentScreen;

- (CGRect)setWindowSize:(CGSize)windowSize andSnapOrigin:(Origin)Origin to:(CGPoint)point;

- (float)snapToThirdsForValue:(float)value containerValue:(float)containerValue ifOrigin:(Origin)Origin isNearPoint:(CGPoint)point;
- (BOOL)origin:(Origin)Origin isNearPoint:(CGPoint)point;

@end

@implementation ShiftComputer

@synthesize window, windowRect, currentScreen, isWide;

//ShiftComputer replaces windowSizer... X11 later.
//No need to pass windowRect.  initialize will pull out the focused window, and this class will manage all screen related things, etc..

+ (ShiftComputer *)shiftComputer {
    return [[[ShiftComputer alloc] init] autorelease];
}

- (id)init {
    self = [super init];
    if (self) {
        self.window = [self identifyFocusedWindowAndMetrics];
        if (!self.window) return nil;
        self.windowRect = [self measureWindowRectangle];
        self.currentScreen = [self identifyCurrentScreen];
        self.isWide = self.currentScreen.visibleFrame.size.width > self.currentScreen.visibleFrame.size.height;
    }
    
    return self;
}

- (void)dealloc {
    CFRelease(self.window);
    self.window = nil;
    self.currentScreen = nil;
    [super dealloc];
}

- (AXUIElementRef)identifyFocusedWindowAndMetrics {
    AXUIElementRef systemElementRef = AXUIElementCreateSystemWide();
    
    AXUIElementRef focusedAppRef = nil;
	AXError axerror = AXUIElementCopyAttributeValue(systemElementRef,kAXFocusedApplicationAttribute, (CFTypeRef *) &focusedAppRef);
	CFRelease(systemElementRef);
    if (axerror != kAXErrorSuccess) return nil;
    
	AXUIElementRef focusedWindowRef = nil;
	axerror = AXUIElementCopyAttributeValue(focusedAppRef,(CFStringRef)NSAccessibilityFocusedWindowAttribute,(CFTypeRef*)&focusedWindowRef);
	CFRelease(focusedAppRef);
    if (axerror != kAXErrorSuccess) return nil;
    
    return focusedWindowRef;
}

- (CGRect)measureWindowRectangle {
    NSPoint position;
	CFTypeRef positionRef;
    AXError axerror = AXUIElementCopyAttributeValue(self.window,(CFStringRef)NSAccessibilityPositionAttribute,(CFTypeRef*)&positionRef);
	if (axerror != kAXErrorSuccess) return CGRectZero;    
    AXValueGetValue(positionRef, kAXValueCGPointType, (void*)&position);
	CFRelease(positionRef);
    
	NSSize size;
    CFTypeRef sizeRef;
	axerror = AXUIElementCopyAttributeValue(self.window,(CFStringRef)NSAccessibilitySizeAttribute,(CFTypeRef*)&sizeRef);
	if (axerror != kAXErrorSuccess) return CGRectZero;        
    AXValueGetValue(sizeRef, kAXValueCGSizeType, (void*)&size);
    CFRelease(sizeRef);
    
    return CGRectMake(position.x, position.y, size.width, size.height);
}

- (NSScreen *)identifyCurrentScreen {
    NSScreen *winner = [NSScreen mainScreen];
	float winnerArea = 0;
	
	for (NSScreen *screen in [NSScreen screens]) {
		NSRect intersectRect = NSIntersectionRect(screen.visibleFrame, self.windowRect);        
        float area = intersectRect.size.width * intersectRect.size.height;
        if (area > winnerArea) {
            winner = screen;
            winnerArea = area;
        }
	}
    
    return winner;
}

- (CGRect)setWindowSize:(CGSize)windowSize andSnapOrigin:(Origin)Origin to:(CGPoint)point {
    NSLog(@"================> Set WindowRectangle: %@", NSStringFromCGRect(self.windowRect));    
    NSLog(@"================> To Size: [%f, %f], snap to: %d, anchored at: [%f, %f]", windowSize.width, windowSize.height, Origin, point.x, point.y);    
    
    CGRect frame = [self.currentScreen windowRectFromScreenRect:self.currentScreen.visibleFrame];
    BOOL willExceedWidth = self.windowRect.origin.x + windowSize.width > frame.origin.x + frame.size.width + 5;
    BOOL willExceedHeight = self.windowRect.origin.y + windowSize.height > frame.origin.y + frame.size.height + 5;
    
    if (willExceedWidth || willExceedHeight) {
        CGPoint temporaryPosition = CGPointMake(self.windowRect.origin.x, self.windowRect.origin.y);
        if (willExceedWidth) temporaryPosition.x = frame.origin.x + frame.size.width - windowSize.width;
        if (willExceedHeight) temporaryPosition.y = frame.origin.y + frame.size.height - windowSize.height;
        
        CFTypeRef positionRef = (CFTypeRef)(AXValueCreate(kAXValueCGPointType, (const void *)&temporaryPosition));
        AXUIElementSetAttributeValue(self.window,(CFStringRef)NSAccessibilityPositionAttribute,(CFTypeRef*)positionRef);
        CFRelease(positionRef);
        NSLog(@"====================> Repositioning first to [%f, %f]", temporaryPosition.x, temporaryPosition.y);
    }
    
    CFTypeRef sizeRef = (CFTypeRef)(AXValueCreate(kAXValueCGSizeType, (const void *)&windowSize));
    AXUIElementSetAttributeValue(self.window,(CFStringRef)NSAccessibilitySizeAttribute,(CFTypeRef*)sizeRef);
    NSSize resultingSize = [self measureWindowRectangle].size;
    NSLog(@"================> After resize: %@", NSStringFromCGRect([self measureWindowRectangle]));    
    
    CGPoint targetPosition;
    if (Origin == topLeft) {
        targetPosition = CGPointMake(point.x, point.y);
    } else if (Origin == topRight) {
        targetPosition = CGPointMake(point.x - resultingSize.width, point.y);       
    } else if (Origin == bottomLeft) {
        targetPosition = CGPointMake(point.x, point.y - resultingSize.height);       
    } else if (Origin == bottomRight) {
        targetPosition = CGPointMake(point.x - resultingSize.width, point.y - resultingSize.height);        
    } else if (Origin == center) {
        targetPosition = CGPointMake(point.x - resultingSize.width / 2, point.y - resultingSize.height / 2);
    }
    
    NSLog(@"================> Set position to: %f, %f", targetPosition.x, targetPosition.y);    
    
    CFTypeRef positionRef = (CFTypeRef)(AXValueCreate(kAXValueCGPointType, (const void *)&targetPosition));
    AXUIElementSetAttributeValue(self.window,(CFStringRef)NSAccessibilityPositionAttribute,(CFTypeRef*)positionRef);
    NSLog(@"================> After reposition: %@", NSStringFromCGRect([self measureWindowRectangle]));    
    
    CFRelease(positionRef);
    CFRelease(sizeRef);
    
    return [self measureWindowRectangle];
}


- (float)snapToThirdsForValue:(float)value containerValue:(float)containerValue ifOrigin:(Origin)Origin isNearPoint:(CGPoint)point {
    float resultingValue = ceilf(containerValue / 2.0);
    if ([self origin:Origin isNearPoint:point]) {
        if (AreClose(value, ceilf(containerValue / 2.0))) {
            resultingValue = ceilf(containerValue / 3.0);
        } else if (AreClose(value, ceilf(containerValue / 3.0))) {
            resultingValue = ceilf(2 * containerValue / 3.0);
        }
    }
    
    return resultingValue;
}

- (BOOL)origin:(Origin)Origin isNearPoint:(CGPoint)point {
    CGPoint positionOfOrigin;
    if (Origin == topLeft) {
        positionOfOrigin = CGPointMake(self.windowRect.origin.x, self.windowRect.origin.y);
    } else if (Origin == topRight) {
        positionOfOrigin = CGPointMake(self.windowRect.origin.x + self.windowRect.size.width, self.windowRect.origin.y);
    } else if (Origin == bottomLeft) {
        positionOfOrigin = CGPointMake(self.windowRect.origin.x, self.windowRect.origin.y + self.windowRect.size.height);
    } else if (Origin == bottomRight) {
        positionOfOrigin = CGPointMake(self.windowRect.origin.x + self.windowRect.size.width, self.windowRect.origin.y + self.windowRect.size.height);
    } else if (Origin == center) {
        positionOfOrigin = CGPointCenterOfCGRect(self.windowRect);
    }
    
    return AreClose(positionOfOrigin.x, point.x) && AreClose(positionOfOrigin.y, point.y);
}

- (void)left {
    CGRect frame = [self.currentScreen windowRectFromScreenRect:self.currentScreen.visibleFrame];
    CGPoint originPoint = CGPointMake(frame.origin.x, self.isWide ? frame.origin.y : self.windowRect.origin.y);
    float targetHeight = self.isWide ? frame.size.height : self.windowRect.size.height;
    float targetWidth = [self snapToThirdsForValue:self.windowRect.size.width containerValue:frame.size.width 
                                          ifOrigin:topLeft isNearPoint:originPoint];
    
    [self setWindowSize:CGSizeMake(targetWidth, targetHeight) andSnapOrigin:topLeft to:originPoint];
}

- (void)right {
    CGRect frame = [self.currentScreen windowRectFromScreenRect:self.currentScreen.visibleFrame];
    CGPoint originPoint = CGPointMake(frame.origin.x + frame.size.width, self.isWide ? frame.origin.y : self.windowRect.origin.y);
    float targetHeight = self.isWide ? frame.size.height : self.windowRect.size.height;
    float targetWidth = [self snapToThirdsForValue:self.windowRect.size.width containerValue:frame.size.width 
                                          ifOrigin:topRight isNearPoint:originPoint];
    
    [self setWindowSize:CGSizeMake(targetWidth, targetHeight) andSnapOrigin:topRight to:originPoint];
}

- (void)top {
    CGRect frame = [self.currentScreen windowRectFromScreenRect:self.currentScreen.visibleFrame];
    CGPoint originPoint = CGPointMake(self.isWide ? self.windowRect.origin.x : frame.origin.x, frame.origin.y);
    float targetHeight = [self snapToThirdsForValue:self.windowRect.size.height containerValue:frame.size.height 
                                           ifOrigin:topLeft isNearPoint:originPoint];
    float targetWidth = self.isWide ? self.windowRect.size.width : frame.size.width;

    [self setWindowSize:CGSizeMake(targetWidth, targetHeight) andSnapOrigin:topLeft to:originPoint];
}

- (void)bottom {
    CGRect frame = [self.currentScreen windowRectFromScreenRect:self.currentScreen.visibleFrame];
    CGPoint originPoint = CGPointMake(self.isWide ? self.windowRect.origin.x : frame.origin.x, frame.origin.y + frame.size.height);
    float targetHeight = [self snapToThirdsForValue:self.windowRect.size.height containerValue:frame.size.height 
                                           ifOrigin:bottomLeft isNearPoint:originPoint];
    float targetWidth = self.isWide ? self.windowRect.size.width : frame.size.width;
    
    [self setWindowSize:CGSizeMake(targetWidth, targetHeight) andSnapOrigin:bottomLeft to:originPoint];
}

- (void)fullscreen {
    CGRect frame = [self.currentScreen windowRectFromScreenRect:self.currentScreen.visibleFrame];
    if ([self origin:topLeft isNearPoint:frame.origin] && SizesAreClose(self.windowRect.size, frame.size) && !CGRectIsEmpty(lastWindowRect)) {
        [self setWindowSize:lastWindowRect.size andSnapOrigin:topLeft to:lastWindowRect.origin];            
    } else {
        lastWindowRect = self.windowRect;
        [self setWindowSize:frame.size andSnapOrigin:topLeft to:frame.origin];    
    }
}

- (void)center {
    CGRect frame = [self.currentScreen windowRectFromScreenRect:self.currentScreen.visibleFrame];
    float targetFactor = 0.85;

    float currentWidthFactor = self.windowRect.size.width / frame.size.width;
    float currentHeightFactor = self.windowRect.size.height / frame.size.height;
    
    if ([self origin:center isNearPoint:CGPointCenterOfCGRect(frame)] && AreClose(currentWidthFactor, currentHeightFactor)) {
        if (AreClose(currentWidthFactor * 1000, 850)) {
            targetFactor = 0.6;
        } else if (AreClose(currentWidthFactor * 1000, 600)) {
            targetFactor = 0.33333;
        }
    }
    
    [self setWindowSize:CGSizeMake(frame.size.width * targetFactor, frame.size.height * targetFactor) andSnapOrigin:center to:CGPointCenterOfCGRect(frame)];
}

- (void)swapscreen {
    
}

@end