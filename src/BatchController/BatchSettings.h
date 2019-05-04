//
//  BatchSettings.h
//  NormalMappr
//
//  Created by Shamyl Zakariya on 4/13/09.
//  Copyright 2009 Shamyl Zakariya. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum _NMNameDecoration
{
	NMNameDecorationPrepend = 0,
	NMNameDecorationAppend = 1
} NMNameDecoration;


@interface BatchSettings : NSObject {

	BOOL syncOutputDimensions, resizeOutput, showSaveQualityControls;

	CGFloat saveQuality, strength;

	int outputWidth, outputHeight, 
	    sampleRadius, saveFormat;

	NSString *nameDecoration;


	NMNameDecoration nameDecorationStyle;
}

- (void) loadPrefs;
- (void) savePrefs;

@property (readwrite) BOOL syncOutputDimensions;
@property (readwrite) BOOL resizeOutput;
@property (readwrite) CGFloat saveQuality;
@property (readwrite) CGFloat strength;
@property (readwrite) int outputWidth;
@property (readwrite) int outputHeight; 
@property (readwrite) int sampleRadius;
@property (readwrite) int saveFormat;
@property (readonly) NSString* saveFormatExtension;
@property (readwrite,retain) NSString* nameDecoration;
@property (readwrite) NMNameDecoration nameDecorationStyle;
@property (readwrite) BOOL showSaveQualityControls;

@end
