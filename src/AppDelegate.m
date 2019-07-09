//
//  AppDelegate.m
//  NormalMappr
//
//  Created by Shamyl Zakariya on 6/27/07.
//  Copyright 2007-2019 Shamyl Zakariya. All rights reserved.
//

#import "AppDelegate.h"
#import "BatchController.h"

#define kPrefBatchWindowShowing @"BatchWindowShowing"

@implementation AppDelegate

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication*)sender
{
    return NO;
}

- (void)applicationDidFinishLaunching:(NSNotification*)aNotification
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];

    id value = nil;
    if ((value = [defaults valueForKey:kPrefBatchWindowShowing])) {
        if ([value boolValue]) {
            self.batchWindowShowing = [value boolValue];
        }
    }

    NSProcessInfo* info = [NSProcessInfo processInfo];
    NSArray<NSString*>* args = info.arguments;

    if ([args count] > 2) {
        NSMutableArray<NSURL*>* batchFiles = [NSMutableArray array];
        for (int i = 1; i < args.count; i++) {
            if ([args[i] isEqualToString:@"--batch"]) {
                [batchFiles addObject:[NSURL fileURLWithPath:args[i + 1]]];
                i++;
            }
        }

        if (batchFiles.count > 0) {
            self.batchWindowShowing = YES;
            [batchController addFiles:batchFiles];
        }
    }
}

- (void)applicationWillTerminate:(NSNotification*)aNotification
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithBool:self.batchWindowShowing] forKey:kPrefBatchWindowShowing];
}

#pragma mark -

- (void)setBatchWindowShowing:(BOOL)showing
{
    if (showing) {
        if (!batchController) {
            batchController = [[BatchController alloc] init];
        }
    } else {
        if (batchController) {
            [batchController dismiss];
            batchController = nil;
        }
    }
}

- (BOOL)batchWindowShowing
{
    return batchController != nil;
}

@end
