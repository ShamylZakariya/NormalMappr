//
//  BatchItemLabel.m
//  FilteredImageList
//
//  Created by Shamyl Zakariya on 4/1/09.
//  Copyright 2009 Shamyl Zakariya. All rights reserved.
//

#import "BatchItemLabel.h"


@implementation BatchItemLabel


- (void)drawRect:(NSRect)rect 
{
	if ( !shadow )
	{
		shadow = [[NSShadow alloc] init];
		shadow.shadowBlurRadius = 1;
		shadow.shadowOffset = NSMakeSize( 0,-1 );
		shadow.shadowColor = [NSColor colorWithDeviceWhite:0 alpha:0.5];		
	}

	NSGraphicsContext *context = [NSGraphicsContext currentContext];
	[context saveGraphicsState];

	[shadow set];

	[super drawRect: rect];
	
	[context restoreGraphicsState];
}

@end
