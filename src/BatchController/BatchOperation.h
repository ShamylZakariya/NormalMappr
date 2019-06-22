//
//  BatchOperation.h
//  NormalMappr
//
//  Created by Shamyl Zakariya on 6/29/07.
//  Copyright 2007-2019 Shamyl Zakariya. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BatchSettings.h"
#import "BatchEntry.h"

@interface BatchOperation : NSObject {
	BatchEntry *entry;
	BatchSettings *settings;
}

- (id) initWithEntry: (BatchEntry*) entry andSettings: (BatchSettings*) settings;
+ (BatchOperation*) batchOperationWithEntry: (BatchEntry*) entry andSettings: (BatchSettings*) settings;

- (NSURL*) outputURL;

- (void) run;


@end
