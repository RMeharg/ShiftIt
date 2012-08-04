#import "ShiftComputer.h"
#import "NSScreen+Coordinates.h"

#define CGPointCenterOfCGRect(rect) CGPointMake((rect).origin.x + (rect).size.width / 2, (rect).origin.y + (rect).size.height / 2)

typedef enum {
    topLeft,
    topRight,
    bottomRight,
    bottomLeft,
    center
} Origin;

BOOL AreClose(float a, float b) {
	return fabs(a - b) < 20;
}

BOOL RectsAreClose(CGRect a, CGRect b) {
	return AreClose(a.size.width, b.size.width) &&
    AreClose(a.size.height, b.size.height) &&
    AreClose(a.origin.x, b.origin.x) &&
    AreClose(a.origin.y, b.origin.y);
}


CGRect lastWindowRect = {{0,0},{0,0}};

@interface ShiftComputer ()

@property (nonatomic, assign) AXUIElementRef window;
@property (nonatomic, assign) CGRect windowRect;
@property (nonatomic, retain) NSScreen *currentScreen;
@property (nonatomic, assign) BOOL isWide;

- (AXUIElementRef)identifyFocusedWindowAndMetrics;
- (CGRect)measureWindowRectangle;
- (NSScreen *)identifyCurrentScreen;

- (CGPoint)targetPositionForOrigin:(Origin)origin toBeAtPoint:(CGPoint)point forSize:(CGSize)size;
- (CGRect)setWindowSize:(CGSize)windowSize andSnapOrigin:(Origin)Origin to:(CGPoint)point;

- (float)snapToThirdsForValue:(float)value containerValue:(float)containerValue ifOrigin:(Origin)Origin isNearPoint:(CGPoint)point cycleToFull:(BOOL)cycleToFull;
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

- (CGPoint)targetPositionForOrigin:(Origin)origin toBeAtPoint:(CGPoint)point forSize:(CGSize)size {
    if (origin == topLeft) {
        return CGPointMake(point.x, point.y);
    } else if (origin == topRight) {
        return CGPointMake(point.x - size.width, point.y);       
    } else if (origin == bottomLeft) {
        return CGPointMake(point.x, point.y - size.height);       
    } else if (origin == bottomRight) {
        return CGPointMake(point.x - size.width, point.y - size.height);        
    } else if (origin == center) {
        return CGPointMake(point.x - size.width / 2, point.y - size.height / 2);
    }
    
    return CGPointZero;
}

- (CGRect)setWindowSize:(CGSize)windowSize andSnapOrigin:(Origin)origin to:(CGPoint)point {
    CGRect frame = [self.currentScreen windowRectFromScreenRect:self.currentScreen.visibleFrame];
    BOOL willExceedWidth = self.windowRect.origin.x + windowSize.width > frame.origin.x + frame.size.width + 5;
    BOOL willExceedHeight = self.windowRect.origin.y + windowSize.height > frame.origin.y + frame.size.height + 5;
    
    if (willExceedWidth || willExceedHeight) {
        CGPoint temporaryPosition = [self targetPositionForOrigin:origin toBeAtPoint:point forSize:windowSize];
        if (temporaryPosition.x + windowSize.width > frame.origin.x + frame.size.width + 5) {
            temporaryPosition.x = frame.origin.x + frame.size.width - windowSize.width;
        }
        
        if (temporaryPosition.y + windowSize.height > frame.origin.y + frame.size.height + 5) {
            temporaryPosition.y = frame.origin.y + frame.size.height - windowSize.height;
        }
        
        CFTypeRef positionRef = (CFTypeRef)(AXValueCreate(kAXValueCGPointType, (const void *)&temporaryPosition));
        AXUIElementSetAttributeValue(self.window,(CFStringRef)NSAccessibilityPositionAttribute,(CFTypeRef*)positionRef);
        CFRelease(positionRef);
    }
    
    CFTypeRef sizeRef = (CFTypeRef)(AXValueCreate(kAXValueCGSizeType, (const void *)&windowSize));
    AXUIElementSetAttributeValue(self.window,(CFStringRef)NSAccessibilitySizeAttribute,(CFTypeRef*)sizeRef);
    NSSize resultingSize = [self measureWindowRectangle].size;
    
    CGPoint targetPosition = [self targetPositionForOrigin:origin toBeAtPoint:point forSize:resultingSize];
    CFTypeRef positionRef = (CFTypeRef)(AXValueCreate(kAXValueCGPointType, (const void *)&targetPosition));
    AXUIElementSetAttributeValue(self.window,(CFStringRef)NSAccessibilityPositionAttribute,(CFTypeRef*)positionRef);
    
    CFRelease(positionRef);
    CFRelease(sizeRef);
    
    return [self measureWindowRectangle];
}


