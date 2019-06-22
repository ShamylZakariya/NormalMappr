//
//  BatchEntry.m
//  FilteredImageList
//
//  Created by Shamyl Zakariya on 3/12/09.
//  Copyright 2009-2019 Shamyl Zakariya. All rights reserved.
//

#import "BatchEntry.h"
#import "LoadCGImage.h"

#define kTHUMB_SIZE 128
#define kCOLOR_THRESHOLD 16.0

@interface BatchEntry(Private)

-(void) createImage: (CGImageRef) sourceImage;
-(void) createThumb: (CGImageRef) sourceImage;
- (CGFloat) computeBumpmapScore: (NSBitmapImageRep*) image;

@end


@implementation BatchEntry

+ (BatchEntry*) fromFileURL: (NSURL*) fileURL
{
	BatchEntry *e = [[BatchEntry alloc] initWithFileURL:fileURL];
	if ( e )
	{
        return e;
	}
	
	return nil;
}

- (id) initWithFileURL: (NSURL*) fileURL
{
	if ( self = [super init] )
	{
        self->fileURL = fileURL;
        identifier = self.filePath;

		CGImageRef img = LoadCGImage( self.filePath );
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
                bumpmapScore = 0; // small value means YES, this is a bumpmap
            }
            else
            {
                bumpmapScore = [self computeBumpmapScore:thumbBitmap];
            }
			
			CGImageRelease(img);		
		}
		else
		{
			return nil;
		}
	}
	
	return self;
}

- (NSString*) description
{
	return [NSString stringWithFormat: @"<BatchEntry bumpmap: %@ path: %@>", (self.looksLikeBumpmap ? @"YES" : @"NO" ), self.filePath ];
}

#pragma mark -
#pragma mark Synthesized Properties

@synthesize image;
@synthesize thumb;
@synthesize imageBitmap;
@synthesize thumbBitmap;
@synthesize fileURL = fileURL;
@synthesize identifier;

- (NSString*) filePath
{
    return @(fileURL.fileSystemRepresentation);
}

- (BOOL) looksLikeBumpmap
{
    return bumpmapScore < kCOLOR_THRESHOLD;
}

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
		thumbSize.width = kTHUMB_SIZE;
		thumbSize.height = thumbSize.width / aspect;
	}
	else
	{
		thumbSize.height = kTHUMB_SIZE;
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

- (CGFloat) computeBumpmapScore:(NSBitmapImageRep*)image
{
    int width = image.size.width,
        height = image.size.height,
        bpp = 4,
        length = width * height,
        i;
    
    unsigned char *bytes = [image bitmapData];
    
    //
    // Compute the mean deviation from grayscale
    //

    long sum = 0;
    for ( i = 0; i < length; i++ )
    {
        int offset = i * bpp;
        unsigned char r = bytes[offset],
            g = bytes[offset+1],
            b = bytes[offset+2];
        
        sum += ABS(r - g) + ABS(g - b) + ABS(b - r);
    }
    
    CGFloat mean = (CGFloat)sum / (CGFloat) length;
    return mean;
}

@end
