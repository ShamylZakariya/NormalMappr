//
//  BatchOperation.m
//  NormalMappr
//
//  Created by Shamyl Zakariya on 6/29/07.
//  Copyright 2007 Shamyl Zakariya. All rights reserved.
//

#import "BatchOperation.h"
#import "CINormalMapper.h"

@implementation BatchOperation

/*
	BatchEntry *entry;
	BatchSettings *settings;
*/

- (id) initWithEntry: (BatchEntry*) e andSettings: (BatchSettings*) s
{
	if ( self = [super init] )
	{
		entry = [e retain];
		settings = [s retain];
	}
	
	return self;
}

+ (BatchOperation*) batchOperationWithEntry: (BatchEntry*) entry andSettings: (BatchSettings*) settings;
{
	return [[[BatchOperation alloc] initWithEntry: entry andSettings: settings] autorelease];
}

- (void) dealloc
{
	[entry release];
	[settings release];
	[super dealloc];
}

- (NSURL*) outputURL
{
	NSString *outputFile = nil;
	
	switch( settings.nameDecorationStyle )
	{
		case NMNameDecorationPrepend:
		{
			NSString *pathToFile = [entry.path stringByDeletingLastPathComponent];
			NSString *name = [entry.path lastPathComponent];
			
			outputFile = [settings.nameDecoration stringByAppendingString: name];
			outputFile = [pathToFile stringByAppendingPathComponent: outputFile];			
			break;
		}
		
		case NMNameDecorationAppend:
		{
			outputFile = [entry.path stringByDeletingPathExtension];
			outputFile = [outputFile stringByAppendingString: settings.nameDecoration];
			outputFile = [outputFile stringByAppendingPathExtension: settings.saveFormatExtension];
			break;
		}
	}

	return [NSURL fileURLWithPath:outputFile];
}

- (void) run
{
	CINormalMapper *nm = [[CINormalMapper alloc] init];
	nm.bumpmap = entry.imageBitmap;
	nm.strength = settings.strength;
	nm.sampleRadius = settings.sampleRadius;
	
	if ( settings.resizeOutput )
	{
		nm.size = CGSizeMake( settings.outputWidth, settings.outputHeight );
	}	
	
	NSBitmapImageRep *normalmap = nm.normalmap;

	if ( normalmap )
	{
		NSDictionary *props = nil;
		switch( settings.saveFormat )
		{
			case NSJPEG2000FileType:
			case NSJPEGFileType:
			{
				props = [NSDictionary dictionaryWithObject: [NSNumber numberWithFloat:settings.saveQuality] forKey: NSImageCompressionFactor];
				break;
			}
			
			case NSTIFFFileType:
			{
				props = [NSDictionary dictionaryWithObject: [NSNumber numberWithInt:NSTIFFCompressionLZW] forKey: NSImageCompressionMethod];
				break;
			}
			
			default: break;
		}
	
		NSData *data = 	[normalmap representationUsingType: settings.saveFormat properties:props];
		if ( data )
		{
			[data writeToURL: [self outputURL] atomically:YES];
		}
	}	
	
	[nm release];
}


@end
