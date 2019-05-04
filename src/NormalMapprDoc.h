//
//  NormalMapprDoc.h
//  NormalMappr
//
//  Created by Shamyl Zakariya on 6/26/07.
//  Copyright Shamyl Zakariya 2007 . All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import "ImageView.h"
#import "TilingImageView.h"
#import "CINormalMapper.h"

#define kJPEG2000Format @"JPEG-2000"
#define kJPEGFormat @"JPEG"
#define kPNGFormat @"PNG"
#define kTIFFFormat @"TIFF"

@interface NormalMapprDoc : NSDocument <NSWindowDelegate>
{
	CGSize _outputSize;
	CINormalMapper *_normalmapper;
	NSArray *_saveFormats;
	NSString *_saveFormat;
	NSSavePanel *_currentSavePanel;
	NSDate *_fileTimestamp;
	float _saveQuality;
	BOOL _syncDimensions;

	IBOutlet NSWindow *docWindow;
	IBOutlet NSView *imageViewContainer;
	IBOutlet ImageView *imageView;
	IBOutlet TilingImageView *tilingImageView;
	IBOutlet NSScrollView *imageViewScroller;
	IBOutlet NSSlider *strengthSlider;
	IBOutlet NSSlider *sampleRadiusSlider;
	IBOutlet NSForm *outputDimensionsForm;
	IBOutlet NSView *savePanelDialog;
	IBOutlet NSBox *savePanelQualityControls;
	IBOutlet NSView *controlPanelView;
}

@property (readwrite) int strength;
@property (readwrite) int sampleRadius;
@property (readwrite) BOOL clampToEdge;
@property (readwrite) int outputWidth;
@property (readwrite) int outputHeight;
@property (readwrite) BOOL syncDimensions;
@property (readonly,retain) NSArray* saveFormats;
@property (readwrite,retain) NSString* saveFormat;
@property (readwrite) float saveQuality;
@property (readwrite) int tileMode;

#pragma mark -

/**
	Reload the current image being displayed
*/
- (void) reload;

#pragma mark -

- (IBAction) export: (id) sender;
- (IBAction) showSingleImage: (id) sender;
- (IBAction) showTiledImage: (id) sender;

#pragma mark -

- (NSRect) windowWillUseStandardFrame:(NSWindow *)window defaultFrame:(NSRect)newFrame;


@end
