//
//  NSView+viewAtPointExcluding.m
//  FilteredImageList
//
//  Created by Shamyl Zakariya on 3/28/09.
//  Copyright 2009 Shamyl Zakariya. All rights reserved.
//

#import "NSView+viewAtPointExcluding.h"


@implementation NSView (viewAtPointExcluding)

- (id)viewAtPoint:(NSPoint)pt excludingView:(id)eView {
	for( NSView * view in [self subviews] ) {
		if( view != eView && [self mouse:pt inRect:[view frame]] ) {
			return (view);
		}
	}
	
	return nil;
}

@end
