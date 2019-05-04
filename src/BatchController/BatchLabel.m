//
//  BatchLabel.m
//  FilteredImageList
//
//  Created by Shamyl Zakariya on 4/1/09.
//  Copyright 2009 Shamyl Zakariya. All rights reserved.
//

#import "BatchLabel.h"


@implementation BatchLabel

@synthesize label, fill, open, count;

- (id)initWithCoder:(NSCoder*)decoder 
{
    if (self = [super initWithCoder:decoder]) 
	{
		self.label = @"Unnamed";
    }
    return self;
}

- (id)initWithFrame:(NSRect)frame 
{
    if (self = [super initWithFrame:frame]) 
	{
		self.label = @"Unnamed";
    }
    return self;
}

- (void) awakeFromNib
{
	if ( toggleSwitch )
	{
		[toggleSwitch bind: @"value" toObject: self withKeyPath: @"open" options: nil];
		self.open = YES;
	}
}

- (void) dealloc
{
	[label release];
	[shadow release];
	[super dealloc];
}

- (void)drawRect:(NSRect)rect 
{
	if ( !fill )
	{
		self.fill = [[[NSGradient alloc] 
			initWithStartingColor: [NSColor colorWithDeviceWhite: 0.4 alpha:1] 
			endingColor:[NSColor colorWithDeviceWhite:0.3 alpha:1]] autorelease];
	}

	if ( !fillShadow )
	{
		fillShadow = [[NSGradient alloc] 
			initWithStartingColor:[NSColor colorWithDeviceWhite:0 alpha:0.5] 
			endingColor: [NSColor colorWithDeviceWhite:0 alpha:0]];
	}

	if ( !shadow )
	{
		shadow = [[NSShadow alloc] init];
		shadow.shadowBlurRadius = 1;
		shadow.shadowOffset = NSMakeSize( 0,-1 );
		shadow.shadowColor = [NSColor colorWithDeviceWhite:0 alpha:0.5];		
	}

	[[NSGraphicsContext currentContext] saveGraphicsState];

	CGFloat sh = 0;
	NSRect barRect = NSMakeRect(0,sh,self.bounds.size.width, self.bounds.size.height-sh);
	
	[self.fill drawInRect: barRect angle:270];
	
	if ( sh > 0 )
	{
		[fillShadow drawInRect:NSMakeRect(0,0,self.bounds.size.width,sh) angle:270];
	}
	
	[[NSGraphicsContext currentContext] restoreGraphicsState];

	NSDictionary *labelAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSFont fontWithName: @"Helvetica Neue Bold" size:20], NSFontAttributeName,
		[NSColor colorWithDeviceWhite:1 alpha:1], NSForegroundColorAttributeName,
		shadow, NSShadowAttributeName,
		nil ];

	NSDictionary *countAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSFont fontWithName: @"Helvetica Neue Light" size:20], NSFontAttributeName,
		[NSColor colorWithDeviceWhite:1 alpha:0.5], NSForegroundColorAttributeName,
		shadow, NSShadowAttributeName,
		nil ];

	NSMutableAttributedString *displayLabel = [[[NSMutableAttributedString alloc] initWithString:self.label attributes:labelAttributes] autorelease];
	NSAttributedString *countLabel = [[[NSAttributedString alloc] initWithString: [NSString stringWithFormat: @" (%d)", self.count] attributes:countAttributes] autorelease];
	[displayLabel appendAttributedString: countLabel];

	NSSize labelSize = [displayLabel size];
	CGFloat x = toggleSwitch ? 30 : 10;
	[displayLabel drawAtPoint: NSMakePoint( x,NSMidY( barRect ) - labelSize.height/2 + 1 )];		
}

- (void) mouseUp: (NSEvent*) event
{
	NSPoint point = [self convertPoint: [event locationInWindow] fromView:nil];
	BOOL inside = NSPointInRect( point, [self bounds] );
	
	if ( inside && toggleSwitch )
	{
		self.open = !self.open;
	}
}

#pragma mark -

- (void) setLabel: (NSString*) newLabel
{
	if ( newLabel != label )
	{
		[newLabel retain];
		[label release];
		label = newLabel;
		[self setNeedsDisplay:YES];
	}
}

- (void) setCount: (NSInteger) newCount
{
	if ( newCount != count )
	{
		count = newCount;
		[self setNeedsDisplay:YES];
	}
}

- (CGFloat) preferredHeight
{
	return 30;
}


@end
