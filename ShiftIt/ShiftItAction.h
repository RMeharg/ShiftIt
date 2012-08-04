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

/** 
 * A reference to a function that position
 * and size the window's geometry denoted by the windowRect argument
 * relatively to a screen rect that originates at [0,0] (top left corner)
 * and has a size screenSize. The windowRect is the whole window
 * including any sort window decorators.
 */

@interface ShiftItAction : NSObject

@property (nonatomic, retain) NSString *identifier;
@property (nonatomic, retain) NSString *label;
@property (nonatomic, assign) NSInteger uiTag;

+ (ShiftItAction *)actionWithID:(NSString *)identifier label:(NSString *)label uiTag:(NSInteger)uiTag;

- (SEL)action;

@end
