//
//  BatchControlsView.m
//  NormalMappr
//
//  Created by Shamyl Zakariya on 7/3/07.
//  Copyright 2007 Shamyl Zakariya. All rights reserved.
//

#import "BatchControlsView.h"


@implementation BatchControlsView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		_gradient = [[NSGradient alloc] 
			initWithStartingColor: [NSColor colorWithDeviceWhite:0.8f alpha:1.0f] 
			endingColor:[NSColor colorWithDeviceWhite:0.95f alpha:1.0f]];
    }
    return self;
}

- (void)drawRect:(NSRect)rect {
	[[NSColor whiteColor] set];
	NSRectFill( [self bounds] );

	[_gradient drawInRect: self.bounds angle: 90];
}

@end
