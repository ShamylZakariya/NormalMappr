//
//  BatchEntry.h
//  FilteredImageList
//
//  Created by Shamyl Zakariya on 3/12/09.
//  Copyright 2009 Shamyl Zakariya. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BatchEntry : NSObject {
    NSURL *fileURL;
	NSImage *image, *thumb;
	NSBitmapImageRep *imageBitmap, *thumbBitmap;
	NSString *displayTitle, *displayPath, *identifier;
    CGFloat bumpmapScore;
}

+ (BatchEntry*) fromFileURL: (NSURL*) fileURL;

- (id) initWithFileURL: (NSURL*) fileURL;

@property (readonly) NSString* identifier;

@property (readonly) NSImage* image;
@property (readonly) NSImage* thumb;
@property (readonly) NSBitmapImageRep* imageBitmap;
@property (readonly) NSBitmapImageRep* thumbBitmap;
@property (readonly) NSURL* fileURL;
@property (readonly) NSString *filePath;
@property (readonly) BOOL looksLikeBumpmap;

@end
