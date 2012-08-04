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

#import "ShiftItAppDelegate.h"
#import "ShiftIt.h"
#import "ShiftItAction.h"
#import "PreferencesWindowController.h"
#import "ShiftComputer.h"
#import "FMTLoginItems.h"
#import "FMTHotKey.h"
#import "FMTHotKeyManager.h"
#import "FMTUtils.h"
#import "FMTDefines.h"

NSString *const kShiftItAppBundleId = @"org.shiftitapp.ShiftIt";

// the name of the plist file containing the preference defaults
NSString *const kShiftItUserDefaults = @"ShiftIt-defaults";

// preferencs
NSString *const kHasStartedBeforePrefKey = @"hasStartedBefore";
NSString *const kShowMenuPrefKey = @"shiftItshowMenu";

// notifications
NSString *const kShowPreferencesRequestNotification = @"org.shiftitapp.shiftit.notifiactions.showPreferences";

// icon
NSString *const kSIIconName = @"ShiftIt-menuIcon";
NSString *const kSIMenuItemTitle = @"Shift";

// the size that should be reserved for the menu item in the system menu in px
NSInteger const kSIMenuItemSize = 30;
NSInteger const kSIMenuUITagPrefix = 2000;

NSDictionary *allShiftActions = nil;

@interface ShiftItAppDelegate (Private)

- (void)initializeActions_;
- (void)updateMenuBarIcon_;
- (void)firstLaunch_;
- (void)invokeShiftItActionByIdentifier_:(NSString *)identifier;
- (void)updateStatusMenuShortcutForAction_:(ShiftItAction *)action keyCode:(NSInteger)keyCode modifiers:(NSUInteger)modifiers;

- (void)handleShowPreferencesRequest_:(NSNotification *) notification; 
- (void) shiftItActionHotKeyChanged_:(NSNotification *) notification;
- (void)handleActionsStateChangeRequest_:(NSNotification *) notification;

- (IBAction)shiftItMenuAction_:(id)sender;
@end


@implementation ShiftItAppDelegate

- (id)init{
	if(![super init]){
		return nil;
	}
	
	NSString *iconPath = FMTGetMainBundleResourcePath(kSIIconName, @"png");
	statusMenuItemIcon_ = [[NSImage alloc] initWithContentsOfFile:iconPath];
	allHotKeys_ = [[NSMutableDictionary alloc] init];
	
	return self;
}

- (void) dealloc {
	[statusMenuItemIcon_ release];
	[allShiftActions release];
	
	[super dealloc];
}

