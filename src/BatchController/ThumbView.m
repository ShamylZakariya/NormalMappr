//
//  ThumbView.m
//  FilteredImageList
//
//  Created by Shamyl Zakariya on 3/21/09.
//  Copyright 2009 Shamyl Zakariya. All rights reserved.
//

#import "ThumbView.h"


@implementation ThumbView

- (id)initWithCoder:(NSCoder *)decoder
{
	if ( self = [super initWithCoder: decoder] )
	{
		self.inset = 0;
	}
	
	return self;
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		self.inset = 0;
    }
    return self;
}

- (void)drawRect:(NSRect)rect 
{	
	if ( !shadow )
	{
		shadow = [[NSShadow alloc] init];
		shadow.shadowBlurRadius = 5;
		shadow.shadowOffset = NSMakeSize( 0,-2 );
		shadow.shadowColor = [NSColor colorWithDeviceWhite:0.25 alpha:1];
	}


	NSImage *image = [self image];
	NSRect imageBounds = NSInsetRect([self bounds], inset + shadow.shadowBlurRadius, inset + 2*shadow.shadowBlurRadius);
	NSSize imageSize = [image size];	

	//
	// Scale image size to fit
	//
	
	CGFloat scale = imageBounds.size.width / imageSize.width;
	imageSize.width *= scale;
	imageSize.height *= scale;

	if ( imageSize.height > imageBounds.size.height )
	{
		scale = imageBounds.size.height / imageSize.height;
		imageSize.width *= scale;
		imageSize.height *= scale;
	}
	
	//
	// Make centered rect for image
	//
	
	NSRect imageRect = NSMakeRect( NSMidX( imageBounds ) - imageSize.width/2, NSMidY(imageBounds) - imageSize.height/2, imageSize.width, imageSize.height );
	NSRect frameRect = NSInsetRect(imageRect, -self.inset, -self.inset );

	NSGraphicsContext *context = [NSGraphicsContext currentContext];
	[context saveGraphicsState];

	[shadow set];
	[[NSColor whiteColor] set];
	NSRectFill( frameRect );
	
	[context restoreGraphicsState];

	[self.image drawInRect:imageRect fromRect:NSMakeRect(0,0,self.image.size.width,self.image.size.height) operation:NSCompositeSourceOver fraction:1];
}

- (BOOL) isOpaque
{
	return NO;
}

#pragma mark -
#pragma mark Properties

@synthesize inset;

- (void) setInset: (CGFloat) newInset
{
	inset = newInset;
	[self setNeedsDisplay:YES];
}

@end
