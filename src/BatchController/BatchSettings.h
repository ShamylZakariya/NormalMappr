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

@property (nonatomic, readwrite) BOOL syncOutputDimensions;
@property (nonatomic, readwrite) BOOL resizeOutput;
@property (nonatomic, readwrite) CGFloat saveQuality;
@property (nonatomic, readwrite) CGFloat strength;
@property (nonatomic, readwrite) int outputWidth;
@property (nonatomic, readwrite) int outputHeight;
@property (nonatomic, readwrite) int sampleRadius;
@property (nonatomic, readwrite) int saveFormat;
@property (readonly) NSString* saveFormatExtension;
@property (nonatomic, readwrite) NSString* nameDecoration;
@property (nonatomic, readwrite) NMNameDecoration nameDecorationStyle;
@property (nonatomic, readwrite) BOOL showSaveQualityControls;

@end