- (void) firstLaunch_  {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		
	// ask to start it automatically - make sure it is not there
	
	// TODO: refactor this so it shares the code from the pref controller
	FMTLoginItems *loginItems = [FMTLoginItems sharedSessionLoginItems];
	NSString *appPath = [[NSBundle mainBundle] bundlePath];
	
	if (![loginItems isInLoginItemsApplicationWithPath:appPath]) {
		int ret = NSRunAlertPanel (@"Start ShiftIt automatically?", @"Would you like to have ShiftIt automatically started at a login time?", @"Yes", @"No",NULL);
		switch (ret){
			case NSAlertDefaultReturn:
				// do it!
				[loginItems toggleApplicationInLoginItemsWithPath:appPath enabled:YES];
				break;
			default:
				break;
		}		
	}
	
	// make sure this was the only time
	[defaults setBool:YES forKey:@"hasStartedBefore"];
	[defaults synchronize];
	
}
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults synchronize];

	// check preferences
	BOOL hasStartedBefore = [defaults boolForKey:kHasStartedBeforePrefKey];
	
	if (!hasStartedBefore) {
		[self firstLaunch_];
	}

	// register defaults - we assume that the installation is correct
	NSString *path = FMTGetMainBundleResourcePath(kShiftItUserDefaults, @"plist");
	NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile:path];
	[defaults registerDefaults:d];
	
	if (!AXAPIEnabled()){
        int ret = NSRunAlertPanel (@"UI Element Inspector requires that the Accessibility API be enabled.  Please \"Enable access for assistive devices and try again\".", @"", @"OK", @"Cancel",NULL);
        switch (ret){
            case NSAlertDefaultReturn:
                [[NSWorkspace sharedWorkspace] openFile:@"/System/Library/PreferencePanes/UniversalAccessPref.prefPane"];
				[NSApp terminate:self];
				
				return;
            case NSAlertAlternateReturn:
                [NSApp terminate:self];
                
				return;
            default:
                break;
        }
    }
	
	hotKeyManager_ = [FMTHotKeyManager sharedHotKeyManager];
	
	[self initializeActions_];
	[self updateMenuBarIcon_];
	
	NSUserDefaultsController *userDefaultsController = [NSUserDefaultsController sharedUserDefaultsController];
	[userDefaultsController addObserver:self forKeyPath:FMTStr(@"values.%@",kShowMenuPrefKey) options:0 context:self];
	
	for (ShiftItAction *action in [allShiftActions allValues]) {
		NSString *identifier = [action identifier];
		
		NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:3];
		[userInfo setObject:[action identifier]  forKey:kActionIdentifierKey];
		[userInfo setObject:[NSNumber numberWithInt:[defaults integerForKey:KeyCodePrefKey(identifier)]] forKey:kHotKeyKeyCodeKey];
		[userInfo setObject:[NSNumber numberWithInt:[defaults integerForKey:ModifiersPrefKey(identifier)]] forKey:kHotKeyModifiersKey];
		
		NSNotification *notification = [NSNotification notificationWithName:kHotKeyChangedNotification object:self userInfo:userInfo];
		[self shiftItActionHotKeyChanged_:notification];
	}

	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter addObserver:self selector:@selector(shiftItActionHotKeyChanged_:) name:kHotKeyChangedNotification object:nil];
	[notificationCenter addObserver:self selector:@selector(handleActionsStateChangeRequest_:) name:kDidFinishEditingHotKeysPrefNotification object:nil];
	[notificationCenter addObserver:self selector:@selector(handleActionsStateChangeRequest_:) name:kDidStartEditingHotKeysPrefNotification object:nil];
	
	notificationCenter = [NSDistributedNotificationCenter defaultCenter];
	[notificationCenter addObserver:self selector:@selector(handleShowPreferencesRequest_:) name:kShowPreferencesRequestNotification object:nil];
}

- (void) applicationWillTerminate:(NSNotification *)aNotification {
	// unregister hotkeys
	for (FMTHotKey *hotKey in [allHotKeys_ allValues]) {
		[hotKeyManager_ unregisterHotKey:hotKey];
	}
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows: (BOOL)flag{	
	if(flag==NO){
		[self showPreferences:nil];
	}
	return YES;
} 

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
	if([FMTStr(@"values.%@",kShowMenuPrefKey) isEqualToString:keyPath]) {
		[self updateMenuBarIcon_];
	} 
}

- (void) updateMenuBarIcon_ {
	BOOL showIconInMenuBar = [[NSUserDefaults standardUserDefaults] boolForKey:kShowMenuPrefKey];
	NSStatusBar * statusBar = [NSStatusBar systemStatusBar];
	
	if(showIconInMenuBar) {
		if(!statusItem_) {
			statusItem_ = [[statusBar statusItemWithLength:kSIMenuItemSize] retain];
			[statusItem_ setMenu:statusMenu_];
			if (statusMenuItemIcon_) {
				[statusItem_ setImage:statusMenuItemIcon_];
			} else {
				[statusItem_ setTitle:kSIMenuItemTitle];
			}
			[statusItem_ setHighlightMode:YES];
		}
	} else {
		[statusBar removeStatusItem:statusItem_];
		[statusItem_ autorelease];
		statusItem_ = nil;
	}
}

- (IBAction)showPreferences:(id)sender {
    if (!preferencesController_) {
        preferencesController_ = [[PreferencesWindowController alloc]init];
    }

    [preferencesController_ showPreferences:sender];
    [NSApp activateIgnoringOtherApps:YES];
}

