#import "NSScreen+Coordinates.h"

@implementation NSScreen (Coordinates)

- (CGRect)windowRectFromScreenRect:(CGRect)screenRect {
    NSScreen *mainScreen = [[NSScreen screens] objectAtIndex:0];
    return CGRectMake(screenRect.origin.x, mainScreen.frame.size.height - screenRect.origin.y - screenRect.size.height, screenRect.size.width, screenRect.size.height);
}

@end
