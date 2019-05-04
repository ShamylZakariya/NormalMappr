//
//  BatchEntry.h
//  FilteredImageList
//
//  Created by Shamyl Zakariya on 3/12/09.
//  Copyright 2009 Shamyl Zakariya. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BatchEntry : NSObject {
	NSImage *image, *thumb;
	NSBitmapImageRep *imageBitmap, *thumbBitmap;
	NSString *path, *displayTitle, *displayPath, *identifier;
	BOOL looksLikeBumpmap;
	BOOL isSeparator;
}

+ (BatchEntry*) imageEntryWithURL: (NSURL*) url;
+ (BatchEntry*) imageEntryWithPath: (NSString*) path;

- (id) initWithURL: (NSURL*) url;
- (id) initWithPath: (NSString*) path;

@property (readonly,copy) NSString* identifier;

@property (readonly,retain) NSImage* image;
@property (readonly,retain) NSImage* thumb;
@property (readonly,retain) NSBitmapImageRep* imageBitmap;
@property (readonly,retain) NSBitmapImageRep* thumbBitmap;
@property (readonly,retain) NSString* path;

@property (readonly) NSString* displayTitle;
@property (readonly) NSString* displayPath;

@property (readwrite) BOOL looksLikeBumpmap;

@end
