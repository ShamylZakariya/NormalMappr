//
//  ControlPanelView.m
//  NormalMappr
//
//  Created by Shamyl Zakariya on 6/29/07.
//  Copyright 2007 Shamyl Zakariya. All rights reserved.
//

#import "ControlPanelView.h"

@implementation ControlPanelView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		_gradient = [[NSGradient alloc] 
			initWithStartingColor: [NSColor colorWithDeviceWhite:0.85f alpha:1.0f] 
			endingColor:[NSColor colorWithDeviceWhite:0.95f alpha:1.0f]];
    }
    return self;
}

- (void) dealloc
{
	[_gradient release];
	[super dealloc];
}

- (void)drawRect:(NSRect)rect {

	NSRect bounds = [self bounds];

	NSPoint origin = [self convertPoint: bounds.origin toView: nil];
	BOOL drawBottomLine = origin.y >= 1.0f;

	[_gradient drawInRect: bounds angle: 90];
	
	[[NSColor colorWithDeviceWhite: 0 alpha: 0.65] set];
	NSBezierPath *line = [NSBezierPath bezierPath];
	
	[line moveToPoint: NSMakePoint(0, bounds.size.height)];
	[line lineToPoint: NSMakePoint(bounds.size.width, bounds.size.height)];

	if ( drawBottomLine )
	{
		[line moveToPoint: NSMakePoint(0, 0)];
		[line lineToPoint: NSMakePoint(bounds.size.width, 0)];
	}

	[line setLineWidth: 1];
	[line stroke];
}

@end
