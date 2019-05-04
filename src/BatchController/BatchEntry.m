//
//  BatchEntry.m
//  FilteredImageList
//
//  Created by Shamyl Zakariya on 3/12/09.
//  Copyright 2009 Shamyl Zakariya. All rights reserved.
//

#import "BatchEntry.h"
#import "LoadCGImage.h"

#define THUMB_SIZE 128;

@interface BatchEntry(Private)

-(void) createImage: (CGImageRef) sourceImage;
-(void) createThumb: (CGImageRef) sourceImage;
- (BOOL) looksLikeABumpmap: (NSBitmapImageRep*) sourceImage withTolerance: (int) tolerance;

@end


@implementation BatchEntry

+ (BatchEntry*) imageEntryWithURL: (NSURL*) url
{
	BatchEntry *e = [[BatchEntry alloc] initWithURL:url];
	if ( e )
	{
		return [e autorelease];
	}
	
	return nil;
}

+ (BatchEntry*) imageEntryWithPath: (NSString*) path
{
	BatchEntry *e = [[BatchEntry alloc] initWithPath:path];
	if ( e )
	{
		return [e autorelease];
	}
	
	return nil;
}

- (id) initWithURL: (NSURL*) url
{
	if ( self = [super init] )
	{
		path = [[url path] copy];
		displayTitle = [[path lastPathComponent] copy];
		displayPath = [path copy];
		identifier = [path copy];

		CGImageRef img = LoadCGImage( path );
		if ( img )
		{
			[self createImage:img];
			[self createThumb:img];
			
			CGColorSpaceRef colorSpace = CGImageGetColorSpace( img );

			//
			// This took a little experimentation, and may be wrong. I can't find a way to 
			// say "This image is a greyscale color space", but if an image has once color channel,
			// and that image does not have a color table ( e.g., indexed like a GIF or 8-bit PNG )
			// then I'm reasonably confident that the image is greyscale and can be considered
			// a bumpmap. Otherwise, we need to do a pixel-check. Note we're checking the
			// thumb, not the full image. I figure the thumb's as good a place to check as the image,
			// though in principle downsampling may cause single-pixel color samples to be lost enough to
			// false-positive the result. Imagine: a greyscale image with a single red pixel in the middle.
			//

			if ( CGColorSpaceGetNumberOfComponents( colorSpace ) == 1 && 
				 CGColorSpaceGetColorTableCount( colorSpace ) == 0 )
			{
				looksLikeBumpmap = YES;
			}
			else
			{
				looksLikeBumpmap = [self looksLikeABumpmap: thumbBitmap withTolerance: 8];
			}
			
			CGImageRelease(img);		
		}
		else
		{
			[self release];
			return nil;
		}
	}
	
	return self;
}


- (id) initWithPath: (NSString*) imagePath
{
	return [self initWithURL: [NSURL fileURLWithPath:imagePath]];
}

- (void) dealloc
{
	[image release];
	[thumb release];
	[imageBitmap release];
	[thumbBitmap release];

	[path release];
	[displayTitle release];
	[displayPath release];
	[identifier release];

	[super dealloc];
}	

- (NSString*) description
{
	return [NSString stringWithFormat: @"<BatchEntry bumpmap: %@ path: %@>", (self.looksLikeBumpmap ? @"YES" : @"NO" ), self.path ];
}

#pragma mark -
#pragma mark Synthesized Properties

@synthesize image;
@synthesize thumb;
@synthesize imageBitmap;
@synthesize thumbBitmap;
@synthesize path;
@synthesize displayTitle;
@synthesize displayPath;
@synthesize looksLikeBumpmap;
@synthesize identifier;

#pragma mark -
#pragma mark Private

-(void) createImage: (CGImageRef) sourceImage
{
	NSSize imageSize = NSMakeSize( CGImageGetWidth(sourceImage), CGImageGetHeight(sourceImage));
	
	image = [[NSImage alloc] initWithSize: imageSize];
	imageBitmap = [[NSBitmapImageRep alloc] 
		initWithBitmapDataPlanes:NULL 
		pixelsWide: (int)imageSize.width 
		pixelsHigh: (int)imageSize.height 
		bitsPerSample:8 
		samplesPerPixel:4
		hasAlpha:YES
		isPlanar:NO 
		colorSpaceName:NSDeviceRGBColorSpace 
		bytesPerRow:0 
		bitsPerPixel:0];

	[image addRepresentation:imageBitmap];

	NSGraphicsContext *gc = [NSGraphicsContext graphicsContextWithBitmapImageRep:imageBitmap];
	[NSGraphicsContext setCurrentContext:gc];
	CGContextRef cggc = [gc graphicsPort];
	CGContextSetInterpolationQuality(cggc, kCGInterpolationHigh);
	CGContextDrawImage(cggc, CGRectMake(0, 0, imageSize.width, imageSize.height), sourceImage);
}

-(void) createThumb: (CGImageRef) sourceImage
{
	NSSize imageSize = NSMakeSize( CGImageGetWidth(sourceImage), CGImageGetHeight(sourceImage)), thumbSize;

	CGFloat aspect = imageSize.width / imageSize.height;
	if ( aspect > 1 )
	{
		thumbSize.width = THUMB_SIZE;
		thumbSize.height = thumbSize.width / aspect;
	}
	else
	{
		thumbSize.height = THUMB_SIZE;
		thumbSize.width = thumbSize.height * aspect;
	}
	
	thumb = [[NSImage alloc] initWithSize: imageSize];
	thumbBitmap = [[NSBitmapImageRep alloc] 
		initWithBitmapDataPlanes:NULL 
		pixelsWide: (int)thumbSize.width 
		pixelsHigh: (int)thumbSize.height 
		bitsPerSample:8 
		samplesPerPixel:4
		hasAlpha:YES
		isPlanar:NO 
		colorSpaceName:NSDeviceRGBColorSpace 
		bytesPerRow:0 
		bitsPerPixel:0];

	[thumb addRepresentation:thumbBitmap];

	NSGraphicsContext *gc = [NSGraphicsContext graphicsContextWithBitmapImageRep:thumbBitmap];
	[NSGraphicsContext setCurrentContext:gc];
	CGContextRef cggc = [gc graphicsPort];
	CGContextSetInterpolationQuality(cggc, kCGInterpolationHigh);
	CGContextDrawImage(cggc, CGRectMake(0, 0, thumbSize.width, thumbSize.height), sourceImage);
}

- (BOOL) looksLikeABumpmap: (NSBitmapImageRep*) sourceImage withTolerance: (int) tolerance
{
	int width = sourceImage.size.width,
		height = sourceImage.size.height,
		bpp = 4;
	
	unsigned char *bytes = [sourceImage bitmapData];
							
	//
	// Check each pixel. The image is a heightmap iff all red/green/blue are close-to-equal
	//

	int length = width * height, i;
	for ( i = 0; i < length; i++ )
	{
		int offset = i * bpp;
		unsigned char r = bytes[offset],
					  g = bytes[offset+1],
					  b = bytes[offset+2];

		if ( ABS( r - g ) > tolerance ||
			 ABS( g - b ) > tolerance )
		{
			return NO;
		}
	}

	//
	// If we're here, the image appears to be grayscale within tolerance
	//
	
	return YES;
}


@end
