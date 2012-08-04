#import <Foundation/Foundation.h>

@interface ShiftComputer : NSObject 

+ (ShiftComputer *)shiftComputer;

- (void)left;
- (void)right;
- (void)top;
- (void)bottom;
- (void)fullscreen;
- (void)center;
- (void)swapscreen;

@end