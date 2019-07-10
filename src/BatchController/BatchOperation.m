//
//  BatchOperation.m
//  NormalMappr
//
//  Created by Shamyl Zakariya on 6/29/07.
//  Copyright 2007-2019 Shamyl Zakariya. All rights reserved.
//

#import "BatchOperation.h"
#import "CINormalMapper.h"

@implementation BatchOperation

/*
	BatchEntry *entry;
	BatchSettings *settings;
*/

- (id)initWithEntry:(BatchEntry*)e andSettings:(BatchSettings*)s
{
    if (self = [super init]) {
        entry = e;
        settings = s;
    }

    return self;
}

+ (BatchOperation*)batchOperationWithEntry:(BatchEntry*)entry andSettings:(BatchSettings*)settings;
{
    return [[BatchOperation alloc] initWithEntry:entry andSettings:settings];
}

- (NSURL*)outputURL
{
    //
    // build the file name (sans path)
    //

    NSString* outputFileName = [[entry.filePath lastPathComponent] stringByDeletingPathExtension];
    switch (settings.nameDecorationStyle) {
    case NMNameDecorationPrepend: {
        outputFileName = [settings.nameDecoration stringByAppendingString:outputFileName];
        break;
    }
    case NMNameDecorationAppend: {
        outputFileName = [outputFileName stringByAppendingString:settings.nameDecoration];
        break;
    }
    }
    outputFileName = [outputFileName stringByAppendingPathExtension:settings.saveFormatExtension];

    //
    // build the file path
    //

    NSString* outputFileLocation = [entry.filePath stringByDeletingLastPathComponent];
    if (settings.userSaveDestination != nil && settings.saveDestinationType == NMSaveDestinationUserSelected) {
        outputFileLocation = [settings.userSaveDestination path];
    }

    NSString* fullPath = [outputFileLocation stringByAppendingPathComponent:outputFileName];
    NSURL* fullURL = [NSURL fileURLWithPath:fullPath];
    return fullURL;
}

- (void)run
{
    CINormalMapper* nm = [[CINormalMapper alloc] init];
    nm.bumpmap = entry.imageBitmap;
    nm.strength = settings.strength / 100.0;
    nm.sampleSize = settings.sampleSize;

    nm.size = entry.imageBitmap.size;
    if (settings.resizeHeight && settings.resizeHeight) {
        nm.size = CGSizeMake(settings.outputWidth, settings.outputHeight);
    } else if (settings.resizeWidth) {
        // compute height maintaining aspect ratio
        nm.size = CGSizeMake(settings.outputWidth, nm.size.height * (settings.outputWidth / nm.size.width));
    } else if (settings.resizeHeight) {
        // compute width maintaining aspect ratio
        nm.size = CGSizeMake(nm.size.width * (settings.outputHeight / nm.size.height), settings.outputHeight);
    }

    NSBitmapImageRep* normalmap = nm.normalmap;

    if (normalmap) {
        NSDictionary* props = nil;
        switch (settings.saveFormat) {
        case NSJPEG2000FileType:
        case NSJPEGFileType: {
            props = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:settings.saveQuality] forKey:NSImageCompressionFactor];
            break;
        }

        case NSTIFFFileType: {
            props = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:NSTIFFCompressionLZW] forKey:NSImageCompressionMethod];
            break;
        }

        default:
            break;
        }

        NSData* data = [normalmap representationUsingType:settings.saveFormat properties:props];
        if (data) {
            [data writeToURL:[self outputURL] atomically:YES];
        }
    }
}

@end
