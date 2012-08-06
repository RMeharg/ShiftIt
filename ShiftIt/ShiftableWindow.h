#import <Foundation/Foundation.h>

typedef enum {
    topLeft,
    topRight,
    bottomRight,
    bottomLeft,
    center
} Origin;

@interface ShiftableWindow : NSObject

+ (ShiftableWindow *)focusedWindow;

- (CGRect)frame;
- (NSScreen *)screen;

- (BOOL)origin:(Origin)Origin isNearPoint:(CGPoint)point;

- (void)setWindowSize:(CGSize)targetSize andSnapOrigin:(Origin)origin to:(CGPoint)point;
- (void)setWindowSize:(CGSize)targetSize andSnapOrigin:(Origin)origin to:(CGPoint)point onScreen:(NSScreen *)screen;

@end
