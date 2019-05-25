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
        entry = e;
        settings = s;
	}
	
	return self;
}

+ (BatchOperation*) batchOperationWithEntry: (BatchEntry*) entry andSettings: (BatchSettings*) settings;
{
	return [[BatchOperation alloc] initWithEntry: entry andSettings: settings];
}

- (NSURL*) outputURL
{
	NSString *outputFile = nil;
	
	switch( settings.nameDecorationStyle )
	{
		case NMNameDecorationPrepend:
		{            
			NSString *pathToFile = [entry.filePath stringByDeletingLastPathComponent];
			NSString *name = [entry.filePath lastPathComponent];
			
			outputFile = [settings.nameDecoration stringByAppendingString: name];
			outputFile = [pathToFile stringByAppendingPathComponent: outputFile];			
			break;
		}
		
		case NMNameDecorationAppend:
		{
			outputFile = [entry.filePath stringByDeletingPathExtension];
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
	nm.strength = settings.strength / 100.0;
	nm.sampleRadius = settings.sampleRadius;
	
    nm.size = entry.imageBitmap.size;
    if (settings.resizeHeight && settings.resizeHeight)
    {
        nm.size = CGSizeMake(settings.outputWidth, settings.outputHeight);
    }
    else if (settings.resizeWidth)
    {
        // compute height maintaining aspect ratio
        nm.size = CGSizeMake(settings.outputWidth, nm.size.height * (settings.outputWidth / nm.size.width));
    }
    else if (settings.resizeHeight)
    {
        // compute width maintaining aspect ratio
        nm.size = CGSizeMake(nm.size.width * (settings.outputHeight / nm.size.height), settings.outputHeight);
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
}


@end
