#import "ShiftableWindow.h"
#import "NSScreen+Coordinates.h"
#import "ShiftIt.h"

#define NSStringFromCGRect(rect) [NSString stringWithFormat:@"[%.2f, %.2f] x [%.2f, %.2f]", (rect).origin.x, (rect).origin.y, (rect).size.width, (rect).size.height]

@interface ShiftableWindow ()

@property (nonatomic, assign) AXUIElementRef window;

- (id) initForFocusedWindow;

- (CGPoint)targetPositionForOrigin:(Origin)origin toBeAtPoint:(CGPoint)point forSize:(CGSize)size;
- (void)setPosition:(CGPoint)position;
- (void)setSize:(CGSize)size;

@end


@implementation ShiftableWindow

@synthesize window;

+ (ShiftableWindow *)focusedWindow {
    return [[[ShiftableWindow alloc] initForFocusedWindow] autorelease];
}

- (id)initForFocusedWindow {
    self = [super init];
    if (self) {
        AXUIElementRef systemElementRef = AXUIElementCreateSystemWide();
        
        AXUIElementRef focusedAppRef = nil;
        AXError axerror = AXUIElementCopyAttributeValue(systemElementRef,kAXFocusedApplicationAttribute, (CFTypeRef *) &focusedAppRef);
        CFRelease(systemElementRef);
        if (axerror != kAXErrorSuccess) return nil;
        
        AXUIElementRef focusedWindowRef = nil;
        axerror = AXUIElementCopyAttributeValue(focusedAppRef,(CFStringRef)NSAccessibilityFocusedWindowAttribute,(CFTypeRef*)&focusedWindowRef);
        CFRelease(focusedAppRef);
        if (axerror != kAXErrorSuccess) return nil;
        
        self.window = focusedWindowRef;
    }
    
    return self;
}

- (void)dealloc {
    CFRelease(self.window);
    self.window = nil;
    [super dealloc];
}

- (CGRect)frame {
    CGRect frame;
    
	CFTypeRef positionRef;
    if (AXUIElementCopyAttributeValue(self.window, kAXPositionAttribute, &positionRef) != kAXErrorSuccess) {
        return CGRectZero;   
    }
    AXValueGetValue(positionRef, kAXValueCGPointType, (void*)&(frame.origin));
	CFRelease(positionRef);
    
    CFTypeRef sizeRef;
	if (AXUIElementCopyAttributeValue(self.window,kAXSizeAttribute, &sizeRef) != kAXErrorSuccess) {
        return CGRectZero;
    }
    AXValueGetValue(sizeRef, kAXValueCGSizeType, (void*)&(frame.size));
    CFRelease(sizeRef);
    
    return frame;
}

- (NSScreen *)screen {
    NSScreen *winner = [NSScreen mainScreen];
	float winnerArea = 0;
    CGRect windowRect = self.frame;
	
	for (NSScreen *screen in [NSScreen screens]) {
		NSRect intersectRect = NSIntersectionRect([screen windowRectFromScreenRect:screen.visibleFrame], windowRect);        
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

- (void)setWindowSize:(CGSize)targetSize andSnapOrigin:(Origin)origin to:(CGPoint)point {
    [self setWindowSize:targetSize
          andSnapOrigin:origin
                     to:point
               onScreen:self.screen];
}

- (void)setWindowSize:(CGSize)targetSize andSnapOrigin:(Origin)origin to:(CGPoint)point onScreen:(NSScreen *)screen {
    CGRect screenFrame = [screen windowRectFromScreenRect:screen.visibleFrame];
    CGRect windowFrame = self.frame;

    BOOL willExceedWidth = windowFrame.origin.x + targetSize.width > screenFrame.origin.x + screenFrame.size.width + 5;
    BOOL willExceedHeight = windowFrame.origin.y + targetSize.height > screenFrame.origin.y + screenFrame.size.height + 5;
    
    if (willExceedWidth || willExceedHeight) {
        CGPoint temporaryPosition = [self targetPositionForOrigin:origin toBeAtPoint:point forSize:targetSize];
        if (temporaryPosition.x + targetSize.width > screenFrame.origin.x + screenFrame.size.width + 5) {
            temporaryPosition.x = screenFrame.origin.x + screenFrame.size.width - targetSize.width;
        }
        
        if (temporaryPosition.y + targetSize.height > screenFrame.origin.y + screenFrame.size.height + 5) {
            temporaryPosition.y = screenFrame.origin.y + screenFrame.size.height - targetSize.height;
        }
        
        [self setPosition:temporaryPosition];
    }
    
    [self setSize:targetSize];
    [self setPosition:[self targetPositionForOrigin:origin toBeAtPoint:point forSize:self.frame.size]];
}

- (void)setPosition:(CGPoint)position {
    CFTypeRef positionRef = (CFTypeRef)(AXValueCreate(kAXValueCGPointType, (const void *)&position));
    AXUIElementSetAttributeValue(self.window, kAXPositionAttribute, positionRef);
    CFRelease(positionRef);    
}

- (void)setSize:(CGSize)size {
    CFTypeRef sizeRef = (CFTypeRef)(AXValueCreate(kAXValueCGSizeType, (const void *)&size));
    AXUIElementSetAttributeValue(self.window, kAXSizeAttribute, sizeRef);
    CFRelease(sizeRef);    
}

- (BOOL)origin:(Origin)Origin isNearPoint:(CGPoint)point {
    CGRect frame = self.frame;
    CGPoint positionOfOrigin;
    
    if (Origin == topLeft) {
        positionOfOrigin = CGPointMake(frame.origin.x, frame.origin.y);
    } else if (Origin == topRight) {
        positionOfOrigin = CGPointMake(frame.origin.x + frame.size.width, frame.origin.y);
    } else if (Origin == bottomLeft) {
        positionOfOrigin = CGPointMake(frame.origin.x, frame.origin.y + frame.size.height);
    } else if (Origin == bottomRight) {
        positionOfOrigin = CGPointMake(frame.origin.x + frame.size.width, frame.origin.y + frame.size.height);
    } else if (Origin == center) {
        positionOfOrigin = CGPointCenterOfCGRect(frame);
    }
    
    return AreClose(positionOfOrigin.x, point.x) && AreClose(positionOfOrigin.y, point.y);
}

@end
