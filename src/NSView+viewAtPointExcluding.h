//
//  NSView+viewAtPointExcluding.h
//  FilteredImageList
//
//  Created by Shamyl Zakariya on 3/28/09.
//  Copyright 2009 Shamyl Zakariya. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSView (viewAtPointExcluding)

- (id)viewAtPoint:(NSPoint)pt excludingView:(id)eView;

@end
