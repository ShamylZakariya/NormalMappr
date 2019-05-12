//
//  AppDelegate.m
//  NormalMappr
//
//  Created by Shamyl Zakariya on 6/27/07.
//  Copyright 2007 Shamyl Zakariya. All rights reserved.
//

#import "AppDelegate.h"
#import "BatchController.h"

#define kPrefBatchWindowShowing @"BatchWindowShowing"

@implementation AppDelegate

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
	return NO;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	id value = nil;
	if ((value = [defaults valueForKey: kPrefBatchWindowShowing]))
	{
		self.batchWindowShowing = [value boolValue];
	}	
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	//	Only save batch controller prefs if it has actually been loaded
	if ( batchController ) [batchController savePreferences];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject: [NSNumber numberWithBool:self.batchWindowShowing] forKey: kPrefBatchWindowShowing];
}

#pragma mark -

- (void) setBatchWindowShowing: (BOOL) showing
{
	if ( showing != self.batchWindowShowing )
	{
		self.batchController.showWindow = showing;
	}
}

- (BOOL) batchWindowShowing
{
	// this is so we don't load the nib until we actually need it
	if ( !batchController ) return NO;
	return self.batchController.showWindow;
}

#pragma mark -

- (BatchController*) batchController
{
	if ( !batchController )
	{
		batchController = [[BatchController alloc] init];		

//	Why don't these seem to do anything?
//		[self bind: @"batchWindowShowing" toObject:batchController withKeyPath: @"showWindow" options:nil];		
//		[batchController bind: @"showWindow" toObject: self withKeyPath: @"batchWindowShowing" options: nil];
	}
	
	return batchController;
}

@end
