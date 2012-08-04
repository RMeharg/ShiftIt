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

#import "ShiftItAction.h"
#import "FMTDefines.h"

@implementation ShiftItAction

@synthesize identifier, label, uiTag;

+ (ShiftItAction *)actionWithID:(NSString *)identifier label:(NSString *)label uiTag:(NSInteger)uiTag {
    ShiftItAction *action = [[[self alloc] init] autorelease];
    action.identifier = identifier;
    action.label = label;
    action.uiTag = uiTag;
    
    return action;
}

- (void)dealloc {
    self.identifier = nil;
    self.label = nil;
    [super dealloc];
}

- (SEL)action {
    return NSSelectorFromString(self.identifier);
}

@end
