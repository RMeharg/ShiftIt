/*
 ShiftIt: Resize windows with Hotkeys
 Copyright (C) 2010  Aravind
 
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

#import "PreferencesWindowController.h"
#import "ShiftIt.h"
#import "ShiftItAction.h"
#import "FMTLoginItems.h"
#import "FMTDefines.h"
#import "FMTUtils.h"

NSString *const kKeyCodePrefKeySuffix = @"KeyCode";
NSString *const kModifiersPrefKeySuffix = @"Modifiers";

NSString *const kDidFinishEditingHotKeysPrefNotification = @"kEnableActionsRequestNotification";
NSString *const kDidStartEditingHotKeysPrefNotification = @"kDisableActionsRequestNotification";
NSString *const kHotKeyChangedNotification = @"kHotKeyChangedNotification";
NSString *const kActionIdentifierKey = @"kActionIdentifierKey";
NSString *const kHotKeyKeyCodeKey = @"kHotKeyKeyCodeKey";
NSString *const kHotKeyModifiersKey = @"kHotKeyModifiersKey";

NSInteger const kSISRUITagPrefix = 1000;
NSInteger const kSRContainerTagPrefix = 100;

@interface PreferencesWindowController(Private)

- (void)buildShortcutRecorders;
- (void)windowDidResignMain:(NSNotification *)notification;
- (void)windowDidBecomeMain:(NSNotification *)notification;

@end

@implementation PreferencesWindowController

@dynamic shouldStartAtLogin;
@synthesize view, titleLabel;

-(id)init{
    self = [super initWithWindowNibName:@"PreferencesWindow"];
    return self;
}

-(BOOL)acceptsFirstResponder{
	return YES;
}

-(void)awakeFromNib {
	NSString *versionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
	[self.titleLabel setStringValue:[NSString stringWithFormat:@"ShiftIt %@", versionString]];

	[[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(windowDidResignMain:) 
                                                 name:NSWindowDidResignMainNotification 
                                               object:self.window];
    
	[[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(windowDidBecomeMain:) 
                                                 name:NSWindowDidBecomeMainNotification 
                                               object:self.window];
	
    [self buildShortcutRecorders];
}

-(IBAction)showPreferences:(id)sender{
    [[self window] center];
    [NSApp activateIgnoringOtherApps:YES];
    [[self window] makeKeyAndOrderFront:sender];    
}

- (void)shortcutRecorder:(SRRecorderControl *)recorder keyComboDidChange:(KeyCombo)newKeyCombo{
	NSInteger tag = [recorder tag] - kSISRUITagPrefix;
	
	ShiftItAction *action = nil;
	for (action in [allShiftActions allValues]) {
		if ([action uiTag] == tag) {
			break;
		}
	}
    
	NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:3];
	[userInfo setObject:[action identifier] forKey:kActionIdentifierKey];
	[userInfo setObject:[NSNumber numberWithInt:newKeyCombo.code] forKey:kHotKeyKeyCodeKey];
	[userInfo setObject:[NSNumber numberWithLong:newKeyCombo.flags] forKey:kHotKeyModifiersKey];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kHotKeyChangedNotification 
                                                        object:self 
                                                      userInfo:userInfo];
}


#pragma mark shouldStartAtLogin dynamic property methods

- (BOOL)shouldStartAtLogin {
	NSString *path = [[NSBundle mainBundle] bundlePath];
	return [[FMTLoginItems sharedSessionLoginItems] isInLoginItemsApplicationWithPath:path];
}

- (void)setShouldStartAtLogin:(BOOL)flag {
	NSString *path = [[NSBundle mainBundle] bundlePath];
	[[FMTLoginItems sharedSessionLoginItems] toggleApplicationInLoginItemsWithPath:path enabled:flag];
}

#pragma mark Shortcut Recorder methods

- (void)buildShortcutRecorders {    
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    for (ShiftItAction *action in [allShiftActions allValues]) {
        NSControl *container = [self.view viewWithTag:kSRContainerTagPrefix + action.uiTag];
        SRRecorderControl *shortcutRecorder = [[[SRRecorderControl alloc] initWithFrame:container.frame] autorelease];
        
        shortcutRecorder.style = 1;
        shortcutRecorder.allowedFlags = 10354688;
        shortcutRecorder.tag = kSISRUITagPrefix + action.uiTag;
        shortcutRecorder.delegate = self; 
        [shortcutRecorder setAllowsKeyOnly:YES escapeKeysRecord:NO];
		
		KeyCombo combo;
		combo.code = [defaults integerForKey:KeyCodePrefKey(action.identifier)];
		combo.flags = [defaults integerForKey:ModifiersPrefKey(action.identifier)];
		[shortcutRecorder setKeyCombo:combo];		
        
        [self.view addSubview:shortcutRecorder];
        [container removeFromSuperview];
    }
}

#pragma mark Notification handling methods
- (void)windowDidResignMain:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] postNotificationName:kDidFinishEditingHotKeysPrefNotification object:nil];
}

- (void)windowDidBecomeMain:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] postNotificationName:kDidStartEditingHotKeysPrefNotification object:nil];
}

@end