- (void)updateStatusMenuShortcutForAction_:(ShiftItAction *)action keyCode:(NSInteger)keyCode modifiers:(NSUInteger)modifiers {
	NSMenuItem *menuItem = [statusMenu_ itemWithTag:kSIMenuUITagPrefix+[action uiTag]];
	
	[menuItem setTitle:action.label];
	[menuItem setRepresentedObject:action.identifier];
	[menuItem setAction:@selector(shiftItMenuAction_:)];
	
	if (keyCode != -1) {
		NSString *keyCodeString = keyCode == 49 ? @" " : SRStringForKeyCode(keyCode);

		if (!keyCodeString) keyCodeString = @"";
        
		[menuItem setKeyEquivalent:[keyCodeString lowercaseString]];
		[menuItem setKeyEquivalentModifierMask:modifiers];
	} else {
		[menuItem setKeyEquivalent:@""];
		[menuItem setKeyEquivalentModifierMask:0];
	}
}

- (void) initializeActions_ {
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	
    [dict setObject:[ShiftItAction actionWithID:@"left" label:@"Left" uiTag:1] forKey:@"left"];
    [dict setObject:[ShiftItAction actionWithID:@"right" label:@"Right" uiTag:2] forKey:@"right"];
    [dict setObject:[ShiftItAction actionWithID:@"top" label:@"Top" uiTag:3] forKey:@"top"];
    [dict setObject:[ShiftItAction actionWithID:@"bottom" label:@"Bottom" uiTag:4] forKey:@"bottom"];
    [dict setObject:[ShiftItAction actionWithID:@"fullscreen" label:@"Full Screen" uiTag:5] forKey:@"fullscreen"];
    [dict setObject:[ShiftItAction actionWithID:@"center" label:@"Center" uiTag:6] forKey:@"center"];
    [dict setObject:[ShiftItAction actionWithID:@"swapscreen" label:@"Swap Screen" uiTag:7] forKey:@"swapscreen"];
    
	allShiftActions = [[NSDictionary dictionaryWithDictionary:dict] retain];
}

- (void)handleShowPreferencesRequest_:(NSNotification *) notification {
	[self showPreferences:self];
}

- (void)handleActionsStateChangeRequest_:(NSNotification *) notification {
	NSString *name = [notification name];
	
	if ([name isEqualTo:kDidFinishEditingHotKeysPrefNotification]) {
		@synchronized(self) {
			paused_ = NO;
		}
	} else if ([name isEqualTo:kDidStartEditingHotKeysPrefNotification]) {
		@synchronized(self) {
			paused_ = YES;
		}		
	}
	
}

- (void) shiftItActionHotKeyChanged_:(NSNotification *) notification {
	NSDictionary *userInfo = [notification userInfo];

	NSString *identifier = [userInfo objectForKey:kActionIdentifierKey];
	NSInteger keyCode = [[userInfo objectForKey:kHotKeyKeyCodeKey] integerValue];
	NSUInteger modifiers = [[userInfo objectForKey:kHotKeyModifiersKey] longValue];
	
	ShiftItAction *action = [allShiftActions objectForKey:identifier];	
    
	FMTHotKey *newHotKey = [[FMTHotKey alloc] initWithKeyCode:keyCode modifiers:modifiers];
	FMTHotKey *hotKey = [allHotKeys_ objectForKey:identifier];
	if (hotKey) {
		if ([hotKey isEqualTo:newHotKey]) {
			return;
		}
		
		[hotKeyManager_ unregisterHotKey:hotKey];
		[allHotKeys_ removeObjectForKey:identifier];
	}
	
	if (keyCode != -1) {
		[hotKeyManager_ registerHotKey:newHotKey handler:@selector(invokeShiftItActionByIdentifier_:) provider:self userData:identifier];
		[allHotKeys_ setObject:newHotKey forKey:identifier];
	}
	
	// update menu
	[self updateStatusMenuShortcutForAction_:action keyCode:keyCode modifiers:modifiers];
	
	if ([notification object] != self) {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults setInteger:keyCode forKey:KeyCodePrefKey(identifier)];
		[defaults setInteger:modifiers forKey:ModifiersPrefKey(identifier)];
		[defaults synchronize];
	}
}

- (void) invokeShiftItActionByIdentifier_:(NSString *)identifier {
	@synchronized(self) {
		if (paused_) {
			return ;
		}
	}
	
	ShiftItAction *action = [allShiftActions objectForKey:identifier];	
    [[ShiftComputer shiftComputer] performSelector:action.action];
}

- (IBAction)shiftItMenuAction_:(id)sender {
	NSString *identifier = [sender representedObject];
	[self invokeShiftItActionByIdentifier_:identifier];
}
		 
@end