//
//  TilingImageView.m
//  NormalMappr
//
//  Created by Shamyl Zakariya on 3/8/09.
//  Copyright 2009 Shamyl Zakariya. All rights reserved.
//

#import "TilingImageView.h"


@implementation TilingImageView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    return self;
}

- (void)drawRect: (NSRect) rect 
{
    CGFloat scale = self.hiDPI ? (1.0f / [[self window] screen].backingScaleFactor) : 1.0f;
	NSRect myBounds = [self bounds];
	NSSize imageSize = self.image.size;

	imageSize.width *= scale;
	imageSize.height *= scale;


	NSUInteger rows = (NSUInteger)ceilf( myBounds.size.height / imageSize.height ),
		cols = (NSUInteger)ceilf( myBounds.size.width / imageSize.width ),
		row, col;
		
	if ( !( rows % 2 ) ) rows++;
	if ( !( cols % 2 ) ) cols++;
		
	NSPoint imageOrigin = NSMakePoint( myBounds.size.width / 2 - imageSize.width / 2, myBounds.size.height / 2 - imageSize.height / 2 ),
			origin = NSMakePoint( rint( imageOrigin.x - ( imageSize.width * ( cols / 2 ))) - 0.5,
								  rint( imageOrigin.y - ( imageSize.height * ( rows / 2 ))) - 0.5 );
		
	
	NSGraphicsContext *currentContext = [NSGraphicsContext currentContext];
	[currentContext setShouldAntialias: NO];
	
	for ( row = 0; row < rows; row ++ )
	{
		for ( col = 0; col < cols; col++ )
		{
			NSPoint outOrigin = NSMakePoint( origin.x + col * imageSize.width, origin.y + row * imageSize.height );
			NSRect outRect = [self centerScanRect: NSMakeRect( outOrigin.x, outOrigin.y, imageSize.width, imageSize.height )];
			[self.image drawInRect: outRect];
		}
	}

	[currentContext setShouldAntialias: YES];
}

@end
