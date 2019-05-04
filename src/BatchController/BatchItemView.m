//
//  BatchItemView.m
//  FilteredImageList
//
//  Created by Shamyl Zakariya on 3/22/09.
//  Copyright 2009 Shamyl Zakariya. All rights reserved.
//

#import "BatchItemView.h"

@interface BatchItemView(Private)

- (NSView*) hitTest: (NSPoint) point forView: (NSView*) view;

@end


@implementation BatchItemView

- (id) initWithCoder: (NSCoder*) decoder
{
	if ( self = [super initWithCoder: decoder] )
	{
	}
	
	return self;
}

- (id)initWithFrame:(NSRect)frame {
    if (self = [super initWithFrame:frame]) 
	{

    }
    return self;
}

- (void)drawRect:(NSRect)rect 
{
	if ( !self.isTransparent )
	{
		NSBezierPath *b = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect( self.bounds, 5,5 ) xRadius:6 yRadius:6];
		[[NSColor colorWithDeviceWhite:1 alpha:0.3] set];
		[b fill]; 
		
	}
}

- (BOOL)acceptsFirstResponder
{
	return NO;
}

- (NSView *)hitTest:(NSPoint)aPoint
{
	for ( NSView *sv in self.subviews )
	{
		NSView *tv = [self hitTest: aPoint forView: sv];
		if ( tv ) return tv;
	}

	return nil;
}

#pragma mark -
#pragma mark Private

- (NSView*) hitTest: (NSPoint) point forView: (NSView*) view
{
	if(NSPointInRect(point,[view convertRect:[view bounds] toView:[view superview]])) 
	{
		return view;
	} 

	return nil;    
}


@end
