//
//  LoadCGImage.m
//  NormalMappr
//
//  Created by Shamyl Zakariya on 3/8/09.
//  Copyright 2009-2019 Shamyl Zakariya. All rights reserved.
//

#import "LoadCGImage.h"

CGImageRef
LoadCGImage(NSString* filename)
{
    CFStringRef path = NULL;
    CFURLRef url = NULL;

    path = CFStringCreateWithCString(NULL, [filename fileSystemRepresentation],
        kCFStringEncodingUTF8);

    url = CFURLCreateWithFileSystemPath(NULL, path,
        kCFURLPOSIXPathStyle, false);
    CFRelease(path);

    CGImageRef image = NULL;
    CGImageSourceRef sourceRef = NULL;

    sourceRef = CGImageSourceCreateWithURL(url, NULL);

    CFRelease(url);

    if (sourceRef) {
        image = CGImageSourceCreateImageAtIndex(sourceRef, 0, NULL);
        CFRelease(sourceRef);
    }

    return image;
}