- (float)snapToThirdsForValue:(float)value containerValue:(float)containerValue ifOrigin:(Origin)Origin isNearPoint:(CGPoint)point cycleToFull:(BOOL)cycleToFull {
    float resultingValue = ceilf(containerValue / 2.0);
    if ([self origin:Origin isNearPoint:point]) {
        if (AreClose(value, ceilf(containerValue / 2.0))) {
            resultingValue = ceilf(containerValue / 3.0);
        }
        if (cycleToFull) {
            if (AreClose(value, ceilf(containerValue / 3.0))) {
                resultingValue = ceilf(containerValue);
            }            
            if (AreClose(value, ceilf(containerValue))) {
                resultingValue = ceilf(2 * containerValue / 3.0);
            }            
        } else {
            if (AreClose(value, ceilf(containerValue / 3.0))) {
                resultingValue = ceilf(2 * containerValue / 3.0);
            }            
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
                                          ifOrigin:topLeft isNearPoint:originPoint cycleToFull:!self.isWide];
    
    [self setWindowSize:CGSizeMake(targetWidth, targetHeight) andSnapOrigin:topLeft to:originPoint];
}

- (void)right {
    CGRect frame = [self.currentScreen windowRectFromScreenRect:self.currentScreen.visibleFrame];
    CGPoint originPoint = CGPointMake(frame.origin.x + frame.size.width, self.isWide ? frame.origin.y : self.windowRect.origin.y);
    float targetHeight = self.isWide ? frame.size.height : self.windowRect.size.height;
    float targetWidth = [self snapToThirdsForValue:self.windowRect.size.width containerValue:frame.size.width 
                                          ifOrigin:topRight isNearPoint:originPoint cycleToFull:!self.isWide];
    
    [self setWindowSize:CGSizeMake(targetWidth, targetHeight) andSnapOrigin:topRight to:originPoint];
}

- (void)top {
    CGRect frame = [self.currentScreen windowRectFromScreenRect:self.currentScreen.visibleFrame];
    CGPoint originPoint = CGPointMake(self.isWide ? self.windowRect.origin.x : frame.origin.x, frame.origin.y);
    float targetHeight = [self snapToThirdsForValue:self.windowRect.size.height containerValue:frame.size.height 
                                           ifOrigin:topLeft isNearPoint:originPoint cycleToFull:self.isWide];
    float targetWidth = self.isWide ? self.windowRect.size.width : frame.size.width;

    [self setWindowSize:CGSizeMake(targetWidth, targetHeight) andSnapOrigin:topLeft to:originPoint];
}

- (void)bottom {
    CGRect frame = [self.currentScreen windowRectFromScreenRect:self.currentScreen.visibleFrame];
    CGPoint originPoint = CGPointMake(self.isWide ? self.windowRect.origin.x : frame.origin.x, frame.origin.y + frame.size.height);
    float targetHeight = [self snapToThirdsForValue:self.windowRect.size.height containerValue:frame.size.height 
                                           ifOrigin:bottomLeft isNearPoint:originPoint cycleToFull:self.isWide];
    float targetWidth = self.isWide ? self.windowRect.size.width : frame.size.width;
    
    [self setWindowSize:CGSizeMake(targetWidth, targetHeight) andSnapOrigin:bottomLeft to:originPoint];
}

- (void)fullscreen {
    CGRect frame = [self.currentScreen windowRectFromScreenRect:self.currentScreen.visibleFrame];
    if (RectsAreClose(self.windowRect, frame) && !CGRectIsEmpty(lastWindowRect)) {
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
    
    [self setWindowSize:CGSizeMake(frame.size.width * targetFactor, frame.size.height * targetFactor)
          andSnapOrigin:center
                     to:CGPointCenterOfCGRect(frame)];
}

- (void)swapscreen {
    NSUInteger index = [[NSScreen screens] indexOfObject:self.currentScreen] + 1;
    NSScreen *nextScreen = [[NSScreen screens] objectAtIndex:index % [[NSScreen screens] count]];
    if (nextScreen != self.currentScreen) {
        self.currentScreen = nextScreen;
        CGRect frame = [self.currentScreen windowRectFromScreenRect:self.currentScreen.visibleFrame];
        [self setWindowSize:CGSizeMake(frame.size.width * 0.85, frame.size.height * 0.85) andSnapOrigin:center to:CGPointCenterOfCGRect(frame)];
    }
}

@end