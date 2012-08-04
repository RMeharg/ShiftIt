#import "NSScreen+Coordinates.h"

@implementation NSScreen (Coordinates)

- (CGRect)windowRectFromScreenRect:(CGRect)screenRect {
    return CGRectMake(screenRect.origin.x, self.frame.size.height - screenRect.origin.y - screenRect.size.height, screenRect.size.width, screenRect.size.height);
}

@end
