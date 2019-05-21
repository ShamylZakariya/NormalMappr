//
//  CINormalMapper.m
//  CINormapMappr
//
//  Created by Shamyl Zakariya on 3/2/09.
//  Copyright 2009 Shamyl Zakariya. All rights reserved.
//

#import "CINormalMapper.h"

@interface CINormalMapper(Private)

- (void) render;
- (void) prepareBuffers;

@end



@implementation CINormalMapper

- (id) init
{
	if ( self = [super init] )
	{
		colorSpace = CGColorSpaceCreateDeviceRGB();
        filter = (NormalMapFilter*) [CIFilter filterWithName: @"NormalMapFilter"];
		dirty = YES;
	}
	
	return self;
}

- (id) initWithBumpmap: (NSURL*) bumpmapURL strength: (float) strength sampleRadius: (float) sampleRadius andClampToEdge: (BOOL) cte
{
	if ( self = [self init] )
	{
		NSData *data = [NSData dataWithContentsOfURL: bumpmapURL];
		if ( data )
		{
			NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithData: data];
			if ( bitmap )
			{
				self.bumpmap = bitmap;
				self.strength = strength;
				self.sampleRadius = sampleRadius;
				self.clampToEdge = cte;
			}
			else
			{
				NSLog( @"Unable to open image at URL %@", bumpmapURL );
				return nil;
			}
		}
		else
		{
			NSLog( @"No data at URL %@", bumpmapURL );
			return nil;
		}
	}
	
	return self;
}

#pragma mark -

@synthesize dirty;

- (void) setBumpmap: (NSBitmapImageRep*) newBumpmap
{
	if ( newBumpmap != bumpmap )
	{
        bumpmap = newBumpmap;
		inputImage = nil;

		self.size = bumpmap ? NSSizeToCGSize([bumpmap size]) : CGSizeMake(0.0,0.0);
		dirty = YES;
	}
}

- (NSBitmapImageRep*) bumpmap
{
	return bumpmap;
}

- (NSBitmapImageRep*) normalmap
{
	if ( dirty )
	{
		[self render];
		dirty = NO;
	}

	return normalmap;
}

- (void) setStrength: (float) newStrength
{
	filter.strength = MIN(MAX(newStrength, 0), 1);
	dirty = YES;
}

- (float) strength 
{ 
	return filter.strength; 
}

- (void) setSampleRadius: (float) newSampleRadius
{
	filter.sampleRadius = newSampleRadius;
	dirty = YES;
}

- (float) sampleRadius
{
	return filter.sampleRadius;
}

- (void) setSize: (CGSize) newSize
{
	newSize.width = lrintf( newSize.width );
	newSize.height = lrintf( newSize.height );

	if ( ((int) newSize.width != (int) size.width) ||
	     ((int) newSize.height != (int) size.height) )
	{
		size = newSize;
		dirty = YES;
	}
}

- (CGSize) size
{
	return size;
}

- (void) setClampToEdge: (BOOL) cte
{
	filter.clampToEdge = cte;
	dirty = YES;
}

- (BOOL) clampToEdge
{
	return filter.clampToEdge;
}

#pragma mark -
#pragma mark Private

- (void) render
{
	[self prepareBuffers];
	
	//
	// We can't just use the NSGraphicsContext's CIContext since we need to set the color space
	//

	NSGraphicsContext *nsContext = [NSGraphicsContext graphicsContextWithBitmapImageRep:normalmap];
	CIContext *ciContext = [CIContext 
		contextWithCGContext: (CGContextRef)[nsContext graphicsPort]
		options:
			[NSDictionary dictionaryWithObjectsAndKeys: 
             (__bridge id)colorSpace, kCIContextOutputColorSpace,
             (__bridge id)colorSpace, kCIContextWorkingColorSpace,
				nil]];
			
	[filter setValue: inputImage forKey: kCIInputImageKey];
	
	//
	// And draw
	//

    [ciContext drawImage:filter.outputImage inRect:CGRectMake(0, 0, self.size.width, self.size.height) fromRect:CGRectMake(0,0,self.size.width,self.size.height)];
}

- (void) prepareBuffers
{
	//
	// Create or update the normalmap to match size
	//

	if ( !normalmap || 
	      ABS( self.size.width - [normalmap size].width ) > 0.0f ||
		  ABS( self.size.height - [normalmap size].height ) > 0.0f )
	{
		//
		// create normalmap
		//

		normalmap = [[NSBitmapImageRep alloc]
			initWithBitmapDataPlanes:NULL 
			pixelsWide:self.size.width 
			pixelsHigh:self.size.height 
			bitsPerSample:8 
			samplesPerPixel:4 
			hasAlpha:YES 
			isPlanar:NO 
			colorSpaceName:NSDeviceRGBColorSpace 
			bytesPerRow:0 
			bitsPerPixel:0];
	}


	//
	// create or update inputImage to match size
	//
	if ( !inputImage ||
	     ABS( self.size.width - [inputImage extent].size.width ) > 0.0f ||
	     ABS( self.size.height - [inputImage extent].size.height ) > 0.0f )
	{
		NSBitmapImageRep *tempBitmap = [[NSBitmapImageRep alloc] 
			initWithBitmapDataPlanes:NULL 
			pixelsWide:self.size.width 
			pixelsHigh:self.size.height 
			bitsPerSample:8 
			samplesPerPixel:4 
			hasAlpha:YES 
			isPlanar:NO 
			colorSpaceName:NSDeviceRGBColorSpace 
			bytesPerRow:0 
			bitsPerPixel:0];
		
		NSGraphicsContext *nsContext = [NSGraphicsContext graphicsContextWithBitmapImageRep:tempBitmap];
		[nsContext setImageInterpolation: NSImageInterpolationHigh];

		[NSGraphicsContext saveGraphicsState];
		[NSGraphicsContext setCurrentContext: nsContext];

		//
		//	In 10.6, apparently, I've got to flip my images
		//

		NSAffineTransform *affine = [NSAffineTransform transform];
		[affine translateXBy: 0 yBy: self.size.height];
		[affine scaleXBy: 1 yBy: -1 ];
		[affine set];

			[bumpmap drawInRect:NSMakeRect(0, 0, self.size.width, self.size.height )];

		[NSGraphicsContext restoreGraphicsState];

		//
		// Now create a CIImage from that resized bitmap
		//

        inputImage = [CIImage imageWithData: [tempBitmap TIFFRepresentation]];
	}
}


@end
