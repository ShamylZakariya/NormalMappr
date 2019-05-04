//
//  AppDelegate.h
//  NormalMappr
//
//  Created by Shamyl Zakariya on 6/27/07.
//  Copyright 2007 Shamyl Zakariya. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class BatchController;

@interface AppDelegate : NSObject {
	BatchController	*batchController;
}

@property (readonly) BatchController* batchController;
@property (readwrite) BOOL batchWindowShowing;

@end
